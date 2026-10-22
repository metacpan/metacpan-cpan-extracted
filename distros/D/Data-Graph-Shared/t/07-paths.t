use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Graph::Shared;

{
    package GraphTest::Path;
    use overload '""' => sub { ${$_[0]} }, fallback => 1;
    sub new { my $path = $_[1]; bless \$path, $_[0] }
}

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/graph";
my $object = GraphTest::Path->new($path);
my $g = eval { Data::Graph::Shared->new($object, 4, 4) };
ok $g, 'create with a string-overloaded path' or diag $@;
$g ||= Data::Graph::Shared->new($path, 4, 4);
is $g->path, $path, 'stored path is the string value';
$g->add_node(42);
$g->freeze;
my $ro = Data::Graph::Shared->new_readonly($object);
is $ro->node_data(0), 42, 'read-only open with a string-overloaded path';

for my $overloaded (0, 1) {
    my $prefix = "$dir/nul-$overloaded";
    my $seed = Data::Graph::Shared->new($prefix, 4, 4);
    $seed->freeze;
    my $value = "$prefix\0suffix";
    $value = GraphTest::Path->new($value) if $overloaded;
    for my $call (
        [new => sub { Data::Graph::Shared->new($value, 4, 4) }],
        [new_readonly => sub { Data::Graph::Shared->new_readonly($value) }],
        [unlink => sub { Data::Graph::Shared->unlink($value) }],
    ) {
        eval { $call->[1]->() };
        like $@, qr/embedded NUL/, "$call->[0] rejects a NUL in the string value";
        ok -f $prefix, "$call->[0] preserves the file at the prefix";
    }
}

Data::Graph::Shared->unlink($object);
ok !-e $path, 'class unlink with a string-overloaded path';
done_testing;
