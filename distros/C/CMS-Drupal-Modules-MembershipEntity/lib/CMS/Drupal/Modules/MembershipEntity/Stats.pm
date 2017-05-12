package CMS::Drupal::Modules::MembershipEntity::Stats;
$CMS::Drupal::Modules::MembershipEntity::Stats::VERSION = '0.96';
# ABSTRACT: Generate statistics about MembershipEntity memberships on a Drupal site. 

use strict;
use warnings;

use Moo;
use Types::Standard qw/ :all /;
use base 'Exporter::Tiny'; 
our @EXPORT = qw/
  count_total_memberships
  count_expired_memberships
  count_active_memberships
  count_cancelled_memberships
  count_pending_memberships
  count_set_were_renewal_memberships
  count_daily_were_renewal_memberships
  count_daily_total_memberships
  count_daily_term_expirations
  count_daily_term_activations
  count_daily_new_memberships
  count_daily_new_terms
  count_daily_renewals
  count_daily_active_memberships
  build_date_range
  time_plus_one_day
  datetime_plus_one_day
  report_yesterday
/;

use Time::Local;
use DateTime::Event::Recurrence;

use CMS::Drupal::Modules::MembershipEntity::Membership;

use Carp qw/ carp croak /;

has dbh    => ( is => 'ro', isa => InstanceOf['DBI::db'], required => 1 );
has prefix => ( is => 'ro', isa => Maybe[Str] );


sub count_total_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    $self->{'stats'}->{'_count_total_memberships'} = scalar keys %{ $self->{'_memberships'} };
  } else {
    my $sql = q{ SELECT COUNT(mid) FROM membership_entity };
    $self->{'stats'}->{'_count_total_memberships'} = $self->{'dbh'}->selectrow_array( $sql );
  }
  return $self->{'stats'}->{'_count_total_memberships'};
}


sub count_expired_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    my $count = 0;
    while ( my ($mid, $mem) = each %{ $self->{'_memberships'} } ) {
      $count++ if $mem->is_expired;
    }
    $self->{'_count_expired_memberships'} = $count;
  } else {
    my $sql = q{ select count(mid) from membership_entity where status = 0 };
    $self->{'_count_expired_memberships'} = $self->{'dbh'}->selectrow_array( $sql );
  }
  return $self->{'_count_expired_memberships'};
}


sub count_active_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    my $count = 0;
    while ( my ($mid, $mem) = each %{ $self->{'_memberships'} } ) {
      $count++ if $mem->is_active;
    }
    $self->{'_count_active_memberships'} = $count;
  } else {
    my $sql = q{ SELECT COUNT(mid) FROM membership_entity WHERE status = 1 };
    $self->{'_count_active_memberships'} = $self->{'dbh'}->selectrow_array( $sql );
  }
  return $self->{'_count_active_memberships'};
}


sub count_cancelled_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    my $count = 0;
    while ( my ($mid, $mem) = each %{ $self->{'_memberships'} } ) {
      $count++ if $mem->is_cancelled;
    }
    $self->{'_count_cancelled_memberships'} = $count;
  } else {
    my $sql = q{ SELECT COUNT(mid) FROM membership_entity WHERE status = 2 };
    $self->{'_count_cancelled_memberships'} = $self->{'dbh'}->selectrow_array( $sql );
  }
  return $self->{'_count_cancelled_memberships'};
}


sub count_pending_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    my $count = 0;
    while ( my ($mid, $mem) = each %{ $self->{'_memberships'} } ) {
      $count++ if $mem->is_pending;
    }
    $self->{'_count_pending_memberships'} = $count;
  } else {
    my $sql = q{ select count(mid) from membership_entity where status = 3 };
    $self->{'_count_pending_memberships'} = $self->{'dbh'}->selectrow_array( $sql );
  }
  return $self->{'_count_pending_memberships'};
}


