package App::ppll::Worker;     ## no critic [NamingConventions::Capitalization]

=encoding utf8

=head1 NAME

App::ppll::Worker

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use IPC::Run qw( harness new_chunker );

use experimental qw( signatures );
use overload '""' => 'str';

=head1 SUBROUTINES/METHODS

=head2 new

Constructor.

Named parameters:

=over

=item argv

=item prefix

=back

=cut

sub new ( $class, %self ) {
  my @harness_args = ( $self{argv} );

  push @harness_args, ( '>', new_chunker, $self{out} )
    if $self{out};

  push @harness_args, ( '2>', new_chunker, $self{err} )
    if $self{err};

  $self{harness} = harness( @harness_args );

  return bless \%self, $class;
}

=head2 result

=cut

sub result( $self ) {
  if ( $self->{harness}->pumpable ) {
    $self->{harness}->pump_nb;
    return;
  }

  $self->{harness}->finish;
  $self->{finished} = 1;
  my $result = $self->{harness}->result;

  return $result;
}

=head2 start

=cut

sub start( $self ) {
  $self->{harness}->start;
  return;
}

=head2 stop

=cut

sub stop( $self ) {
  $self->{harness}->kill_kill;
  $self->{harness}->finish;
  $self->{finished} = 1;
  return;
}

=head2 str

=cut

sub str ( $self, @ ) {
  return $self->{parameter};
}

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Theo Willows.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
