# $Id$
use strict;
use Test::More tests => 19;

BEGIN {
    use_ok 'DateTime::Format::Mail';
}

my $class = 'DateTime::Format::Mail';

# Can we format?

{
    my $parse = sub {
	my $type = shift;
	my $obj = shift;
	my $dates = shift || [
	[ 1047278957 => '+0900' => 'Mon, 10 Mar 2003 15:49:17 +0900' ],
	[ 1047278958 => '-0500' => 'Mon, 10 Mar 2003 01:49:18 -0500' ],
	[ 1047192558 => '-0500' => 'Sun,  9 Mar 2003 01:49:18 -0500' ],
	[ 1397018658 => 'Europe/Paris' => 'Wed,  9 Apr 2014 06:44:18 +0200' ],
	[ 1397018658 => 'floating'     => 'Wed,  9 Apr 2014 04:44:18 -0000' ],
	[ 1397018658 => 'GMT'   => 'Wed,  9 Apr 2014 04:44:18 +0000' ],
	[ 1397018658 => 'UTC'   => 'Wed,  9 Apr 2014 04:44:18 +0000' ],
	[ 1397018658 => '+0000' => 'Wed,  9 Apr 2014 04:44:18 +0000' ],
	[ time() => '+1000' => qr{^[A-Z][a-z][a-z],\s[\s\d]\d
	    \s[A-Z][a-z][a-z]\s\d{4}\s\d\d:\d\d:\d\d\s[\+\-]\d{4}$}x ],

	];

	for my $data (@$dates)
	{
	    my ($epoch, $tz, $expected) = @$data;
	    my $dt = DateTime->from_epoch( epoch => $epoch, time_zone => $tz );
	    my $back = $obj->format_datetime( $dt );
	    if (ref $expected eq 'Regexp')
	    {
		like ( $back => $expected,
		    "($type) Format of $epoch ($tz) is $expected" );
	    }
	    else
	    {
		is ( $back => $expected,
		    "($type) Format of $epoch ($tz) is $expected" );
	    }
	}
    };

    $parse->( 'obj', $class->new );
    $parse->( 'class', $class );
}
