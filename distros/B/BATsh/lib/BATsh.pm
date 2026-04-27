package BATsh;
######################################################################
#
# BATsh - Bilingual Shell: cmd.exe and bash in one script
#
# Version 0.01 -- Self-contained interpreter
#
# https://metacpan.org/dist/BATsh
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org>
#
# This version implements both cmd.exe and sh/bash command sets
# entirely in Perl.  No external cmd.exe, bash, or sh is required.
#
######################################################################

use 5.00503;
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use File::Spec ();
use Carp qw(croak);
use vars qw($VERSION);
$VERSION = '0.01';
$VERSION = $VERSION;

require BATsh::Env;
require BATsh::CMD;
require BATsh::SH;

###############################################################################
# Architecture
###############################################################################
#
# BATsh is a self-contained bilingual shell interpreter.
#
# It splits a script into CMD sections and SH sections, then executes
# each section using its own pure-Perl interpreter:
#
#   BATsh::CMD  -- cmd.exe command set (SET, ECHO, IF, FOR, GOTO, ...)
#   BATsh::SH   -- sh/bash command set (echo, export, if/fi, for/done, ...)
#   BATsh::Env  -- shared variable store (bridge between both modes)
#
# MODE DETECTION: first non-empty, non-comment token of each section.
#   CMD: token is [A-Z 0-9 _ - \ / : . @ %]+ with at least one A-Z
#   SH:  anything else
#
# SECTION BOUNDARY:
#   CMD: parenthesis ( ) depth returns to 0
#   SH:  keyword depth (if/fi, for/done, ...) returns to 0
#
# ENV BRIDGE:
#   BATsh::Env::STORE is the single variable table.
#   CMD %VAR% and SH $VAR both read/write the same store.
#
###############################################################################

###############################################################################
# Global state
###############################################################################
my $_TMPCOUNT = 0;

# Subroutine registry: { LABEL => \@lines }
my %_SUBROUTINES = ();

###############################################################################
# Constructor
###############################################################################
sub new {
    my ($class, %args) = @_;
    BATsh::Env::init();
    return bless { verbose => $args{verbose} || 0 }, $class;
}

###############################################################################
# Public run interface
###############################################################################
sub run {
    my ($class_or_self, $file, %args) = @_;
    unless (-f $file) { croak "BATsh->run: file not found: $file" }
    local *SRCFH;
    open(SRCFH, $file) or croak "BATsh->run: cannot open $file: $!";
    my @lines = <SRCFH>;
    close(SRCFH);
    _ensure_env_init();
    _process_lines(@lines);
    return 1;
}

sub run_string {
    my ($class_or_self, $source) = @_;
    croak "BATsh->run_string: source required" unless defined $source;
    my @lines = map { "$_\n" } split(/\n/, $source, -1);
    _ensure_env_init();
    _process_lines(@lines);
    return 1;
}

sub run_lines {
    my ($class_or_self, @lines) = @_;
    _ensure_env_init();
    _process_lines(@lines);
    return 1;
}

sub _ensure_env_init {
    # Init only once per process
    BATsh::Env::init() unless %BATsh::Env::STORE;
}

###############################################################################
# classify_token
###############################################################################
sub classify_token {
    my ($class_or_token, $token) = @_;
    unless (defined $token) { $token = $class_or_token }
    if ($token =~ /\A[A-Z0-9_\-\\\/\.:@%]+\z/ && $token =~ /[A-Z]/) {
        return 'CMD';
    }
    return 'SH';
}

###############################################################################
# Line parser
# Returns ($mode, $stripped_line, $first_token)
###############################################################################
sub _parse_line {
    my ($line) = @_;
    (my $s = $line) =~ s/\r?\n\z//;
    return ('EMPTY', $s, '')   if $s =~ /\A\s*\z/;
    return ('COMMENT', $s, '') if $s =~ /\A\s*(?:::|\@?REM(?:\s|\z))/i;
    return ('COMMENT', $s, '') if $s =~ /\A\s*#(?!!)/;
    (my $t = $s) =~ s/\A\s+//;
    my $first = ($t =~ /\A(\S+)/) ? $1 : '';
    return (classify_token($first), $s, $first);
}

