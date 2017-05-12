package CMS::Drupal::Modules::MembershipEntity;
$CMS::Drupal::Modules::MembershipEntity::VERSION = '0.96';
# ABSTRACT: Perl interface to Drupal MembershipEntity entities

use strict;
use warnings;

use Moo;
use Types::Standard qw/ :all /;
use Time::Local;
use Carp qw/ carp croak /;

use CMS::Drupal::Modules::MembershipEntity::Membership;
use CMS::Drupal::Modules::MembershipEntity::Term;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[StrMatch[ qr/ \w+_ /x ]] );

sub fetch_memberships {

  my $self = shift;

  ## We accept a list of mids as an optional parameter
  my @mids = @_;

  my $WHERE = ' ';
 
  if ( @mids ) {
    if ( scalar @mids < 1 ) {
      carp 'Empty array passed to fetch_memberships() ... returning all Memberships';
    }

    if ( ! grep { /all/ } @mids ) {
       # ^ in that case no WHERE clause

      for ( @mids ) {
        # Let's be real strict about what we try to pass in to the DBMS
        croak 'FATAL: Invalid mid (must be all ASCII digits).'
          unless /^[0-9]+$/;
      
        $WHERE = 'WHERE ';
        $WHERE .= "mid = '$_' OR " for @mids;
        $WHERE =~ s/ OR $//;
      }
    }
  }

  my $prefix = ( $self->{'prefix'} || '' );

  my %temp;
  my %memberships;

  ## Get the Membership info
  my $sql = qq|
    SELECT mid, member_id, type, uid, status, created, changed
    FROM ${prefix}membership_entity
    $WHERE
  |;
  
  my $sth = $self->{'dbh'}->prepare( $sql );
  $sth->execute;
  
  my $results = $sth->fetchall_hashref('mid');
  foreach my $mid (keys( %{ $results } )) {
    $temp{ $mid } = $results->{ $mid };
  }
  
  ## Get the Membership Term info
  #  Use the $WHERE clause from the optional mids parameter
  my $sql2 = qq|
    SELECT id as tid, mid, status, term, modifiers, start, end
    FROM ${prefix}membership_entity_term
    $WHERE
    ORDER BY start
  |;
  
  my $sth2 = $self->{'dbh'}->prepare( $sql2 );
  $sth2->execute;

  my %term_count; # used to track array position of Terms

  while( my $row = $sth2->fetchrow_hashref ) {
    
    ## Shouldn't be, but is, possible to have a Term with no
    ## start or end date
    if ( not defined $row->{'start'} or not defined $row->{'end'} ) {
      carp "MISSING DATE: tid[ $row->{'tid'} ] " .
           "(uid[ $temp{ $row->{'mid'} }->{'uid'} ]) has no start " .
           "or end date defined. Skipping ...";
      next;
    }

    ## Shouldn't be, but is, possible to have a Term with no
    ## corresponding Memberships
    if ( not defined $temp{ $row->{'mid'} } ) {
      carp "TERM WITH NO MEMBERSHIP: tid[ $row->{'tid'} ] " .
           "has no corresponding Membership. Skipping ...";
      next;
    }

    ## convert the start and end to unixtime
    for (qw/ start end /) {
      my @datetime = reverse ( split /[-| |:]/, $row->{ $_ } );
      $datetime[4]--;
      $row->{ $_ } = timelocal( @datetime );
    } 

    ## Track which of the Membership's Terms this is
    $term_count{ $row->{'mid'} }++;
    $row->{'array_position'} = $term_count{ $row->{'mid'} };
    
    ## Instantiate a MembershipEntity::Term object for each
    ## Term now that we have the data
    my $term = CMS::Drupal::Modules::MembershipEntity::Term->new( $row );
    $temp{ $row->{'mid'} }->{'terms'}->{ $row->{'tid'} } = $term;
  }

  ## Instantiate a MembershipEntity::Membership object for each
  ## Membership now that we have the data
  foreach my $mid(keys( %temp )) {
    
    ## Shouldn't be, but is, possible to have a Membership with no Term
    if (not defined $temp{ $mid }->{'terms'}) {
      carp "MISSING TERM: mid[ $mid ] (uid[ $temp{ $mid }->{'uid'} ]) " .
           "has no Membership Terms. Skipping ...";
      next;
    }

    $memberships{ $mid } =
    CMS::Drupal::Modules::MembershipEntity::Membership->new( $temp{ $mid } );
  }
  
  $self->{'_memberships'} = \%memberships;

  return (scalar keys %memberships == 1) ?
       @memberships{ keys %memberships } :
                            \%memberships;
}

1; ## return true to end package CMS::Drupal::Modules::MembershipEntity

__END__

=pod

