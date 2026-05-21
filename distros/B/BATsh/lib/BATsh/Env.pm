package BATsh::Env;
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org>
######################################################################
#
# BATsh::Env - Shared environment variable store
#
# v0.02 changes:
#   - Variable names are case-insensitive (cmd.exe compatible).
#     Stored internally in uppercase.
#   - SETLOCAL ENABLEDELAYEDEXPANSION flag tracked per scope.
#   - expand_cmd expands !VAR! when delayed expansion is active.
#   - expand_cmd expands %0..%9 and %* positional parameters.
#   - _expand_tilde_param: %~[fdpnx]*N batch-parameter tilde modifiers.
#     Modifiers f(full path), d(drive), p(dir), n(basename), x(ext).
#     Uses File::Spec and Cwd for cross-platform absolute path resolution.
#   - init() guards undef %ENV values (Windows compatibility).
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use vars qw($VERSION);
$VERSION = '0.02';

use File::Spec ();
BEGIN { eval { require Cwd } }
$VERSION = $VERSION;

# Keys stored in UPPERCASE for case-insensitive lookup
use vars qw(%STORE);

# Delayed expansion flag
use vars qw($DELAYED_EXPANSION);
$DELAYED_EXPANSION = 0;

# SETLOCAL scope stack: each entry = { store => \%snap, delayed => $flag }
use vars qw(@SETLOCAL_STACK);
@SETLOCAL_STACK = ();

sub init {
    %STORE = ();
    for my $k (keys %ENV) {
        $STORE{uc($k)} = defined $ENV{$k} ? $ENV{$k} : '';
    }
    $DELAYED_EXPANSION = 0;
}

sub _key { return uc($_[0]) }

sub get        { my ($c,$n)=@_; return $STORE{_key($n)} }
sub set        { my ($c,$n,$v)=@_; $STORE{_key($n)} = defined $v ? $v : '' }
sub unset      { my ($c,$n)=@_; delete $STORE{_key($n)} }
sub exists_var { my ($c,$n)=@_; return exists $STORE{_key($n)} ? 1 : 0 }
sub sync_to_env { %ENV = %STORE }
sub snapshot   { my %s = %STORE; return \%s }
sub restore    { my ($c,$s)=@_; %STORE = %{$s} }
sub delayed_expansion { return $DELAYED_EXPANSION }

sub setlocal {
    my ($opts) = @_;
    $opts = '' unless defined $opts;
    my %snap = %STORE;
    push @SETLOCAL_STACK, { store => \%snap, delayed => $DELAYED_EXPANSION };
    if    ($opts =~ /ENABLEDELAYEDEXPANSION/i)  { $DELAYED_EXPANSION = 1 }
    elsif ($opts =~ /DISABLEDELAYEDEXPANSION/i) { $DELAYED_EXPANSION = 0 }
    # ENABLEEXTENSIONS / DISABLEEXTENSIONS: accepted, not modelled
}

sub endlocal {
    unless (@SETLOCAL_STACK) {
        warn "[BATsh] Warning: ENDLOCAL without matching SETLOCAL\n";
        return;
    }
    my $f = pop @SETLOCAL_STACK;
    %STORE             = %{$f->{store}};
    $DELAYED_EXPANSION = $f->{delayed};
}

# ----------------------------------------------------------------
# expand_cmd: %VAR% expansion, then optional !VAR! delayed expansion
# ----------------------------------------------------------------
sub expand_cmd {
    my ($class, $str) = @_;
    return '' unless defined $str;

    # %~[modifiers][0-9]: batch parameter modifiers (e.g. %~dp0, %~nx1)
    # Must be processed BEFORE %VAR% to avoid being mis-parsed.
    $str =~ s/%~([fdpnxs]*)([0-9])/_expand_tilde_param($1, $2)/ge;

    # Batch positional parameters: %0..%9 and %* (single % prefix, no closing %)
    # Must expand BEFORE %VAR% so that "%0 foo=%1" is not mis-parsed by
    # the greedy %([^%]+)% pattern as a single named variable.
    $str =~ s/%([0-9*])/
        do { my $k = "%$1"; exists($STORE{$k}) ? $STORE{$k} : '' }
    /ge;

    # %VAR% substitution (case-insensitive lookup via _key)
    $str =~ s/%([^%\r\n]+)%/
        do { my $k=uc($1); exists($STORE{$k}) ? $STORE{$k} : '' }
    /ge;

    # %% -> literal %
    $str =~ s/%%/%/g;

    # !VAR! delayed expansion (only when enabled)
    if ($DELAYED_EXPANSION) {
        $str =~ s/!([A-Za-z_][A-Za-z0-9_]*)!/
            do { my $k=uc($1); exists($STORE{$k}) ? $STORE{$k} : '' }
        /ge;
    }

    return $str;
}