###############################################################################
# CMD section depth: count unquoted ( )
###############################################################################
sub _cmd_paren_delta {
    my ($line) = @_;
    my ($delta, $in_q) = (0, 0);
    for my $ch (split //, $line) {
        if ($ch eq '"')     { $in_q = !$in_q }
        elsif (!$in_q) {
            $delta++ if $ch eq '(';
            $delta-- if $ch eq ')';
        }
    }
    return $delta;
}

###############################################################################
# SH section depth
###############################################################################
my %_SH_OPEN  = map { $_ => 1 } qw(if for while until case function select);
my %_SH_CLOSE = map { $_ => 1 } qw(fi done esac);

sub _sh_depth_delta {
    my ($first) = @_;
    my $l = lc($first);
    return  1 if exists $_SH_OPEN{$l} || $first eq '{';
    return -1 if exists $_SH_CLOSE{$l} || $first eq '}';
    return  0;
}

###############################################################################
# Subroutine extraction
###############################################################################
sub _extract_subroutines {
    my (@lines) = @_;
    my @out = (); my $in_sub = ''; my @sub_body = ();

    # Two-pass: first identify which :LABEL lines have a matching RET/RETURN.
    # Only those are BATsh subroutines; pure GOTO labels stay in the stream.
    my %is_sub_label = ();
    {
        my $cur = '';
        for my $line (@lines) {
            (my $s = $line) =~ s/\r?\n\z//;
            $s =~ s/\A\s+//;
            if ($s =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
                $cur = uc($1);
            }
            elsif ($cur ne '' && $s =~ /\A(?:RET|RETURN)\s*\z/i) {
                $is_sub_label{$cur} = 1;
                $cur = '';
            }
            elsif ($cur ne '' && $s =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
                # New label before RET: previous one is a GOTO label, not sub
                $cur = uc($1);
            }
        }
    }

    for my $line (@lines) {
        (my $s = $line) =~ s/\r?\n\z//;
        $s =~ s/\A\s+//;
        if ($s =~ /\A:([A-Za-z_][A-Za-z0-9_]*)\s*\z/) {
            my $lbl = uc($1);
            if ($is_sub_label{$lbl}) {
                # This is a BATsh subroutine definition
                $_SUBROUTINES{$in_sub} = [@sub_body] if $in_sub ne '';
                $in_sub = $lbl; @sub_body = ();
                next;   # remove label line from stream
            }
            else {
                # This is a GOTO label: keep in stream for CMD interpreter
                push @out, $line if $in_sub eq '';
                push @sub_body, $line if $in_sub ne '';
                next;
            }
        }
        if ($in_sub ne '') {
            if ($s =~ /\A(?:RET|RETURN)\s*\z/i) {
                $_SUBROUTINES{$in_sub} = [@sub_body];
                $in_sub = ''; @sub_body = ();
            } else { push @sub_body, $line }
            next;
        }
        push @out, $line;
    }
    $_SUBROUTINES{$in_sub} = [@sub_body] if $in_sub ne '';
    return @out;
}

###############################################################################
# call_sub / source_file
###############################################################################
sub call_sub {
    my ($class_or_self, $label, @args) = @_;
    $label = uc($label); $label =~ s/^://;
    croak "BATsh->call_sub: undefined subroutine :$label"
        unless exists $_SUBROUTINES{$label};
    $BATsh::Env::STORE{'BATSH_ARGC'} = scalar @args;
    for my $i (1 .. scalar @args) {
        $BATsh::Env::STORE{"BATSH_ARG$i"} = $args[$i-1];
    }
    _process_lines(@{$_SUBROUTINES{$label}});
    return 1;
}

sub source_file {
    my ($class_or_self, $file) = @_;
    croak "BATsh->source_file: file not found: $file" unless -f $file;
    local *SFHH;
    open(SFHH, $file) or croak "BATsh->source_file: cannot open $file: $!";
    my @src = <SFHH>;
    close(SFHH);
    _process_lines(@src);
    return 1;
}

###############################################################################
# SETLOCAL / ENDLOCAL  (public API)
###############################################################################
sub setlocal  { BATsh::Env::setlocal()  }
sub endlocal  { BATsh::Env::endlocal()  }

