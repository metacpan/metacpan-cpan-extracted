use strict;
use warnings;

use Test::Exception tests => 1;
use DBIO::Test;
use DBIO::ResultSource::Table;

my $schema = DBIO::Test->init_schema(no_deploy => 1);

my $foo = DBIO::ResultSource::Table->new({ name => "foo" });
my $bar = DBIO::ResultSource::Table->new({ name => "bar" });

lives_ok {
    $schema->register_source(foo => $foo);
    $schema->register_source(bar => $bar);
} 'multiple classless sources can be registered';
