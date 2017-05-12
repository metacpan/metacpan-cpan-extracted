package Catalyst::TraitFor::Controller::SpecialAction::Trail;

use 5.008;

use Moose::Role;
use namespace::autoclean;

=head1 NAME

Catalyst::TraitFor::Controller::SpecialAction::Trail - Support for the 'trail' special action

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

See L<Catalyst::Plugin::SpecialAction::Trail>.

=head1 METHODS

=cut

=head2 _END

Overridden (with a 'before' method modifier) from L<Catalyst::Controller/_END>.
Calls the C<trail> actions in turn.

=cut

before _END => sub {
  my ($self, $c) = @_;

  my @trail = $c->get_actions( 'trail', $c->namespace );
  foreach my $trail (@trail) {
    $trail->dispatch( $c );
    return 0 unless $c->state;
  }
  return 1;
};

=head1 AUTHOR

Norbert Buchmuller, C<< <norbi at nix.hu> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Norbert Buchmuller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::TraitFor::Controller::SpecialAction::Trail
