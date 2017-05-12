use Test::More tests => 218;
use strict;
use warnings;
use lib 't/';
BEGIN { use_ok('Simple') };

# construct a small tree
my $root = Simple->new_root(name => 'root');
isa_ok($root, 'Simple');
can_ok($root, 'match', 'xpath');
$root->add_kid(
    name => 'some:page', foo => 10, bar => 'bif')->add_kid(
        name => 'kidfoo', data => 10);
$root->add_kid(
    name => 'some:page', foo => 20, bar => 'bof')->add_kid(
        name => 'kidfoo', data => 20);
$root->add_kid(
    name => 'some:page', foo => 30, bar => 'bongo')->add_kid(
        name => 'kidfoo', data => 30);
my @pages = $root->kids;
for my $page (@pages) {
    isa_ok($page, 'Simple');
    can_ok($page, 'match', 'xpath');
    for (0 .. 9) {
        $page->add_kid(name => 'paragraph', data => "$page->{bar}$_" );
        $page->add_kid(name => 'image') if $_ % 2;
    }
}
#use Data::Dumper;
#warn "tree:",Dumper($root),"\n";

# root's xpath should be /
is($root->xpath(), '/');

# page xpath tests
is($pages[0]->xpath, '/some:page[0]');
is($pages[1]->xpath, '/some:page[1]');
is($pages[2]->xpath, '/some:page[2]');

# paragraph xpath tests
foreach my $page (@pages) {
    my @para = grep { $_->name eq 'paragraph' } $page->kids;
    for (my $x = 0; $x < $#para; $x++) {
        is($para[$x]->xpath, $page->xpath . "/paragraph[$x]");
    }
    my @images = grep { $_->name eq 'image' } $page->kids;
    for (my $x = 0; $x < $#images; $x++) {
        is($images[$x]->xpath, $page->xpath . "/image[$x]");
    }
}

# test match against returned xpaths
is($root->match($pages[0]->xpath), 1);
is(($root->match($pages[0]->xpath))[0], $pages[0]);
is($root->match($pages[1]->xpath), 1);
is(($root->match($pages[1]->xpath))[0], $pages[1]);
is($root->match($pages[2]->xpath), 1);
is(($root->match($pages[2]->xpath))[0], $pages[2]);

# test paragraph xpath matching, both from the page and the root
foreach my $page (@pages) {
    my @para = grep { $_->name eq 'paragraph' } $page->kids;
    for (my $x = 0; $x < $#para; $x++) {
        is($para[$x]->match($page->xpath), 1);
        is(($para[$x]->match($page->xpath))[0], $page);
        is(($root->match($page->xpath))[0], $page);
    }
}

# test local name query
is($root->match('some:page'), 3);
is(($root->match('some:page'))[0]->match('paragraph'), 10);

# test global  name query
is($root->match('//paragraph'), 30);

# test parent context
foreach my $page (@pages) {
    my @para = grep { $_->name eq 'paragraph' } $page->kids;
    for (my $x = 0; $x < $#para; $x++) {
        is(($para[$x]->match("../paragraph[$x]"))[0], $para[$x]);
    }
}

# test string attribute matching
is($root->match('some:page[@bar="bif"]'), 1);
is(($root->match('some:page[@bar="bif"]'))[0], $pages[0]);
is($root->match('some:page[@bar="bof"]'), 1);
is(($root->match('some:page[@bar="bof"]'))[0], $pages[1]);
is($root->match("some:page[\@bar='bongo']"), 1);
is(($root->match("some:page[\@bar='bongo']"))[0], $pages[2]);

# test numeric attribute matching
is($root->match('some:page[@foo=10]'), 1);
is(($root->match('some:page[@foo=10]'))[0], $pages[0]);
is($root->match('some:page[@foo=20]'), 1);
is(($root->match('some:page[@foo=20]'))[0], $pages[1]);
is($root->match('some:page[@foo=30]'), 1);
is(($root->match('some:page[@foo=30]'))[0], $pages[2]);

is($root->match('some:page[@foo>10]'), 2);
is(($root->match('some:page[@foo>10]'))[0], $pages[1]);
is(($root->match('some:page[@foo>10]'))[1], $pages[2]);

is($root->match('some:page[@foo<10]'), 0);

is($root->match('some:page[@foo!=10]'), 2);

is($root->match('some:page[@foo<=10]'), 1);

is($root->match('some:page[@foo>=10]'), 3);

# test attribute value retrieval
is($root->match('/some:page[0]/@foo'), 1);
eq_array([$root->match('/some:page/@foo')], [qw( 10 20 30 )]);
is(($root->match('/some:page[-1]/@bar'))[0], 'bongo');
eq_array([$root->match('/some:page/@bar')], [qw( bif bof bongo )]);

# make sure bad use of @foo is caught
eval { $root->match('/some:page[0]/@foo/bar'); };
like($@, qr/Bad call.*contains an attribute selector in the middle of the expression/);

# test string child matching
is($root->match('some:page[paragraph="bif0"]'), 1, "Child node string match");
is(($root->match('some:page[paragraph="bif0"]'))[0], $pages[0]);
is($root->match('some:page[paragraph="bif3"]'), 1, "Child node string match");
is(($root->match('some:page[paragraph="bif3"]'))[0], $pages[0]);

is($root->match('some:page[paragraph="bof0"]'), 1, "Child node string match");
is(($root->match('some:page[paragraph="bof0"]'))[0], $pages[1]);
is($root->match('some:page[paragraph="bof3"]'), 1, "Child node string match");
is(($root->match('some:page[paragraph="bof3"]'))[0], $pages[1]);

is($root->match('some:page[paragraph="bongo0"]'), 1, "Child node string match");
is(($root->match('some:page[paragraph="bongo0"]'))[0], $pages[2]);
is($root->match('some:page[paragraph="bongo3"]'), 1, "Child node string match");
is(($root->match('some:page[paragraph="bongo3"]'))[0], $pages[2]);

# test numeric child matching
is($root->match('some:page[kidfoo=10]'), 1, "Child node = match");
is(($root->match('some:page[kidfoo=10]'))[0], $pages[0]);
is($root->match('some:page[kidfoo=20]'), 1, "Child node = match");
is(($root->match('some:page[kidfoo=20]'))[0], $pages[1]);
is($root->match('some:page[kidfoo=30]'), 1, "Child node = match");
is(($root->match('some:page[kidfoo=30]'))[0], $pages[2]);

is($root->match('some:page[kidfoo>10]'), 2, "Child node > match");
is(($root->match('some:page[kidfoo>10]'))[0], $pages[1]);
is(($root->match('some:page[kidfoo>10]'))[1], $pages[2]);

is($root->match('some:page[kidfoo<10]'), 0, "Child node < match");

is($root->match('some:page[kidfoo!=10]'), 2, "Child node != match");

is($root->match('some:page[kidfoo<=10]'), 1, "Child node <= match");

is($root->match('some:page[kidfoo>=10]'), 3, "Child node >= match");

is($root->match('some:page[.="10bif0bif1bif2bif3bif4bif5bif6bif7bif8bif9"]'), 1,
"Complex child node string match");
is(($root->match('some:page[.="10bif0bif1bif2bif3bif4bif5bif6bif7bif8bif9"]'))[0], $pages[0]);

