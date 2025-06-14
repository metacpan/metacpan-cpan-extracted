package DBIx::QuickORM::Dialect::MySQL::Community;
use strict;
use warnings;

our $VERSION = '0.000015';

use Carp qw/croak/;

use parent 'DBIx::QuickORM::Dialect::MySQL';
use DBIx::QuickORM::Util::HashBase;

sub dialect_name { 'MySQL::Community' }

sub init {
    my $self = shift;

    $self->SUPER::init();

    my $vendor = $self->db_vendor;
    die "The mysql vendor is '$vendor' not Community" if $vendor && $vendor !~ m/Community/i;
}

1;
