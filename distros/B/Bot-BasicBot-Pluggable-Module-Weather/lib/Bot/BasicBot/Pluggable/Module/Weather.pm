package Bot::BasicBot::Pluggable::Module::Weather;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Geo::WeatherNWS;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);
    return unless $body =~ /^\s*weather\s+(?:for\s+)?(.*?)\s*\?*\s*$/;
    my $code = $1;

    return "Try a 4-letter station code (see http://weather.noaa.gov/weather/curcond.html for locations and codes)"
        unless $code =~ /^[a-zA-Z][a-zA-Z0-9]{3,4}$/;

    my $w = Geo::WeatherNWS->new();

    my $r = $w->getreport($code);

    return "There was an error - ".$r->{errortext}  
        if $r->{error} != 0;    

    my $response = "";

    my $time = $r->{time};

    $time = s!(\d\d)$!:$1!;

    $response .= sprintf "(%s) Conditions at %d; ", $code, $time;
    $response .= sprintf "Dewpoint: %d F (%d C); ",  $r->{dewpoint_f}, $r->{dewpoint_c};
    $response .= sprintf "Pressure (altimeter): %d in. Hg (%d hPa); ", $r->{pressure_inhg}, $r->{pressure_mb};
    $response .= sprintf "Relative Humidity: %d%%; ", $r->{relative_humidity};
    $response .= sprintf "Sky conditions: %s; ", $r->{conditionstext}; 
    $response .= sprintf "Temperature: %d C (%d F);", $r->{temperature_c}, $r->{temperature_f};
    $response .= sprintf "Visibility: %d mile(s) (%d km); ", $r->{visibility_mi}, $r->{visibility_km};
    $response .= sprintf "Wind: from the %s (%d degrees) ", $r->{winddirtext}, $r->{winddir};
    $response .= sprintf "at %d MPH (%d KT) gusting ", $r->{windspeedmph}, $r->{windspeedkts};
    $response .= sprintf "to %d MPH (%d KT)", $r->{windgustmph}, $r->{windgustkts};

    return $response;

}

sub help {
    return "Commands: 'yow' or 'be zippy'";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Weather - get the weather forcast from NOAA

=head1 SYNOPSIS

Contacts C<weather.noaa.gov> and gets the weather report for a given
station.

=head1 IRC USAGE

    weather [for] <station>


=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

based on code by Kevin Lenzo <lenzo@cs.cmu.edu>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

