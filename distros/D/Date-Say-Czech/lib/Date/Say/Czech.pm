# For Emacs: -*- mode:cperl; mode:folding; -*-
#
# Czech.pm
#
# (c) 2005-2011 Jiri Vaclavik <my name dot my last name at gmail dot com>
# All rights reserved. This program is free software; you can redistribute
# and/or modify it under the same terms as perl itself.
#
package Date::Say::Czech;

# {{{ use

use 5.010;
use strict;
use warnings;

use Perl6::Export::Attrs;
use POSIX;

# }}}
# {{{ variables

our $VERSION     = "0.05";
our $AUTHOR      = 'Jiri Vaclavik <my name dot my last name at gmail dot com>';

my %cipher = (
    1  => "jedna",
    2  => "dva",
    3  => "tři",
    4  => "čtyři",
    5  => "pět",
    6  => "šest",
    7  => "sedm",
    8  => "osm",
    9  => "devět",
    10 => "deset",
    11 => "jedenáct",
    12 => "dvanáct",
    13 => "třináct",
    14 => "čtrnáct",
    15 => "patnáct",
    16 => "šestnáct",
    17 => "sedmnáct",
    18 => "osmnáct",
    19 => "devatenáct"
);

my %specialcipher = (
    1  => "prvního",
    2  => "druhého",
    3  => "třetího",
    4  => "čtvrtého",
    5  => "pátého",
    6  => "šestého",
    7  => "sedmého",
    8  => "osmého",
    9  => "devátého",
    10 => "desátého",
    11 => "jedenáctého",
    12 => "dvanáctého",
    13 => "třináctého",
    14 => "čtrnáctého",
    15 => "patnáctého",
    16 => "šestnáctého",
    17 => "sedmnáctého",
    18 => "osmnáctého",
    19 => "devatenáctého"
);

my %tens = (
    1 => "deset",
    2 => "dvacet",
    3 => "třicet",
    4 => "čtyřicet",
    5 => "padesát",
    6 => "šedesát",
    7 => "sedmdesát",
    8 => "osmdesát",
    9 => "devadesát"
);

my %specialtens = (
    1 => "desátého",
    2 => "dvacátého",
    3 => "třicátého",
    4 => "čtyřicátého",
    5 => "padesátého",
    6 => "šedesátého",
    7 => "sedmdesátého",
    8 => "osmdesátého",
    9 => "devadesátého"
);

my %months = (
    1 => "leden",
    2 => "únor",
    3 => "březen",
    4 => "duben",
    5 => "květen",
    6 => "červen",
    7 => "červenec",
    8 => "srpen",
    9 => "září",
    10 => "říjen",
    11 => "listopad",
    12 => "prosinec"
);

my %specialmonths = (
    1 => "ledna",
    2 => "února",
    3 => "března",
    4 => "dubna",
    5 => "května",
    6 => "června",
    7 => "července",
    8 => "srpna",
    9 => "září",
    10 => "října",
    11 => "listopadu",
    12 => "prosince"
);

# }}}

# {{{ year_to_say            export

sub year_to_say :Export {
    my $year = shift // return;

    return if ($year > 2999 or $year < 1);

    (my $tens = $year) =~ s/^.*(\d\d)$/$1/;
    my $hundreds = "";
    if( $year < 10 ) {
        $tens = "";
        $hundreds = $cipher{$year} || "null";
    } else {
        if( $tens == 0 ) {
            $tens = "";
        } elsif( ($tens % 10) == 0 ) {
            $tens =~ s/(.)(.)/$tens{$1}/;
        } else {
            if( $tens < 10 ) {
                $tens =~ s/(.)(.)/$cipher{$2}/;
            } elsif( $tens < 20 ) {
                $tens =~ s/(.)(.)/$cipher{$1.$2}/;
            } else {
                $tens =~ s/(.)(.)/$tens{$1}." ".$cipher{$2}/e;
            }
        }
        if( $year >= 100 ) {
            ($hundreds = $year) =~ s/^(.?.)..$/$1/;
            if( $hundreds % 10 == 0) {
                my $thousand = thousand_form($hundreds);
                if($hundreds == 10){
                    $hundreds =~ s/(.)(.)/"tisíc "/ex;
                }else{
                    $hundreds =~ s/(.)(.)/$cipher{$1}." ".$thousand/ex;
                }
            } else {
                if( $hundreds > 10 ) {
                    my $thousand = thousand_form($hundreds);
                    if ($hundreds < 20){
                        my $hundred = hundred_form($hundreds);
                        my($x, $y) = split("", $hundreds);
                        if($y == 1){
                            $hundreds =~ s/(.)(.)/"tisíc sto "/ex;
                        }else{
                            $hundreds =~ s/(.)(.)/"tisíc ".$cipher{$2}." $hundred "/ex;
                        }
                    }else{
                        my $hundred = hundred_form($hundreds);
                        my($x, $y) = split("", $hundreds);
                        if($y == 1){
                            $hundreds = "sto ";
                        }else{
                            $hundreds =~ s/(.)(.)/$cipher{"$1"}." ".$thousand.$cipher{$2}." ".$hundred." "/e;
                        }
                    }
                } else {
                    if($hundreds == 1){
                       $hundreds = "sto ";
                    }else{
                       my $hundred = hundred_form($hundreds);
                       $hundreds = $cipher{$hundreds}." ".$hundred;
                    }
                }
            }
        }
    }
    return $hundreds.$tens;
}

