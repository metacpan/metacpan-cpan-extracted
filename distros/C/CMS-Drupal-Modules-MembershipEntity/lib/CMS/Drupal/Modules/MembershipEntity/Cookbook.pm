package CMS::Drupal::Modules::MembershipEntity::Cookbook;
$CMS::Drupal::Modules::MembershipEntity::Cookbook::VERSION = '0.96';
# ABSTRACT: Guide and tutorials for using the Perl-Drupal Membership Entity interface

use strict;
use warnings;





1; # return true

__END__

=pod

=encoding UTF-8

=head1 NAME

CMS::Drupal::Modules::MembershipEntity::Cookbook - Guide and tutorials for using the Perl-Drupal Membership Entity interface

=head1 VERSION

version 0.96

=head1 SYNOPSIS

This manual contains a collection of tutorials and tips for using
the CMS::Drupal::Modules::MembershipEntity distribution.

=head1 DESCRIPTION

The individual packages in the CMS::Drupal::Modules::MembershipEntity
distribution each have their own POD of course, but the author hopes
that this documentation will help a new user put it all together.
Maybe you are a non-programmer or a non-Perl user and you are here
because you use Drupal's MembershipEntity modules and you need the
additional tools this distribution provides.

=head2 Code examples

In the interests of brevity and readability I have omitted the standard
opening lines from the code samples below. If you are copy-pasting the
examples and trying them out on your system, you should prepend the
following to each snippet:

  #!/usr/bin/perl -w
  use strict;
  use feature 'say';

The examples also skip the "use Foo::Bar"" lines, except for those
examples in each section that specifically describe how to "use"
them. You'll need to include those lines in your code too!

Note that these examples use the feature "say" which became available in
Perl v5.10 ... you can of course replace with "print" if you like: I
prefer "say" in examples (and in my code!) because you can omit the
newlines and their quotation marks.

=head1 INSTALLATION AND TESTING

Install the modules however you normally do. The easiest way is to get
them from CPAN:

  $ cpan install CMS::Drupal
  $ cpan install CMS::Drupal::Modules::MembershipEntity

If you want the modules to test themselves against your Drupal database
you will need to set the DRUPAL_TEST_CREDS environment variable as 
described in the Testing section of the documentation for the parent
CMS::Drupal module. Essentially you will need to provide at least
the database name and driver, so your minimum testing config would be:

  $ set DRUPAL_TEST_CREDS=database,foo,driver,Pg

or something similar.

If you come to this tutorial after you've installed the modules you
can still test by finding the CPAN build directory and just running

  $ perl t/02_valid_drupal.t

=head1 USING THE MODULES

You'll need to load the libraries in any script or program you write.
First you need to get a connection to your Drupal database. This is
done through the L<CMS::Drupal|CMS::Drupal> parent module:

  #!/usr/bin/perl -w
  use strict;
  use CMS::Drupal;
 
  my $drupal = CMS::Drupal->new;
  my $dbh    = $drupal->dbh(
    'database' => "my_db",
    'driver'   => "mysql",
    'username' => "my_user",
    'password' => "my_password"
  );

Once you have a DB connection you can make use of the Membership Entity
modules. Again, you'll have to load them with use():

  #!/usr/bin/perl -w
  use strict;
  use CMS::Drupal;
  use CMS::Drupal::Modules::MembershipEntity;

  my $drupal = CMS::Drupal->new;
  my $dbh    = $drupal->dbh(
    'database' => "my_db",
    'driver'   => "mysql",
    'username' => "my_user",
    'password' => "my_password"
  );
  
  my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );
  my $h  = $ME->fetch_memberships('all');

Now you have a hashref containing all our Memberships, and you can work
with each one:

  foreach my $mid ( keys %{ $h } ) {
    
    if ( $h->{ $mid }->is_active ) {
      $active_count++;
    }
    
    # pass the Membership object to a sub you wrote
    frobinate_member( $h->{ $mid } ); 

  }

If you just want to fetch one Membership, just pass a single mid to the 
fetch_memberships() method, and you'll get a single object returned 
instead of a hashref:

  my $mem = $ME->fetch_memberships( 12345 );
  print $mem->type;
  frobinate_member( $mem );

=head1 DATA ANALYSIS

The creation of this distribution was originally motivated by the lack of
tools for doing even rudimentary data analysis in Drupal's MembershipEntity
modules. This section explains the various ways it can help you with that.

=head1 Stats.pm

