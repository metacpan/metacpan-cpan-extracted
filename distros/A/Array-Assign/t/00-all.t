use strict;
use warnings;
use Array::Assign;
use Test::More;

my @arry;
my $asgn = Array::Assign->new(qw(foo bar baz));
$asgn->assign_s(\@arry, foo => "hi", bar => "bye!");
is_deeply( [ @arry[0,1] ], ['hi', 'bye!'], "OO string assignment");

@arry = ();
$asgn->assign_i(\@arry, 1 => "Hello", 3 => "World");
is_deeply( [ @arry[1,3] ], ["Hello", "World"], "OO integer assignment");

@arry = ();
my $mapping = {
    first => 0,
    second => 1,
    third => 2,
    final => 10,
};

arry_assign_s @arry, $mapping, first => "Rishon", third => "Shlishi";
is_deeply( [ @arry[0,2] ], ["Rishon", "Shlishi"], "Procedural string assignment");

@arry = ();
arry_assign_i @arry, 6 => "Shishi", 5 => "Hamishi";
is_deeply([ @arry[6,5] ], [qw(Shishi Hamishi)], "Procedural Integer Assignment");

$asgn->assign_s(\@arry, foo => "FooStr", bar => "BarStr", baz => "BazStr");
$asgn->extract_s(\@arry, foo => \my $fooval, bar => \my $barval, baz => \my $bazval);

is_deeply([$fooval,$barval,$bazval], ["FooStr", "BarStr", "BazStr"],
          "OO String extraction");

$asgn->extract_i([qw(snap crackle pop)], 2 => \my $last, 0 => \my $first);
is_deeply(["snap", "pop"], [$first, $last], "OO Idx extraction");


@arry = qw(snap crackle pop);
arry_extract_i @arry, 0 => \$first, 2 => \$last;
is_deeply( [ $first, $last ], [qw(snap pop)], "Procedural Idx extraction");

my $emapping = {
    first => 0,
    last => 2
};

arry_extract_s @arry, $emapping, first => \$first, last => \$last;
is_deeply( [ $first, $last] , [qw(snap pop)], "Procedural String Extraction");
done_testing();