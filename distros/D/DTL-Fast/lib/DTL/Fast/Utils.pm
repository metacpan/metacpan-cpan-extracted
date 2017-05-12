package DTL::Fast::Utils;
use strict; use utf8; use warnings FATAL => 'all';
use parent 'Exporter';

require Date::Format;
require URI::Escape::XS;

our $VERSION = '1.00';

our @EXPORT_OK;

# @todo what with timezones?
push @EXPORT_OK, 'time2str';
sub time2str
{
    my $format = shift;
    my $time = shift;

    #  TIME_FORMAT, DATE_FORMAT, DATETIME_FORMAT, SHORT_DATE_FORMAT or SHORT_DATETIME_FORMAT

    return Date::Format::time2str($format, $time );
}

push @EXPORT_OK, 'time2str_php';
# the code below has been taken from Dotiac::DTL and should be re-written on C
# would be nice to implement module with this functionality (take from PHP source)
#locale stuff
our @datemonths=qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
our @datemonthl=qw( January February March April May Juni Juli August September October November December );
our @datemontha=qw( Jan. Feb. March April May Juni Juli Aug. Sep. Oct. Nov. Dec. );
our @weekdays=qw/Sun Mon Tue Wed Thu Fri Sat/;
our @weekdayl=qw/Sunday Monday Tuesday Wednesday Thursday Friday Saturday/;
our @timeampm=qw/a.m. p.m. AM PM/;
our @timespotnames=qw/midnight noon/;
our @datesuffixes=qw/th st nd rd/; #qw/Default day1 day2 day3 day4 day5...
sub time2str_php
{
    my $format = shift // "";
    my $time = shift // 0;

    my @t = localtime($time);
    my @s = split //, $format;

    my $res;

    while(my $s = shift @s )
    {
        if ($s eq '\\') {
            $res.=shift(@s);
        }
        elsif ($s eq "a") {
            if ($t[2] > 12 or ($t[2] == 12 and $t[1] > 0)) {
                $res.=$timeampm[0];
            }
            else {
                $res.=$timeampm[1];
            }
        }
        elsif ($s eq "A") {
            if ($t[2] > 12 or ($t[2] == 12 and $t[1] > 0)) {
                $res.=$timeampm[2];
            }
            else {
                $res.=$timeampm[3];
            }
        }
        elsif ($s eq "b") {
            $res.=lc($datemonths[$t[4]]);
        }
        elsif ($s eq "d") {
            $res.=sprintf("%02d",$t[3]);
        }
        elsif ($s eq "D") {
            $res.=$weekdays[$t[6]];
        }
        elsif ($s eq "f") {
            my $h=$t[2];
            $h=$h%12;
            $h=12 unless $h;
            $res.=$h;
            $res.=sprintf(":%02d",$t[1]) if ($t[1]);
        }
        elsif ($s eq "F") {
            $res.=$datemonthl[$t[4]];
        }
        elsif ($s eq "g") {
            my $h=$t[2];
            $h=$h%12;
            $h=12 unless $h;
            $res.=$h;
        }
        elsif ($s eq "G") {
            $res.=$t[2];
        }
        elsif ($s eq "h") {
            my $h=$t[2];
            $h=$h%12;
            $h=12 unless $h;
            $res.=sprintf("%02d",$h);
        }
        elsif ($s eq "H") {
            $res.=sprintf("%02d",$t[2]);
        }
        elsif ($s eq "i") {
            $res.=sprintf("%02d",$t[1]);
        }
        elsif ($s eq "j") {
            $res.=$t[3];
        }
        elsif ($s eq "l") {
            $res.=$weekdayl[$t[6]];
        }
        elsif ($s eq "L") {
            my $d=$t[5]+1900;
            $res.=(((not $d%4 and $d%100) or not $d%400)?"1":"0");
        }
        elsif ($s eq "m") {
            $res.=sprintf("%02d",$t[4]+1);
        }
        elsif ($s eq "M") {
            $res.=$datemonths[$t[4]];
        }
        elsif ($s eq "n") {
            $res.=$t[4]+1;
        }
        elsif ($s eq "N") {
            $res.=$datemontha[$t[4]];
        }
        elsif ($s eq "O") {
            my @tt=localtime(0);
            $tt[2]+=1 if $t[8];
            $res.=sprintf("%+05d",$tt[2]*100+$tt[1]);
        }
        elsif ($s eq "P") {
            if ($t[2] == 12 and $t[1] == 0) {
                $res.=$timespotnames[1];
            }
            elsif ($t[2] == 0 and $t[1] == 0) {
                $res.=$timespotnames[0];
            }
            else {
                my $h=$t[2];
                $h=$h%12;
                $h=12 unless $h;
                $res.=$h;
                $res.=sprintf(":%02d",$t[1]) if ($t[1]);
                if ($t[2] > 12 or ($t[2] == 12 and $t[1] > 0)) {
                    $res.=" ".$timeampm[0];
                }
                else {
                    $res.=" ".$timeampm[1];
                }
            }

        }
        elsif ($s eq "r") {
            $res.=$weekdays[$t[6]];
            $res.=", ";
            $res.=$t[4]+1;
            $res.=" ".$datemonths[$t[4]]." ".($t[5]+1900);
            $res.=sprintf(" %02d:%02d:%02d",$t[2],$t[1],$t[0]);
            my @tt=localtime(0);
            $tt[2]+=1 if $t[8];
            $res.=sprintf(" %+05d",$tt[2]*100+$tt[1]);
        }
        elsif ($s eq "s") {
            $res.=sprintf("%02d",$t[0]);
        }
        elsif ($s eq "S") {
            if ($datesuffixes[$t[3]]) {
                $res.=$datesuffixes[$t[3]];
            }
            else {
                $res.=$datesuffixes[0]
            }
        }
        elsif ($s eq "t") {
            if ($t[4] == 1 or $t[4]==3 or $t[4] == 5 or $t[4] == 7 or $t[4] == 8 or $t[4] == 10 or $t[4] == 12) {
                $res.="31";
            }
            elsif ($t[4] == 2) {
                my $d=$t[5]+1900;
                if ((not $d%4 and $d%100) or not $d%400) {
                    $res.="29";
                }
                else {
                    $res.="28";
                }
            }
            else {
                $res.="30";
            }
        }
        elsif ($s eq "T") {
            require POSIX;
            $res.=POSIX::strftime("%Z", @t);
        }
        elsif ($s eq "t") {
            $res.=$t[6];
        }
        elsif ($s eq "W") {
            require POSIX;
            $res.=POSIX::strftime("%W", @t);
        }
        elsif ($s eq "y") {
            $res.=sprintf("%02d",($t[5]%100));
        }
        elsif ($s eq "Y") {
            $res.=sprintf("%04d",$t[5]+1900);
        }
        elsif ($s eq "z") {
            $res.=$t[7];
        }
        elsif ($s eq "Z") {
            my @tt=localtime(0);
            $tt[2]+=1 if $t[8];
            $res.=$tt[2]*3600+$t[1]*60+$t[0];
        }
        elsif ($s eq "\n") {
            $res.="n";
        }
        elsif ($s eq "\t") {
            $res.="t";
        }
        elsif ($s eq "\f") {
            $res.="f";
        }
        elsif ($s eq "\b") {
            $res.="b";
        }
        elsif ($s eq "\r") {
            $res.="r";
        }
        else {
            $res.=$s;
        }
    }
    return $res;
}
### end of Dotiac::DTL code

#Shortcuts below not working on mswin and perl =< 18.2
push @EXPORT_OK, 'uri_escape';
*DTL::Fast::Utils::uri_escape = \&URI::Escape::XS::uri_escape;

push @EXPORT_OK, 'uri_unescape';
*DTL::Fast::Utils::uri_unescape = \&URI::Escape::XS::uri_unescape;

push @EXPORT_OK, 'escape';
*DTL::Fast::Utils::escape = \&URI::Escape::XS::encodeURIComponent;

push @EXPORT_OK, 'unescape';
*DTL::Fast::Utils::unescape = \&URI::Escape::XS::decodeURIComponent;

push @EXPORT_OK, 'as_bool';
sub as_bool
{
    my $value = shift;
    my $value_type = ref $value;

    if( $value_type )
    {
        if ( $value_type eq 'SCALAR' )
        {
            $value = $$value;
        }
        elsif( $value_type eq 'HASH' )
        {
            $value = scalar keys(%$value);
        }
        elsif( $value_type eq 'ARRAY' )
        {
            $value = scalar @$value;
        }
        elsif( UNIVERSAL::can( $value, 'as_bool' ) )
        {
            $value = $value->as_bool();
        }
    }

    return $value;
}


1;
