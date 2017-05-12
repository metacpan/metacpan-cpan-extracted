package B::Stats;
our $VERSION = '0.09';

# TODO
# exact: probably use Opcodes and DynaLoader at BEGIN for c_minus.
# less overhead: do more in XS: _class, _count_op, _walkoptree_simple, _walksymtable
# detect -E usage, features overhead

=head1 NAME

B::Stats - print optree statistics

=head1 SYNOPSIS

  perl -MB::Stats myprog.pl # all
  perl -MO=Stats myprog.pl  # compile-time only
  perl -MB::Stats[,OPTIONS] myprog.pl

=head1 DESCRIPTION

Print statistics for all generated ops.

static analysis at compile-time,
static analysis at end-time to include all runtime added modules,
and dynamic analysis at run-time, as with a profiler.

The purpose is to help you in your goal:

    no bloat;

=head1 OPTIONS

Options can be bundled: C<-c,-e,-r> eq C<-cer>

=over

=item -c I<static>

Do static analysis at compile-time. This does not include all run-time require packages.
Invocation via -MO=Stats does this automatically.

=item -e I<end>

Do static analysis at end-time. This is includes all run-time require packages.
This calculates the heap space for the optree.

=item -r I<run>

Do dynamic run-time analysis of all actually visited ops, similar to a profiler.
Single ops can be called multiple times.

=item -a I<all (default)>

Same as -cer: static compile-time, end-time and dynamic run-time.

=item -t I<table>

Tabular list of -c, -e and -r results.

=item -u I<summary>

Short summary only, no op class.
With -t only the final table(s).

=item -F I<Files>

Prints included file names

=item -x I<fragmentation>  B<NOT YET>

Calculates the optree I<fragmentation>. 0.0 is perfect, 1.0 is very bad.

A perfect optree has no null ops and every op->next is immediately next
to the op.

=item -f<op,...> I<filter>  B<NOT YET>

Filter for op names and classes. Only calculate the given ops, resp. op class.

  perl -MB::Stats,-fLOGOP,-fCOP,-fconcat myprog.pl

=item -lF<logfile>

Print output only to this file. Default: STDERR

  perl -MB::Stats,-llog myprog.pl

=back

=head1 METHODS

=over

=cut

our (%B_inc, %B_env);
BEGIN { %B_inc = %INC; }

use strict;
# B includes 14 files and 3821 lines. overhead subtracted with B::Stats::Minus
use B;
use B::Stats::Minus;
# XSLoader adds 0 files and 0 lines, already with B.
# Changed to DynaLoader
# Opcodes-0.10 adds 6 files and 5303-3821 lines: Carp, AutoLoader, subs
# Opcodes-0.11 adds 2 files and 4141-3821 lines: subs
# use Opcodes; # deferred to run-time below
our ($static, @runtime, $compiled, $imported, $LOG);
my (%opt, $nops, $rops, @all_subs, $frag, %roots);
my ($c_count, $e_count, $r_count);

# check options
sub import {
  $DB::single = 1 if defined &DB::DB;
#print STDERR "opt: ",join(',',@_),"; "; # for Debugging
  for (@_) { # switch bundling without Getopt bloat
    if (/^-?([acerxtFu])(.*)$/) {
      $opt{$1} = 1;
      my $rest = $2;
      do {
	if ($rest =~ /^-?([acerxtFu])(.*)$/) {
	  $opt{$1} = 1;
	  $rest = $2;
	}
      } while $rest;
    }
    # taking multiple arguments: -ffilter
    if (/^-?f(.*)$/) {
      my $arg = $1;
      if ($arg =~ /^[A-Z_]*OP$/) {
        my @optype = qw(BASEOP UNOP BINOP LOGOP LISTOP PMOP SVOP PADOP PVOP_OR_SVOP
                        LOOP COP BASEOP_OR_UNOP FILESTATOP LOOPEXOP);
	$opt{f}->{class}->{$arg} = 1;
	die "invalid B::Stats,-fOPCLASS argument: $arg\n"
	  unless grep {$arg eq $_} @optype;
	# pre-expand names for the class
	require Opcodes;
	my $maxo = Opcodes::opcodes();
	for my $i (0..$maxo-1) {
	  my $name = Opcodes::opname($i);
	  my $class = $optype[ Opcodes::opclass($i) ];
	  if ($class eq $arg) {
	    $opt{f}->{name}->{$name} = 1;
	  }
	}
      } elsif ($arg =~ /^[a-z_]+$/) {
	$opt{f}->{name}->{$arg} = 1;
      } else {
	die "invalid B::Stats,-ffilter argument: $arg\n";
      }
    }
    if (/^-?(l)(.*)$/) { # taking arguments: -llogfile
      $opt{$1} = $2;
      open $LOG, ">", $opt{l} or die "Cannot write to B::Stats,-llogfile: $opt{l}\n";
    }
  }

  $opt{a} = 1 if !$opt{c} and !$opt{e} and !$opt{r}; # default
  $opt{c} = $opt{e} = $opt{r} = 1 if $opt{a};
#warn "%opt: ",keys %opt,"\n"; # for Debugging
  $LOG = \*STDERR unless $opt{l};
  $imported = 1;
}