# ----------------------------------------------------------------
# _expand_tilde_param: resolve %~[fdpnx]*N batch-parameter modifiers
#
# Modifier letters (combinable, same as cmd.exe):
#   (none) strip surrounding double-quotes only
#   f      fully qualified path (absolute)
#   d      drive letter only   (e.g. "C:" on Windows, "" on Unix)
#   p      path component only (directory, with trailing separator)
#   n      filename without extension
#   x      extension only (including leading dot, e.g. ".bat")
#
# The value is taken from %N in the Env store (%0..%9).
# Uses File::Spec (platform-aware) and a hand-rolled path splitter so
# that Windows-style paths work correctly on Windows and Unix-style
# paths work on Unix without requiring Win32-specific modules.
# ----------------------------------------------------------------
sub _expand_tilde_param {
    my ($mods, $n) = @_;
    my $key = "%$n";
    my $val = exists($STORE{$key}) ? $STORE{$key} : '';

    # Always strip surrounding double-quotes first
    $val =~ s/\A"//;
    $val =~ s/"\z//;

    # With no recognised modifiers, just return the dequoted value
    return $val unless $mods =~ /[fdpnx]/;

    # --- Normalise: extract drive letter first, then convert \ to / ---
    # Extracting the drive before splitting avoids "C:" being treated as
    # a path component and re-attached incorrectly.
    my $drv  = '';        # e.g. "C:" on Windows, "" on Unix
    my $path = $val;
    $path =~ s{\\}{/}g;  # normalise separators
    if ($path =~ s{\A([A-Za-z]:)}{}) { $drv = $1 }

    # --- resolve to absolute path when f/d/p requested ---
    if ($mods =~ /[fdp]/) {
        unless ($path =~ m{\A/} || $drv ne '') {
            # relative Unix path: prepend cwd
            my $cwd = defined(&Cwd::cwd) ? Cwd::cwd() : '.';
            $cwd =~ s{\\}{/}g;
            $cwd =~ s{/+\z}{};
            $path = "$cwd/$path";
        }
        # Ensure exactly one leading slash
        $path = "/$path" unless $path =~ m{\A/};
        # Collapse . and ..
        my @segs;
        for my $p (split m{/+}, $path) {
            next if $p eq '' || $p eq '.';
            if ($p eq '..') { pop @segs if @segs }
            else             { push @segs, $p }
        }
        $path = '/' . join('/', @segs);
        $path = '/' if $path eq '/';
    }

    # --- split path into directory and filename ---
    my ($dirs, $file) = ('', '');
    if ($path =~ m{\A(.*/)([^/]*)\z}) {
        ($dirs, $file) = ($1, $2);
    }
    else {
        $file = $path;
    }

    # --- split filename into base and extension ---
    my ($base, $ext) = ('', '');
    if ($file =~ m{\A(.+)(\.[^.]+)\z}) {
        ($base, $ext) = ($1, $2);
    }
    else {
        $base = $file;
    }

    # --- build result ---
    if ($mods =~ /f/) {
        # Full absolute path: drive + dirs + file
        # dirs already ends with / when non-root
        return $drv . $dirs . $file;
    }

    my $result = '';
    $result .= $drv  if $mods =~ /d/;
    $result .= $dirs if $mods =~ /p/;
    $result .= $base if $mods =~ /n/;
    $result .= $ext  if $mods =~ /x/;
    return $result;
}

