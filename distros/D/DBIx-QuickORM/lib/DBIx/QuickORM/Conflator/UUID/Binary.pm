package DBIx::QuickORM::Conflator::UUID::Binary;
use strict;
use warnings;

our $VERSION = '0.000002';

use parent 'DBIx::QuickORM::Conflator::UUID';
use DBIx::QuickORM::Util::HashBase;

sub _qorm_sql_type {
    my $class = shift;
    my %params = @_;

    my $con = $params{connection};

    return 'BYTEA' if $con->db->isa('DBIx::QuickORM::DB::PostgreSQL');
    return 'BINARY(16)';
}

1;