sub count_set_were_renewal_memberships {
  my $self = shift;
  if ($self->{'_memberships'}) {
    $self->{'_count_were_renewal_memberships'} = 0;
    while ( my ($mid, $mem) = each %{ $self->{'_memberships'} } ) {
      if ( $mem->current_was_renewal ) {
        $self->{'_count_were_renewal_memberships'}++;
      }
    }
  } else {
    croak qq/
      Died.
      count_were_renewal_memberships() must be called with a set of
      Memberships. You probably forgot to call fetch_memberships()
      on your MembershipEntity object before calling this method.
    /;
  }
  return $self->{'_count_were_renewal_memberships'};
}


sub count_daily_were_renewal_memberships {
  my $self = shift;
  my @dates = @_;
  my %counts;

  carp qq/
    Warning!
    Called a count_daily_ method with no dates. This will return nothing!
  / if ! @dates;

  ## First get all the terms 
  my $sql = qq/ 
    SELECT mid, id AS tid, start, end
    FROM membership_entity_term
  /;

  my %current_mids;
  my %current_tids;
  my %ordered_terms;

  ## get all the terms from the DB
  my $terms = $self->{'dbh'}->selectall_hashref( $sql, 'tid' );
  
  foreach my $term ( values %{ $terms } ) { 
    # indexed by mid, but terms indexed by start time for easier sorting
    $ordered_terms{ $term->{'mid'} }->{ $term->{'start'} } = $term->{'tid'};
  }

  ## loop through the dates
  foreach my $datetime ( @dates ) {

    ## find the ones that were current on the date
    foreach my $term ( values %{ $terms } ) {
      next unless $datetime gt $term->{'start'} and $term->{'end'} gt $datetime;
   
      $current_mids{ $term->{'mid'} }++;
      $current_tids{ $term->{'tid'} }++;
    }   

    # Now process each mid
    foreach my $mid ( keys %ordered_terms ) { 
      
      # only keep it if it had a current term, i.e. was active
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

    $counts{ $datetime } = scalar keys %were_renewal_memberships;
  }

  return (scalar keys %counts == 1) ?
               $counts{ $dates[0] } :
               \%counts;

} # end sub 


sub count_daily_term_expirations {
  my $self = shift;
  my @dates = @_;
  my %counts;

  carp qq/ 
    Warning!
    Called a count_daily_ method with no dates. This will return nothing!
  / if ! @dates;

  my $sql = qq/
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity_term
    WHERE end >= ?
    AND end < ?
    AND status NOT IN (2,3)
  /;
  
  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {
    $sth->execute( $datetime, $self->datetime_plus_one_day( $datetime ) );
    $counts{ $datetime } = $sth->fetchrow_array;
  }

  return (scalar keys %counts == 1) ?
               $counts{ $dates[0] } :
               \%counts;
  
} # end sub


sub count_daily_term_activations {
  my $self = shift;
  my @dates = @_; 
  my %counts;

  carp qq/ 
    Warning!
    Called a count_daily_ method with no dates. This will return nothing!
  / if ! @dates;

  my $sql = qq/ 
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity_term
    WHERE start >= ?
    AND start < ?
    AND status NOT IN (2,3)
  /;
  
  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {
    $sth->execute( $datetime, $self->datetime_plus_one_day( $datetime ) );
    $counts{ $datetime } = $sth->fetchrow_array;
  }   

  return (scalar keys %counts == 1) ?
              $counts{ $dates[0] } : 
              \%counts;
  
} # end sub


sub count_daily_new_memberships {
  my $self = shift;
  my @dates = @_;
  my %counts;

  carp qq/ 
    Warning!
    Called a count_daily_ method with no dates. This will return nothing!
  / if ! @dates;

  my $sql = qq/ 
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity
    WHERE created >= ?
    AND created < ?
    AND status NOT IN (3)
  /;

  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {
    my ( $start, $over ) = $self->time_plus_one_day( $datetime );
    $sth->execute( $start, $over );
    $counts{ $datetime } = $sth->fetchrow_array;
  }

  return (scalar keys %counts == 1) ?
              $counts{ $dates[0] } :
              \%counts;

} # end sub


sub count_daily_new_terms {
  my $self = shift;
  my @dates = @_;
  my %counts;

  carp qq/ 
    Warning!
    Called a count_daily_ method with no dates. This will return nothing!
  / if ! @dates;

  my $sql = qq/ 
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity_term
    WHERE created >= ?
    AND created < ?
    AND status NOT IN (3)
  /;

  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {
    my ( $start, $over ) = $self->time_plus_one_day( $datetime );
    $sth->execute( $start, $over );
    $counts{ $datetime } = $sth->fetchrow_array;
  }

  return (scalar keys %counts == 1) ?
              $counts{ $dates[0] } :
              \%counts;

} # end sub



sub count_daily_renewals {
  my $self = shift;
  my @dates = @_;
  my %counts;

  carp qq/ 
    Warning!
    Called a count_daily_ method with no dates. This will return nothing!
  / if ! @dates;

  my $sql1 = qq/ 
    SELECT id, mid
    FROM membership_entity_term
    WHERE created >= ?
    AND created < ?
    AND status NOT IN (3)
  /;

  my $sth1 = $self->{'dbh'}->prepare( $sql1 );

  my $sql2 = qq/
    SELECT id
    FROM membership_entity_term
    WHERE mid = ?
  /;

  my $sth2 = $self->{'dbh'}->prepare( $sql2 );

  foreach my $datetime (@dates) {
    $counts{ $datetime } = 0;
    my ( $start, $over ) = $self->time_plus_one_day( $datetime );
    $sth1->execute( $start, $over );
    while ( my ($id, $mid) = $sth1->fetchrow_array ) {
      my $was_renewal = 0;
      $sth2->execute( $mid );
      for ( $sth2->fetchrow_array ) {
        $was_renewal = 1 if $_ < $id;
      }
      $counts{ $datetime } += $was_renewal;
    }
  }

  return (scalar keys %counts == 1) ?
            $counts{ $dates[0] } :
            \%counts;

} # end sub


sub count_daily_active_memberships {
  my $self = shift;
  my @dates = @_;
  my %counts;

  carp qq/ 
    Warning!
    Called a count_daily_ method with no dates. This will return nothing!
  / if ! @dates;

  my $sql = qq/
    SELECT COUNT(DISTINCT mid)
    FROM membership_entity_term
    WHERE start <= ? AND end > ?
    AND status NOT IN (2,3)
  /;

  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $date (@dates) {
    $sth->execute( $date, $date );
    $counts{ $date } = $sth->fetchrow_array;
  }

  return (scalar keys %counts == 1) ?
           $counts{ $dates[0] } :
           \%counts;

} # end sub


sub count_daily_total_memberships {
  my $self = shift;
  my @dates = @_;
  my %counts;

  carp qq/ 
    Warning!
    Called a count_daily_ method with no dates. This will return nothing!
  / if ! @dates;

  my $sql = qq/ 
    SELECT COUNT(mid)
    FROM membership_entity
    WHERE created <= ?
    AND status NOT IN (3)
  /;

  my $sth = $self->{'dbh'}->prepare( $sql );

  foreach my $datetime (@dates) {
    my ( $start, $over ) = $self->time_plus_one_day( $datetime );
    $sth->execute( $over );
    $counts{ $datetime } = $sth->fetchrow_array;
  }

  return (scalar keys %counts == 1) ?
              $counts{ $dates[0] } :
              \%counts;

} # end sub


##################################################
##
## Utility subs
##



sub build_date_range {

  my $self      = shift;
  my $opt_start = shift;
  my $opt_end   = shift;

  my $dt_start;
  if ( ! $opt_start or $opt_start !~ m/[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
    croak qq/
      Died.
      build_date_range() requires a beginning date in format 'YYYY-MM-DD'.
    /;
  } else {
    my ($y,$m,$d) = split( '-', $opt_start);
    $dt_start = DateTime->new( year => $y, month => $m, day => $d );
  }
  $dt_start->set_time_zone('UTC');
  
  my $dt_end;
  if ( $opt_end ) {
    if ( $opt_end !~ m/[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
      croak qq/ 
        Died.
        build_date_range() requires that the end date,
        if supplied, be in the format 'YYYY-MM-DD'.
      /; 
    } else {
      my ($y,$m,$d) = split( '-', $opt_end);
      $dt_end = DateTime->new( year => $y, month => $m, day => $d );
    }
  } else {
    # default to today;
    $dt_end = DateTime->now;
    $dt_end->set_hour('00');
    $dt_end->set_minute('00');
    $dt_end->set_second('00');
  }
  $dt_end->set_time_zone('UTC');

  my $set = DateTime::Event::Recurrence->daily();
  my $itr = $set->iterator( start => $dt_start, end => $dt_end );
 
  my @dates;

  while ( my $dt = $itr->next ) {
    push @dates, $dt->datetime;
  }

  return \@dates;

} # end sub


sub datetime_plus_one_day {
  my $self = shift;
  my $datetime = shift;

  if ( ! $datetime or $datetime !~ m/[0-9]{4}-[0-9]{2}-[0-9]{2}/ ) {
    croak qq/
      Died.
      datetime_plus_one() requires a datetime
      in ISO-ish format (YYYY-MM-DDTHH:MM:SS).
    /;
  }

  my ($y, $m, $d) = split /[-| |T|:]/, $datetime;
  return DateTime->new( year => $y, month => $m, day => $d )
                   ->set_time_zone( 'UTC' )
                     ->clone()
                       ->add( days => 1 )
                         ->datetime();

} # end sub



sub time_plus_one_day {
  my $self = shift;
  my $datetime = shift;

  if ( ! $datetime or $datetime !~ m/[0-9]{4}-[0-9]{2}-[0-9]{2}/ ) {
    croak qq/
      Died.
      time_plus_one() requires a datetime in
      ISO-ish format (YYYY-MM-DDTHH:MM:SS).
    /;
  }

  my @dateparts = reverse ( split /[-| |T|:]/, $datetime );
  $dateparts[4]--;
  my $time = timelocal( @dateparts );
  my $plus_one = ($time + (24*3600));

  return( $time, $plus_one );

} # end sub


sub report_yesterday {
  my $self = shift;
  my %args = @_;
  
  my %methods = map { $_ => 1 } ( qw/
    count_daily_total_memberships
    count_daily_total_memberships
    count_daily_term_expirations
    count_daily_term_activations
    count_daily_new_memberships
    count_daily_new_terms
    count_daily_active_memberships
    count_daily_renewals
    count_daily_were_renewal_memberships
  /);

  if ( $args{'exclude'} ) {
    delete $methods{ $_ } for @{ $args{'exclude'} };
  }

  my $yesterday = DateTime->now()
                            ->clone()
                              ->subtract(days => 1)
                                ->set( hour => 0, minute => 0, second => 0 )
                                  ->datetime();
  
  my %data;

  for ( keys %methods ) {
    $data{ $_ } = $self->$_( $yesterday );
  }
  
  $data{ 'date' } = $yesterday;

  return \%data;

} # end sub


1; ## return true to end package CMS::Drupal::Modules::MembershipEntity

__END__

=pod

=encoding UTF-8

=head1 NAME

CMS::Drupal::Modules::MembershipEntity::Stats - Generate statistics about MembershipEntity memberships on a Drupal site. 

=head1 VERSION

version 0.96

=head1 SYNOPSIS

  use CMS::Drupal::Modules::MembershipEntity;
  use CMS::Drupal::Modules::MembershipEntity::Stats { into => 'CMS::Drupal::Modules::MembershipEntity' };
  
  my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh ); 
  $ME->fetch_memberships();
  
  print $ME->count_active_memberships;
  print $ME->pct_active_memberships_were_renewal; 
 
  ...

=head1 DESCRIPTION

This module provides some basic statistical analysis about your Drupal
site Memberships. It operates on the set of Memberships contained in 
$ME->{'_memberships'} in other words whichever ones you fetched with
your call to $ME->fetch_memberships().

It has some methods for doing retroactive reporting on the DB records
so you can initialize a reporting system with some statistical
baselines. 

See L<CMS::Drupal::Modules::MembershipEntity::Cookbook|the Cookbook>
for more information and examples of usage.

=head1 METHODS

=head2 count_total_memberships( )

Returns the number of Memberships in the set.

=head2 count_expired_memberships( )

Returns the number of Memberships from the set that have status of 'expired'.

=head2 count_active_memberships( )

Returns the number of Memberships from the set that have status of 'active'.

=head2 count_cancelled_memberships( )

Returns the number of Memberships from the set that have status of 'cancelled'.

=head2 count_pending_memberships( )

Returns the number of Memberships from the set that have status of 'pending'.

=head2 count_set_were_renewal_memberships( )

Returns the number of Memberships from the set whose current Term was a renewal.

Dies if $ME->{'_memberships'} is not defined.

=head2 count_daily_were_renewal_memberships( @list_of_dates )

Returns the number of Memberships within the set that were renewals,
i.e. whose currently active term was not the first term, on a given
date, or range of dates. Takes a date-time or a range of date-times
in ISO-ish format.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

=head2 count_daily_term_expirations( @list_of_dates )

Returns the number of Membership Terms belonging to Members
in the set that expired in the 24-hour period beginning with
the date supplied. Takes dates in ISO-ish format.

Returns a scalar when called with one date, or a hashref of counts
indexed by dates, if called with an array of date-times.

=head2 count_daily_term_activations( @list_of_dates )

Returns the number of Membership Terms belonging to Members in the
set that began in the 24-hour period beginning with the date
supplied. Takes dates in ISO-ish format.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

=head2 count_daily_new_memberships( @list_of_dates )

Returns the number of Memberships in the set that were created in the
24-hour period beginning with the date supplied. Takes dates in ISO-ish
format.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

=head2 count_daily_new_terms( @list_of_dates )

Returns the number of Terms (belonging to Memberships in the set)
that were created in the 24-hour period beginning with the date
supplied.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

=head2 count_daily_renewals( @list_of_dates )

Retruns the number of Membership Terms belonging to Memberships in
the set that were created in the 24-hour period beginning with the
date supplied and that were the second or subsequent Term belonging
to that Membership.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

=head2 count_daily_active_memberships( @list_of_dates )

Returns the number of Memberships within the set with status of
'active' on a given date, or range of dates. Takes a date-time
or a range of date-times in ISO-ish format.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of date-times.

Note that this report may not be 100% accurate, as data in the DB
may have changed since a given date,particularly the status
of Terms.

=head2 count_daily_total_memberships( @list_of_dates )

Returns the total number of Memberships (including those that
have expired) that had been created by the end of the 24-hour
period beginning with the datetime supplied.

Returns a scalar value when called with one date, or a hashref of
counts indexed by dates, if called with an array of datetimes.

=head2 build_date_range( $datetime [, $datetime2] )

Builds a range of dates in ISO 8601 format. Takes dates in YYYY-MM-DD
format. First date is the earliest date in the range. Second date is
the latest date in the range: if omitted, this defaults to today's
date. Returns an arrayref of datetime strings.

=head2 datetime_plus_one_day( $datetime )

Returns a timestamp representing the datetime one day
after the datetime supplied.

=head2 time_plus_one_day( $datetime )

Returns a pair of epoch timestamps representing the datetime supplied
and the datetime 24 hours later.

=head2 report_yesterday( [exclude => \@excluded_methods] )

This convenience method returns a hashref with the statistics from the
day before today. If called with no arguments it returns data from
all the count_daily_*() methods. Hashref returned includes the 
datetime used, indexed with 'date'.

Optionally takes an argument 'exclude', the value of which must be an
anonymous array of method names you wish to exclude from the data
returned.

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
