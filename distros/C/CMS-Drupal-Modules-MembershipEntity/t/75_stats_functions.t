#! perl
use strict;
use warnings;

use Test::More tests => 6;
use Test::Group;
use Time::Local;

use lib '/Users/nick/dev/perl_dev/CMS-Drupal-Modules-MembershipEntity/lib';

use CMS::Drupal;
use CMS::Drupal::Modules::MembershipEntity;
use CMS::Drupal::Modules::MembershipEntity::Test;

use CMS::Drupal::Modules::MembershipEntity::Stats { into => 'CMS::Drupal::Modules::MembershipEntity' };

my $drupal = CMS::Drupal->new;

my $dbh    = ( exists $ENV{'DRUPAL_TEST_CREDS'}) ?
               $drupal->dbh :
               build_test_db( $drupal );

my $ME     = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );

$ME->fetch_memberships('all');

my %data;

$data{'count_total_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity});

$data{'count_expired_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity WHERE status = '0'});

$data{'count_active_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity WHERE status = '1'});

$data{'count_cancelled_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity WHERE status = '2'});

$data{'count_pending_memberships'} =
  $dbh->selectrow_array(q{SELECT COUNT(mid) FROM membership_entity WHERE status = '3'});

$data{'count_set_were_renewal_memberships'} = count_were_renewals_from_db();

sub count_were_renewals_from_db {

  ## Wow, this seems complicated. Gather data to compare results

  ## First limit to current terms only 
  my $sql = qq/
    SELECT mid, id AS tid, start, end
    FROM membership_entity_term
  /;

  my $terms = $dbh->selectall_hashref( $sql, 'tid' );

  my $now = time();

  my %current_mids;
  my %current_tids;
  my %ordered_terms;

  foreach my $term ( values %{ $terms } ) {
    for (qw/ start end /) {
      my @datetime = reverse ( split /[-| |:]/, $term->{ $_ } );
     $datetime[4]--;
     $term->{ $_ } = timelocal( @datetime );
    }

    # indexed by mid, but terms indexed by start time for easier sorting
    $ordered_terms{ $term->{'mid'} }->{ $term->{'start'} } = $term->{'tid'};

    next unless $term->{'start'} <= $now and $term->{'end'} > $now;
   
    $current_mids{ $term->{'mid'} }++;
    $current_tids{ $term->{'tid'} }++;

  } 

  # Now process each mid we have
  foreach my $mid ( keys %ordered_terms ) {
    # only keep it if it has a current term, i.e. is active
    if ( ! exists $current_mids{ $mid } ) {
      delete $ordered_terms{ $mid };
      next;
    }
    
    # only keep it if it has at least two terms
    if ( scalar keys %{ $ordered_terms{ $mid } } < 2 ) {
      delete $ordered_terms{ $mid };
      next;
    }
  }

  # if the mem is still here, it has a current term and more than one term.
  # shift the earliest one off; the rest are renewals; is one of them current? 
  my %were_renewal_memberships;

  foreach my $mid ( keys %ordered_terms ) {
    my $term_count = 0;
    foreach my $start (sort keys %{ $ordered_terms{ $mid } } ) {
      $term_count++;
      next if $term_count == 1;
      if ( exists $current_tids{ $ordered_terms{ $mid }->{ $start } } ) {
        $were_renewal_memberships{ $mid } = 1;
      }
    }
  }

  return scalar keys %were_renewal_memberships;

} # end sub 

#######################

is( $ME->count_total_memberships,
    $data{'count_total_memberships'},
    'Count all memberships' );

is( $ME->count_expired_memberships,
    $data{'count_expired_memberships'},
    'Count expired memberships' );

is( $ME->count_active_memberships,
    $data{'count_active_memberships'},
    'Count active memberships' );

is( $ME->count_cancelled_memberships,
    $data{'count_cancelled_memberships'},
    'Count cancelled memberships' );

is( $ME->count_pending_memberships,
    $data{'count_pending_memberships'},
    'Count pending memberships' );

is( $ME->count_set_were_renewal_memberships,
    $data{'count_set_were_renewal_memberships'},
    'Count "were renewal" memberships' );

__END__

