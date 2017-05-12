package Coteng::QueryBuilder;
use strict;
use warnings;
use parent qw(SQL::Maker);

__PACKAGE__->load_plugin('InsertMulti');

1;
