package TestAppC3Fail::Model::DB;
use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'TestAppC3Fail::Schema::DB',
    connect_info => [ 'DBI:SQLite:dbname=foo', '', '' ],
);

1;
