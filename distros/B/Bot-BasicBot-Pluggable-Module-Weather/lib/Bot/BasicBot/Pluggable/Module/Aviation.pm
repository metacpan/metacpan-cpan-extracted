package Bot::BasicBot::Pluggable::Module::Aviation;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Geo::WeatherNWS;
use LWP::Simple ();
use HTML::Entities;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $line = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    if    ($line =~ /^metar/i)             { return $self->metar($line)       }
    elsif ($line =~ /^taf/i)               { return $self->taf($line)         }
    elsif ($line =~ /^great[-\s]?circle/i) { return $self->greatcircle($line) }
    elsif ($line =~ /^tsd/i)               { return $self->tsd($line)         }
    elsif ($line =~ /^zulutime/i)          { return $self->zulutime($line)    }
    elsif ($line =~ /^airport/i)           { return $self->airport($line)     }
    elsif ($line =~ /^aviation/i)          { return $self->aviation($line)    }

    return;

}

sub help {
    return "My aviation-related functions are metar, taf, great-circle, tsd, zulutime, and airport. For help with any, ask me about '<function name> help";
}

sub _fix_icao {
    my $site = uc(shift);

    # ICAO airport codes *can* contain numbers, despite earlier claims.
    # Americans tend to use old FAA three-letter codes; luckily we can
    # *usually* guess what they mean by prepending a 'K'. The original
    # author, being Canadian apparently, displays similarl impeccable 
    # laziness.    

    $site =~ s/[.?!]$//;
    $site =~ s/\s+$//g;
    return undef
            unless $site =~ /^[\w\d]{3,4}$/;
    $site  = "C" . $site if length($site) == 3 && $site =~ /^Y/;
    $site  = "K" . $site if length($site) == 3;

    return $site;
}


#
# METAR - current weather observation
#
sub metar {
    my ($self, $line) = @_;

    return unless $line  =~ /\s*metar\s+(for\s+)?(.*)/i;
    
    my $site = _fix_icao($2);
    return "'$site' doesn't look like a valid ICAO airport identifier." 
        unless defined $site;

    return "For observations, ask me 'metar <code>'. For information on decoding Aerodrome Weather Observations (METAR ), see http://www.avweb.com/toc/metartaf.html"
        if ($site eq 'HELP');

    my $r = Geo::WeatherNWS->new();

    $r->getreport($site);

    return "Hrmm, I hit a problem - ".$r->{errortext} if $r->{error};

    return $r->{obs};

}

#
# TAF - terminal area (aerodrome) forecast
#
sub taf {
    my ($self, $line) = @_;


    return unless $line  =~ /\s*taf\s+(for\s+)?(.*)/i;

    my $site = _fix_icao($2);
    return "'$site' doesn't look like a valid ICAO airport identifier."
        unless defined $site;    


    return "For a forecast, ask me 'taf <ICAO code>'. For information on decoding Terminal Area Forecasts, see http://www.avweb.com/toc/metartaf.html"
        if ($site eq 'HELP'); 

    # god I hate CPAN some times, this code should be in GEO::Taf
    my $content = LWP::Simple::get("http://weather.noaa.gov/cgi-bin/mgettaf.pl?cccc=$site");
    return "I can't seem to retrieve data from weather.noaa.com right now." 
            unless $content;

    # extract TAF from equally verbose webpage
    $content  =~ m/($site( AMD)* \d+Z .*?)</s;
    my $taf = $1;
    $taf =~ s/\n//gm;
    $taf =~ s/\s+/ /g;
    
    my $taf_highlight_bold = $self->get("taf_highlight_bold");

    
    # Optionally highlight beginnings of parts of the forecast. Some
    # find it useful, some find it obnoxious, so it's configurable. :-)
    $taf =~ s/(FM\d+Z?|TEMPO \d+|BECMG \d+|PROB\d+)/\cB$1\cB/g if $taf_highlight_bold;


    # Sane?
    return "I can't find any forecast for $site." if length($taf) < 10;

    return $taf;
}

#
# greatcircle -- calculate great circle distance and heading between
#
sub greatcircle {
    my ($self, $line) = @_;

    return "That doesn't look right. The 'great-circle' command takes two airport identifiers and returns the great circle distance and heading between them."
            unless $line =~ /^great-?circle\s+((from|between|for)\s+)?(\w+)\s+((and|to)\s)?(\w+)/i;

    # See metar part for explanation of this bit.
    my $orig_apt = _fix_icao($3);
    my $dest_apt = _fix_icao($6);

    return "$3 doesn't look like an ICAO code" unless $orig_apt;
    return "$6 doesn't look like an ICAO code" unless $dest_apt;

    return "To get the great circle distance two airports ask me 'great-circle between <ICAO code> and <ICAO code>'"
        if ($orig_apt eq 'HELP' or $dest_apt eq 'HELP');

    my $content = LWP::Simple::get("http://www8.landings.com/cgi-bin/nph-dist_apt?airport1=$orig_apt&airport2=$dest_apt");

    return "I can't seem to retrieve data from www.landings.com right now." unless $content;

    my $gcd;
    if ($content =~ m/circle: ([.\d]+).*?, ([.\d]+).*?, ([.\d]+).*?heading: ([.\d]+)/s) {
        $gcd = "Great-circle distance: $1 mi, $2 nm, $3 km, heading $4 degrees true";
    } else {
        $content =~ m/(No airport.*?database)/;
        $gcd = $1;
    }

    return $gcd;


}

