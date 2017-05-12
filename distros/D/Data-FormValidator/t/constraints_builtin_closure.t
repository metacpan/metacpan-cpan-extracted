#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::FormValidator;
use Data::FormValidator::Constraints qw(:closures);

my $input_profile = {
  required           => [qw( number_field nan nan_typo )],
  optional           => [qw( nan_name_this )],
  constraint_methods => {
    number_field => sub {
      my ( $self, $v ) = @_;

      #$self->set_current_constraint_name('number');
      return ( $v =~ m/^\d+$/ );
    },
    nan => sub {
      my ( $self, $v ) = @_;
      $self->name_this('number');
      return ( $v =~ m/^\d+$/ );
    },
    nan_typo => sub {
      my ( $self, $v ) = @_;
      $self->name_this('numer');
      return ( $v =~ m/^\d+$/ );
    },
    nan_name_this => sub {
      my ( $d, $v ) = @_;
      $d->name_this('number');
      return ( $v =~ m/^\d+$/ );
    },

  },
  msgs => {
    constraints => {
      number => 'Must be a digit',
    } } };

my $input_hashref = {
  number_field  => 0,
  nan           => 'infinity',
  nan_name_this => 'infinity',
};

my $results;
eval {
  $results = Data::FormValidator->check( $input_hashref, $input_profile );
};
is( $@, '', 'survived eval' );
is( $results->valid()->{number_field},
  0, 'using 0 in a constraint regexp works' );
my $msgs = $results->msgs();
like( $msgs->{nan}, qr/Must be a digit/,
  'set_current_contraint_name succeeds' );
like( $msgs->{nan_name_this}, qr/Must be a digit/, 'name_this succeeds' );

unlike(
  $msgs->{nan_typo},
  qr/Must be a digit/,
  'set_current_contraint_name doesn\'t work if you typo it'
);

done_testing();