###############################################################################
# _exec_cmd_section -- run CMD lines through BATsh::CMD
###############################################################################
sub _exec_cmd_section {
    my (@lines) = @_;
    # Handle BATsh-native directives before CMD interpreter
    my @batch = ();
    for my $line (@lines) {
        (my $s = $line) =~ s/\r?\n\z//;
        $s =~ s/\A\s+//;
        if ($s =~ /\ASETLOCAL\s*\z/i) {
            _flush_cmd(\@batch) if @batch; @batch = ();
            BATsh::Env::setlocal();
            next;
        }
        if ($s =~ /\AENDLOCAL\s*\z/i) {
            _flush_cmd(\@batch) if @batch; @batch = ();
            BATsh::Env::endlocal();
            next;
        }
        if ($s =~ /\ACALL\s+:([A-Za-z_][A-Za-z0-9_]*)(.*)/i) {
            my ($lbl, $rest) = (uc($1), $2);
            _flush_cmd(\@batch) if @batch; @batch = ();
            $rest =~ s/\A\s+//;
            my @args = split /\s+/, $rest;
            eval { call_sub('', $lbl, @args) };
            warn $@ if $@;
            next;
        }
        if ($s =~ /\ACALL\s+(\S+\.batsh)(.*)/i) {
            my $bfile = $1;
            _flush_cmd(\@batch) if @batch; @batch = ();
            eval { source_file('', $bfile) };
            warn $@ if $@;
            next;
        }
        push @batch, $line;
    }
    _flush_cmd(\@batch) if @batch;
}

sub _flush_cmd {
    my ($lines_ref) = @_;
    return unless @{$lines_ref};
    BATsh::CMD::exec_block('BATsh::CMD', $lines_ref,
        _batsh => __PACKAGE__,
        _pushd_stack => [],
    );
}

###############################################################################
# _exec_sh_section -- run SH lines through BATsh::SH
###############################################################################
sub _exec_sh_section {
    my (@lines) = @_;
    my @batch = ();
    for my $line (@lines) {
        (my $s = $line) =~ s/\r?\n\z//;
        $s =~ s/\A\s+//;
        if ($s =~ /\A(?:source|\.)\s+(\S+\.batsh)/) {
            my $bfile = $1;
            _flush_sh(\@batch) if @batch; @batch = ();
            eval { source_file('', $bfile) };
            warn $@ if $@;
            next;
        }
        push @batch, $line;
    }
    _flush_sh(\@batch) if @batch;
}

sub _flush_sh {
    my ($lines_ref) = @_;
    return unless @{$lines_ref};
    BATsh::SH::exec_block('BATsh::SH', $lines_ref,
        _batsh => __PACKAGE__,
    );
}

