#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Data::CSel qw(csel);
use Local::C;
use Local::TN;
use Local::TN1;
use Local::TN2;
use Test::More 0.98;

# to test combinator, class selector, ID selector, pseudo-classes (:first-child,
# :last-child, etc)
my $tree1 = Local::TN->new_from_struct({
    id => 'root', _children => [
        {id => 'a1', _children => [
            {id => 'b11'},
            {id => 'b12', _class=>'Local::TN2'},
            {id => 'b13', _class=>'Local::TN2'},
            {id => 'b14', _class=>'Local::TN1'},
            {id => 'b15', _class=>'Local::TN'},
        ]},
        {id => 'a2', _children => [
             {id => 'b21', _class=>'Local::TN2', _children => [
                 {id => 'c211', _class=>'Local::TN1'},
             ]},
         ]},
    ]},
);

my %n; # nodes, key=id, val=obj
$tree1->walk(sub { $n{$_[0]{id}} = $_ });
$n{root} = $tree1;

# to test attribute selector
my $tree2 = Local::TN->new_from_struct({
    id => 'root', _children => [
        {id => 'd1', int1=>2  , str1=>'a', bool1=>1    , defined1=>0    , },
        {id => 'd2', int1=>3  , str1=>'b', bool2=>0    , defined2=>undef, },
        {id => 'd3', int1=>'a', str1=>'c', bool3=>undef, },
        {id => 'd4', _class=>'Local::TN2'},
    ]},
);

my %m; # nodes, key=id, val=obj
$tree2->walk(sub { $m{$_[0]{id}} = $_ });
$m{root} = $tree2;

# to test chained attribute
my $tree3 = Local::TN->new_from_struct({
    id => 'root', _children => [
        {id => 'd1'},
        {id => 'd2', obj1=>undef},
        {id => 'd3', obj1=>1},
        {id => 'd4', obj1=>Local::C->new()},
        {id => 'd5', obj1=>Local::C->new(attr1=>'a')},
        {id => 'd6', obj1=>Local::C->new(attr1=>'b')},
    ]},
);

my %n3; # nodes, key=id, val=obj
$tree3->walk(sub { $n3{$_[0]{id}} = $_ });
$n3{root} = $tree3;

subtest "simple selector: type selector" => sub {
    test_csel(
        expr   => "Local::TN",
        nodes  => [$tree1],
        result => [@n{qw/root a1 a2 b11 b15/}],
    );
    test_csel(
        expr   => "Local::TN2",
        nodes  => [$tree1],
        result => [@n{qw/b12 b13 b21/}],
    );
};

subtest "simple selector: universal selector" => sub {
    test_csel(
        expr   => "*",
        nodes  => [@n{qw/a2/}],
        result => [@n{qw/a2 b21 c211/}],
    );
};

subtest "simple selector: class selector" => sub {
    test_csel(
        expr   => ".Local::TN",
        nodes  => [$tree1],
        result => [@n{qw/root a1 a2 b11 b12 b13 b14 b15 b21 c211/}],
    );
    test_csel(
        expr   => ".Local::TN1",
        nodes  => [$tree1],
        result => [@n{qw/b14 c211/}],
    );
    test_csel(
        expr   => ".Local::TN1.Local::TN2",
        nodes  => [$tree1],
        result => [],
    );
    test_csel(
        expr   => ".foo",
        nodes  => [$tree1],
        result => [],
    );
};

subtest "simple selector: ID selector" => sub {
    test_csel(
        expr   => "#a1",
        nodes  => [$tree1],
        result => [@n{qw/a1/}],
    );
    test_csel(
        expr   => "#foo",
        nodes  => [$tree1],
        result => [],
    );
    test_csel(
        expr   => "#a1#a1",
        nodes  => [$tree1],
        result => [@n{qw/a1/}],
    );
    test_csel(
        expr   => "#a1#a2",
        nodes  => [$tree1],
        result => [],
    );
};

