package CAD::Format::STL::part;
$VERSION = v0.2.1;

use warnings;
use strict;
use Carp;

=head1 NAME

CAD::Format::STL::part - guts of the STL object

=head1 SYNOPSIS

See L<CAD::Format::STL>

=cut

use Class::Accessor::Classy;
rw 'name';
lw 'facets';
no  Class::Accessor::Classy;

=head1 Constructor

=head2 new

  my $part = CAD::Format::STL::part->new($name, @facets);

=cut

sub new {
  my $package = shift;
  my ($name, @facets) = @_;

  my $class = ref($package) || $package;
  my $self = {
    name => (defined($name) ? $name : 'CAD::Format::STL part'),
    facets => [],
  };
  bless($self, $class);

  $self->add_facets(@facets) if(@facets);

  return($self);
} # end subroutine new definition
########################################################################

=head2 add_facets

  $self->add_facets(@facets);

Facets are stored with the normal vector, followed by vertices.
Typically, a single facet is a triangle and the normal is [0,0,0]
(meaning that it should be calculated by the user if needed.)

  [0,0,0], [0,0,0],[0,1,0],[1,1,0]

=cut

sub add_facets {
  my $self = shift;
  my (@facets) = @_;

  foreach my $facet (@facets) {
    my @pts = @$facet;
    my $n = ((scalar(@pts) == 3) ? [0,0,0] : shift(@pts));
    $self->SUPER::add_facets([$n, @pts]);
  }
} # end subroutine add_facets definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
