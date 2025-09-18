#!/usr/bin/env perl

package App::CloudTrail;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use JSON;

use Role::Tiny::With;
with 'App::AWS';

use parent qw(App::Command);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(profile region));

########################################################################
sub lookup_events {
########################################################################
  my ( $self, %args ) = @_;

  my ( $attributes, $start_time, $end_time ) = @args{qw(attributes start_time end_time)};

  my $result = $self->command(
    'lookup-events' => [
      '--lookup-attributes' => $self->format_attributes($attributes),
      $start_time ? ( '--start-time' => $start_time ) : (),
      $end_time   ? ( '--end-time'   => $end_time )   : (),
    ]
  );

  $self->check_result( message => 'ERROR: unable to lookup events' );

  foreach ( @{ $result->{Events} } ) {
    $_->{CloudTrailEvent} = from_json( $_->{CloudTrailEvent} );
  }

  return $result->{Events};
}

########################################################################
sub format_attributes {
########################################################################
  my ( $self, $events ) = @_;

  return map { sprintf 'AttributeKey=%s,AttributeValue=%s', $_, $events->{$_} } keys %{$events};
}

1;
