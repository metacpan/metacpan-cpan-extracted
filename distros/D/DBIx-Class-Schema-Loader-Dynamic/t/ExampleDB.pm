package ExampleDB;

use strict;
use warnings;

use base qw/DBIx::Class::Schema/;
use DBIx::Class::Schema::Loader::Dynamic;

sub connect_info { [ "dbi:SQLite:$ENV{EXAMPLEDB}", '', '' ] }

sub setup {
    my $class = shift;

    my $schema = $class->connection(@{$class->connect_info});

    DBIx::Class::Schema::Loader::Dynamic->new(
        left_base_classes => 'ExampleDB::Row',
        naming            => 'v8',
        use_namespaces    => 0,
        schema            => $schema,
    )->load;

    return $schema;
}

1;