sub _class {
    my $name = ref shift;
    $name =~ s/^.*:://;
    return $name;
}

# static
sub _count_op {
  my $op = shift;
  $nops++; # count also null ops
  if ($$op) {
    $static->{name}->{$op->name}++;
    # $static->{class}->{_class($op)}++;
  }
}

# collect subs and stashes before B is loaded
# XXX not yet used. we rather use B::Stats::Minus
sub _collect_env {
  %B_env = { 'B::Stats' => 1 };
  _xs_collect_env() if $INC{'DynaLoader.pm'};
}

# from B::Utils
our $sub;
sub B::GV::_mypush_starts {
  my $name = $_[0]->STASH->NAME."::".$_[0]->SAFENAME;
  return unless ${$_[0]->CV};
  my $cv = $_[0]->CV;
  if ($cv->PADLIST->can("ARRAY")
      and $cv->PADLIST->ARRAY
      and $cv->PADLIST->ARRAY->can("ARRAY"))
  {
    push @all_subs, $_->ROOT
      for grep { _class($_) eq "CV" } $cv->PADLIST->ARRAY->ARRAY;
  }
  return unless ${$cv->START} and ${$cv->ROOT};
  $roots{$name} = $cv->ROOT;
};
sub B::SPECIAL::_mypush_starts{}

sub _walkops {
  my ($callback, $data) = @_;
  # _collect_env() unless %B_env;
  %roots  = ( '__MAIN__' =>  B::main_root()  );
  _walksymtable(\%main::,
	       '_mypush_starts',
	       sub {
		 return if scalar grep {$_[0] eq $_."::"} ('B::Stats');
		 1;
	       }, # Do not eat our own children!
	       '');
  push @all_subs, $_->ROOT
    for grep { _class($_) eq "CV" } B::main_cv->PADLIST->ARRAY->ARRAY;
  for $sub (keys %roots) {
    _walkoptree_simple($roots{$sub}, $callback, $data);
  }
  # catches __ANON__
  for (@all_subs) {
    _walkoptree_simple($_, $callback, $data);
  }
}

sub _walkoptree_simple {
  my ($op, $callback, $data) = @_;
  $callback->($op,$data);
  if ($$op && ($op->flags & B::OPf_KIDS)) {
    for (my $kid = $op->first; $$kid; $kid = $kid->sibling) {
      _walkoptree_simple($kid, $callback, $data);
    }
  }
}

sub _walksymtable {
    my ($symref, $method, $recurse, $prefix) = @_;
    my ($sym, $ref, $fullname);
    no strict 'refs';
    $prefix = '' unless defined $prefix;
    foreach my $sym (keys %$symref) {
        my $ref = $symref->{$sym};
        $fullname = "*main::".$prefix.$sym;
	if ($sym =~ /::$/) {
	    $sym = $prefix . $sym;
	    if (B::svref_2object(\*$sym)->NAME ne "main::" &&
		$sym ne "<none>::" && &$recurse($sym))
	    {
               _walksymtable(\%$fullname, $method, $recurse, $sym);
	    }
	} else {
           B::svref_2object(\*$fullname)->$method();
	}
    }
}

=item compile

Static -c check at CHECK time. Triggered by -MO=Stats,-OPTS

=cut

sub compile {
  import(@_) unless $imported; # check options via O
  $compiled++;
  $opt{c} = 1;
  return sub {
    $nops = 0;
    _walkops(\&_count_op);
    output($static, $nops, 'static compile-time');
  }
}

=item rcount ($opcode)

Returns run-time count per op type.

=item rcount_all()

Returns an AV ref for all opcounts, indexed by opcode.

=item reset_rcount()

Resets to opcount array for all ops to 0

=item output ($count-hash, $ops, $name)

General formatter

=cut

