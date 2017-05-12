# Copyright 2007, 2008, 2009, 2010, 2017 Kevin Ryde

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


# Currently unused ...


package App::Chart::Finance::Yahoo::Exchanges;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');


# This looks at the exchanges page
#
# use constant URL => 'http://finance.yahoo.com/exchanges';
use constant URL => 'https://help.yahoo.com/kb/SLN2310.html';

# Refetch the exchanges page after this many days
#
use constant UPDATE_DAYS => 7;

# return a hashref of exchange delay data like { '.AX' => 20, '.BI' => 15 }
sub exchanges_data {
  require App::Chart::Pagebits;
  return App::Chart::Pagebits::get
    (name      => __('Yahoo exchanges page'),
     url       => URL,
     key       => 'yahoo-quote-delays',
     freq_days => UPDATE_DAYS,
     parse     => \&parse_html);
}

sub parse_html {
  my ($content) = @_;
  my @entries;
  my $h = { entries   => \@entries,
            timestamp => timestamp_now(),
          };

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => [ 'Country',
                  'Exchange',
                  'Suffix',
                  'Delay',
                  'Provider' ]);

  $te->parse($content);
  if (! $te->tables) {
    warn "Yahoo exchanges page unrecognised, assuming 15 min quote delay";
    return $h;
  }

  foreach my $row ($te->rows) {
    my %entry;
    @entry{'country','exchange','suffix','delay_minutes','provider'} = @$row;

    # wash two spaces in "Chicago  Mercantile ..." to one
    foreach (values %entry) { s/\s+/ /g; }

    # US suffix N/A means no suffix
    if ($entry{'suffix'} eq 'N/A') { $entry{'suffix'} = ''; }

    # Delay like "15 min", or "15 min**" with footnote for NS India
    #
    if ($entry{'delay_minutes'} =~ /^(\d+) min/) {
      $entry{'delay_minutes'} = $1;
    } else {
      warn "Yahoo exchanges page unrecognised delay: \"$entry{delay_minutes}\"\n";
      $entry{'delay_minutes'} = 20; # assumed default
    }

    push @entries, \%entry;
  }
  return $h;
}

sub timestamp_now {
  return timet_to_timestamp(time());
}
sub timet_to_timestamp {
  my ($t) = @_;
  require POSIX;
  return POSIX::strftime ('%Y-%m-%d %H:%M:%S+00:00', gmtime($t));
}


#------------------------------------------------------------------------------
# containing arefs [$pred,'.XX']
my @quote_delay_aliases;

sub setup_quote_delay_alias {
  my ($pred, $suffix) = @_;
  push @quote_delay_aliases, [ $pred, $suffix ];
}

sub symbol_quote_delay {
  my ($symbol) = @_;

  # indexes all in real time
  if ($symbol =~ /^\^/) {
    return 0;
  }

  my $suffix = ($symbol =~ /(\.[^.]+)$/ && $1);
  my $h = exchanges_data();
  my $delay = $h->{$suffix};

  if (! defined $delay) {
    if (my $elem = List::Util::first { $_->[0]->match ($symbol) }
        @quote_delay_aliases) {
      $suffix = $elem->[1];
      $delay = $h->{$suffix};
    }
  }
  if (! defined $delay) {
    # guess default 20 minutes
    $delay = 20;
  }
  return $delay;
}

1;
__END__
