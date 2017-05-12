# $Id: basic.t,v 1.1 2003/03/21 05:35:58 koschei Exp $
# modified by jandrew 2014-4-16
BEGIN{
	$ENV{PERL_TYPE_TINY_XS} = 0;
	#~ $ENV{ Smart_Comments } = '###';
}
if( $ENV{Smart_Comments} ){
	use Smart::Comments -ENV;
	### Smart-Comments turned on for DateTimeX-Format-Excel original basic ...
}
use strict;
use Test::More tests => 22;# Old 62;
use lib '../../../lib';
use DateTimeX::Format::Excel;
my $class = 'DateTimeX::Format::Excel';

{
    #~ my $parse = sub {
	my	$parser = $class->new();
	my	$type = $parser->get_system_type;
	#~ my $obj = shift;
	my $dates = [
	    [ 37680	=> '28 02 2003' ] ,
	    #[ 0 => '01 01 1900' ],#0 doesn't round trip since DateTime doesn't recognize 00 01 1900
	    [ 1	=> '01 01 1900'	],#DateTime Excel gives 31 12 1899
	    [ 2	=> '02 01 1900'	],#DateTime Excel gives 01 01 1900
	    [ 3	=> '03 01 1900' ],#DateTime Excel gives 02 01 1900
	    [ 4	=> '04 01 1900' ],#DateTime Excel gives 03 01 1900
	    [ 25569	=> '01 01 1970' ],
	    [ 2958465	=> '31 12 9999' ],
	    #[ 60 => '28 02 1900' ],#Excel reads this as 29 02 1900 (Not a real date)
	    [ 61	=> '01 03 1900' ],

	];
	for my $data (@$dates)
	{
	    my ($excel, $dmy) = @$data;
	    my	$dt = $parser->parse_datetime( $excel );
	    is ( $dt->dmy(' ') => $dmy, "($type) Parse  of $excel is $dmy" );
	    my $back = $parser->format_datetime( $dt );
	    is ( $back => $excel, "($type) Format of $dmy is $excel" );
	}
	$parser->set_system_type( 'apple_excel' );
    #~ $parse->( 'obj', $class->new );#Old setup4
    #~ $parse->( 'class', $class );
    #~ my $mac = $class->new();
    #~ $mac->epoch_mac();
    $dates = [
	[ 2957003	=> '31 12 9999' ],
	[ 36227		=> '09 03 2003' ],
	[ 1			=> '02 01 1904' ],
	];
	for my $data (@$dates)
	{
	    my ($excel, $dmy) = @$data;
	    my	$dt = $parser->parse_datetime( $excel );
	    is ( $dt->dmy(' ') => $dmy, "($type) Parse  of $excel is $dmy" );
	    my $back = $parser->format_datetime( $dt );
	    is ( $back => $excel, "($type) Format of $dmy is $excel" );
	}
}


# Durations (now handled by DateTime
#~ {
    #~ my @durations = qw( 0 1 2 3 100 200 300 4000 );
    #~ my $obj = $class->new;

    #~ for my $duration (@durations)
    #~ {
	#~ my $dobj = $obj->parse_duration( $duration );
	#~ is ( $dobj->delta_days, $duration, "Duration parse : $duration" );
	#~ my $interval = $obj->format_duration( $dobj );
	#~ is ( $interval, $duration, "Duration format: $duration" );
    #~ }
#~ }
