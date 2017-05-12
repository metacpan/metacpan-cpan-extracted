use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;

BEGIN {
    {
        package MyApp::Schema::Result::Artist;
        use base 'DBIx::Class::Core';
        __PACKAGE__->table('artists');
        __PACKAGE__->add_columns(
            id => 'int',
        );
        __PACKAGE__->set_primary_key('id');
    }

    {
        package MyApp::Schema::Result::Track;
        use base 'DBIx::Class::Core';
        __PACKAGE__->table('tracks');
        __PACKAGE__->add_columns(
            id => 'int',
        );
        __PACKAGE__->set_primary_key('id');
    }

    {
        package MyApp::Schema;
        use base 'DBIx::Class::Schema';
        __PACKAGE__->register_class(Artist => 'MyApp::Schema::Result::Artist');
        __PACKAGE__->register_class(Track => 'MyApp::Schema::Result::Track');
    }
}

use DBIx::Class::TopoSort;
use Test::DBIx::Class qw(:resultsets);

my @tables = DBIx::Class::TopoSort->toposort(Schema);
cmp_bag( [@tables], ['Artist', 'Track'], "Unconnected tables are returned in any order" );

done_testing;