The main tool for analyzing your Membership base is the module
L<CMS::Drupal::Modules::MembershipEntity::Stats|Stats>.

=head2 Usage and Importing Methods

Start out by using Stats.pm in your program after you have loaded
the MembershipEntity modules as decribed above.

Notice that because Stats.pm exports all its useful methods, you can
import them into MembershipEntity.pm and thus make them available in
your $ME object:

  #!/usr/bin/perl -w
  use strict;
  use CMS::Drupal;
  use CMS::Drupal::Modules::MembershipEntity;
  use CMS::Drupal::Modules::MembershipEntity::Stats
       { into => 'CMS::Drupal::Modules::MembershipEntity' };
  
  my $drupal = CMS::Drupal->new;
  my $dbh    = $drupal->dbh;
  my $ME = CMS::Drupal::Modules::MembershipEntity->new( dbh => $dbh );
  $ME->fetch_memberships('all');

  my $active = $ME->count_active_memberships;
  say "We have $active active Memberships";

=head2 Types of methods

The methods in Stats.pm can be grouped into three basic categories,
which are signalled through the prefix of the methods' names:

=over 4

=item *

count_

These methods may be called with or without a set of Memberships. If
called without a set (see below), they will operate on all your
Memberships.

=item *

count_set_

These methods B<must> be called with a set of Memberships.

=item *

count_daily_

These methods B<must> be called with a range of dates (see below), and
may be called with a set of Memberships (see below).

=back

=head2 Working with a set of Memberships

Methods whose names begine with the prefix 'count_set_' must be called
with a set of Memberships, even if you want all Memberships included.
The set of Memberships is already contained in your MembershipEntity
object if you called fetch_memberships() on your MembershipEntity object
as described above:

  my @mids = ( 123, 456, 665, 667 );
  $ME->fetch_memberships( @mids );

or

  $ME->fetch_memberships('all');

If you do not call fetch_memberships() first, calling a method whose
name begins with the prefix 'count_set_' will cause your program to
die.

On the other hand, if you want to limit the statistics returned by
a 'count_' method or 'count_daily_' method to a subset of your 
Memberships, you can do so by first calling fetch_memberships() with
a list of mids.

=head2 Performance

For reasons of performance, and especially if you have a lot of 
Memberships, you should use Stats.pm B<without> first calling
fetch_memberships(), if you do not need to use any of the 
count_set_*() methods. This is because it will get its counts
by querying the database directly rather than by instantiating several
objects for each Membership.

If you are working with stats for your entire Membership base, you
should therefore not call fetch_memberships(). If you want to use
the count_set_*() methods on all your Memberships, you will have to 
call fetch_memberships('all') first, but you can then remove the set
and go back to the fast methods as shown below

  my $all = $ME->count_all_memberships; # fast
  
  # load the Memberships into a hashref
  $ME->fetch_memberships('all');
 
  # get a count that calls methods on the objects
  my $num = $ME->count_set_were_renewal_memberships();
  
  delete $ME->{'_hashref'};

  my $active = $ME->count_active_memberships; # back to the fast way

=head2 Working with dates

The methods in Stats.pm whose names begin with the prefix count_daily_
return counts for a date or range of dates. They can be optionally
limited to search on a set of Memberships if the fetch_memberships()
method is called in advance. These methods take dates in ISOish
format, i.e. something like:

  2001-01-01T12:00:00

(called ISO-ish because there is no time zone, as the ISO 8601 format
specifies).

You can use these methods to look at a date in the past:

  my $num =
    $ME->count_daily_expired_memberships('2015-06-15T00:00:00');

or at a range of dates:

  my $counts =
    $ME->count_daily_expired_memberships('2015-06-15T00:00:00',
                                         '2015-07-15T00:00:00',
                                         '2015-08-15T00:00:00');
  
  while (my ($date, $count) = each %{ $counts }) {
    $quarterly_total += $count;
    ...
  }

=head3 What time to use?

If you are forensically building a record of your Memberships, you
should probably set the time element of your date(s) to 00:00:00,
since the searchlooks for Terms with a start date <= and an end
date > the date given, and this strategy will give a daily report
that is closest to the historical truth if you store your statistics
indexed by a date.

=head3 Building a range of dates

Working with dates can be cumbersome, and typing them manually is
prone to errors. The Stats.pm module provides a method to build an
array of datetime strings that you can pass to its other methods.

