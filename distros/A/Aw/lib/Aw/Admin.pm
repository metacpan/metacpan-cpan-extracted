package Aw::Admin;

use strict;
use Carp;
use vars qw($VERSION $VERSION_NAME @ISA @EXPORT @EXPORT_OK $AUTOLOAD $SPAM %DefinedStrings);

$ENV{LD_LIBRARY_PATH} .= ':/opt/active40/lib:/opt/active40/samples/adapter_devkit/c_lib/';


require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	AW_AUTH_TYPE_NONE
	AW_AUTH_TYPE_SSL
	AW_LIFECYCLE_DESTROY_ON_DISCONNECT
	AW_LIFECYCLE_EXPLICIT_DESTROY
	AW_LOG_OUTPUT_NT_EVENT_LOG
	AW_LOG_OUTPUT_SNMP
	AW_LOG_OUTPUT_UNIX_SYSLOG
	AW_LOG_TOPIC_ALERT
	AW_LOG_TOPIC_INFO
	AW_LOG_TOPIC_WARNING
	AW_SERVER_LOG_ALL_ENTRIES
	AW_SERVER_LOG_MESSAGE_ALERT
	AW_SERVER_LOG_MESSAGE_INFO
	AW_SERVER_LOG_MESSAGE_UNKNOWN
	AW_SERVER_LOG_MESSAGE_WARNING
	AW_SERVER_STATUS_ERROR
	AW_SERVER_STATUS_RUNNING
	AW_SERVER_STATUS_STARTING
	AW_SERVER_STATUS_STOPPED
	AW_SERVER_STATUS_STOPPING
	AW_SSL_STATUS_DISABLED
	AW_SSL_STATUS_ENABLED
	AW_SSL_STATUS_ERROR
	AW_SSL_STATUS_NOT_SUPPORTED
	AW_TRACE_BROKER_ADDED
	AW_TRACE_BROKER_REMOVED
	AW_TRACE_CLIENT_CONNECT
	AW_TRACE_CLIENT_CREATE
	AW_TRACE_CLIENT_DESTROY
	AW_TRACE_CLIENT_DISCONNECT
	AW_TRACE_EVENT_DROP
	AW_TRACE_EVENT_ENQUEUE
	AW_TRACE_EVENT_PUBLISH
	AW_TRACE_EVENT_RECEIVE
	AW_TRACE_OTHER
);

$VERSION = '0.16.7';
$VERSION_NAME = 'Dromedary Samurai';
$SPAM = 0;


%DefinedStrings = (
	#
	# Values for the log output code
	#
	AW_LOG_OUTPUT_UNIX_SYSLOG    => "syslog",
	AW_LOG_OUTPUT_NT_EVENT_LOG   => "nteventlog",
	AW_LOG_OUTPUT_SNMP           => "snmptrap",

	#
	# Values for the log topic code
	#
	AW_LOG_TOPIC_ALERT           => "alert",
	AW_LOG_TOPIC_WARNING         => "warning",
	AW_LOG_TOPIC_INFO            => "info",
);


sub import {
my $pkg = shift;

	for ( my $i = 0; $i <= $#_; $i++ ) {
		$SPAM = 0 if ( $_[$i] =~ /^nospam$/i );
	}

 	setDefaultBroker ( @_ ) if ( @_ );
	Aw::Admin->export_to_level (1, $pkg, @EXPORT);  # this works too...
	#
	# Don't do this!  Resetting Exporter::ExportLevel _can_ hose other
	# packages using Exporter (such as POSIX, Data::Dumper).
	#
	# $Exporter::ExportLevel = 1;
	# Exporter::import ($pkg, @EXPORT);
}



sub setDefaultBroker {

	require Aw;
	Aw::setDefaultBroker (@_);

1;
}



sub setSpam {

	$SPAM = $_[0];

}



sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    return ( $DefinedStrings{$constname} )
        if ( exists($DefinedStrings{$constname}) );
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Aw::Admin macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Aw::Admin $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Aw::Admin - Perl extension for the ActiveWorks C Administration Libraries

=head1 SYNOPSIS

 use Aw 'MyFavoriteBroker@my.host.net:6449';
 require Aw::Admin::ServerClient;

 my $desc = new Aw::ConnectionDescriptor;

 my $server = new Aw::Admin::ServerClient ( "my.host.net:6449", $desc );
             #
             # fix new to use default host we've already set..
             #

 my @brokers = $server->getServerBrokers ( );

 foreach ( @brokers ) {
	print "Territory  : $_->{territory_name}\n";
	print "Broker Host: $_->{broker_host}\n";
	print "Broker Name: $_->{broker_name}\n";
	print "Description: $_->{description}\n";
 }

=head1 DESCRIPTION

  A Java like interface to the CADK thru Perl.

=head1 Exported Constants

Everything in the CADK include files I<should> be exported as constants.
  


=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wmUsers.Com|mailto:Yacob@wmUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
