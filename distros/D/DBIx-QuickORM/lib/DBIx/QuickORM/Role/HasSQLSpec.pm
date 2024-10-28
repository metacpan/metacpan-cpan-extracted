package DBIx::QuickORM::Role::HasSQLSpec;
use strict;
use warnings;

our $VERSION = '0.000004';

use Scalar::Util();
use DBIx::QuickORM::SQLSpec();
use Class::Method::Modifiers();

sub SQL_SPEC { 'sql_spec' }

use Role::Tiny;

sub sql_spec { return $_[0]->{+SQL_SPEC} }

after init => sub {
    my $self = shift;
    $self->{+SQL_SPEC} //= DBIx::QuickORM::SQLSpec->new;
    $self->{+SQL_SPEC} = DBIx::QuickORM::SQLSpec->new($self->{+SQL_SPEC}) unless Scalar::Util::blessed($self->{+SQL_SPEC});
};

1;
