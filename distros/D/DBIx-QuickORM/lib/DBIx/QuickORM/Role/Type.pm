package DBIx::QuickORM::Role::Type;
use strict;
use warnings;

our $VERSION = '0.000015';

use Carp qw/croak/;

use Role::Tiny;

requires qw{
    qorm_inflate
    qorm_deflate
    qorm_compare
    qorm_affinity
    qorm_sql_type
};

sub qorm_register_type {
    my $this = shift;
    my $class = ref($this) || $this;
    croak "'$class' does not implement qorm_register_type() and cannot be used with autotype()";
}

1;
