package B::Debugger;

our $VERSION = '0.14';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

=pod

=head1 NAME

B::Debugger - optree debugger

=head1 SYNOPSIS

  perl -MB::Debugger programm.pl
  B::Debugger 0.01 - optree debugger. h for help
  op 0 enter
  > n
  op 1 nextstate
  > h
  Usage:
  n [n] next op                       l [n|x-y]     list ops
  c [n] continue (until)              d|Debug       op
  b <n> break at op                   o|Concise     op
  s     step into kids                f|Flags       op
  sib   step to next sibling          x|eval expr
  u [n] up                            [sahpicg]v<n> n-th global var: sv1,
  g <n> goto                          pad <n>       n-th pad variable (my)
  h     help
  q     quit debugger, execute        exit           quit with no execution
  op 0 enter
  > b 5
  breakpoint 5 added
  > b const
  breakpoint const added
  > n
  op 2 pushmark
  > l
  -  <0> enter ->-
  -  <;> nextstate(main 111 test.pl:5) v:{ ->-
  -  <0> pushmark sM ->-  > c
  > q
  quit
  executing...

=head1 DESCRIPTION

  Start an optree inspector before the runtime execution begins, similar
  to the perl debugger, but only at the internal optree level, not the
  source level. Kind of interactive B::Concise.

  The ops are numbered and in basic (=parsed) order, starting from 0.
  Breakpoints can be defined as number or by opname.

=head1 OPTIONS

None yet.

Planned:

  -exec      switch to exec order
  -root      start at main_root, not main_start
  -check     hook into CHECK block (Default, at B)
  -unit      hook into UNITCHECK block (after B)
  -init      hook into INIT block (before B)
  -begin     hook into BEGIN block (before compilation)
  -d         debug, be verbose in the internal recursion steps

=head1 COMMANDS

  n [n]   goto the next op, or step the next n ops
  s       step into kid if not next
  sib     step to next sibling
  u [n]   go one or n steps back or up
  g <n>   goto op 0-opmax
  c [n]   continue. Optionally until op n
  l [n|x-y] list n ops or from x to y.
  x <x>   eval perl expression
  f       list B::Flags op
  o/C     list B::Concise op
  d/D     list B::Debug op
  [sahpicg]v<n> inspect n-th global variable. eg. sv1
  h       help
  q       quit debugger, start execution
  exit    quit perl, no execution

=head1 SEE ALSO

Use L<Od> to step through the compiler with the perl debugger.
It delays the C<CHECK> block for the B::backend.

=head1 TODO

How to manage direct opidx access?

  Such as: Concise 10, list 5-10, up, sib
  Do a first sweep in desired basic or exec order recording the ops?

set curcv in Concise

Commandline options

exit

de-recursify and simplify the loop, cont is broken.

=head1 BUGS

Plenty. This is alpha and for interested compiler developers only.

l =>
  coderef CODE(0x1553f40) has no START (set curcv in Concise)

cont, goto broken

=head1 AUTHOR

Reini Urban C<rurban@cpan.org>

=cut

use Devel::Hook;
use B qw(main_start main_root class main_cv);
use B::Utils; # qw(carp croak);
use B::Debug;
use B::Flags;
use B::Concise;
use Opcode;

use constant DBG_SAME => 1;
use constant DBG_CONT => 2;
use constant DBG_NEXT => 3;
use constant DBG_QUIT => 4;
our ($next_op, %break_op, @ops, %opnames, %opt, $last_in);

sub debugger_banner {
  our $maxo = Opcode::opcodes();
  for my $o (grep(/^-/, @_)) { $opt{$o}++; }
  print "\nB::Debugger $XS_VERSION - optree debugger. h for help\n";
}
sub debugger_help {
  print "Usage:\n";
  my @left = (
	      "n [n] next op",			#1
	      "c [n] continue (until)",		#2
	      "b <n> break at op",		#3
	      "s     step into kids",		#4
	      "sib   step to next sibling",	#5
	      "u [n] up",			#6
	      "g <n> goto",			#7
	      "h     help",			#8
	      "q     quit debugger, execute",	#9
	      );
  my @right = (
	       "l [n|x-y]     list ops",	#1
	       "d|Debug       op",		#2
	       "o|Concise     op",		#3
	       "f|Flags       op",		#4
	       "x|eval expr",			#5
	       "[sahpicg]v<n> n-th global var: sv1,",	#6
	       "pad <n>       n-th pad variable (my)",	#7
	       "",					#8
	      "exit           quit with no execution",	#9
	       );
  my $max = $#left > $#right ? $#left : $#right;
  for my $i (0 .. $max) {
    print sprintf("%-35s %s\n", $left[$i], $right[$i]);
  }
}

# numeric in the valid range 0..PL_maxo or a valid opname
sub valid_breakpoint {
  $b = shift;
  return $b if $b =~ /^\d+$/ and $op >= 0 and $op <= $maxo;
  unless (%opnames) {
    for my $opnum (0 .. $maxo ) {
      my $ppname = B::ppname($opnum); # pp_{name}
      $opnames{substr($ppname,3)} = $opnum;
    }
  }
  return exists $opnames{lc($b)} ? lc($b) : undef;
}

sub debugger_prompt {
  my $op = $_[0]; # need to manipulate it
  print "op $opidx ",$op->name,"\n"; # ?: full concise, size, flags?
  print "> ";
  my $in = readline(*STDIN);
  chomp $in;
  $in = $last_in unless $in;
  $last_in = $in;
  # $in =~ s/[:cntrl:]//g; # strip control chars, cursor keys
  if ($in =~ /^(h|help)$/) { debugger_help; return DBG_SAME; }
  elsif ($in =~ /^(q|quit)$/) { print "quit\nexecuting...\n"; return DBG_QUIT; }
  elsif ($in =~ /^exit$/) { print "exit\n"; exit; } # FIXME! Add an exit hook into INIT?
  elsif ($in =~ /^(x|eval)\s+(.+)$/) { print (eval "$2"),"\n"; return DBG_SAME; }
  elsif ($in =~ /^(n|next)$/) {
    print "..next\n" if $opt{debug};
    return DBG_NEXT;
  }
  elsif ($in =~ /^(n|next)\s+(\w+)$/) { # count
    my $count = valid_breakpoint($2);
    print "..next $count\n" if $opt{debug};
    $count = ($count and $count =~ /^\d$/);
    unless ($count) { print "invalid count \"$count\"\n"; return DBG_NEXT; }
    $break_op{$opidx + $count} = 2;
    return DBG_CONT;
  }
  elsif ($in =~ /^(b|break)\s+?(\w+)?$/) { # opidx or name?
    my $b = valid_breakpoint($2);
    unless ($b) { print "invalid breakpoint \"$b\"\n"; return DBG_SAME; }
    if (exists $break_op{$b}) { undef $break_op{$b};
				 print "breakpoint $b removed\n"; }
    else { $break_op{$b} = 1; print "breakpoint $b added\n"; }
    return DBG_SAME;
  }
  elsif ($in =~ /^(c|cont)$/) {
    return DBG_CONT;
  }
  elsif ($in =~ /^(c|cont)\s+(\w+)$/) { # arg <opidx> or next matching name?
    my $b = valid_breakpoint($2);
    print "..cont $b\n" if $opt{debug};
    unless ($b) { print "invalid breakpoint \"$b\"\n"; return DBG_SAME; }
    $break_op{$b} = 2 if $b; # 2: delete this op at the next break
    return DBG_CONT;
  }
  elsif ($in =~ /^(u|up)\s*(\w+)?$/) {
    if ($2 and valid_breakpoint($2)) {
      my $b = valid_breakpoint($2);
      unless ($b) { print "invalid opidx \"$b\"\n"; return DBG_SAME; }
      $opidx = $b;
    } else {
      $opidx--;
    }
    if (exists $ops[$opidx]) { $_[0] = $ops[$opidx]; } # rewind
    print "up to $opidx\n" if $opt{debug};
    return DBG_SAME;
  }
  elsif ($in =~ /^(g|goto)\s+(\w+)$/) { # arg <opidx>
    my $b = valid_breakpoint($2);
    unless ($b) { print "invalid breakpoint \"$b\"\n"; return DBG_SAME; }
    $break_op{$b} = 2; # 2: delete this op at the next break
    return DBG_CONT;
  }
  elsif ($in =~ /^(s|step)$/) {
    if ($op->flags & OPf_KIDS) {
      $opidx++;
      print "..step into kids: $op->first->name\n" if $opt{debug};
      return debugger_walkoptree($op->first, \&debugger_prompt, [ $op->first ])
    } else {
      print "no kids\n";
      return DBG_SAME;
    }
  }
  elsif ($in =~ /^(i|sib)$/) {
    print "..sibling: $op->sibling\n" if $opt{debug};
    $opidx++; # hmm. the real index?
    return debugger_walkoptree($op->sibling, \&debugger_prompt, [ $op->sibling ])
  }
  elsif ($in =~ /^(l|list)\s*(\S*)$/) { # arg <count>, todo: from-to
    my $count = $2;
    $count = ($count and $count =~ /^\d$/) ? $count : 10;
    if ($count =~ /^(\d+)-(\d+)$/) {
      # up or down?
      my ($from, $to) = ($1, $2);
      unless (valid_breakpoint($from)) { print "invalid opidx \"$from-\"\n"; return DBG_SAME; }
      unless (valid_breakpoint($to)) { print "invalid opidx \"-$to\"\n"; return DBG_SAME; }
      unless ($from < $to) { print "invalid list \"$from-$to\"\n"; return DBG_SAME; }
      if ($from < $opidx) {
	if (exists $ops[$from]) {
	  $_[0] = $ops[$from]; # rewind
	  $opidx = $from;
	}
      } # else { step forwards: TODO nyi
      # }
      $count = $to - $opidx;
    }
    print "list ",$opidx,"-",$count+$opidx,"\n";
    my $idx = $opidx;
    debugger_walkoptree($op, \&debugger_listop, [ $op, $count+$opidx ] );
    $opidx = $idx;
    return DBG_SAME;
  }
  elsif ($in =~ /^(d|D|Debug)$/) { # <count>
    print "debug\n";
    debugger_debugop($op, $2 ? $2 : 1);
    return DBG_SAME;
  }
  elsif ($in =~ /^(F|f|Flags)$/) { # opidx ignored
    print "op $opidx ",$op->name;
    print "  Flags: ",$op->flagspv,"\n";
    return DBG_SAME;
  }
  elsif ($in =~ /^(o|C|Concise)$/) { # opidx ignored
    debugger_listop($op,1);
    return DBG_SAME;
  }
  else { print "unknown command \"$in\"\n"; return DBG_SAME; }
}

sub debugger_listop {
  my $op = shift;
  my $until = shift;
  print "..op $opidx $op $op->name until: $until\n" if $opt{debug};
  my $style = "#hyphseq2 (*(   (x( ;)x))*)<#classsym> #exname#arg(?([#targarglife])?)"
    . "~#flags(?(/#private)?)(?(:#hints)?)(x(;~->#next)x)\n";
  return DBG_QUIT unless $$op;

  # hack to set the private curcv
  # manipulate the B::Concise pad? $B::Concise::curcv = main_cv;
  # or localize op->targ
  B::Concise::walk_output(open($^O eq 'MSWin32' ? '>NUL' : ">/dev/null")) unless $opt{debug};
  B::Concise::concise_cv_obj('basic', main_cv, \&main_start);

  print B::Concise::concise_op($op, 0, $style);
  return ($opidx >= $until) ? DBG_QUIT : DBG_NEXT;
}

sub debugger_debugop {
  my $op = shift;
  my $until = shift;
  print "..op ".$opidx." ".$op." ".$op->name.", until: $until\n" if $opt{debug};
  $op->debug;
  return ($opidx >= $until) ? DBG_SAME : DBG_NEXT;
}

our ($file, $line, $opidx) = ("dbg>", 0, 0);
# FIXME: wrong cont logic.
# For now this is recursive, exhausting the stack.
# we could make a loop instead
sub debugger_walkoptree {
  my ($op, $callback, $data) = @_;
  print "..walkoptree - op:", $op,", callback:",$callback,", data:",$data,"\n"
    if $opt{debug};
  ($file, $line) = ($op->file, $op->line) if $op->isa("B::COP");
  return unless $$op;
  my $opname = $op->name;
  $ops[$opidx] = $op unless exists $ops[$opidx];
  if ($dbg_state != DBG_CONT) {
    while (($dbg_state = $callback->($op, $data)) == DBG_SAME) {
      print "..walkoptree SAME - op:", $op,"\n" if $opt{debug};
    }
  }
  print "..walkoptree => $dbg_state\n" if $opt{debug};
  return if $dbg_state == DBG_QUIT;

  if ($op->flags & OPf_KIDS) {
    print "..walkoptree kids ", $$op, $op->flags if $opt{debug};
    my $kid;
    for ($kid = $op->first; $$kid; $kid = $kid->sibling) {
      $opidx++;
      $opname = $kid->name;
      $ops[$opidx] = $kid unless exists $ops[$opidx];
      print "..walkoptree - $opidx, kid:",$kid,' $kid:',$$kid,"\n" if $opt{debug};
      if ($break_op{$opidx} or $break_op{$opname}) {
	if ($break_op{$opidx}) {
	  print "break at $opidx:\n";
	  $break_op{$opidx} = 0 if $break_op{$opidx} == 2; # reset if temporary
	} else {
	  print "break at $opname : $opidx:\n";
	  $break_op{$opname} = 0 if $break_op{$opname} == 2; # reset if temporary
	}
	while (($dbg_state = $callback->($op, $data)) == DBG_SAME) {
	  print "..walkoptree SAME - op:", $op,"\n" if $opt{debug};
	}
	return if $dbg_state == DBG_QUIT;
      }
      debugger_walkoptree($kid, $callback, [ $kid, $data ])
	unless $dbg_state == DBG_CONT;
    }
  } elsif ($op->next) {
    print "..walkoptree next\n" if $opt{debug};
    $opidx++; $op = $op->next;
    $opname = $op->name unless $op->isa('B::NULL');
    $ops[$opidx] = $op unless exists $ops[$opidx];
    # debugger_walkoptree($op, $callback, [ $op, $data ])
    # TODO: check break at the sub entry
    if ($break_op{$opidx} or $break_op{$opname}) { # check break opidx
      print "break at $opidx:\n";
      while (($dbg_state = $callback->($op, $data)) == DBG_SAME) {
	print "..walkoptree SAME - op:", $op,"\n" if $opt{debug};
      }
      return if $dbg_state == DBG_QUIT;
    }
    debugger_walkoptree($op, $callback, [ $op, $data ])
      unless $dbg_state == DBG_CONT;
  }
}

# exchange walkop loop with ours to check the walk state?
sub debugger_initloop {
  print "..initloop ".main_start." ".main_start->name."\n" if $opt{debug};
  debugger_walkoptree(main_start, \&debugger_prompt, [ main_start ]);
}

sub compile { debugger_banner; debugger_initloop; }

BEGIN {
  my $dbg_state = DBG_SAME;
  # TODO: check cfg: --unit, --init, --check
  # before B starts
  Devel::Hook->unshift_CHECK_hook( \&debugger_banner );
  # after B is finished
  Devel::Hook->push_CHECK_hook( \&debugger_initloop );
}

#eval {
#    require XSLoader;
#    XSLoader::load('B::Debugger', $XS_VERSION);
#    1;
#}
#or do {
#    require DynaLoader;
#    local @ISA = qw(DynaLoader);
#    bootstrap B::Debugger $XS_VERSION ;
#};

1;
