# Finance::Quote interface to Chart latest prices.

# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


package Finance::Quote::Chart;
use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = 267;

sub chartprog_quotes {
  my ($quoter, @symbol_list) = @_;
  require App::Chart::Latest;

  my %quotes = ();
  foreach my $symbol (@symbol_list) {
    my $latest = App::Chart::Latest->get ($symbol);

    # standard F-Q fields
    if (my $date = $latest->{'last_date'}) {
      $quoter->store_date(\%quotes, $symbol, {isodate => $date});
    }
    $quotes{$symbol,'name'}     = $latest->{'name'};
    $quotes{$symbol,'currency'} = $latest->{'currency'};

    $quotes{$symbol,'bid'}      = $latest->{'bid'};
    $quotes{$symbol,'ask'}      = $latest->{'offer'};
    $quotes{$symbol,'last'}     = $latest->{'last'};
    $quotes{$symbol,'open'}     = $latest->{'open'};
    $quotes{$symbol,'high'}     = $latest->{'high'};
    $quotes{$symbol,'low'}      = $latest->{'low'};
    $quotes{$symbol,'net'}      = $latest->{'change'};
    $quotes{$symbol,'volume'}   = $latest->{'volume'};

    $quotes{$symbol,'method'}   = 'chartprog';
    $quotes{$symbol,'source'}   = __PACKAGE__;
    $quotes{$symbol,'success'}  = 1;
    $quotes{$symbol,'errormsg'} = $latest->{'error'};

    # extras
    $quotes{$symbol,'time'}     = $latest->{'last_time'};
    $quotes{$symbol,'exchange'} = $latest->{'exchange'};
    #     my $div_amount = $latest->{'ex_dividend'};
    #     $latest->{'ex_div'};
    #    $quotes{$symbol,'ex_div'}   = $ex_date;
    #    $quotes{$symbol,'div'}      = $div_amount;

  }
  ### \%quotes
  return wantarray ? %quotes : \%quotes;
}

sub labels {
  return (chartprog => [ qw(date isodate time name price change currency
                            method source) ]);
}

sub methods {
  return (chartprog => \&chartprog_quotes);
}


1;
__END__

=head1 NAME

Finance::Quote::Chart - read Chart program quotes

=for test_synopsis my ($fq, %quotes)

=head1 SYNOPSIS

 use Finance::Quote;
 $fq = Finance::Quote->new ('-defaults', 'Chart');
 %quotes = $fq->fetch('chartprog','BHP.AX','RS.WCE');

=head1 DESCRIPTION

...

=head1 DATA

The following standard F-Q fields are returned

=for Finance_Quote_Grab fields flowed standard

    date isodate name currency
    bid ask
    open high low last net
    volume
    method source success errormsg

Plus the following extras

=for Finance_Quote_Grab fields table extra

    time         ISO string "HH:MM"
    exchange

=head1 SEE ALSO

L<chart>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