You call it with either one or two dates: the first is required
and is the start date in the range. The second argument, if provided,
is used for the end date in the range. If no end date is provided,
the module will use today's date. Times are set to 00:00:00.

  my @dates = $ME->build_date_range('2014-01-01','2014-12-31');
  # one year's worth of dates

  my @dates = $ME->build_date_range('2001-01-01);
  # Every date in the millenium so far

=head3 An example

Here's an example of a simple program that reports the previous
week's statistics.

  #!/usr/bin/perl -w
  use strict;
  use DateTime;
  use CMS::Drupal;
  use CMS::Drupal::Modules::MembershipEntity;
  use CMS::Drupal::Modules::MembershipEntity::Stats
        { into => 'CMS::Drupal::Modules::MembershipEntity' };

  my $drupal = CMS::Drupal->new;
  my $dbh    = $drupal->dbh;
  my $ME = CMS::Drupal::Modules::MembershipEntity->new({dbh => $dbh});

  my $today      = DateTime->now()->set_time_zone('UTC');
  my $a_week_ago = $today->subtract( days => 6 )->ymd();
                   # 6 days because the set includes today

  my @days = @{ $ME->build_date_range( $a_week_ago ) };

  my $report = <<EOT;
  MembershipEntity Report
  ---------------------------
  Date        Exp New Active
  ---------------------------
  EOT

  my $exp = $ME->count_daily_term_expirations( @days );
  my $new = $ME->count_daily_new_terms( @days );
  my $act = $ME->count_daily_active_memberships( @days );

  foreach my $date ( @days ) { 
    my @line = substr $date, 0, 10;  
    for ( $exp, $new, $act ) { 
      push @line, $_->{ $date };
    }
    $report .= (join ' | ', @line) . "\n";
  }
  $report .= '-' x 25 . "\n";
  
  print $report;

  __END__

This program outputs something like:

  MembershipEntity Report
  ---------------------------
  Date        Exp New Active
  ---------------------------
  2015-07-09 | 0 | 0 | 580
  2015-07-10 | 0 | 0 | 580
  2015-07-11 | 0 | 1 | 580
  2015-07-12 | 0 | 1 | 580
  2015-07-13 | 1 | 0 | 581
  2015-07-14 | 0 | 1 | 580
  2015-07-15 | 1 | 0 | 580
  2015-07-16 | 0 | 0 | 580
  -------------------------

Now all you have to do is get the data for multiple weeks, sum
up the daily totals for the week, and you have the beginnings
of a useful report!

=head3 Automated daily report

If you want to build up a statistical record about your Memberships,
you'll probably want to export counts from the database into a
spreadsheet or other local database, so you can analyse them and make
graphs and so on.

The simplest way to do this is to write a program similar to the one
above and run it from cron every day. The Stats.pm module provides
a handy method for retrieving yesterday's data.

If you call $ME->report_yesterday() you'll get an anonymous hash
like this:

 {
  'count_daily_term_expirations' => '1',
  'count_daily_new_memberships' => '2',
  'count_daily_were_renewal_memberships' => '224',
  'count_daily_total_memberships' => '1498',
  'count_daily_new_terms' => '3',
  'count_daily_term_activations' => '2',
  'count_daily_active_memberships' => '580',
  'count_daily_renewals' => '2',
  'date' => '2013-02-14T00:00:00'
 }

You can optionally pass an anonymous array of method names that you
want exlcuded from the output. Check the documentation for Stats.pm
for a list of all the count_daily_*() methods.

So now you can do something in your nightly program something like:

  ## Assumes you have a database with a table called 'daily'

  my $sql = qq/ 
    INSERT INTO daily
    ('date', 'active', 'expirations', 'new_terms', 'new_memberships', 'renewals')
    VALUES ( ?, ?, ?, ?, ?, ? ) 
  /;

  my $sth = $dbh->prepare( $sql );

  my @exclude = qw/ count_daily_total_memberships
                    count_daily_term_activations
                    count_daily_were_renewal_memberships /;

  my $yesterday = $ME->report_yesterday( \@exclude );

  $sth->execute( $yesterday->{'date'},
                 $yesterday->{'count_daily_active_memberships'},
                 $yesterday->{'count_daily_term_expirations'},
                 $yesterday->{'count_daily_new_terms'},
                 $yesterday->{'count_daily_new_memberships'},
                 $yesterday->{'count_daily_renewals'} );

. . . or of course you could send an email, update a text log, whatever...

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