# ----------------------------------------------------------------
# expand_sh: $VAR and ${VAR} (SH mode)
# ----------------------------------------------------------------
sub expand_sh {
    my ($class, $str) = @_;
    return '' unless defined $str;
    $str =~ s/\$\{([A-Za-z_][A-Za-z0-9_]*)\}/
        do { my $k=$1; defined($STORE{$k}) ? $STORE{$k} : defined($STORE{uc($k)}) ? $STORE{uc($k)} : '' }
    /ge;
    $str =~ s/\$([A-Za-z_][A-Za-z0-9_]*)/
        do { my $k=$1; defined($STORE{$k}) ? $STORE{$k} : defined($STORE{uc($k)}) ? $STORE{uc($k)} : '' }
    /ge;
    return $str;
}

1;

__END__

=head1 NAME

BATsh::Env - Shared variable store for BATsh

=head1 SYNOPSIS

  use BATsh::Env;

  BATsh::Env::init();                          # seed from %ENV
  BATsh::Env::set('FOO', 'bar');               # store (key uppercased)
  my $v = BATsh::Env::get('foo');              # fetch -- same as 'FOO'
  BATsh::Env::setlocal('ENABLEDELAYEDEXPANSION');
  # ... commands that use !VAR! ...
  BATsh::Env::endlocal();

=head1 DESCRIPTION

BATsh::Env is the single variable table shared by BATsh::CMD and BATsh::SH.
All variable names are stored in B<uppercase>; all lookups (get, set, unset,
exists_var) are case-insensitive, matching cmd.exe behaviour.

=head2 Delayed Expansion

The package variable C<$DELAYED_EXPANSION> (default 0) controls whether
C<!VAR!> references are expanded by C<expand_cmd()>.

C<setlocal($opts)> saves a snapshot of the entire variable store and the
current C<$DELAYED_EXPANSION> flag onto an internal scope stack, then
optionally updates the flag:

  setlocal('ENABLEDELAYEDEXPANSION')   -- sets $DELAYED_EXPANSION = 1
  setlocal('DISABLEDELAYEDEXPANSION')  -- sets $DELAYED_EXPANSION = 0
  setlocal('')                         -- no flag change

C<endlocal()> pops the stack and restores both the variable store and the
flag, so nested SETLOCAL/ENDLOCAL pairs each get their own isolated scope.

=head2 Variable Expansion

C<expand_cmd($str)> performs three passes:

=over

=item 1. C<%~[modifiers]N> batch-parameter tilde expansion (e.g. C<%~dp0>, C<%~nx1>).
Supported modifier letters: C<f> (full path), C<d> (drive), C<p> (directory),
C<n> (basename without extension), C<x> (extension).  With no modifiers,
surrounding double-quotes are stripped.

=item 2. C<%VAR%> substitution (case-insensitive lookup via uppercase key).
Unresolved references expand to the empty string.
C<%%> is replaced with a literal C<%>.

=item 3. C<!VAR!> substitution (only when C<$DELAYED_EXPANSION> is true).
Unresolved C<!VAR!> references expand to the empty string.

=back

C<expand_sh($str)> expands C<${VAR}> and C<$VAR> for the SH interpreter.
It tries the exact-case key first, then the uppercase key, so variables
set by CMD (uppercase keys) are visible in SH sections as C<$var> or C<$VAR>.

=head1 FUNCTIONS

=over

=item C<init()>

Seeds C<%STORE> from C<%ENV> (keys uppercased) and resets
C<$DELAYED_EXPANSION> to 0.

=item C<get($name)>

Returns the value of variable C<$name> (case-insensitive), or C<undef>.

=item C<set($name, $value)>

Stores C<$value> under the uppercase form of C<$name>.

=item C<unset($name)>

Deletes the variable.

=item C<exists_var($name)>

Returns 1 if the variable is defined, 0 otherwise.

=item C<sync_to_env()>

Copies C<%STORE> to C<%ENV> so child processes spawned via C<system()>
inherit the current variable state.

=item C<setlocal($opts)>

Pushes the current store and C<$DELAYED_EXPANSION> flag onto the scope stack,
then parses C<$opts> for ENABLEDELAYEDEXPANSION or DISABLEDELAYEDEXPANSION.

=item C<endlocal()>

Pops and restores the store and flag from the scope stack.

=item C<expand_cmd($str)>

Expands C<%VAR%> (and C<!VAR!> when delayed expansion is active).

=item C<expand_sh($str)>

Expands C<${VAR}> and C<$VAR> for the SH interpreter.

=item C<delayed_expansion()>

Returns the current value of C<$DELAYED_EXPANSION> (0 or 1).

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