###############################################################################
# _process_lines -- main dispatcher
###############################################################################
sub _process_lines {
    my (@source) = @_;
    @source = _extract_subroutines(@source);

    my @pending = (); my $cur_mode = ''; my $depth = 0;

    for my $raw (@source) {
        chomp $raw;
        my ($mode, $line, $first) = _parse_line($raw);

        if ($mode eq 'EMPTY' || $mode eq 'COMMENT') {
            push @pending, $line if $cur_mode ne '';
            next;
        }

        if ($cur_mode eq '') {
            $cur_mode = $mode; $depth = 0;
            push @pending, $line;
            $depth += ($mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($first);
        }
        elsif ($mode eq $cur_mode) {
            push @pending, $line;
            $depth += ($mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($first);
            $depth = 0 if $depth < 0;
        }
        else {
            if ($depth > 0) {
                push @pending, $line;
                $depth += ($cur_mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($first);
                $depth = 0 if $depth < 0;
            }
            else {
                _flush_section($cur_mode, @pending) if @pending;
                @pending = ($line); $cur_mode = $mode; $depth = 0;
                $depth += ($mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($first);
            }
        }
    }
    _flush_section($cur_mode, @pending) if @pending;
}

sub _flush_section {
    my ($mode, @lines) = @_;
    return unless @lines;
    if ($mode eq 'CMD') { _exec_cmd_section(@lines) }
    else                { _exec_sh_section(@lines) }
}

###############################################################################
# REPL
###############################################################################
sub repl {
    my ($class_or_self) = @_;
    _ensure_env_init();
    print "BATsh $VERSION - Self-contained Bilingual Shell\n";
    print "Uppercase => CMD mode, lowercase => SH mode. EXIT/exit to quit.\n\n";

    my (@buf, $depth, $cur_mode) = ((), 0, '');
    while (1) {
        print $depth > 0 ? '    +> ' : 'BATsh> ';
        my $line = <STDIN>;
        last unless defined $line;
        chomp $line;
        if ($line =~ /\A\s*(?:EXIT|exit)\s*\z/) { print "Bye.\n"; last }
        next if $depth == 0 && $line =~ /\A\s*\z/;
        push @buf, $line;
        my (undef, undef, $first) = _parse_line($line);
        $cur_mode = classify_token($first) if $depth == 0 && $cur_mode eq '';
        $depth += ($cur_mode eq 'CMD') ? _cmd_paren_delta($line) : _sh_depth_delta($first);
        $depth = 0 if $depth < 0;
        if ($depth == 0) {
            _flush_section($cur_mode, @buf);
            @buf = (); $cur_mode = ''; $depth = 0;
        }
    }
}

###############################################################################
# Accessors
###############################################################################
sub version      { return $VERSION }
sub sh_available { return 1 }   # always: built-in SH interpreter

###############################################################################
# Run as script
###############################################################################
unless (caller) {
    BATsh::Env::init();
    if (@ARGV == 0) { BATsh->repl() }
    elsif ($ARGV[0] eq '-e') { shift @ARGV; BATsh->run_string(join("\n", @ARGV)) }
    else { BATsh->run($ARGV[0]) }
}

1;

__END__

=head1 NAME

BATsh - Bilingual Shell: cmd.exe and bash in one script (self-contained)

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use BATsh;

  BATsh->run('myscript.batsh');
  BATsh->run_string('echo hello from sh');
  BATsh->repl();

=head1 DESCRIPTION

BATsh is a self-contained bilingual shell interpreter written in pure Perl.
It implements both the cmd.exe command set and the sh/bash command set
entirely in Perl -- no external cmd.exe, bash, or sh is required.

Scripts are divided into CMD sections (uppercase first token) and SH sections
(lowercase first token). Both sections share a common variable store via
BATsh::Env, so variables set in a CMD section are immediately visible in the
next SH section and vice versa.

=head1 CMD MODE

Any line whose first token is all uppercase (A-Z, 0-9, path chars) is a CMD
line. CMD sections are executed by BATsh::CMD, which implements:

  ECHO, @ECHO OFF/ON
  SET VAR=value, SET /A expr
  IF "A"=="B" ... ELSE ..., IF EXIST, IF DEFINED, IF ERRORLEVEL
  FOR %%V IN (list) DO ..., FOR /L %%V IN (s,step,e) DO ...
  GOTO :label, :label
  CALL :label [args], CALL file.batsh
  SETLOCAL, ENDLOCAL
  CD, DIR, COPY, DEL, MOVE, MKDIR, RMDIR, REN, TYPE
  PAUSE, EXIT, CLS, TITLE, VER, PUSHD, POPD

=head1 SH MODE

Any line whose first token contains a lowercase letter is a SH line.
SH sections are executed by BATsh::SH, which implements:

  VAR=value, export VAR=value, unset VAR
  echo, printf
  if/then/elif/else/fi
  for VAR in list; do ... done
  while condition; do ... done
  until condition; do ... done
  case $var in pattern) ... ;; esac
  test / [ ... ]  (file tests, string, integer comparisons)
  cd, pwd, exit, true, false, :, read, shift
  $(( arithmetic )), $( command substitution )
  ${VAR}, ${VAR:-default}, ${VAR:=default}
  source / . file

=head1 REQUIREMENTS

Perl 5.005_03 or later. Core modules only. No external shell required.

=head1 BUGS AND LIMITATIONS

The built-in CMD interpreter does not support all cmd.exe extensions
(e.g. FOR /F with complex token options, delayed expansion with !VAR!).

The built-in SH interpreter does not support pipelines (|), redirection
(> >> <), background execution (&), or here-documents (<<).

Section boundary detection is token-based (uppercase vs. lowercase first
token). Mixed-case first tokens are treated as SH.

Please report bugs via the issue tracker:
L<https://github.com/ina-cpan/BATsh/issues>

=head1 SEE ALSO

L<BATsh::CMD>, L<BATsh::SH>, L<BATsh::Env>

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 LICENSE

This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
