package DBIx::QuickORM::Dialect::MySQL::Percona;
use strict;
use warnings;

our $VERSION = '0.000019';

use Carp qw/croak/;

use parent 'DBIx::QuickORM::Dialect::MySQL';
use DBIx::QuickORM::Util::HashBase;

sub dialect_name { 'MySQL::Percona' }

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $vendor = $self->db_vendor;
    die "The mysql vendor is '$vendor' not Percona" if $vendor && $vendor !~ m/Percona/i;
}

1;
