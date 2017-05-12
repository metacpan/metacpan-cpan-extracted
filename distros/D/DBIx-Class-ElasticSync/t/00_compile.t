use strict;
use Test::More 0.98;

use_ok $_ for qw(
    DBIx::Class::ElasticSync
    DBIx::Class::ElasticSync::Role::ElasticResult
    DBIx::Class::ElasticSync::Role::ElasticBlackholeResult
    DBIx::Class::ElasticSync::Role::ElasticSchema
    DBIx::Class::ElasticSync::ResultSet
);

done_testing;

