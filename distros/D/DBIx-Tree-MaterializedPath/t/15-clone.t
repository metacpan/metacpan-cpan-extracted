
use strict;
use warnings;

use Test::More tests => 18;

use DBIx::Tree::MaterializedPath;

BEGIN
{
    chdir 't' if -d 't';
    use File::Spec;
    my $testlib = File::Spec->catfile('testlib', 'testutils.pm');
    require $testlib;
}

SKIP:
{
    my $dbh;
    eval { $dbh = test_get_dbh() };
    skip($@, 18) if $@;

    my $clone;

    #####

    my ($tree, $childhash) = test_create_test_tree($dbh);

    foreach my $node ($tree, $childhash->{'1.3.1'})
    {

        # This creates a cached statement handle in the process of storing:
        $node->data({name => 'original name'});

        $clone = $node->clone();
        isa_ok($clone, ref($node), 'Object created via clone()');
        isnt($node, $clone, 'Clone is at distinct memory location');
        is_deeply($node, $clone, 'Clone is a deep copy');

        is($clone->_id,          $node->_id,          'Cloned _id() matches');
        is($clone->_path,        $node->_path,        'Cloned _path() matches');
        is($clone->data->{name}, $node->data->{name}, 'Cloned data() matches');

        # This stores data to DB (should use cached statement handle):
        $clone->data({name => 'new name'});

        is($clone->data->{name}, 'new name',      'Clone set new data()');
        is($node->data->{name},  'original name', 'Original has old data()');

        # Refresh data from DB into original node:
        $node->refresh_data();

        is($clone->data->{name},
            $node->data->{name}, 'Original data() matches after refresh');
    }
}
