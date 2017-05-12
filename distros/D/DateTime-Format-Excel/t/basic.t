# $Id: basic.t,v 1.1 2003/03/21 05:35:58 koschei Exp $
use strict;
use Test::More tests => 62;

BEGIN {
    use_ok 'DateTime::Format::Excel';
}

my $class = 'DateTime::Format::Excel';

# Does new() work properly?
{
    eval { $class->new('fnar') };
    ok( $@ and $@ =~ /takes no param/, "Too many parameters exception" );

    my $obj = eval { $class->new() };
    ok( !$@, "Created object" );
    isa_ok( $obj, $class );

}

# Can we parse?

{
    my $parse = sub {
	my $type = shift;
	my $obj = shift;
	my $dates = shift || [
	    [ 37680	=> '28 02 2003' ] ,
	    [ 1	=> '31 12 1899'	],
	    [ 2	=> '01 01 1900'	],
	    [ 3	=> '02 01 1900' ],
	    [ 4	=> '03 01 1900' ],
	    [ 25569	=> '01 01 1970' ],
	    [ 2958465	=> '31 12 9999' ],
	    [ 60	=> '28 02 1900' ],
	    [ 61	=> '01 03 1900' ],

	];

	for my $data (@$dates)
	{
	    my ($excel, $dmy) = @$data;
	    my $dt = $obj->parse_datetime( $excel );
	    is ( $dt->dmy(' ') => $dmy, "($type) Parse  of $excel is $dmy" );
	    my $back = $obj->format_datetime( $dt );
	    is ( $back => $excel, "($type) Format of $dmy is $excel" );
	}
    };

    $parse->( 'obj', $class->new );
    $parse->( 'class', $class );
    my $mac = $class->new();
    $mac->epoch_mac();
    $parse->( 'mac', $mac => [
	[ 2957003	=> '31 12 9999' ],
	[ 36227		=> '09 03 2003' ],
	[ 1		=> '02 01 1904' ],
	]
    );
}


# Durations
{
    my @durations = qw( 0 1 2 3 100 200 300 4000 );
    my $obj = $class->new;

    for my $duration (@durations)
    {
	my $dobj = $obj->parse_duration( $duration );
	is ( $dobj->delta_days, $duration, "Duration parse : $duration" );
	my $interval = $obj->format_duration( $dobj );
	is ( $interval, $duration, "Duration format: $duration" );
    }
}
