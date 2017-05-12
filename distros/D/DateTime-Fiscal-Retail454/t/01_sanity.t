# $Id: 01_sanity.t 22 2012-07-05 21:36:33Z jim $

BEGIN {
  use DateTime::Fiscal::Retail454;

  chdir 't' if -d 't';
  require './r454_testdata';

  my $loops = scalar(keys(%r454_data));
  $loops *= (1 + 4 + (12 * (6 + 5)));
  $totaltests = $loops;
}

use Test::More tests => $totaltests;

foreach ( keys(%r454_data) ) {
  do_it($_);
}

exit;

sub do_it
{
my $fyear = shift;

  print "Testing $fyear\n";

  my $r454 = DateTime::Fiscal::Retail454->from_r454year( r454year => $fyear );
  isa_ok($r454,'DateTime');

  my $tdata = $r454_data{$fyear};
  for (qw( r454_year r454_start r454_end is_r454_leap_year )) {
    ok($r454->$_ eq $tdata->{$_}, "Correct response for $_");
  }

  for ( 1 .. 12 ) {
    my $ptest = $tdata->{periods}->{$_};
    my @pdata = $r454->r454_period( period => $_ );
    print "Testing period $_\n";
# Test array results
    ok($pdata[0] == $ptest->{r454_period},"Correct period for period $_");
    ok($pdata[1] == $ptest->{r454_period_weeks},"Correct weeks for period $_");
    ok($pdata[2] eq $ptest->{r454_period_start},"Correct start for period $_");
    ok($pdata[3] eq $ptest->{r454_period_end},"Correct end for period $_");
    ok($pdata[4] eq $ptest->{r454_period_publish},"Correct publish for period $_");
    ok($pdata[5] == $ptest->{r454_year},"Correct year for period $_");
# Test component results
    for my $comp ( qw(r454_period_weeks r454_period_start r454_period_end r454_period_publish r454_year) ) {
      ok($ptest->{$comp} eq $r454->$comp( period => $_ ),"Correct $comp for period $_");
    }
  }

}

__END__