subtest "simple selector: attribute selector" => sub {
    test_csel(
        expr   => "[foo]",
        nodes  => [$m{root}],
        result => [],
    );
    test_csel(
        expr   => "[int1]",
        nodes  => [$m{root}],
        result => [@m{qw/root d1 d2 d3 d4/}],
    );
    test_csel(
        expr   => "[int2]",
        nodes  => [$m{root}],
        result => [@m{qw/d4/}],
    );
    test_csel(
        expr   => "[obj1.attr1]",
        nodes  => [$n3{root}],
        result => [@n3{qw/d4 d5 d6/}],
    );

    test_csel(
        name   => 'op:eq (with type)',
        expr   => "Local::TN[id eq 'd1']",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );
    test_csel(
        name   => 'op:eq (unquoted operand)',
        expr   => "Local::TN[id eq d1]",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );
    test_csel(
        name   => 'op:= (str)',
        expr   => "[int1='a']",
        nodes  => [$m{root}],
        result => [@m{qw/d3/}],
    );
    test_csel(
        name   => 'op:=',
        expr   => "[int1=2]",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );
    test_csel(
        name   => 'op:==',
        expr   => "[int1==2]",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );

    test_csel(
        name   => 'op:ne',
        expr   => "[id ne 'd1']",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );
    test_csel(
        name   => 'op:!= (str)',
        expr   => "[id != 'd1']",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );
    test_csel(
        name   => 'op:!=',
        expr   => "[int1 != 3]",
        nodes  => [$m{root}],
        result => [@m{qw/root d1 d3 d4/}],
    );
    test_csel(
        name   => 'op:<>',
        expr   => "[int1 <> 3]",
        nodes  => [$m{root}],
        result => [@m{qw/root d1 d3 d4/}],
    );

    test_csel(
        name   => 'op:gt',
        expr   => "[id gt 'd1']",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );
    test_csel(
        name   => 'op:> (str)',
        expr   => "[id > 'd1']",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );
    test_csel(
        name   => 'op:>',
        expr   => "[int1 > 2]",
        nodes  => [$m{root}],
        result => [@m{qw/d2/}],
    );

    test_csel(
        name   => 'op:ge',
        expr   => "[id ge 'd2']",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );
    test_csel(
        name   => 'op:>= (str)',
        expr   => "[id >= 'd2']",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );
    test_csel(
        name   => 'op:>=',
        expr   => "[int1 >= 3]",
        nodes  => [$m{root}],
        result => [@m{qw/d2/}],
    );

    test_csel(
        name   => 'op:lt',
        expr   => "[id lt 'd2']",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );
    test_csel(
        name   => 'op:< (str)',
        expr   => "[id < 'd2']",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );
    test_csel(
        name   => 'op:<',
        expr   => "Local::TN[int1 < 3]",
        nodes  => [$m{root}],
        result => [@m{qw/root d1 d3/}],
    );

    test_csel(
        name   => 'op:le',
        expr   => "[id le 'd2']",
        nodes  => [$m{root}],
        result => [@m{qw/d1 d2/}],
    );
    test_csel(
        name   => 'op:<= (str)',
        expr   => "[id <= 'd2']",
        nodes  => [$m{root}],
        result => [@m{qw/d1 d2/}],
    );
    test_csel(
        name   => 'op:<=',
        expr   => "Local::TN[int1 <= 3]",
        nodes  => [$m{root}],
        result => [@m{qw/root d1 d2 d3/}],
    );

    test_csel(
        name   => 'op:=~',
        expr   => "[str1 =~ /[Ab]/]",
        nodes  => [$m{root}],
        result => [@m{qw/d2/}],
    );
    test_csel(
        name   => 'op:=~ (i)',
        expr   => "[str1 =~ /[Ab]/i]",
        nodes  => [$m{root}],
        result => [@m{qw/d1 d2/}],
    );
    test_csel(
        name   => 'op:!~',
        expr   => "[str1 !~ /[a-z]/]",
        nodes  => [$m{root}],
        result => [@m{qw/root d4/}],
    );

    test_csel(
        name   => 'op:is (bool, true)',
        expr   => "[bool1 is true]",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );
    test_csel(
        name   => 'op:is (bool, false)',
        expr   => "[bool1 is false]",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );
    test_csel(
        name   => 'op:is (defined)',
        expr   => "[defined1 is null]",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );

    test_csel(
        name   => 'op:isnt (bool, false)',
        expr   => "[bool1 isnt false]",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );
    test_csel(
        name   => 'op:isnt (bool, true)',
        expr   => "[bool1 isnt true]",
        nodes  => [$m{root}],
        result => [@m{qw/root d2 d3 d4/}],
    );
    test_csel(
        name   => 'op:isnt (defined)',
        expr   => "[defined1 isnt null]",
        nodes  => [$m{root}],
        result => [@m{qw/d1/}],
    );
};

