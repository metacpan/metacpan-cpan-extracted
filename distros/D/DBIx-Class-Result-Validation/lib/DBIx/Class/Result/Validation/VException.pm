package DBIx::Class::Result::Validation::VException;

use strict;
use warnings;
use Moose;
use overload '""' => sub {
    shift->message;
  },
  fallback => 1;

=head1 NAME

DBIx::Class::Result::Validation::VException - Exception for Validation

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

DBIx::Class::Result::Validation::VException.

croak( DBIx::Class::Result::Validation::VException->new( message => "my message", object => $object);

=cut

has object => (
    is  => 'rw',
    isa => 'DBIx::Class::Row',

    #    required => 0,
);

has message => (
    is  => 'rw',
    isa => 'Str',

    #    required => 0,
);

no Moose;

1;