=encoding UTF-8

=head1 NAME

CMS::Drupal::Modules::MembershipEntity - Perl interface to Drupal MembershipEntity entities

=head1 VERSION

version 0.96

=head1 SYNOPSIS

  use CMS::Drupal::Modules::MembershipEntity;

  my $ME = CMS::Drupal::Modules::MembershipEntity->new( { dbh => $dbh } );

  my $href = $ME->fetch_memberships( 'all' );

  # or:
  my $href = $ME->fetch_memberships( @list );

  foreach my $mid ( sort keys %{ $hashref } ) {
    my $mem = $hashref->{ $mid };
   
    print $mem->type;
    send_newsletter( $mem->uid ) if $mem->active;
   
    # etc ...
  }

Or, for a single Membership:

   my $mem = $ME->fetch_memberships( 123 );

   print $mem->type;
   send_newsletter( $mem->uid ) if $mem->active;
        
   # etc ...

=head1 METHODS

=head2 fetch_memberships

This method returns either a hashref containing Membership objects indexed by
B<mid>, or a single Membership object (if it was called with a single B<mid>).

When called with the argument 'all', the hashref contains all Memberships in 
the Drupal database, which might be too much for your memory if you have 
lots of them.

When called with an array containing B<mid>s, the hashref will contain an 
object for each mid in the array.

When called with a single B<mid>, the method will return a single object
(no hashref).

  # Fetch a single Membership
  my $mem = $ME->fetch_memberships( 1234 ); 

  # Fetch a set of Memberships
  my $hashref = $ME->fetch_memberships( 1234, 5678 );

  # Fetch a set of Memberships using a list you prepared elsewhere
  my $hashref = $ME->fetch_memberships( @list );

  # Fetch all your Memberships
  my $hashref = $ME->fetch_memberships('all');

  # Same thing but with a warning
  my $hashref = $ME->fetch_memberships();

IMPORTANT: If you have bad records in your Drupal database, the module will
print a warning and skip the record. This happens when there are no Terms
belonging to the Membership, or when the Term is missing a start date or end
date. You should immediately normalize your data! This issue will also
cause installation testing to fail if you have configured your environment
to test against your real Drupal database.

=head1 USAGE

This package provides easy access to Perl objects representing Membership
Entity memberships and their terms. Rather than creating those objects
directly, you should allow this module to do so.

For each Membership that you want, you can fetch a Membership object, which
contains at least one Term object, so you have access to all the methods
you can use on your Membership and its Terms.

For this reason the methods actually provided by the submodules are documented
here.

=head2 Memberships

This module uses CMS::Drupal::Modules::MembershipEntity::Membership so you
don't have to. The methods shown below are actually in the latter 
module where they are documented completely.

=head3 Attributes

You can directly access all the Membership's attributes as follows:

  $mem->attr_name

Where attr_name is one of:

  mid           
  member_id
  type
  uid
  status
  created
  changed

There is also another attribute 'terms', which contains a hashref of Term
objects, indexed by B<tid>. Each Term can be accessed by the methods described
in the Membership Terms section below.

=head3 Membership methods

Once you have the Membership object, you can call some methods on it:

  print 'User ' . $mem->uid . ' is in good standing' if $mem->is_active;
  print $mem->mid . ' has already renewed' if $mem->has_renewal;

Methods are:

=over 4

=item *

is_active()

=item *

is_expired()

=item *

is_cancelled()

=item *

is_pending()

=item *

has_renewal()

=item *

current_was_renewal()

=back

=head2 Membership Terms

This module uses CMS::Drupal::Modules::MembershipEntity::Term so you
don't have to. The methods described below are actually in the latter
module where they are documented compeletely.

  while ( my ($tid, $term) = each %{ $mem->{'terms'} } ) {
    # do something ...
  }

=head3 Attributes

You can directly access all the Term's attributes as follows:

  $term->attr_name;

Where attr_name is one of:

  tid
  mid
  status
  term
  modifiers
  start
  end

There is also another attribute, 'array_position', which is used to determine if
the Term is a renewal, etc.

=head3 Membership Term methods

  print 'This is a live one' if $term->is_current;
  push @renewals, $term->tid if $term->was_renewal;

Methods are:

=over 4

=item *

is_active()

=item *

is_current()

=item *

is_future()

=item *

was_renewal()

=back

=head1 SEE ALSO

=over 4

=item *

L<CMS::Drupal::Modules::MembershipEntity::Membership|CMS::Drupal::Modules::MembershipEntity::Membership>

=item *

L<CMS::Drupal::Modules::MembershipEntity::Term|CMS::Drupal::Modules::MembershipEntity::Term>

=item *

L<CMS::Drupal|CMS::Drupal>

=back

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
