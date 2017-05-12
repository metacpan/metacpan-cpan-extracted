#!./perl
use ARS;
require './t/config.cache';

my $maxtest = 7;
my $c = 1;

# perl -w -Iblib/lib -Iblib/arch t/21setlogging.t 


print "1..$maxtest\n";


my $ctrl = ars_Login( &CCACHE::SERVER, &CCACHE::USERNAME, &CCACHE::PASSWORD, "","", &CCACHE::TCPPORT );

if(!defined($ctrl)) {
	for(my $i = $c ; $i <= $maxtest ; $i++) {
		print "not ok [$i] [ctrl]\n";
	}
	exit 0;
} else {
	print "ok [$c]\n";
}


# test appending log messages to ars_errstr
++$c;
my $ret = ars_SetLogging( $ctrl,
	&ARS::AR_DEBUG_SERVER_SQL | &ARS::AR_DEBUG_SERVER_FILTER | &ARS::AR_DEBUG_SERVER_API );
if( ! $ret ) {
	print "not ok [$c] [$ars_errstr]\n";
} else {
	print "ok [$c]\n";
}


++$c;
ars_CreateEntry( $ctrl, 'ARSperl Test', 2 => 'Demo', 7 => 1, 8 => 'ShortDescription' );
if( $ars_errstr =~ /<API >.*<FLTR>.*<SQL >/s ){
	print "ok [$c]\n";
} else {
	print "not ok [$c]\n";
}



++$c;
$ret = ars_SetLogging( $ctrl, 0 );

if( ! $ret ) {
	print "not ok [$c] [$ars_errstr]\n";
} else {
	print "ok [$c]\n";
}




# test writing log messages to file

my $logfile = 't/test_SetLogging.log';
unlink $logfile if -f $logfile;

++$c;
$ret = ars_SetLogging( $ctrl,
	&ARS::AR_DEBUG_SERVER_SQL | &ARS::AR_DEBUG_SERVER_FILTER | &ARS::AR_DEBUG_SERVER_API,
	$logfile );
if( ! $ret ) {
	print "not ok [$c] [$ars_errstr]\n";
} else {
	print "ok [$c]\n";
}


++$c;
ars_CreateEntry( $ctrl, 'ARSperl Test', 2 => 'Demo', 7 => 1, 8 => 'ShortDescription' );
my $fc;
{
	local $/ = undef;
	open(FD, $logfile) || die "not ok [$c open]\n";
	binmode FD;
	$fc = <FD>;
	close(FD);
}
if( $fc =~ /<API >.*<FLTR>.*<SQL >/s ){
	print "ok [$c]\n";
} else {
	print "not ok [$c]\n";
}



++$c;
$ret = ars_SetLogging( $ctrl, 0 );
if( ! $ret ) {
	print "not ok [$c] [$ars_errstr]\n";
} else {
	print "ok [$c]\n";
}


exit 0;


