use strict;
use warnings;

use Test::More;
use Test::Exception;
use t::Utils;
use File::Basename qw(dirname);

use Bread::Board::LazyLoader;

my $dir = join( '/', dirname(__FILE__), 'files' );

subtest 'add tree at root position' => sub {
    my $loader = Bread::Board::LazyLoader->new;
    ok( $loader->name, 'Default loader name is Root' );
    lives_ok { $loader->add_tree( $dir, 'ioc' ); } or return;

    my $root = $loader->build;

    is( $root->fetch('config')->get,
        'CONFIG', 'Root.ioc was loaded at Root position' );
    is( $root->fetch('Database/dbh')->get,
        'DBH', 'Database.ioc was loaded at Database position' );
    is( $root->fetch('WebServices/REST/rest')->get,
        'REST',
        'WebServices/REST.ioc was loaded at WebServices/REST position' );
};

subtest 'add tree at nested position' => sub {
    my $loader = Bread::Board::LazyLoader->new;

    $loader->add_tree( $dir, 'ioc', 'Foo' );

    my $root = $loader->build;
    is( $root->fetch('Foo/Root/config')->get,
        'CONFIG', 'Root.ioc was loaded at Foo/Root position' );
    is( $root->fetch('Foo/Database/dbh')->get,
        'DBH', 'Database.ioc was loaded at Foo/Database position' );
    is( $root->fetch('Foo/WebServices/REST/rest')->get,
        'REST',
        'WebServices/REST.ioc was loaded at Foo/WebServices/REST position' );
};

# loading again at new position

done_testing();

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:
