# -*- perl -*-

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan tests => 3;

pod_coverage_ok(
     'DBIx::Class::InflateColumn::Serializer::Storable',
);

pod_coverage_ok(
     'DBIx::Class::InflateColumn::Serializer::JSON',
);

pod_coverage_ok(
     'DBIx::Class::InflateColumn::Serializer::YAML',
);