subtest "simple selector: pseudo-class" => sub {
    test_csel(
        expr   => "Local::TN1:first",
        nodes  => [$n{root}],
        result => [@n{qw/b14/}],
    );
    test_csel(
        expr   => ":last",
        nodes  => [$n{root}],
        result => [@n{qw/c211/}],
    );
    test_csel(
        expr   => ":first-child",
        nodes  => [$n{root}],
        result => [@n{qw/a1 b11 b21 c211/}],
    );
    test_csel(
        expr   => ":last-child",
        nodes  => [$n{root}],
        result => [@n{qw/a2 b15 b21 c211/}],
    );
    test_csel(
        expr   => ":only-child",
        nodes  => [$n{root}],
        result => [@n{qw/b21 c211/}],
    );
    test_csel(
        expr   => ":nth-child(2)",
        nodes  => [$n{root}],
        result => [@n{qw/a2 b12/}],
    );
    test_csel(
        expr   => ":nth-last-child(2)",
        nodes  => [$n{root}],
        result => [@n{qw/a1 b14/}],
    );

    test_csel(
        expr   => ":first-of-type",
        nodes  => [$n{root}],
        result => [@n{qw/a1 b11 b12 b14 b21 c211/}],
    );
    test_csel(
        expr   => ":last-of-type",
        nodes  => [$n{root}],
        result => [@n{qw/a2 b13 b14 b15 b21 c211/}],
    );
    test_csel(
        expr   => ":only-of-type",
        nodes  => [$n{root}],
        result => [@n{qw/b14 b21 c211/}],
    );
    test_csel(
        expr   => ":nth-of-type(2)",
        nodes  => [$n{root}],
        result => [@n{qw/a2 b13 b15/}],
    );
    test_csel(
        expr   => ":nth-last-of-type(2)",
        nodes  => [$n{root}],
        result => [@n{qw/a1 b11 b12/}],
    );

    test_csel(
        expr   => ":root",
        nodes  => [$n{root}],
        result => [@n{qw/root/}],
    );
    test_csel(
        expr   => ":root",
        nodes  => [$n{a1}],
        result => [@n{qw//}],
    );

    test_csel(
        expr   => ":empty",
        nodes  => [$n{root}],
        result => [@n{qw/b11 b12 b13 b14 b15 c211/}],
    );

    test_csel(
        expr   => ":has('Local::TN1')",
        nodes  => [$n{root}],
        result => [@n{qw/root a1 a2 b21/}],
    );
    test_csel(
        expr   => ":not(':first-child')",
        nodes  => [$n{root}],
        result => [@n{qw/root a2 b12 b13 b14 b15/}],
    );
    test_csel(
        name   => ":not (quote optional)",
        expr   => ":not(:first-child)",
        nodes  => [$n{root}],
        result => [@n{qw/root a2 b12 b13 b14 b15/}],
    );
};

subtest "selector: combinator" => sub {
    test_csel(
        name   => "descendant",
        expr   => "Local::TN Local::TN1",
        nodes  => [$n{root}],
        result => [@n{qw/b14 c211/}],
    );
    test_csel(
        name   => "child",
        expr   => "Local::TN > Local::TN1",
        nodes  => [$n{root}],
        result => [@n{qw/b14/}],
    );
    test_csel(
        name   => "sibling",
        expr   => "Local::TN ~ Local::TN",
        nodes  => [$n{root}],
        result => [@n{qw/a2 b15/}],
    );
    test_csel(
        name   => "adjacent sibling",
        expr   => "Local::TN + Local::TN",
        nodes  => [$n{root}],
        result => [@n{qw/a2/}],
    );
};

subtest "selectors: comma" => sub {
    test_csel(
        expr   => "Local::TN1, Local::TN2",
        nodes  => [$n{root}],
        result => [@n{qw/b14 c211 b12 b13 b21/}],
    );
};

subtest "option: class_prefixes" => sub {
    my $tree = Local::TN->new_from_struct({
        id => 'root', _children => [
            {id => 'a2', _class => 'Local::TN2'},
            {id => 'a3', _class => 'Local::TN'},
        ]},
    );
    my %n; # nodes, key=id, val=obj
    $tree->walk(sub { $n{$_[0]{id}} = $_ });
    $n{root} = $tree;

    test_csel(
        name   => "without prefix",
        expr   => "TN2",
        nodes  => [$n{root}],
        result => [],
    );
    test_csel(
        name   => "with prefix",
        expr   => "TN2",
        opts   => {class_prefixes=>['Local']},
        nodes  => [$n{root}],
        result => [@n{qw/a2/}],
    );
};

DONE_TESTING:
done_testing;

sub test_csel {
    my %args = @_;

    my $opts = $args{opts} // {};
    my @res = csel($opts, $args{expr}, @{$args{nodes}});

    my $res_ids = [map {$_->{id}} @res];
    my $exp_res_ids = [map {$_->{id}} @{ $args{result} }];

    subtest +($args{name} // $args{expr}) => sub {
        is_deeply($res_ids, $exp_res_ids, "result")
            or diag explain $res_ids;
    };
}
