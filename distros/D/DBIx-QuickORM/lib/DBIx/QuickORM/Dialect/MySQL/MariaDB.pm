package DBIx::QuickORM::Dialect::MySQL::MariaDB;
use strict;
use warnings;

our $VERSION = '0.000013';

use Carp qw/croak/;

use parent 'DBIx::QuickORM::Dialect::MySQL';
use DBIx::QuickORM::Util::HashBase;

sub dialect_name { 'MySQL::MariaDB' }

sub supports_returning_update { 0 }
sub supports_returning_insert { 1 }
sub supports_returning_delete { 1 }

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $vendor = $self->db_vendor;
    die "The mysql vendor is '$vendor' not MariaDB" if $vendor && $vendor !~ m/MariaDB/i;
}

1;