# }}}
# {{{ day_to_say             export

sub day_to_say :Export {
    my $day = shift // return;

    return if ($day > 31 or $day < 1);

    if( $day >= 10 ) {
        $day =~ s/(.)(.)/$specialcipher{"$1$2"} || $specialtens{$1}." ".$specialcipher{$2}/ex;
    } else {
        $day = $specialcipher{$day} || $cipher{$day};
    }
    return $day;
}

# }}}
# {{{ month_to_say           export

sub month_to_say :Export {
    my $month = shift // return;

    return if ($month > 12 or $month < 1);

    return $specialmonths{$month};
}

# }}}
# {{{ date_to_say            export

sub date_to_say :Export {
    my $day   = shift // return;
    my $month = shift // return;
    my $year  = shift // return;

    my $res;

    my $d = day_to_say($day);
    my $m = month_to_say($month);
    my $y = year_to_say($year);

    if( wantarray ) {
        return ($d, $m, $y);
    } else {
        my $res = "$d $m $y";
        $res =~ s/\A(.*) +\z/$1/;;
        return $res;
    }
}

# }}}
# {{{ time_to_say            export

sub time_to_say :Export {
    my($day, $month, $year) = (gmtime( shift || time() ))[3, 4, 5];
    return date_to_say($day, $month + 1, 1900 + $year);
}

# }}}
# {{{ hundred_form           internal

sub hundred_form {
    my($hundreds) = shift;
    my($x, $num) = split(//, $hundreds);
    if($num > 4){
        return "set";
    }elsif($num == 4){
        return "sta";
    }else{
        return "set";
    }
}

# }}}
# {{{ thousand_form          internal

sub thousand_form {
    my($num) = shift;
    if($num > 49){
        return "tisíc ";
    }else{
        return "tisíce ";
    }
}

# }}}

1;

__END__

# {{{ POD

=head1 NAME

Date::Say::Czech - Outputs dates as text as you would speak it

=head1 SYNOPSIS

 use Date::Say::Czech;

 print time_to_say(time());
 print date_to_say($DAY, $MONTH, $YEAR);

 print day_to_say($DAY);
 print month_to_say($MONTH);
 print year_to_say($YEAR);

=head1 DESCRIPTION

This module provides functions to easily convert a date (given
as either integer values for a day, a month and a year or as a unix timestamp)
into the Czech text representation, like you would read it aloud.

=head1 FUNCTIONS

Please, put correct args to all functions, otherwise there is no guarantee
what the result will be.

=over 2

=item B<time_to_say($TIMESTAMP)>

In the scalar context, returns a string consisting of the text
representation of the date in given unix timestamp,
like e.g. "dvacátého pátého června dva tisíce pět".

In list context, returns the three words of the string as the list.

=item B<date_to_say($DAY, $MONTH, $YEAR)>

Takes the values for a day of a month, a month and a year as integers
(month starting with B<1>) and translates them into the Czech
text representation.

=item B<day_to_say($DAY)>

Converts a day number to its Czech text representation.

=item B<month_to_say($MONTH)>

Converts a month number (January = 1 etc.) to its Czech
text representation.

=item B<year_to_say($YEAR)>

Converts a year number to its Czech text representation.

=back

=head1 BUGS

Please report all bugs to the author of this module:
Jiri Vaclavik <my name dot my last name at gmail dot com>

=for html <a href="mailto:jiri.vaclavik@NOSPAMgmailNOSPAM.com?subject=Bug%20in%20Date::Say::Czech">Mail a Bug</a>

=head1 AUTHOR

Jiri Vaclavik <my name dot my last name at gmail dot com>

=head1 SEE ALSO

Date::Spoken::German from Christian Winter

=cut

# }}}
