#!/usr/bin/perl -w

# test suite stolen shamelessly from TimeDate distro

# re-stolen from DateTime

BEGIN
{
    return unless $] >= 5.006;

    require utf8; import utf8;
}

use strict;

use Test::More tests => 100;

use DateTime::Incomplete;
use DateTime;

my $locale = 'en_US';  #  ?? "Can't locate DateTime/Locale/en_US.pm in @INC"
$locale = 'undef';
my $dt;
my $params;

while (<DATA>)
{
    chomp;
    next if /^#/;
    if (/^year =>/)
    {
        $params = $_;

        $dt = eval "DateTime::Incomplete->new( $params, time_zone => undef, locale => $locale )";
        next;
    }
    elsif (/^(\w+)/)
    {
        $locale = $1;
        eval "use DateTime::Locale; DateTime::Locale->load('$1');";
        die $@ if $@;

        # Test::More::diag("New locale: $locale\n");

        $dt = eval "DateTime::Incomplete->new( $params, time_zone => 'UTC', locale => '$locale' )";
        next;
    }

    my ($fmt, $res) = split /\t/, $_;

    my $broken = 'marted' . chr(195);
    if ( $fmt eq '%A' && $locale eq 'it' && $] >= 5.006 && $] <= 5.008 )
    {
        ok( 1, "Perl 5.6.0 & 5.6.1 cannot handle Unicode characters in the DATA filehandle properly" );
        next;
    }

    is( $dt->strftime($fmt), $res, "$fmt" );
}

# test use of strftime with multiple params - in list and scalar
# context
{
    my $dt = DateTime::Incomplete->new( year => 1800,
                            month => 1,
                            day => 10,
                            time_zone => 'UTC',
                            locale => 'en',
                          );

    my ($y, $d) = $dt->strftime( '%Y', '%d' );
    is( $y, 1800, 'first value is year' );
    is( $d, 10, 'second value is day' );

    $y = $dt->strftime( '%Y', '%d' );
    is( $y, 1800, 'scalar context returns year' );
}

{
    my $dt = DateTime::Incomplete->new( year => 2003,
                            hour => 0,
                            minute => 0,
                            locale => 'en',
                          ) ;

#     is( $dt->strftime('%I %M %p'), '12 00 AM', 'formatting of hours as 1-12' );
#     is( $dt->strftime('%l %M %p'), '12 00 AM', 'formatting of hours as 1-12' );
# 
#     $dt->set(hour => 1) ;
#     is( $dt->strftime('%I %M %p'), '01 00 AM', 'formatting of hours as 1-12' );
#     is( $dt->strftime('%l %M %p'), ' 1 00 AM', 'formatting of hours as 1-12' );
# 
#     $dt->set(hour => 11) ;
#     is( $dt->strftime('%I %M %p'), '11 00 AM', 'formatting of hours as 1-12' );
#     is( $dt->strftime('%l %M %p'), '11 00 AM', 'formatting of hours as 1-12' );
# 
#     $dt->set(hour => 12) ;
#     is( $dt->strftime('%I %M %p'), '12 00 PM', 'formatting of hours as 1-12' );
#     is( $dt->strftime('%l %M %p'), '12 00 PM', 'formatting of hours as 1-12' );
# 
#     $dt->set(hour => 13) ;
#     is( $dt->strftime('%I %M %p'), '01 00 PM', 'formatting of hours as 1-12' );
#     is( $dt->strftime('%l %M %p'), ' 1 00 PM', 'formatting of hours as 1-12' );
# 
#     $dt->set(hour => 23) ;
#     is( $dt->strftime('%I %M %p'), '11 00 PM', 'formatting of hours as 1-12' );
#     is( $dt->strftime('%l %M %p'), '11 00 PM', 'formatting of hours as 1-12' );
# 
#     $dt->set(hour => 0) ;
#     is( $dt->strftime('%I %M %p'), '12 00 AM', 'formatting of hours as 1-12' );
#     is( $dt->strftime('%l %M %p'), '12 00 AM', 'formatting of hours as 1-12' );
}


# add these if we do roman-numeral stuff
# %Od	VII
# %Oe	VII
# %OH	XIII
# %OI	I
# %Oj	CCL
# %Ok	XIII
# %Ol	I
# %Om	IX
# %OM	II
# %Oq	III
# %OY	MCMXCIX
# %Oy	XCIX

__DATA__
year => undef
%y	xx
%Y	xxxx
%%	%
%a	xxx
%A	xxxxx
%b	xxx
%B	xxxxx
%C	xx
%d	xx
%e	 x
%D	xx/xx/xx
%h	xxx
%H	xx
%I	xx
%j	xxx
%k	xx
%l	 x
%m	xx
%M	xx
%N	xxxxxxxxx
%3N	xxx
%6N	xxxxxx
%10N	xxxxxxxxxx
# %p	xx
# %r	xx:xx:xx xx
%R	xx:xx
# %s	xxxxxx - epoch returns today()
%S	xx
%T	xx:xx:xx
%U	xx
%w	x
%W	xx
%y	xx
%Y	xxxx
%Z	xxxxx
%z	xxxxx
%{month}	xx
%{year}	xxxx
%x	xxxx-xx-xx
%X	xx:xx:xx
%c	xxxx-xx-xxTxx:xx:xx
year => 1999, month => 9, day => 7, hour => 13, minute => 2, second => 42, nanosecond => 123456789.123456
de
%y	99
%Y	1999
%%	%
# %a	Di.
%A	Dienstag
# %b	Sep.
%B	September
%C	19
%d	07
%e	 7
%D	09/07/99
# %h	Sep.
%H	13
%I	01
%j	250
%k	13
%l	 1
%m	09
%M	02
# %p	nachm.
# %r	01:02:42 nachm.
%R	13:02
# %s	936709362   -- epoch is not implemented
%S	42
%T	13:02:42
%U	36
%w	2
%W	36
%y	99
%Y	1999
%Z	UTC
%z	+0000
%{month}	9
%{year}	1999
it
%y	99
%Y	1999
%%	%
%a	mar
%A	martedì
%b	set
%B	settembre
%C	19
%d	07
%e	 7
%D	09/07/99
%h	set
%H	13
%I	01
%j	250
%k	13
%l	 1
%m	09
%M	02
# %p	p.
# %r	01:02:42 p.
%R	13:02
# %s	936709362   -- epoch is not implemented
%S	42
%T	13:02:42
%U	36
%w	2
%W	36
%y	99
%Y	1999
%Z	UTC
%z	+0000
%{month}	9
%{year}	1999
