#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../../lib';

use B qw(main_root);

use Test::More;
note( "Testing B::DeparseTree B::DeparseTree:TreeMain" );

BEGIN {
use_ok( 'B::DeparseTree::TreeMain' );
use_ok( 'B::DeparseTree::SyntaxTree' );
}

my $deparse = B::DeparseTree->new();

Test::More::note ( "info_from_list() testing" );
my @texts = ('a', 'b', 'c');
my $info = info_from_list(main_root, $deparse, \@texts, ', ', 'test1', {});
is $info->{text}, 'a, b, c';
is $info->{type}, 'test1';

@texts = (['d', 1], ['e', 2], 'f');
my $info1 = info_from_list(main_root, $deparse, \@texts, '', 'test2', {});
is $info1->{text}, 'def';

my $info2 = info_from_list(main_root, $deparse, [$info, $info1], ':', 'test3', {});
is $info2->{text}, 'a, b, c:def';

my $info3 = $deparse->info_from_string('test4', main_root, 'foo');
is $info3->{text}, 'foo';

$info = info_from_list(main_root, $deparse, \@texts, '', 'test2',
			  {maybe_parens => [$deparse, 10, 20]});
is $info->{text}, 'def', 'precedence does not require parens';
$info = info_from_list(main_root, $deparse, \@texts, '', 'test2',
		       {maybe_parens => [$deparse, 20, 10]});
is $info->{text}, '(def)', 'precedence requires parens';
$info = info_from_list(main_root, $deparse, \@texts, '', 'test2',
		       {maybe_parens => [$deparse, 20, 20]});
is $info->{text}, '(def)', 'not special-case UNARY_PRECIDENCE';

$info = info_from_list(main_root, $deparse, \@texts, '', 'test2',
		       {maybe_parens => [$deparse, 16, 16]});
is $info->{text}, 'def', 'special-case UNARY_PRECIDENCE';

foreach my $cx (keys %B::DeparseTree::Node::UNARY_PRECEDENCES) {
    $info = info_from_list(main_root, $deparse, \@texts, '', 'test2',
		       {maybe_parens => [$deparse, $cx, $cx]});
    is $info->{text}, 'def';
}

Test::More::note ( "template_engine() testing" );

$deparse->{level} = 0;
is $deparse->template_engine("100%% ", [], []), "100% ";
is $deparse->{level}, 0;

$deparse->{'indent_size'} = 2;
my $str = $deparse->template_engine("%c,\n%+%c\n%|%c %c!",
				    [1, 0, 2, 3],
				    ["is", "now", "the", "time"]);
is $str, "now,\n  is\n  the time!", '%c';
is $deparse->{level}, 2;

$info = $deparse->info_from_template("demo", undef, "%C",
				     [[0, 1, ";\n%|"]],
				     ['$x=1', '$y=2']);
is $info->{text}, "\$x=1;\n  \$y=2", 'template %|';

$deparse->{level} = 0;
@texts = ("use warnings;", "use strict", "my(\$a)");
$info = $deparse->info_from_template("demo", undef, "%;", [], \@texts);
is $info->{text}, "use warnings;\nuse strict;\nmy(\$a)";

my ($found_str, $pos) = $deparse->template_engine("<--%c-->", [0],
						  [$info1], $info2->{addr});
print $found_str, "\n";
print ' ' x $pos->[0] . '-' x $pos->[1], "\n";
# use Data::Printer; p $pos;

$str = $deparse->template_engine("%c", [0], ["16"]);
my $str2 = $deparse->template_engine("%F", [[0, sub {'0x' . sprintf "%x", shift}]], [$str]);
is $str2, '0x10', "Transformation function %F";

Test::More::done_testing();
