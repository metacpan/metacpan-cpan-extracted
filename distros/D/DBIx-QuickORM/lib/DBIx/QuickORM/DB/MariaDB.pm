package DBIx::QuickORM::DB::MariaDB;
use strict;
use warnings;

our $VERSION = '0.000001';

use DBD::MariaDB;

use parent 'DBIx::QuickORM::DB::MySQL';
use DBIx::QuickORM::Util::HashBase;

sub sql_spec_keys { qw/mariadb mysql/ }
sub dsn_socket_field { 'mariadb_socket' };

sub insert_returning_supported { 1 }
sub update_returning_supported { 0 }

sub supports_datetime { 'DATETIME(6)' }

sub supports_uuid {
    my $self = shift;
    my ($dbh) = @_;

    return 'UUID' unless $dbh;

    my $ver = $self->db_version($dbh);

    my ($maj, $min) = split /\./, $ver;
    return 'UUID' if $maj > 10 || ($maj == 10 && $min >= 7);

    return ();
}

sub supports_json {
    my $self = shift;
    my ($dbh) = @_;

    return 'JSON' unless $dbh;

    my $ver = $self->db_version($dbh);

    my ($maj, $min) = split /\./, $ver;
    return 'JSON' if $maj > 10 || ($maj == 10 && $min >= 4);

    return ();
}

my %NORMALIZED_TYPES = (
    UUID => 'UUID',
);

sub normalize_sql_type {
    my $self = shift;
    my ($type, %params) = @_;

    $type = uc($type);
    return $NORMALIZED_TYPES{$type} // $self->SUPER::normalize_sql_type(@_);
}

1;
