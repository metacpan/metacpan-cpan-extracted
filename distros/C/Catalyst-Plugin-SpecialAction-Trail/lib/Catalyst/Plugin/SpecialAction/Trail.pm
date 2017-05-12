package Catalyst::Plugin::SpecialAction::Trail;

use 5.008;

use Moose::Role;
use namespace::autoclean;

use Moose::Util qw/ ensure_all_roles /;

=head1 NAME

Catalyst::Plugin::SpecialAction::Trail - Support for the 'trail' special action

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  # enabling the 'trail' special action in a single controller:

  package MyApp::Controller::Foo;

  use Moose;
  use namespace::autoclean;

  extends 'Catalyst::Controller';

  with 'Catalyst::TraitFor::Controller::SpecialAction::Trail';

  sub trail : Private {
    my ($self, $c, @args) = (shift, shift, @_);

    ...
  }

  # globally enabling the 'trail' special action:

  package MyApp;

  use Moose;
  use namespace::autoclean;

  extends 'Catalyst';

  __PACKAGE__->setup(qw/ SpecialAction::Trail /);

  # now you can use 'trail' in any controller in your app

=head1 DISCLAIMER

This is ALPHA SOFTWARE. Use at your own risk. Features may change.

=head1 DESCRIPTION

This module introduces a new special action C<trail> that unites the features
of C<end> and C<auto> special actions (see L<Catalyst::Manual::Intro/"Built-in
special actions">):

=over

=item *

Like C<end>, the C<trail> actions will be run at the end of the request, after
all URL-matching actions are called; but they are called before any C<end> is
run.

=item *

Like C<auto>, multiple C<trail> actions will be run in turn, starting with the
application class and going through to the most specific controller class, and
the processing chain stops if any of them returns false (any remaining C<trail>
actions are skipped and the control goes to C<end> if there's any).

=back

=head1 METHODS

=cut

=head2 setup_component

Overridden (with an 'around' method modifier) from L<Catalyst/setup_component>.
Applies the L<Catalyst::TraitFor::Controller::SpecialAction::Trail> role to
the C<Catalyst::Controller> instance.

=cut

around setup_component => sub {
  my ($orig, $class) = (shift, shift, @_);

  my $component = $class->$orig(@_);

  if ($component->isa('Catalyst::Controller')) {
    ensure_all_roles($component,
      'Catalyst::TraitFor::Controller::SpecialAction::Trail');
  }

  return $component;
};


=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Manual::Intro>.

=head1 AUTHOR

Norbert Buchmuller, C<< <norbi at nix.hu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-specialaction-trail at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-SpecialAction-Trail>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::SpecialAction::Trail

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-SpecialAction-Trail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-SpecialAction-Trail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-SpecialAction-Trail>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-SpecialAction-Trail/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Norbert Buchmuller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::SpecialAction::Trail
