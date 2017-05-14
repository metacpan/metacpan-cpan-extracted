package Arc;

use strict;
use warnings;
use Sys::Syslog;
use Exporter;

use constant LOG_AUTH	=> 1;
use constant LOG_USER	=> 2;
use constant LOG_ERR	=> 4;
use constant LOG_CMD	=> 8;
use constant LOG_SIDE	=> 16;
use constant LOG_DEBUG	=> 32;

use vars qw($VERSION $ConfigPath $DefaultPort $DefaultHost $Copyright $Contact @ISA @EXPORT_OK $DefaultPIDFile);

@ISA = qw(Exporter);

@EXPORT_OK = qw(LOG_AUTH LOG_USER LOG_ERR LOG_CMD LOG_SIDE LOG_DEBUG);

$VERSION = '1.05';
$ConfigPath = "/etc/arcx";
$DefaultPort = 4242;
$DefaultHost = "arcdsrv";
$DefaultPIDFile = "/var/run/arcxd.pid";

$Copyright = "ARCv2 $VERSION (C) 2003-5 Patrick Boettcher and others. All right reserved.";
$Contact = "Patrick Boettcher <patrick.boettcher\@desy.de>, Wolfgang Friebel <wolfgang.friebel\@desy.de>";

my @syslog_arr = ('emerg','alert','crit','err','warning','notice','info','debug');

# package member vars
sub members
{
	return {
		# private:
		# protected:
			_error => undef, # contains the error message
			_syslog => 1,    # log to syslog or to STDERR
		# public:
			loglevel => 7,              # loglevel is combination of bits (1=AUTH,2=USER,4=ERR,8=CMDDEBUG,16=VERBSIDE,32=DEBUG) see _Log method
			logfileprefix => "",        # Prepended to every log entry
			logdestination => 'syslog', # Where should all the log output go to ('stderr','syslog')
	};
}

## Constructor. 
## Initializes the object and returns it blessed.
## For all sub classes, please override C<_Init> to check the 
## parameter which are passed to the C<new> function. This
## is necessary because you are not able to call the the new method of a
## parent class, when having a class name (new $class::SUPER::new, does not work.).
##in> %hash, key => val, ...
##out> blessed object of the class
##eg> my $this = new Arc::Class ( key => value, key2 => value2 );
sub new
{
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = bless { },$class;
	$self->_Init(@_);

	return $self;
}

## Init function (initializes class context)
## Module dependent initialization, every subclass shall override it
## and call the _Init of its SUPER class. This method is called by the new method of C<Arc>.
##in> %hash, key => val, ...
##out> true, if all passed values are in their definition scope, otherwise false
##eg> see source code of any non-abstract sub class of Arc
sub _Init
{
	my $this = shift;
	my (%values) = @_;
	my $members = $this->members;

	while (my ($key,$val) = each(%$members)) {
		$this->{$key} = exists($values{$key}) ? $values{$key} : $val;
		delete $values{$key};
	}

	croak("Ignored values at object-creation (this is probably not what you want): ",join(" ",keys (%values))) if keys %values;
	
	# loglevel
	$this->{loglevel} = 4 if not defined $this->{loglevel};

	$this->{_syslog} = ! (defined $this->{logdestination} && $this->{logdestination} eq "stderr");

	openlog("arcv2","cons,pid","user") if $this->{_syslog};
	
	1;
}

## Debug function.
## Logs messages with "DEBUG" 
##in> ... (message)
##out> always false
##eg> $this->_Debug("hello","world"); # message will be "hello world"
sub _Debug
{
	my $this = shift;
	$this->Log(LOG_DEBUG,@_);
}

## Log function.
## Logs messages to 'logdestination' if 'loglevel' is is set appropriatly.
## loglevel behaviour has changed in the 1.0 release of ARCv2, the "Arc"-class can export
## LOG_AUTH (authentication information), LOG_USER (connection information), LOG_ERR (errors), 
## LOG_CMD (ARCv2 addition internal command information), LOG_SIDE (verbose client/server-specific
## information), LOG_DEBUG (verbose debug information). It possible to combine the 
## levels with or (resp. +) to allow a message to appear when not all loglevels are 
## requested by the user.
## Commonly used for logging errors from application level.
##in> $facility, ... (message)
##out> always false
##eg> return $arc->Log(LOG_ERR,"Message");
sub Log
{
	my $this = shift;
	my $pr = shift;
	my $ll = $this->{loglevel};
	my $lev = 1;
	my @syslog_arr = ('err','info','debug');
	
	$lev = 0 if $pr & LOG_ERR;
	$lev = 2 if $pr & LOG_DEBUG;

	if ($pr & $this->{loglevel}) {
		if ($this->{_syslog}) {
			syslog $syslog_arr[$lev], $this->{logfileprefix}." ".join(" ",@_);
		} else {
			print STDERR "[",$syslog_arr[$lev],"]: (",$this->{logfileprefix},") ",join(" ",@_),"\n";
		}
	}
	return;
}

## SetError function.
## This function prepends the error message (@_) to an existing error message (if any) and
## logs the message with LOG_ERR facility.
## Use this function for setting an error from class level. Users should use IsError 
## to get the message if a function failed.
##in> ... (message) 
##out> always false
##eg> return $this->_SetError("User is not allowed to do this."); # breaks when an error occured
sub _SetError
{
	my $this = shift;
	$this->Log(LOG_ERR,@_);
	
	my $errstr = "";
	if ($this->{_error}) {
		$errstr = ' maybe caused by: '.$this->{_error};
	}
	unless (@_) {
		$errstr .= 'Error, but no message.';
	} else {
		$errstr = join(" ",@_).$errstr ;
	}
	$errstr =~ s/\r//g;
	$errstr =~ s/\n/ /g;
	$this->{_error} = $errstr;
	return;
}

## User function to get the error msg.
##out> the error message if any otherwise undef
##eg> unless (my $err = $arc->IsError()) { .. } else { print STDERR $err; }
sub IsError
{
	my $this = shift;
	my $ret = $this->{_error};
	
	$this->{_error} = undef;
	
	return $ret;
}

## Destructor
sub DESTROY {
	my $this = shift;
	closelog() if $this->{_syslog};
}

1;
