#!/usr/bin/env perl
use strict;

use Test::More tests => 9;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

$lib = catdir(@path, 't');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
eval "use App::Followme::Web";
require App::Followme::Template;
require MockData;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir;

#----------------------------------------------------------------------
# Create object

my $pp = App::Followme::Template->new();
isa_ok($pp, "App::Followme::Template"); # test 1
can_ok($pp, qw(new compile)); # test 2

#----------------------------------------------------------------------
# Test simple rendering

do {
    my $template = "\$data\n";
    my $render = $pp->compile($template);

    my $data = {data => undef};
    my $meta = MockData->new($data);

    $data = {data => '<>'};
    $meta = MockData->new($data);

    my $result = $render->($meta);
    is($result, "<>\n", "Rendar single value"); # test 3

    $template = "\$a\n\$b\n";
    $render = $pp->compile($template);

    $data = {a => 1, b => 2};
    $meta = MockData->new($data);
    $result = $render->($meta);
    is($result, "1\n2\n", "Render two values"); # test 4
};

#----------------------------------------------------------------------
# Test for loop

do {
    my $template = <<'EOQ';
<!-- for @list -->
$item
<!-- else -->
<p>No items</p>
<!-- endfor -->
EOQ

    my $render = App::Followme::Template->compile($template);
    my $data = {list => [qw(first second third)]};

    my $meta = MockData->new($data);
    my $text = $render->($meta);

    my $text_ok = <<'EOQ';
first
second
third
EOQ

    is($text, $text_ok, "For loop"); # test 5

    $data = {list => []};
    $meta = MockData->new($data);
    $text = $render->($meta);

    $text_ok = <<'EOQ';
<p>No items</p>
EOQ

    is($text, $text_ok, "Empty for loop"); # test 6

};

#----------------------------------------------------------------------
# Test if blocks

do {
    my $template = <<'EOQ';
<!-- if $x == 1 -->
\$x is $x (one)
<!-- elsif $x  == 2 -->
\$x is $x (two)
<!-- else -->
\$x is unknown
<!-- endif -->
EOQ

    my $render = App::Followme::Template->compile($template);

    my $data = {x => 1};
    my $meta = MockData->new($data);

    my $text = $render->($meta);
    is($text, "\$x is 1 (one)\n", "If block"); # test 7

    $data = {x => 2};
    $meta = MockData->new($data);

    $text = $render->($meta);
    is($text, "\$x is 2 (two)\n", "Elsif block"); # test 8

    $data = {x => 3};
    $meta = MockData->new($data);

    $text = $render->($meta);
    is($text, "\$x is unknown\n", "Else block"); # test 9
};