#
# tsd -- calculate time, speed, distance, given any two
#
sub tsd {
    my ($self, $line) = @_;

    return "To solve time/speed/distance problems, substitute 'x' for " .
        "the unknown value in 'tsd TIME SPEED DISTANCE'. For example, " .
        "'tsd 3 x 200' will solve for the speed in at which you can travel " .
        "200 mi in 3h." if $line =~ /help/i;

    my ($time, $speed, $distance) = ($line =~ /tsd\s+(\S+)\s+(\S+)\s+(\S+)/);

    my $error;
    $error++ unless $time && $speed && $distance;

    if ($time =~ /^[A-Za-z]$/) { # solve for time
        $error++ unless $speed =~ /^[\d.]+$/;
        $error++ unless $distance =~ /^[\d.]+$/;
        return $distance / $speed unless $error;
    }
    elsif ($speed =~ /^[A-Za-z]$/) { # solve for speed
        $error++ unless $time =~ /^[\d.]+$/;
        $error++ unless $distance =~ /^[\d.]+$/;
        return $distance / $time unless $error;
    }
    elsif ($distance =~ /^[A-Za-z]$/) { # solve for distance
        $error++ unless $speed =~ /^[\d.]+$/;
        $error++ unless $time =~ /^[\d.]+$/;
        return $time * $speed unless $error;
    }

    return "Your time/speed/distance problem looks incorrect. For help, try 'tsd help'.";

}

#
# zulutime -- return current UTC time
#
sub zulutime {
    my ($self, $line) = @_;
    return "zulutime returns the time in DDHHMM format." if $line =~ /help/i;
    return sprintf('%02d%02d%02dZ', reverse((gmtime())[1..3]));
}

sub airport {
    my ($self, $line) = @_;
    
    return "That doesn't look right. Try 'airport code for CITY' or 'airport name for CODE' instead." 
        unless $line =~ (/airport\s+(name|code|id)s?\s+(for\s+)?(.*)/i);

    my $function = lc($1); $function = 'code' if $function eq 'id';
    my $query    = $3;

    return $self->airport_name($query) if $function eq 'name';
    return $self->airport_code($query);
}


sub airport_name {
    my ($self, $query) = @_;

    my $code = _fix_icao($query);

    return "That doesn't look like a valid ICAO airport identifier. (Perhaps you mean 'airport code for $query'?)"
        unless defined $code;

    my $content = LWP::Simple::get("http://www8.landings.com/cgi-bin/nph-search_apt?1=$code&max_ret=1");

    my @apt_lines = split (/\n/, $content);

    my $pnext = 0;
    my $response   = '';

    foreach (@apt_lines) {
        # skip over entries without ICAO idents (ICAO: n/a)
        if    (/\(ICAO: <b>[^n]/) { $response .= "$_, "; $pnext = 1; }
        elsif ($pnext)            { $response .= $_; $pnext = 0; }
    }

    $response =~ s/(<.*?>)+/ /g; # naive, but works in *this* case.
    $response =~ s/.*?\) //;     # strip (ICAO: foo) bit
    $response =~ s/\s+/ /g;
    $response =~ s/ ,/,/g;       # pet peeve.

    $response = decode_entities($response);

    return "I can't find an airport for $query." unless $response;
    return "$query is $response";

}

sub airport_code {
    my ($self, $query) = @_;

     $query =~ s/[.?!]$//;
    $query =~ s/\s+$//;

    # Grab airport data from Web.
    my $url = "http://www8.landings.com/cgi-bin/nph-search_apt?6=$query&max_ret=100";
    my $content = LWP::Simple::get($url);

    # If it can't find it, assume luser error :-)
    return "I can't seem to access my airport data -- perhaps try again later."
                unless $content;

    # extract csv-format airport data from incredibly and painfully verbose webpage
    my @apt_lines = split (/\n/, $content);

    my $response   = '';
    foreach (@apt_lines) {
        print "$_";
        $response .= "$1 " if m|\(ICAO: <b>([^n]+?)</b>|;
    }

    $response =~ s/(<.*?>)+/ /g; # naive, but works in *this* case.

    return "I can't find an airport code for $query." unless $response;
    return "$query may be: $response";
                
}


1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Aviation - module for various flight-planning bits


=head1 IRC USAGE

    metar for <ICAO code>
    taf for <ICAO code>
    airport name for <ICAO code>
    airport code for <airport name>
    great-circle from <ICAO code> to <ICAO code>
    zulutime

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

based on code by

Rich Lafferty <rich@alcor.concordia.ca> (original version)
Kevin Lenzo   <lenzo@cs.cmu.edu> (fixes)
Lazarus Long  <lazarus@frontiernet.net> (fixes)


=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

