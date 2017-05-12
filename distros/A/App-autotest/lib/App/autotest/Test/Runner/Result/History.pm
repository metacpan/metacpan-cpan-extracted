use strict;
use warnings;

package App::autotest::Test::Runner::Result::History;
$App::autotest::Test::Runner::Result::History::VERSION = '0.006';
# ABSTRACT: collects test runner results

use Moose;
use App::autotest::Test::Runner::Result;

has current_result => ( is => 'rw' );
has last_result => ( is => 'rw' );


sub perpetuate {
  my ( $self, $result ) = @_;

  $self->last_result( $self->current_result ) if $self->current_result;
  $self->current_result($result);
}


sub things_just_got_better {
  my ( $self ) = @_;

  # we can't claim 'better' if we have no last result
  return unless $self->last_result;

  my $was_red=$self->last_result->has_failures;
  my $is_green=not $self->current_result->has_failures;

  return $was_red && $is_green;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::autotest::Test::Runner::Result::History - collects test runner results

=head1 VERSION

version 0.006

=head2 perpetuate ($result)

Stores C<$result> as the new current result.
Shifts the former current result to the last result.

=head2 things_just_got_better

Things are better if the last run was red and the current run is green.

=head1 AUTHOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
