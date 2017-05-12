#!perl -w
use strict;
BEGIN {
  if ($] < 5.008001) {
    print "1..0 #skip B::CV->NEW_with_start requires perl 5.8.1";
    exit;
  }
  require B::Generate;
  B::Generate->import;
  no strict 'refs'; 
  unless (exists ${'B::CV::'}{'NEW_with_start'}) { 
    print "1..0 #skip no cv_clone"; exit; 
  }
  if (eval "$B::VERSION" < '1.09') {
    print "1..0 #skip B::CV->NEW_with_start requires B 1.09"; exit;
  }
}
use Test::More tests => 26;
use B::Terse;
no warnings 'void';

my $DEBUG;
my $orz;

sub foo {
    my $n = shift;
    return $orz->($n);
}

my ($a, $b) = 0;

# $a is the first and only lexical here.
sub dothat_and_1 {
    $a;
    1;
}

# we swap the lexicals. $b is now the first lexical in the padlist
sub dothat_and_2 {
    $b, $a;
    1;
}

# $a is really the first lexical in the padlist
sub inc_a {
    ++$a;
}

sub showlex {
    my ($what, $names, $vals) = @_;
    my @names = $names->ARRAY;
    my @vals  = $vals->ARRAY;
    my $count = @names;
    print "# $what:\n";
    for (my $i = 1; $i < $count; $i++) {
	printf "# $i: %s = %s\n", $names[$i]->terse, $vals[$i]->terse;
    }
}

sub prepend_function_with_inc {
    my $code = shift;
    #diag "\$^P = $^P";
    my $P = $^P & ~260; # do not expect dbstate with Devel::Cover
    my $statename = $P ? 'dbstate' : 'nextstate';
    my $whoami = B::svref_2object($code);
    isa_ok($whoami, 'B::CV');
    is($whoami->ROOT->name, 'leavesub', 'leavesub');
    is($whoami->START->name, $statename, $statename);
    my $leavesub = B::UNOP->new("leavesub", $whoami->ROOT->flags, $whoami->ROOT->first);
    is($leavesub->name, 'leavesub', 'leavesub');
    my $nextstate = $whoami->START;
    is($nextstate->name, $statename, $statename);

    my $inc_a = B::svref_2object(\&inc_a);
    my $inc_a_entry = $inc_a->START;
    if ($] >= 5.010 and ($P or $DEBUG)) {
        print "# code=",$whoami,"\n";
        print "# inc_a=", $inc_a, ", inc_a->OUTSIDE->PADLIST=",$inc_a->OUTSIDE->PADLIST,"\n";
        showlex("inc_a->OUTSIDE", $inc_a->OUTSIDE->PADLIST->ARRAY) if $DEBUG;
        print "# OUTSIDE=", $inc_a->OUTSIDE, ", PADLIST=",$inc_a->PADLIST,
          ", FLAGS=",$inc_a->FLAGS, ", OUTSIDE_SEQ=", $inc_a->OUTSIDE_SEQ, "\n";
        print "# inc_a->targ=",$inc_a->START->targ,"\n";
        print "# a=",B::svref_2object(\$a),"\n";
        showlex("inc_a", $inc_a->PADLIST->ARRAY) if $DEBUG;
    }
    is($inc_a_entry->name, $statename, $statename);
    my $padsv = $inc_a->START->next;

    my $inc = $padsv->next;
    while ($inc->name ne 'preinc') {
        $inc = $inc->next;
        last if $inc->name eq 'entersub';
    }
    is($inc->name, 'preinc', 'preinc');
    $inc->sibling($nextstate);
    $inc->next($nextstate);

    my $orz_obj = $whoami->NEW_with_start($leavesub, $inc_a_entry);
    showlex("orz", $orz_obj->START->PADLIST->ARRAY) if $DEBUG;
    return $orz_obj->object_2svref;
}

$orz = prepend_function_with_inc(\&dothat_and_1);

is(dothat_and_1(), 1, 'dothat_and_1 returns 1');
is($a, 0, 'a is 0');

showlex("comppadlist", B::comppadlist->ARRAY) if $DEBUG;
is($orz->(), 1, 'orz returns 1');
is($a, 1, 'a is 1');

showlex("comppadlist", B::comppadlist->ARRAY) if $DEBUG;
is($orz->(), 1, 'orz returns 1');
is($a, 2, 'a is 2');

$orz = prepend_function_with_inc(\&dothat_and_2);
is($orz->(), 1, 'dothat_and_2: orz returns 1');

# The inc_a targ 1 is now $b, not $a
showlex("comppadlist", B::comppadlist->ARRAY) if $DEBUG;
is($a, 2, 'a is 2');
is($b, 1, 'b is 1');
is($orz->(), 1, 'dothat_and_2: orz returns 1');
is($a, 2, 'a is 2');
is($b, 2, 'b is 2');

# dumps core at END with 5.8.6 and lower
# END { undef $orz; }

