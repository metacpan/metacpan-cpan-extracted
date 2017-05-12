#
# $Id: mx-config.pl,v 0.1 2001/04/22 17:57:05 ram Exp $
#
# CGI::MxScreen dynamic configuration
#
# HISTORY
# $Log: mx-config.pl,v $
# Revision 0.1  2001/04/22 17:57:05  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

$libpath = "$bindir";
$fatals_to_browser = 1;

$disable_upload = 1;
$post_max = 512 * 1024;	# 512 kb

$datum_config = "debug.cf";
$datum_on = 0;

$logdir = "$bindir/../logs";
$logfile = "mx.err";	# For CGI::Carp, since we also define $logchannels

#
# loglevel
#
#   Specify the loglevel for tracing (DTRACE) when the debug mode of
#   Carp::Datum is turned off.
#   Possible values are: 
#     emergency, alert, critical, error, warning, notice, info, debug
#
#  (See Log::Agent(3) for further details).
#
$loglevel = "notice";
$logdebug = "warn";
$logchannels = {
	'debug'		=>	"%s.dbg",
	'output'	=>  "mx.out",
	'error'		=>  $logfile,
};

$log_maxsize = 10_000_000;
$log_maxtime = "1w";
$log_single_host = 1;	# Logfiles always accessed from same host
$log_backlog = 7;		# Amount of backlog to keep

$mx_logfile = "mx.log";
$mx_loglevel = "debug";
$mx_check_vars = 1;		# Guard against access to unknown keys in screen vars
$mx_buffer_stdout = 1;	# Buffer stdout

$mx_medium = ["+File", -directory => "$bindir/../sessions"];
$mx_serializer = ["+Storable", -shared => 0, -compress	=> 1];

$cgi_carpout = 1;
$view_source = 1;

1;