sub output {
  my ($count, $ops, $name) = @_;

  my %name = (
    'static compile-time' => 'c',
    'static end-time'     => 'e',
    'dynamic run-time'    => 'r'
    );
  my $key = $name{$name};
  my $lines = 0;
  my $inc = $key eq 'c' ? \%B_inc : \%INC;
  my $files = scalar keys %$inc;
  for (values %$inc) {
    print $LOG $_,"\n" if $opt{F};
    open IN, "<", "$_";
    # Todo: skip pod?
    while (<IN>) { chomp; s/#.*//; next if not length $_; $lines++; };
    close IN;
  }
  for (qw(_files _lines _ops)) {
    $B::Stats::Minus::overhead->{$key}{$_} = 0 unless $B::Stats::Minus::overhead->{$key}{$_};
  }
  $files -= $B::Stats::Minus::overhead->{$key}{_files};
  $lines -= $B::Stats::Minus::overhead->{$key}{_lines};
  $ops -= $B::Stats::Minus::overhead->{$key}{_ops};
  print $LOG "\nB::Stats $name:\nfiles=$files\tlines=$lines\tops=$ops\n";
  return if $opt{t} and $opt{u};

  print $LOG "\nop name:\n";
  for (sort { $count->{name}->{$b} <=> $count->{name}->{$a} }
       keys %{$count->{name}}) {
    my $l = length $_;
    my $c = $count->{name}->{$_};
    $c -= $B::Stats::Minus::overhead->{$key}{$_} if exists $B::Stats::Minus::overhead->{$key}{$_};
    $count->{name}->{$_} = $c;
    next if $opt{f} and !$opt{f}->{name}->{$_};
    next if !$c;
    print $LOG $_, " " x (10-$l), "\t", $c, "\n";
  }
  # FIXME: no OPCLASS overhead substraction
  unless ($opt{u}) {
    print $LOG "\nop class:\n";

    require Opcodes;
    my $maxo = Opcodes::opcodes();
    my @optype = qw(BASEOP UNOP BINOP LOGOP LISTOP PMOP SVOP PADOP PVOP_OR_SVOP
                    LOOP COP BASEOP_OR_UNOP FILESTATOP LOOPEXOP);
    for my $i (0..$maxo-1) {
      my $name = Opcodes::opname($i);
      if ($name) {
        my $class = $optype[ Opcodes::opclass($i) ];
        next if $opt{f} and !$opt{f}->{name}->{$name};
        next if $opt{f} and !$opt{f}->{class}->{$class};
        $count->{class}->{ $class } += $count->{name}->{ $name };
      } else {
        warn "invalid name for opcount[$i]";
      }
    }
    for (sort { $count->{class}->{$b} <=> $count->{class}->{$a} }
	 keys %{$count->{class}}) {
      next if $opt{f} and !$opt{f}->{class}->{$_};
      next if !$count->{class}->{$_};
      my $l = length $_;
      print $LOG $_, " " x (10-$l), "\t", $count->{class}->{$_}, "\n";
    }
  }
  $count;
}

=item output_runtime

-r formatter.

Prepares count hash from the runtime generated structure in XS and calls output().

=cut

sub output_runtime {
  $r_count = {};
  my $r_countarr = $_[0];

  #require DynaLoader;
  #our @ISA = ('DynaLoader');
  #DynaLoader::bootstrap('B::Stats', $VERSION);
  require Opcodes;
  my $maxo = Opcodes::opcodes();
  # @optype only since 5.8.9 in B
  my @optype = qw(BASEOP UNOP BINOP LOGOP LISTOP PMOP SVOP PADOP PVOP_OR_SVOP
                  LOOP COP BASEOP_OR_UNOP FILESTATOP LOOPEXOP);
  for my $i (0..$maxo-1) {
    if (my $count = $r_countarr->[$i]) {
      my $name = Opcodes::opname($i);
      if ($name) {
	my $class = $optype[ Opcodes::opclass($i) ];
	next if $opt{f} and !$opt{f}->{name}->{$name};
	next if $opt{f} and !$opt{f}->{class}->{$class};
	$r_count->{name}->{ $name } += $count;
	$rops += $count;
	# $r_count->{class}->{ $class } += $count;
      } else {
	warn "invalid name for opcount[$i]";
      }
    }
  }
  $r_count = output($r_count, $rops, 'dynamic run-time');
}

=item output_table

-t formatter

Does not work together with -r

=cut

sub _output_tline {
  my $n = shift;
  my $name = $n.(" "x(12-length($n)));
  return if $opt{f} and !$opt{f}->{name}->{$n};
  my ($c, $e, $r) = ($c_count->{name}->{$n},
		     $e_count->{name}->{$n},
		     $r_count->{name}->{$n});
  return if !$c and !$e and !$r;
  print $LOG join("\t", ($name, $c, $e, $r)), "\n";
}

sub output_table {
  # XXX we have empty runops runs with format.
  #my $x = 0;
  #for (keys %{$r_count->{name}}) {
  #  $x++ if $r_count->{name}->{$_};
  #}
  #return unless $x;
  print $LOG "
B::Stats table:
           	-c	-e	-r
";
  warn "Cannot use -t with -r only\n" if !$opt{c} and !$opt{e};
  if ($e_count and %$e_count) {
    for (sort { $e_count->{name}->{$b} <=> $e_count->{name}->{$a} }
         keys %{$e_count->{name}}) {
      _output_tline($_);
    }
  } else {
    for (sort { $c_count->{name}->{$b} <=> $c_count->{name}->{$a} }
         keys %{$c_count->{name}}) {
      _output_tline($_);
    }
  }
}

=back

=cut

# Called not via -MO=Stats, rather -MB::Stats
CHECK {
  compile->() if !$compiled and $opt{c};
}

sub _end { #void _end($refToArrOfRuntimeCounts)
  $c_count = $static;
  if ($opt{e}) {
    $nops = 0;
    $static = {};
    _walkops(\&_count_op);
    $e_count = output($static, $nops, 'static end-time');
  }
  output_runtime($_[0]) if $opt{r};
  if ( $opt{t} and ($] < 5.014 or ${^GLOBAL_PHASE} ne 'DESTRUCT') ) {
    output_table;
  }
}

=head1 LICENSE

This module is available under the same licences as perl, the Artistic
license and the GPL.

=head1 SEE ALSO

=cut

XSLoader::load 'B::Stats', $VERSION;
1;
