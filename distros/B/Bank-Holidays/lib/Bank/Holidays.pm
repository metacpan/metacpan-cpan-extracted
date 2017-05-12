package Bank::Holidays;

use 5.006001;
use strict;
use warnings;
use HTML::TableExtract;
use LWP::UserAgent;
use DateTime;

our $VERSION = '0.86';

sub new {
  my ( $package, %params ) = @_;

  my $param;
  $param->{dt} =
    $params{dt}
    ? $params{dt}
    : $params{date}
        ? $params{date}
        : DateTime->now;
  $param->{holidays} = reserve_holidays();
  bless $param, $package;
}

sub reserve_holidays() {
  my $te = HTML::TableExtract->new();

  my $ua = LWP::UserAgent->new();

  $ua->timeout(120);

  my $home = $ENV{HOME} || $ENV{LOCALAPPDATA};

  unless ( -d $home . "/.bankholidays" ) {
    mkdir( $home . "/.bankholidays" );
  }

  my $cache = $home . "/.bankholidays/frbholidays.html";

  # Cache the content from the FRB since holdays are unlikely to
  # change from day to day (or year to year)

  my $content;

  if ( -f $cache && ( time() - ( stat($cache) )[9] ) < 86400 ) {
    open my $fh, "<", $cache or die $!;
    $content = do { local $/ = <$fh> };
    close $fh;
  }
  else {
    my $url = 'http://www.federalreserve.gov/aboutthefed/k8.htm';

    my $request = HTTP::Request->new( 'GET', $url );

    my $response = $ua->request($request);

    $content = $response->content();

    open my $fh, ">", $cache or die $!;
    print {$fh} $content;
    close $fh;
  }

  $te->parse($content);

  my $months = {
    'January'   => 1,
    'February'  => 2,
    'March'     => 3,
    'April'     => 4,
    'May'       => 5,
    'June'      => 6,
    'July'      => 7,
    'August'    => 8,
    'September' => 9,
    'October'   => 10,
    'November'  => 11,
    'December'  => 12
  };

  my $holidays;

  foreach my $ts ( $te->tables ) {
    next if ( $ts->coords ) != 2;
    my @colyears;
    foreach my $row ( $ts->rows ) {

      next unless @$row;
      map { s/\r|\n//g if $_ } @$row;
      my $colcount = 0;
      foreach my $col (@$row) {
        if ($col) {
          if ( $col =~ /(\d{4})/ ) {
            $colyears[$colcount] = $1;
          }
          elsif ( $col =~ /(\w+)\s(\d{1,2})(\*?)/ ) {
            push @{ $holidays->{ $colyears[$colcount] }->{ $months->{$1} } },
              {
              day     => $2,
              satflag => $3
              };

          }
        }
        $colcount++;
      }
    }
  }
  return $holidays;
}

sub is_holiday {
  my ( $param, %opts ) = @_;

  if ( $opts{date} ) {
    $param->{dt} = $opts{date};
  }

  if ( $opts{Tomorrow} ) {
    $param->{dt}->add( days => 1 );
  }
  elsif ( $opts{Yesterday} ) {
    $param->{dt}->subtract( days => 1 );
  }
  return 1 if $param->{dt}->dow == 7;
  foreach my $holiday ( @{ $param->{holidays}->{ $param->{dt}->year }->{ int( $param->{dt}->month ) } } ) {
    return 1 if int( $param->{dt}->day ) == $holiday->{day};
  }
  return undef;
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Bank::Holidays - Determine Federal Reserve holidays, 2017 - 2021

=head1 VERSION

0.86

=head1 SYNOPSIS

  use Bank::Holidays;

  # Using the date => reference you can specify any date you like.
  my $bank = Bank::Holidays->new( date => DateTime->now ); # or any datetime object

  # Check yesterday to see if it was a holiday
  print "Yesterday ";
  $bank->is_holiday( Yesterday => 1 ) ? print "is " : print "is not";
  print " a holiday";

  # Check to see if today is a holiday;
  print "Today ";
  $bank->is_holiday ? print "is" : print "is not";
  print " a holiday\n";

  # Check to see if tomorrow is a holiday.
  print "Tomorrow ";
  $bank->is_holiday( Tomorrow => 1 ) ? print "is" : print "is not";
  print " a holiday\n";

=head1 EXPORTER

As of version 0.82, no functions are exported, and EXPORTER has been removed. It's
unclear if exported functions worked, as both (`is_holiday' and `reserve_holidays')
required an existing Bank::Holidays object to have been created by the caller.

=head1 DESCRIPTION

Bank::Holidays reads a page from the Federal Reserve's website that contains
holidays until 2021. However should the FR's site change this code may not work.
This code is very useful for determining days that a valid banking transaction
can occur, remembering that Sunday is never a banking day.

=head2 methods

new( [ date => dt->object ] ) Defaults to today if undefines.

is_holiday( [ Yesterday|Tomorrow => 1 ] ) To determine what day to check default is current date in date object.

=head1 AUTHOR

Tyler Hardison, E<lt>thardison@seraph-net.netE<gt>

=head1 THANKS TO

Alex White E<lt>wu@geekfarm.orgE<gt> - For providing a patch for 2010 changes to the fed's site.

Robert Leap E<lt>robertleap@gmail.comE<gt> - For providing a patch for the 2012-2016 holday period.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Tyler Hardison

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
