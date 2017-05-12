package CMS::Drupal::Modules::MembershipEntity::Membership;
$CMS::Drupal::Modules::MembershipEntity::Membership::VERSION = '0.96';
# ABSTRACT: Perl interface to a Drupal MembershipEntity membership

use strict;
use warnings;

use Moo;
use Types::Standard qw/ :all /;

has mid       => ( is => 'ro', isa => Int, required => 1 );
has created   => ( is => 'ro', isa => Int, required => 1 );
has changed   => ( is => 'ro', isa => Int, required => 1 );
has uid       => ( is => 'ro', isa => Int, required => 1 );
has status    => ( is => 'ro', isa => Enum[ qw/0 1 2 3/ ], required => 1 );
has member_id => ( is => 'ro', isa => Str, required => 1 );
has type      => ( is => 'ro', isa => Str, required => 1 );
has terms     => ( is => 'ro', isa => HashRef, required => 1 );


sub is_expired {
  my $self = shift;
  $self->{'_is_expired'} = $self->{'status'} eq '0' ? 1 : 0;
  return $self->{'_is_expired'};
}


sub is_active {
  my $self = shift;
  $self->{'_is_active'} = $self->{'status'} eq '1' ? 1 : 0;
  return $self->{'_is_active'};
}


sub is_cancelled {
  my $self = shift;
  $self->{'_is_cancelled'} = $self->{'status'} eq '2' ? 1 : 0;
  return $self->{'_is_cancelled'};
}


sub is_pending {
  my $self = shift;
  $self->{'_is_pending'} = $self->{'status'} eq '3' ? 1 : 0;
  return $self->{'_is_pending'};
}


sub has_renewal {
  my $self = shift;
  $self->{'_has_renewal'} = 0;
  foreach my $term ( values %{ $self->{'terms'} } ) {
    $self->{'_has_renewal'} = 1 if ($term->is_future and $term->is_active);
  }
  return $self->{'_has_renewal'};
}


sub current_was_renewal {
  my $self = shift;
  $self->{'_current_was_renewal'} = 0;
  foreach my $term ( values %{ $self->{'terms'} } ) {
    $self->{'_current_was_renewal'} = 1 if ($term->is_current and $term->was_renewal);
  }
  return $self->{'_current_was_renewal'};
}


1; ## return true to end package MembershipEntity::Membership

__END__

=pod

=encoding UTF-8

=head1 NAME

CMS::Drupal::Modules::MembershipEntity::Membership - Perl interface to a Drupal MembershipEntity membership

=head1 VERSION

version 0.96

=head1 SYNOPSIS

 use CMS::Drupal::Modules::MembershipEntity::Membership;

 $mem = CMS::Drupal::Modules::MembershipEntity::Membership->new(
          'mid'       => '1234',
          'created'   => '1234565432',
          'changed'   => '1234567890',
          'uid'       => '5678',
          'status'    => '1',
          'member_id' => 'my_scheme_0123',
          'type'      => 'my_type',
          'terms'     => \%terms
        );

=head1 METHODS

=head2 is_expired

Returns 1 if the Membership has status of 'expired'. Else returns 0.

=head2 is_active

Returns 1 if the Membership has status of 'active'. Else returns 0.

=head2 is_cancelled

Returns 1 if the Membership has status of 'cancelled'. Else returns 0.

=head2 is_pending

Returns 1 if the Membership has status of 'pending'. Else returns 0.

=head2 has_renewal

Returns 1 if the Membership has a renewal Term that has not yet started. This is defined by the value of $term->is_future and $term->is_active both being true for at least one of the Membership's Terms. Else returns 0.

  print "User $mem->{'uid'} has already renewed" if $mem->has_renewal;

=head2 current_was_renewal

Returns 1 if the current Term belonging to the Membership was a renewal
(i.e. not the Membership's first ever Term). Else returns 0.

=head1 USAGE

Note: This module does not currently create or edit Memberships.

This module is not designed to be called directly, although it can be. This module is called by L<CMS::Drupal::Modules::MembershipEntity|CMS::Drupal::Modules::MembershipEntity>, which has a method to retrieve Memberships and create an object for each of them. Error checking is handled in the latter module, so if you use this module directly you will have to do your own error checking, for example, to make sure that the Membership actually has at least one Term associated with it. (Yes, I know it should be impossible not to, but it happens. This is Drupal we are dealing with.)

=head2 CONSTRUCTOR PARAMETERS

B<All parameters are required.> Consult the Drupal MembershipEntity documentation for more details.

=over 4

=item *

B<mid>

The B<mid> for the Membership. Must be an integer.

=item *

B<created>

The date-and-time the Membership was created. Must be a Unix timestamp.

=item *

B<changed>

The date-and-time the Membership was last changed. Must be a Unix timestamp.

=item *

B<uid>

The Drupal user ID for the owner of the Membership. Must be an integer.

=item *

B<status>

The status of the Membership. Must be an integer from 0 to 3.

=item *

B<member_id>

The unique Member ID that Drupal assigns to the Membership. This is separate from the B<uid> and the B<mid> and can be configured by the Drupal sysadmin to take almost any string-y format.

=item *

B<type>

The Membership type.

=item *

B<terms>

A hashref containing a L<CMS::Drupal::Modules::MembershipEntity::Term|CMS::Drupal::Modules::MembershipEntity::Term> object for each term belonging to the Membership, keyed by the B<tid> (term ID).

=back

=head1 SEE ALSO

=over 4

=item *

L<CMS::Drupal|CMS::Drupal>

=item *

L<CMS::Drupal::Modules::MembershipEntity|CMS::Drupal::Modules::MembershipEntity>

=item *

L<CMS::Drupal::Modules::MembershipEntity::Term|CMS::Drupal::Modules::MembershipEntity::Term>

=back

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
