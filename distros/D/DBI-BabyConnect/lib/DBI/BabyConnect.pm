package DBI::BabyConnect;

use strict;
use Carp;
use warnings;

use DBI;
use Time::HiRes ();
use Time::localtime; # needed for iso_date() function


our @ISA = qw();
our $VERSION = '0.93';

#BEGIN{ $0 =~ /(.*)(\\|\/)/; push @INC, $1 if $1; }

# DEPRECATED: THE CONFIGURATION DATA IS READ FROM >>>>>>>>>>.. VS_CONFIG.PM
#    /usr/lib/perl5/site_perl/5.8/VS_HOME.pm
#use VS_CONFIG;
#use constant DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING => VS_CONFIG::DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING;
#my $DATABASE_CONFIGURATION_DIR = VS_CONFIG::DB_CONFIG_DIR;
#my $SCHEMA_REPOS               = VS_CONFIG::CONFIG_DIR . '/SQL/TABLES';


#The following signals have been redefined in the IO Section in this file
#$SIG{__DIE__} = sub { print STDERR "DIE: $_[0]" };
#$SIG{__WARN__} = sub { print STDERR "WARN: $_[0]" };

# This is an internal flag that enforces the connection/disconnection
#use constant CALLER_DISCONNECT => 1;

# This is an internal flag used by the author to enable debug
# info when ending this class
#use constant PRT_CEND => 0;


# to monitor the internal state of a BabyConnect object handle (during run time)
# and setting the state to ISTATE_CRISIS allows to build a logical plan
# of execution to know what to do next (i.e. when ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT)
use constant ISTATE_UNDEF  => 0;
use constant ISTATE_GOOD   =>  1;
use constant ISTATE_CRISIS => -1;

# The $SKELETON is a struc to hold basic skeletal table by database type
# and it is used by many of the author applications, for example when
# creating dynamic table for webProcessors (Varisphere Processing Server)

use constant SKELETON_MYSQL => <<SKELETON_MYSQL;
drop table <<<TABLENAME>>>
~
CREATE TABLE <<<TABLENAME>>> (
ID bigint(20) unsigned NOT NULL AUTO_INCREMENT,
LOOKUP varchar(14) default NULL,
<<<ATTRIBUTES>>>
RECORDDATE_T timestamp(14) NOT NULL,
PRIMARY KEY (ID), UNIQUE KEY ID (ID) ) TYPE=MyISAM

SKELETON_MYSQL

use constant SKELETON_ORA => <<SKELETON_ORA;

drop trigger BIR_<<<TABLENAME>>>
~
drop sequence <<<TABLENAME>>>_SEQ
~
drop table <<<TABLENAME>>>

~
create table <<<TABLENAME>>> (
ID number(20) NOT NULL,
LOOKUP varchar(14) DEFAULT NULL,
<<<ATTRIBUTES>>>
RECORDDATE_T timestamp NOT NULL
)

~
-- create a sequence
create sequence <<<TABLENAME>>>_SEQ

~
-- do not forget the ; at the end of the trigger
create trigger BIR_<<<TABLENAME>>>
before insert on <<<TABLENAME>>>
for each row
begin
    select <<<TABLENAME>>>_SEQ.nextval into :new.ID from dual;
end;

~alter table <<<TABLENAME>>> add constraint <<<TABLENAME>>>_PK primary key(ID)
SKELETON_ORA

my $SKELETON = 
{
	ora => SKELETON_ORA,
	mysql => SKELETON_MYSQL,
};


# export BABYCONNECT=/opt/DBI-BabyConnect/configuration
my $ENV_BABYCONNECT = $ENV{BABYCONNECT};
$ENV_BABYCONNECT ||= "./configuration";

my $DATABASE_CONFIGURATION_DIR = $ENV_BABYCONNECT . "/dbconf";
my $SCHEMA_REPOS               = $ENV_BABYCONNECT. '/SQL/TABLES';

die "
Cannot read configuration directory: $ENV_BABYCONNECT!
You may have not set the BABYCONNECT environment variable. You need
to set and export the environment variable BABYCONNECT to point to the
directory where your configuration files reside. For example:
    export BABYCONNECT=/opt/DBI-BabyConnect-0.93/configuration
If you are using Apache::BabyConnect then you need to export the
environment variable prior to loading this module, for example:
    PerlSetEnv BABYCONNECT /opt/DBI-BabyConnect-0.93/configuration
    PerlRequire /opt/DBI-BabyConnect-0.93/startupscripts/babystartup.pl

Refer to the documentation of this module to understand how the 
configuration directory is structured.

" unless -d $ENV_BABYCONNECT;

die "
now I am using the environment variable BABYCONNECT as being set to: $ENV_BABYCONNECT
but I do not seem be able o locate the database configuration directory: $DATABASE_CONFIGURATION_DIR

" unless -d $DATABASE_CONFIGURATION_DIR;

#die "Cannot read the ..." unless -d $SCHEMA_REPOS;


# a set of parameters that will affect the whole behavior of a BabyConnect object
my @xprm = 
	qw(
		DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING 
		CALLER_DISCONNECT 
		ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT
		ENABLE_STATISTICS_ON_DO
		ENABLE_STATISTICS_ON_SPC
		PRT_CEND 
	);

my %xprm = map{$_=>0}@xprm;


{
	# if the globalconf.pl is found then parse its parameters
	my $file = "$DATABASE_CONFIGURATION_DIR/globalconf.pl";
	if (-f $file) {
		open (F, "<$file") || die __PACKAGE__, " EXITING BECAUSE CANNOT OPEN THE GLOBAL CONFIG FILE $file!\n";
		while(<F>) { 
			s/\r//;  s/\n//;
			next if ($_ =~ /^#/) || ($_ =~ /^$/);
			my ($l,$r) = split(/=/,$_);
			# attn, if a param is redefined then will pick on the last one read
			foreach my $p ( @xprm ) {
				($l eq $p) && ($xprm{$p} = $r);
			}
		}
		close F;
	}
}

# $db_ref hold a reference to a set of DB identifiers called descriptors.
# When using Apache::BabyConnect, the programmer will use these descriptors to effectively
# cache instances of DBI::BabyConnect objects, since it is simpler to keep
# track of what he is doing.
my $db_ref;
{
# TODO: glob all *.conf files and build the $db_ref
	my $file = "$DATABASE_CONFIGURATION_DIR/databases.pl";
	if (! -f $file) {
		$db_ref = {};
		# it is not nevessary to have the databases.pl file.
		#die __PACKAGE__, " EXITING BECAUSE CANNOT FIND FILE $file!\n";
	}
	else {
		# if there is such a databases.pl file, then try to open it
		open (F, "<$file") || die __PACKAGE__, " EXITING BECAUSE CANNOT OPEN THE DATABASE DESCRIPTORS FILE $file!\n";
		my $s; while(<F>) { $s .= $_; } close F;
		$db_ref = eval $s;
		if ($@) {
			die "
I located the file $file
and tried to evaluate it as being a Perl struct
bu the eval failed with the following error:
$@

";
		}
	}
}

# glob $ENV{CONFIG}/db_ref/*.conf and get a hash
# mapping descriptor-file-name to fully-specified-file-name
my %dbR;
{
	#my $baseDir = $ENV{CONFIG} || '/app/lcdbdev/config';
	my $baseDir = $DATABASE_CONFIGURATION_DIR;
	my(@files)=glob("$baseDir/*.conf");
	foreach my $f (@files) {
		my $dsc = $f;
		$dsc =~ s/^$baseDir\///;
		$dsc =~ s/\.conf$//;
		$dbR{$dsc} = $f;
	}
}



# a dbiParams object that is set to default values
# but can be overwritten when parsing the 
# config file (_confFromFile) or loading the config 
# object (_confFromObject called via reconnect() )
##my $Driver = "mysql";
##my $Server = "";

my $dbiParams = {
	Driver => "",
	Server => "",
	UserName => "",
	Password => "",
	DataName => "",

#	Driver => "mysql",
#	Server => "",
#	UserName => "dadada",
#	Password => "dedede",
#	DataName => "testdb",

#	PrintError => 0,
#	RaiseError => 0,
#	AutoCommit => 1,
#	AutoRollback => 1, # handled within this class
#	LongTruncOk=>1,
#	LongReadLen=>900000,

	#Connections = 1,
	#PollingInterval = 5000,
};

# The database handle attributes are defined within the
# object $dbiLags. These attributes can be passed when
# getting an initial db handle from the DBI, except for
# the AutoRollback attribute whose behavior is programmed
# within this class.
my $dbiLags =
{
	PrintError => 0,
	RaiseError => 0,
	AutoCommit => 0, # when this is 0 then rollback is possible, otherwise it is ineffective
	AutoRollback => 1, # handled within this class
	LongTruncOk=>1,
	LongReadLen=>900000,
};



sub _no_filter { return $_[0]; }

my $statCC = {};
my $ENABLE_CACHING = 0;
my $PERSISTENT_OBJECT_ENABLED = 0;
sub import {
	my ($class, $enableCaching, $disableDestroy) = @_;
	$enableCaching && ($ENABLE_CACHING = $enableCaching);
	$disableDestroy && ($PERSISTENT_OBJECT_ENABLED = $disableDestroy);
}
# check for the persistent database connection Apache::BabyConnect
#if ($INC{'Apache/BabyConnect.pm'}) {
#	$DBI::BabyConnect::connect_via = "Apache::BabyConnect::connect";
#}
my %CACHED_CONN=();


########################################################################################
########################################################################################
#
sub new {
	my $class = shift;
	my $conf = shift;

	#my %args = @_;


#print STDERR "*** DBI::BabyConnect NEW, ENABLE_CACHING=$ENABLE_CACHING  PERSISTENT_OBJECT_ENABLED=$PERSISTENT_OBJECT_ENABLED  ", caller, "\n";

#my $dbi_connect_method = ($DBI::BabyConnect::connect_via eq "Apache::BabyConnect::connect")
#	? 'Apache::BabyConnect::connect' : 'connect_cached';
#use Apache::BabyConnect;
#if ($DBI::BabyConnect::connect_via eq "Apache::BabyConnect::connect") {
#	##return $dbi_connect_method($conf,%args);
#	foreach my $cn (keys %CACHED_CONN) {
#		if ($cn eq $conf) { 
#			print STDERR "******************** FOUND A CACHED CONNECTION FOR: $cn\n"; 
#			return $CACHED_CONN{$conf};
#		}
#	}
#}
if ($ENABLE_CACHING) {
	my $s1 = $$ . $conf;
	foreach (keys %CACHED_CONN) {
		#print STDERR "[$s1] iCOMPARE\n[$_]\n\n";
		if ($s1 eq $_) {
			#print STDERR "******************** FOUND A CACHED CONNECTION FOR: $$ + $conf with DESCRIPTOR ${$$statCC{$$ . $conf}}{descriptor}\n";
			#print STDERR "****** CACHED CLASS = ${$CACHED_CONN{$$ . $conf}}{class} \n";
			_statCC($$,$conf);
			#return $CACHED_CONN{$conf};
			return ${$CACHED_CONN{$$ . $conf}}{class};
		}
	}
}
#print STDERR " ****************************** MAKING NEW CONNECTION FOR $conf\n";


	my $self = {
	};

	bless $self, ref $class || $class ;

	# We will hold a reference to a hash to cache the configuration data into an object
	# as this is useful when we need to reconnect() in such a situation where a thread is
	# being used. This is useful for a database whose driver does not support sharing
	# connection via threads. Quite typical, that a db will not be able to update concurrently
	# a db record from two different threads. Threads can also run on multiple CPU, but
	# updating a record should be done from a single point ...
	my %_CONF;
	$self->{_CONF}=\%_CONF;


	# getting a connection, from 1 to 4
	# as curly {...}
	if (ref $conf eq 'HASH') {
		$self-> _confFromObject($conf);
	}
	# as a file  '/cygdrive/c/opt/DBI-BabyConnect/configuration/dbconf/WEBPROCESSORS_MYSQL.conf'
	elsif (-f $conf) {
		$self-> _confFromFile($conf);
	}
	# as a reference within our evaled' loaded-hashref (/cygdrive/c/opt/DBI-BabyConnect/configuration/dbconf/databases.pl)
	elsif (exists $$db_ref{$conf}) {
		$self-> _confFromRef($conf);
	}
	# as a lastresort, try as a descriptor (i.e. 'WEBPROCESSORS_MYSQL')
	#elsif (defined $dbR{$conf}) {
	else {
		my ($src_pkg,$src_file,$src_line,$src_meth) = (caller,(caller 1)[3] || '');
		print STDERR "(CALLER)\n\t++ $src_pkg\n\t++ $src_meth\n\t++ $src_file\n\t++ $src_line\n(END)\n";

		die __PACKAGE__,"!! ERROR: NO SUCH DATABASE DESCRIPTOR TO ESTABLISH A CONNECTION [$conf]. PROGRAM EXITING.

AS A LAST RESORT OF GETTING A CONNECTION, CANNOT LOCATE AN OBJECT FOR THAT DESCRIPTOR $conf.
WHEN GETTING A CONNECTION, THE PARAMETER PROVIDED IS VERIFIED IN THE FOLLOWING ORDER:
   1- AS AN OBJECT REFERENCE THAT HOLD THE CONNECTION
   2- AS A CONFIGURATION FILE THAT HOLD THE CONNECTION IF SUCH A FILE EXIST
   3- AS AN IDENTIFIER (ALSO CALLED DESCRIPTOR) TO A DB CONNECTION SAVED IN databases.pl
   4- AS A LAST RESORT, AS A DESCRIPTOR MAPPED INTO THE \$ENV{BABYCONNECT}/dbconf/*.conf

WHEN USING Apache::BabyConnect IT IS RECOMMENDED TO USE THE IDENTIFIER OR DESCRIPTOR AS STRESSED IN (3).
		
		\n" unless $dbR{$conf};
		$self-> _parseDBIAttributesFile($dbR{$conf});
	}

	#TRUE FOR ORACLE ONLY!  die "DATABASE SERVER IS NOT SPECIFIED!\n" unless defined $$dbiParams{Server};

	# Verify that the driver is loadable and get it, yet if it cannot be found then try the ODBC
	{
		my $drv = $$dbiParams{Driver};
		my $driver;
		my @globDBD = DBI->available_drivers;
		# Good way to exit the loop following an assertion. Voila!
		# Try to locate the specified driver
		foreach (@globDBD) { !$driver && ($_ =~ /$drv/i) &&  ($driver = $_); }
		# If the specified driver is not found, then try to load an ODBC
		foreach (@globDBD) { !$driver && ($_ =~ /ODBC/i) &&  ($driver = $_); }
		$driver || die "CANNOT FIND AN ($drv OR ODBC) DRIVER IN ( @globDBD )!\n";
		$$dbiParams{Driver} = $driver;
	}
	$$dbiParams{Server} = "" unless defined $$dbiParams{Server};

{	
	my $dbipath = 'DBI';
	$dbipath .= ':' . $$dbiParams{Driver} if $$dbiParams{Driver};
	$dbipath .= ':' . $$dbiParams{DataName} if $$dbiParams{DataName};
	$dbipath .= ':' . $$dbiParams{Server} if $$dbiParams{Server};
	#my $dbipath = 'DBI:';
	#	. $$dbiParams{Driver} 
	#	. ':' 
	#	. $$dbiParams{DataName} 
	#	. ':' 
	#	. $$dbiParams{Server};

	# use the temporary %dbiHandleAttr, clean the AutoRollback that is programmed in this class
	my %dbiHandleAttr = %$dbiLags;
	delete $dbiHandleAttr{AutoRollback};
	#my $dbiconnection = DBI->connect($dbipath, $$dbiParams{UserName},$$dbiParams{Password}, 
	#	{ RaiseError => $$dbiParams{RaiseError}, PrintError => $$dbiParams{PrintError}, AutoCommit => $$dbiParams{AutoCommit} });


	my $dbiconnection = DBI->connect(
		$dbipath,
		$$dbiParams{UserName},$$dbiParams{Password},
		\%dbiHandleAttr,
	);

	if (!$dbiconnection) 
	{ 
		# This is a critical error, and there is no reason why to continue with this object
		#die "ERROR: ConnectionManager cannot connect to database: $DBI::errstr !\n";

		#warn "ERROR: ConnectionManager cannot connect to database: $DBI::errstr !\n";
		#return undef;
		$self-> _set_connection(undef);
		$self-> _internal_state(ISTATE_UNDEF);
		$self-> state('UNDEF');
		$self-> status($DBI::errstr);
		die "
ERROR: ConnectionManager cannot connect to database: $DBI::errstr!
Make sure that the aimed SQL server is up and running.
";
	}
	else #TODO TODO TODO When we reconnect() we need to set the following as well
	{
		# Set the connection handle for this class, this is the handle
		# for the process instanciating this handle
		#$self->{connection} = $dbiconnection;
		$self-> _set_connection($dbiconnection);
		
		# set a simple Bean to gather info during run-time
		#   (although that can be guessed from %$dbiParams after setup)
		$self-> _set_dbname($$dbiParams{DataName});
		$self-> _set_dbserver($$dbiParams{Server});
		$self-> _set_dbdriver($$dbiParams{Driver});
		$self-> _set_dbusername($$dbiParams{UserName});
		$self-> _set_dbpassword($$dbiParams{Password});

		# these two cannot be varied
		$self-> _set_longtruncok($$dbiLags{LongTruncOk});
		$self-> _set_longreadlen($$dbiLags{LongReadLen});

		# and here goes the Lags
		$self-> raiseerror($$dbiLags{RaiseError});
		$self-> printerror($$dbiLags{PrintError});
		$self-> autocommit($$dbiLags{AutoCommit});
		$self-> autorollback($$dbiLags{AutoRollback});

		# get a copy of the original Lags needed in the function resetLags()
		$self-> {_bk_raiseerror_0} = $$dbiLags{RaiseError};
		$self-> {_bk_printerror_0} = $$dbiLags{PrintError};
		$self-> {_bk_autocommit_0} = $$dbiLags{AutoCommit};
		$self-> {_bk_autorollbak_0} = $$dbiLags{AutoRollback};

		# TODO: added w/o verifying the impact on reconnect!
		# and here goes my special purpose typ_'sub
		$self->{dbb} =
			$$dbiParams{Driver} =~ /Oracle/i ? 'ora' :
			$$dbiParams{Driver} =~ /Mysql/i ? 'mysql' :
			die "UNKNOWN DATA BASE WITH DRIVER $$dbiParams{Driver} IS NOT SUPPORTED!\n";
		#$self->{SKELETON} = $self->{dbb} eq 'ora' ? $SKELETON_ORA : $SKELETON_MYSQL;
		$self->{SKELETON} = $$SKELETON{ $self->{dbb} };
		$self->{SYSDATE}= 
			$self->{dbb} eq 'ora' ? 'SYSDATE' : 'SYSDATE()';
		
		$self-> _internal_state(ISTATE_GOOD);
		$self-> state('CONNECTED');
		$self-> status('CONNECTED');
		$self->{clock0} = Time::HiRes::clock();
		$self->{time0} = [Time::HiRes::gettimeofday];
		#$self->{time0} = time;
		$self->{cumu_conrun} = 0;

		# when the hook is active, one can setup anything within
		# a filter as an anonymous sub (e.g. character filtering,
		# email notification, even a new connection, and much more).
		# TODO have the filter code settable from the global configuration file
	#	$self->{in_filter} = $args{in} || \&_no_filter,
	#	$self->{out_filter} = $args{out} || \&_no_filter,
	}
}

	$ENABLE_CACHING && (${$CACHED_CONN{$$ . $conf}}{class} = $self) && (_statCCreset($$,$conf));
	return $self;
}

##############################################################################
##############################################################################
##############################################################################
#
sub HookTracing {
	my($class) = shift;
	my($deb) = shift;
	my($level) = shift;

	#my(%h) = @_;
	my %h; # filter disabled

	# Hookup tracing if requested
	if ( (defined($deb)) && ($deb ne '') )  {
		#$class->{debhook} = (defined(%h)) ? DBI::BabyConnect::Deb->new(file=>"$deb",%h) : DBI::BabyConnect::Deb->new(file=>"$deb");
		$class->{debhook} = %h ? DBI::BabyConnect::Deb->new(file=>"$deb",%h) : DBI::BabyConnect::Deb->new(file=>"$deb");
		$class->{tracing} = 1;
		# in case we call reconnect()
		$class->{_debfilename} = $deb;
		my $time = iso_date();
		if ($level) {
			my $dbilog = $deb;
			$dbilog =~ s/>{1,}//;
			DBI->trace( $level , "$dbilog");
			$class->{debhook}->print("Started at $time (with DBI trace level set to [$level]\n\n");
			# in case we call reconnect()
			$class->{_tracelevel} = $level;
		}
		else {
			$class->{debhook}->print("Started at $time (without DBI trace level)\n\n");
		}
	}
	else {
		$class->{tracing} = 0;
	}
}


##############################################################################
#
sub HookError {
	my($class) = shift;
	my($errlog) = shift;
#	my($level) = shift;

	#my(%h) = @_;
	my %h; # filter disabled

	# Hookup tracing if requested
	if ( (defined($errlog)) && ($errlog ne '') )  {
		#$class->{debhook} = (defined(%h)) ? DBI::BabyConnect::Deb->new(file=>"$deb",%h) : DBI::BabyConnect::Deb->new(file=>"$deb");
		$class->{errloghook} = %h ? DBI::BabyConnect::Deb->new(file=>"$errlog",%h) : DBI::BabyConnect::Deb->new(file=>"$errlog");
		*STDERR = $class->{errloghook};
		$class->{redirect_error_log} = 1;
#		if ($level) {
#			my $dbilog = $errlog;
#			$dbilog =~ s/>{1,}//;
#			DBI->trace( $level , "$dbilog");
#		}
		my $time = iso_date();
		print STDERR "Started at $time\n";
		# in case we call reconnect()
		$class->{_errfilename} = $errlog;
	}
	else {
		$class->{redirect_error_log} = 0;
	}
}


##############################################################################
##############################################################################
##############################################################################
##############################################################################

#EXPERIMENTAL
##############################################################################
# a DBI::BabyConnect object cache its connection parameter within its object,
# and calling the reconnect() method establishes the connection seemlessly with
# the same parameters.
# reconnect() uses the cached configuration object to re-establish a DBI connection
# similar to new() except that the parameters are read from the cache.
sub reconnect {
	my $class = shift;

	#$class-> _confFromObject($class->{_CONF},\$dbDriver,\$dbServer,\$dbUserName,\$dbPassword,\$dbName,
	#	\$dbPrintError,\$dbRaiseError,\$dbAutoCommit,\$dbConnections,\$dbPollingInterval);
	$class-> _confFromObject($class->{_CONF});

	$$dbiParams{Server} = "" unless defined $$dbiParams{Server};

	my $dbipath = 'DBI:' . $$dbiParams{Driver} . ':' . $$dbiParams{DataName} . ':' . $$dbiParams{Server};
	#my $dbiconnection = DBI->connect("DBI:$dbDriver:$dbName:$dbServer", $dbUserName,$dbPassword, 
	my $dbiconnection = DBI->connect($dbipath, $$dbiParams{UserName},$$dbiParams{Password}, 
		#{RaiseError => $dbRaiseError, PrintError => $dbPrintError, AutoCommit => $dbAutoCommit});
		{ RaiseError => $$dbiParams{RaiseError}, PrintError => $$dbiParams{PrintError}, AutoCommit => $$dbiParams{AutoCommit} });

	if (!$dbiconnection) 
	{ 
		# This is a critical error, and there is no reason why to continue with this object
		#die "ERROR: ConnectionManager cannot connect to database: $DBI::errstr !\n";

		#warn "ERROR: ConnectionManager cannot connect to database: $DBI::errstr !\n";
		#return undef;
		$class-> _set_connection(undef);
		$class-> _internal_state(ISTATE_UNDEF);
		$class-> state('UNDEF');
		$class-> status($DBI::errstr);
	}
	else 
	{
		#$class->{connection} = $dbiconnection;
		$class-> _set_connection($dbiconnection);
		$class-> _internal_state(ISTATE_GOOD);
		$class-> state('CONNECTED');
		$class-> status('CONNECTED');
		#OK: $class->{in_filter} = $args{in} || \&_no_filter,
		#OK: $class->{out_filter} = $args{out} || \&_no_filter,
	}

	# Re-hook in case HookTracing() HookError() have been called on the previous
	# object, and prior to calling reconnect()
	
###my $ccc = [caller]; print " @{$ccc} \n";
###print ">>>>>>>>>>>>>>>>>>>> $class->{_debfilename} ++ $class->{_tracelevel} ========= $dbPassword == $class->{_CONF} \n"; exit;
	$class->HookTracing($class->{_debfilename},$class->{_tracelevel});
	$class->HookError($class->{_errfilename});
	#$class->{tracing} = $class->{tracing};

	# Tracing
	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracing("RECONNECT:\n\n");

	return $class;
}

# CONNECTION ATTRIBUTES FUNCTIONS
##############################################################################
##############################################################################
##############################################################################
##############################################################################

# *getHandleFlags
sub getActiveDescriptor {
	my $class = shift;

	my $bean_flags = @_ ? shift : undef;

	my $wanthash = 0;
	$bean_flags && ($wanthash = 1);
	#$bean_flags ||= {};

	#(ref $rshr eq 'HASH') && (%$rshr = map{$_=>$$statCC{$_}} (keys %$statCC)) && (return $rshr);

#$bean_flags = {
my $t_bean_flags = {
	Driver=>	$class-> dbdriver,
	Server=>	$class-> dbserver,
UserName=> $class-> dbusername,
Password=> $class-> dbpassword,
	DataName=>  $class-> dbname,
	PrintError=>	$class-> printerror,
	RaiseError=>	$class-> raiseerror,
	AutoRollback=>  $class-> autorollback,
	AutoCommit=>	$class-> autocommit,

	LongTruncOk=> $class-> longtruncok,
	LongReadLen=> $class-> longreadlen,

	DBIhandle=>	$class->connection,
	#Connection=>	$class->connection,
	Connection=>	$class,
	###$class->dbilags($dbiLags),
	_internal_state => $class-> _internal_state,
	State=>	$class-> state,
	Status=>	$class-> status,
};
	$wanthash && (%$bean_flags = map{$_=>$$t_bean_flags{$_}} (keys %$t_bean_flags)) && (return $bean_flags);
	#$wanthash && return $bean_flags;
	my $info;
	foreach my $k (keys %$t_bean_flags) {
		$info .= "$k\t $$t_bean_flags{$k}\n";
	}
	return $info;
}

sub saveLags {
	my $class = shift;
#my $bean_flags = {
	$class->{_bk_raiseerror}  =	$class->raiseerror,
	$class->{_bk_printerror}  =	$class->printerror,
	$class->{_bk_autocommit}  =	$class->autocommit,
	$class->{_bk_autorollbak} = $class->autorollback,
	#DataName=>  $class->dbname,
	#Server=>	$class->server,
	#Driver=>	$class->driver,
	#Connection=>	$class->connection,
	###$class->dbilags($dbiLags),
	#_internal_state=>	$class-> _internal_state,
	#State=>	$class-> state,
	#Status=>	$class->status,
#};
}

sub restoreLags {
	my $class = shift;

	$class->raiseerror( $class->{_bk_raiseerror} );
	$class->printerror( $class->{_bk_printerror} );
	$class->autocommit( $class->{_bk_autocommit} );
	$class->autorollback( $class->{_bk_autorollbak} );
	#DataName=>  $class->dbname,
	#Server=>	$class->server,
	#Driver=>	$class->driver,
	#Connection=>	$class->connection,
	###$class->dbilags($dbiLags),
	#_internal_state=>	$class-> _internal_state,
	#State=>	$class->state,
	#Status=>	$class->status,

}

sub resetLags {
	my $class = shift;

	$class->raiseerror( $class->{_bk_raiseerror_0} );
	$class->printerror( $class->{_bk_printerror_0} );
	$class->autocommit( $class->{_bk_autocommit_0} );
	$class->autorollback( $class->{_bk_autorollbak_0} );
}

##############################################################################
#
#connection()

sub connection {
	my $class = shift;
	return $class->{connection};
}
sub _set_connection {
	my $class = shift;
	my $dbiconnection = shift;
	$class->{connection} = $dbiconnection;
}
	
sub _internal_state {
	my $class = shift;
	if (@_)
	{
		my $state = shift;
		$class->{_internal_state} = $state;
	}
	else
	{
		return $class->{_internal_state};
	}
}

# used internally
sub state {
	my $class = shift;
	if (@_)
	{
		my $state = shift;
		$class->{state} = $state;
	}
	else
	{
		return $class->{state};
	}
}
	
sub status {
	my $class = shift;
	if (@_)
	{
		my $status = shift;
		$class->{status} = $status;
	}
	else
	{
		return $class->{status};
	}
}
	
sub dbierror {
	my $class = shift;
	return "DBI ERROR No:", $DBI::err , " -- " ,  $DBI::errstr;
}

sub babyconfess {
	my $class = shift;
	eval { confess('') };
	my @stack = split m/\n/, $@;
	shift @stack for 1..3;
	my $stack = join "\n", @stack;
	return "$stack\n\n";
}


sub raiseerror {
	my $class = shift;
	if(@_) {
		$class->{dbraiseerror} = shift;
	}
	return $class->{dbraiseerror};
}

sub is_RaiseError {
	my $class = shift;
	return $class->raiseerror;
}


sub printerror {
	my $class = shift;
	if(@_) {
		$class->{dbprinterror} = shift;
	}
	return $class->{dbprinterror};
}
 sub is_PrintError
 {
 	my $class = shift;
 	return $class->printerror;
 }


sub autocommit {
	my $class = shift;
	if(@_) {
		$class->{dbautocommit} = shift;
	}
	return $class->{dbautocommit};
}

sub is_AutoCommit {
	my $class = shift;
	return $class->autocommit;
}

sub are_commited {
	my $class = shift;
	die "NOT IMPLEMENTED -- NEED DBI::BabiesTransactionBundle!\n";
}

sub are_rolled {
	my $class = shift;
	die "NOT IMPLEMENTED -- NEED DBI::BabiesTransactionBundle!\n";
}

sub autorollback {
	my $class = shift;
	if(@_) {
		$class->{dbrollback} = shift;
	}
	return $class->{dbrollback};
}
sub is_AutoRollback {
	my $class = shift;
	return $class->autorollback;
}



sub _set_longtruncok {
	my $class = shift;
	if(@_) {
		$class->{longtruncok} = shift;
	}
	return $class->{longtruncok};
}
sub longtruncok {
	my $class = shift;
	return $class->{longtruncok};
}



sub _set_longreadlen {
	my $class = shift;
	if(@_) {
		$class->{longreadlen} = shift;
	}
	return $class->{longreadlen};
}
sub longreadlen {
	my $class = shift;
	return $class->{longreadlen};
}



	
sub _set_dbname {
	my $class = shift;
	if(@_) {
		$class->{dbname} = shift;
	}
	return $class->{dbname};
}
sub dbname {
	my $class = shift;
	return $class->{dbname};
}


sub _set_dbserver {
	my $class = shift;
	if(@_) {
		$class->{dbserver} = shift;
	}
	return $class->{dbserver};
}
sub dbserver {
	my $class = shift;
	return $class->{dbserver};
}

	
sub _set_dbdriver {
	my $class = shift;
	if(@_) {
		$class->{dbdriver} = shift;
	}
	return $class->{dbdriver};
}
sub dbdriver {
	my $class = shift;
	return $class->{dbdriver};
}

sub _set_dbusername {
	my $class = shift;
	if(@_) {
		$class->{dbusername} = shift;
	}
	return $class->{dbusername};
}
sub dbusername {
	my $class = shift;
	return $class->{dbusername};
}
sub _set_dbpassword {
	my $class = shift;
	if(@_) {
		$class->{dbpassword} = shift;
	}
	return $class->{dbpassword};
}
sub dbpassword {
	my $class = shift;
	return $class->{dbpassword};
}



sub _parseDBIAttributesFile {
	my $class = shift;
	my $conf = shift;
	my $line;
	open(F,"$conf") or die "Cannot open the config file ($conf)\n" ;
	while ($line = <F>) {
		$line =~ s/\r//;  $line =~ s/\n//;
		if ( !(($line =~ /^#/) ||  ($line =~ /^$/)) ) {
			my $pos1 = index($line,":"); my $head = substr($line,0,$pos1);
			my $rest = substr($line,$pos1+1,length($line));
			my @parts = split(/,/,$rest);
			foreach (qw(Driver Server UserName Password DataName PrintError RaiseError AutoCommit AutoRollback LongTruncOk LongReadLen)) {
				($head eq $_) && ($$dbiParams{$_} = $parts[0]);
			}
		}
	}
	close(F);
	foreach my $k (keys %$dbiParams) {
		${$class->{_CONF}}{$k} = $$dbiParams{$k};
	}
	foreach my $k (keys %$dbiLags) {
		${$class->{_CONF}}{$k} = $$dbiLags{$k};
	}
}

# PRIVATE! next release
sub getSKELETON {
	my $class = shift;
	return $class->{SKELETON};
}

##############################################################################
# _confFromFile() opens the initial configuration file, and set up the
# config params, and cache these config params within an object.
sub _confFromFile {
	my $class = shift;
	my $conf = shift;

	# %$dbiParams are already set to default, but will be overriden from config file
	my $line;
	open(F,"$conf") or die "Cannot open the config file ($conf)\n" ;
	flock F,1;
	while ($line = <F>) {
		$line =~ s/\r//;  $line =~ s/\n//;
		if ( !(($line =~ /^#/) ||  ($line =~ /^$/)) ) {
			my $pos1 = index($line,":");
			my $head = substr($line,0,$pos1);
			my $rest = substr($line,$pos1+1,length($line));
			my @parts = split(/,/,$rest);
			foreach (qw(Driver Server UserName Password DataName PrintError RaiseError AutoCommit AutoRollback LongTruncOk LongReadLen)) {
				($head eq $_) && ($$dbiParams{$_} = $parts[0]);
			}
			#elsif  ($head eq 'LongReadLen')  { $$dbiLags{LongReadLen} = $parts[0]; }
			###elsif  ($head eq 'Connections')		{ $$dbiParams{Connections} = $parts[0]; }
			###elsif  ($head eq 'PollingInterval')	{ $$dbiParams{PollingInterval} = $parts[0]; }
		}
	}
	close(F);
	foreach my $k (keys %$dbiParams) {
		${$class->{_CONF}}{$k} = $$dbiParams{$k};
	}
	foreach my $k (keys %$dbiLags) {
		${$class->{_CONF}}{$k} = $$dbiLags{$k};
	}

	#${$class->{_CONF}}{Driver} = $dbDriver;
	#${$class->{_CONF}}{Server} = $dbServer;
	#${$class->{_CONF}}{UserName} = $dbUserName;
	#${$class->{_CONF}}{Password} = $dbPassword;
	#${$class->{_CONF}}{DataName} = $dbName;
	#${$class->{_CONF}}{PrintError} = $dbPrintError;
	#${$class->{_CONF}}{RaiseError} = $dbRaiseError;
	#${$class->{_CONF}}{AutoCommit} = $dbAutoCommit;
	#${$class->{_CONF}}{Connections} = $dbConnections;
	#${$class->{_CONF}}{PollingInterval} = $dbPollingInterval;
}

 ##############################################################################
 # () used when calling reconnect() method that is
 # called after the instantiation of the class
 sub _confFromRef {
	my $class = shift;
	my $lookup_db_descriptor = shift;

	die __PACKAGE__, " DATABASE DESCRIPTOR IS NOT DEFINED FOR [$lookup_db_descriptor]. PROGRAM EXITING.

AS A LAST RESORT OF GETTING A CONNECTION, CANNOT LOCATE AN OBJECT FOR THAT DESCRIPTOR $lookup_db_descriptor.
WHEN GETTING A CONNECTION, THE PARAMTER PROVIDED IS VERIFIED IN THE FOLLOWING ORDER:
   1- AS AN OBJECT REFERENCE THAT HOLD THE CONNECTION
   2- AS A CONFIGURATION FILE THAT HOLD THE CONNECTION IF SUCH A FILE EXIST
   3- AS AN IDENTIFIER TO A DB CONNECTION SAVED IN databases.conf
   4- AS A LAST RESORT, AS A DESCRIPTOR MAPPED INTO THE ./dbconf/*.conf

"
		unless $$db_ref{ $lookup_db_descriptor };
	my $conf = $$db_ref{ $lookup_db_descriptor };
	foreach my $k (keys %$dbiParams) {
		$$dbiParams{$k} = $$conf{$k} if defined $$conf{$k};
		# set'em in the class
		${$class->{_CONF}}{$k} = $$dbiParams{$k};
	}
	foreach my $k (keys %$dbiLags) {
		$$dbiLags{$k} = $$conf{$k} if defined $$conf{$k};
		# set'em in the class
		${$class->{_CONF}}{$k} = $$dbiLags{$k};
	}
 }


##############################################################################
# _get_db_config_object() may be needed for debugging
sub _get_db_config_object {
	my $class = shift;
	return %{$class->{_CONF}};
}

##############################################################################
# _confFromObject() used when calling reconnect() method that is
# called after the instantiation of the class 
sub _confFromObject {
	my $class = shift;
	my $conf = shift;

	# %$dbiParams are already set to default, but will be overridden from config file
	##foreach my $k (keys %$dbiDefaultParams) {
	##	$$dbiParams{$k} = $$dbiDefaultParams{$k};
	##}

	# override from conf object
	#foreach my $k (keys %$conf) {
	#	$$dbiParams{$k} = $$conf{$k};
	#}

	# override from conf object
	foreach my $k (keys %$dbiParams) {
		$$dbiParams{$k} = $$conf{$k} if defined $$conf{$k};
		# set'em in the class
		${$class->{_CONF}}{$k} = $$dbiParams{$k};
	}
	# override from conf object
	foreach my $k (keys %$dbiLags) {
		$$dbiLags{$k} = $$conf{$k} if defined $$conf{$k};
		# set'em in the class
		${$class->{_CONF}}{$k} = $$dbiLags{$k};
	}

}


# IO Section
########################################################################################
########################################################################################
########################################################################################
########################################################################################
sub _traceln {
	my $class = shift;
	my $s = shift;
	return unless $class->{debhook};
	$class->{debhook}->print("$s");
}

$SIG{__DIE__} = sub {
#print STDERR "DIE: $_[0]" 
	my $s = shift;
	my ($cur_pkg,$cur_file,$cur_line,$cur_meth) = (caller, (caller 1)[3] || '');
	#my ($src_pkg,$src_file,$src_line,$src_meth) = @_ ? @_ : (undef,undef,undef,undef)
	#my ($src_pkg,$src_file,$src_line,$src_meth) = (caller, (caller 2)[3]);

	my $time = iso_date();
	print STDERR "\n\nDIE =================================== $time \n";
	print STDERR "msg=". $s."\n";
	print STDERR "\t++ $cur_pkg\n\t++ $cur_meth\n\t++ $cur_file\n\t++ $cur_line\n(END)\n";
	#$src_pkg && print STDERR "\n\t++ $src_pkg\n\t++ $src_meth\n\t++ $src_file\n\t++ $src_line\n";
	#print STDERR "DBI STATUS: DBI::err=\t".$DBI::err."\n\t DBI::errstr=:\t".$DBI::errstr."\n\t DBI LED=\t".$DBI::state."\n\n";

	eval { confess('') };
	my @stack = split m/\n/, $@;
	shift @stack for 1..3;
	my $stack = join "\n", @stack;
	print STDERR $stack,"\n\n";
};

$SIG{__WARN__} = sub {
#print STDERR "WARN: $_[0]" 
	my $s = shift;
	my ($cur_pkg,$cur_file,$cur_line,$cur_meth) = (caller, (caller 1)[3] || '');
	#my ($src_pkg,$src_file,$src_line,$src_meth) = (caller, (caller 0)[3]);

	my $time = iso_date();
	print STDERR "WARN =================================== $time \n";
	print STDERR "msg=" , $s ,"\n";
	print STDERR "\t++ $cur_pkg\n\t++ $cur_meth\n\t++ $cur_file\n\t++ $cur_line\n(END)\n";
	#print STDERR "++ $src_pkg\n++ $src_meth\n++ $src_file\n++ $src_line\n";
	#print STDERR "DBI STATUS: DBI::err=\t".$DBI::err."\n\t DBI::errstr=:\t".$DBI::errstr."\n\t DBI LED=\t".$DBI::state."\n\n";
};

# when calling w/o beginning and ending, use this _tracing
sub _tracing {
	my $class = shift;
	my $cumu_conrun = $class->{cumu_conrun};
	return unless $class->{debhook};
	#return unless $class->{tracing};
	#if ($class->{tracing} ) {
	my $s = shift;
	my ($cur_pkg,$cur_file,$cur_line,$cur_meth) = (caller, (caller 1)[3] || '');
	my ($src_pkg,$src_file,$src_line,$src_meth) = @{$class->{src}};

	my $time = iso_date();
	$class->{debhook}->print("=================================== $time (CUMU: $cumu_conrun)\n");
	$class->{debhook}->print("msg=".$s."\n");
	$class->{debhook}->print("\t++ $cur_pkg\n\t++ $cur_meth\n\t++ $cur_file\n\t++ $cur_line\n");
	$class->{debhook}->print("\t++ $src_pkg\n\t++ $src_meth\n\t++ $src_file\n\t++ $src_line\n");
	#$class->{debhook}->print("DBI STATUS: DBI::err=\t$DBI::err\n\t DBI::errstr=:\t$DBI::errstr\n\t DBI LED=\t$DBI::state\n\n");
	$class->{debhook}->print("\tDBI STATUS: DBI::err=\t".$DBI::err."\n\t DBI::errstr=:\t".$DBI::errstr."\n\t DBI LED=\t".$DBI::state."\n");
	$class->{debhook}->print("(END)\n\n");
}


#beginning a trace
sub _tracingB {
	my $class = shift;
	my $cumu_conrun = $class->{cumu_conrun};
	# return unless this hook is enabled
	return unless $class->{debhook};
	my $s = shift;
	my ($cur_pkg,$cur_file,$cur_line,$cur_meth) = (caller, (caller 1)[3] || '');
	my ($src_pkg,$src_file,$src_line,$src_meth) = @{$class->{src}};

	my $time = iso_date();
	$class->{debhook}->print("=================================== $time (CUMU: $cumu_conrun)\n");
	$class->{debhook}->print("msg=".$s."\n");
	$class->{debhook}->print("\t++ $cur_pkg\n\t++ $cur_meth\n\t++ $cur_file\n\t++ $cur_line\n");
	$class->{debhook}->print("\t++ $src_pkg\n\t++ $src_meth\n\t++ $src_file\n\t++ $src_line\n");
}

# closing a trace
sub _tracingE {
	my $class = shift;
	# return unless this hook is enabled
	return unless $class->{debhook};
	my $cumu_conrun = $class->{cumu_conrun};
	my $s = shift;
	my $time = iso_date();
	$class->{debhook}->print("\n$s\n($time (CUMU: $cumu_conrun)\n(END)\n\n");
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################


########################################################################################
# Creating tables dynamically during the product runtime is vital for the application.
# For this reason, this class provides two useful functions that allow the creation
# of database tables: 
#    recreateTable to create table reading'em from $DATABASE_CONFIGURATION_DIR .  '/SQL/TABLES/'
#    recreateTableFromString to create table from input string
#

# recreateTable() drops (silently) the table first, then it will recreate the table.
#   the table dll is found in the $ENV{BABYCONNECT}/SQL/TABLES
sub recreateTable {
my $class=shift;
my $SCHEMA_TABLENAME = shift;
my $TABLENAME = shift;
my $ATTRIBUTES = @_ ? shift : undef;

	#my $SCHEMA_FILENAME = $DATABASE_CONFIGURATION_DIR .  '/SQL/TABLES/' . $SCHEMA_TABLENAME;
	my $SCHEMA_FILENAME = $SCHEMA_REPOS . '/' . $SCHEMA_TABLENAME;
	my $dbtablespec;
	open(F,"<$SCHEMA_FILENAME") || die "ERROR: Cannot open table file $SCHEMA_FILENAME!\n";
	# remove all comments, these are lines starting with --
	while(<F>) {
		next if $_ =~ /^\s*--/;
		$dbtablespec .= $_;
	}
	close(F);
	$dbtablespec .= "\n";

	$SCHEMA_TABLENAME = $TABLENAME if $dbtablespec =~ /<<<TABLENAME>>>/;
	$dbtablespec  =~ s/<<<TABLENAME>>>/$TABLENAME/g;
	$dbtablespec  =~ s/<<<ATTRIBUTES>>>/$ATTRIBUTES/g if defined $ATTRIBUTES;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("recreateTable: $TABLENAME\n");
	print "RECREATING TABLE: $SCHEMA_TABLENAME\n"; # to ACTIVITY file

	if ($dbtablespec =~ /\~/) {
		my @sql = split(/\~/,$dbtablespec);
		foreach my $sql (@sql) {
			if ((length($sql) > 1) && ($sql =~ /drop/i)) {
				# for the drop command, do it silently, suppressing any error
				# or warning message whether table to be dropped exists or not
				$class-> saveLags;
				#>>> $class-> printerror(1);
				$class-> printerror(0);
				$class-> raiseerror(0); # do not exit if no ta
				$class-> autorollback(0);
				$class-> autocommit(1);
				#$class-> do($sql) || return 0;
				$class-> do($sql);
				$class-> restoreLags;
			}
			elsif (length($sql) > 1) {
				defined $class-> do($sql) || return 0;
			}
		}
	}
	else {
		# for the drop command, do it silently, suppressing any error
		# or warning message whether table to be dropped exists or not
		$class-> saveLags;
		$class-> printerror(0);
		$class-> raiseerror(0); # do not exit if no table exists to be dropped
		$class-> autorollback(0);
		$class-> autocommit(1);
		# Call the do() from this class itself, since it will localize the variables
		#$class-> do("drop table $SCHEMA_TABLENAME") || return 0;
		$class-> do("drop table $SCHEMA_TABLENAME");
		# Do not call the do() from DBI unless you want to localize everything once again!
		#eval {
		#   local ...
		#	$class->{connection}->do("drop table $SCHEMA_TABLENAME");
		#};
		#$@ && $class->{dberr}->println();
		#$@ && $class-> printerror && print STDERR ">>>> $@\n";
		$class-> restoreLags;

		defined $class->{connection}->do($dbtablespec) || return 0;
	}
	$class-> _tracingE("recreateTable: $TABLENAME\n");
	return 1;
}


########################################################################################
# recreateTableFromString drops (silently) the table first, then it will recreate the table.
#   the table dll is found in the configuration-directory/SQL/TABLES
sub recreateTableFromString {
my $class=shift;
my $dbtablespec = shift; # my $SCHEMA_STRING = shift;
my $TABLENAME = shift;

	$dbtablespec  =~ s/<<<TABLENAME>>>/$TABLENAME/g;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("recreateTableFromString: $TABLENAME\n");
	print "RECREATING TABLE: $TABLENAME\n"; # to ACTIVITY file

	if ($dbtablespec =~ /\~/) {
		my @sql = split(/\~/,$dbtablespec);
		foreach my $sql (@sql) {
			if ((length($sql) > 1) && ($sql =~ /drop/i)) {
				# WARNING: must exclude "drop" from table name.
				# for the drop command, do it silently, suppressing any error
				# or warning message whether table to be dropped exists or not
				$class-> saveLags;
				#>>> $class-> printerror(1);
				$class-> printerror(0);
				$class-> raiseerror(0);
				$class-> autorollback(0);
				$class-> autocommit(1);

				$class-> do($sql);
				$class-> restoreLags;
			}
			elsif (length($sql) > 1) {
				defined $class-> do($sql) || return 0;
			}
		}
	}
	else {
		# for the drop command, do it silently, suppressing any error
		# or warning message whether table to be dropped exists or not
		$class-> saveLags;
		$class-> printerror(0);
		$class-> raiseerror(0); # do not exit if no table exists to be dropped
		$class-> autorollback(0);
		$class-> autocommit(1);
		# Call the do() from this class itself, since it will localize the variables
		$class-> do("drop table $TABLENAME"); # $class-> do("drop table $SCHEMA_TABLENAME");
		# Do not call the do() from DBI unless you want to localize everything once again!
		#eval {
		#   local ...
		#	$class->{connection}->do("drop table $SCHEMA_TABLENAME");
		#};
		#$@ && $class->{dberr}->println();
		#$@ && $class-> printerror && print STDERR ">>>> $@\n";
		$class-> restoreLags;

		defined $class->{connection}->do($dbtablespec) || return 0;
	}

	$class-> _tracingE("recreateTableFromString: $TABLENAME\n");
	return 1;
}




########################################################################################
# getTcount($table,$col,$where)
#   returns the count records from $table on column=$col where $where condition apply
# returns a positive integer on success, 0 if no record is found, -1 if DBI error

sub getTcount {
	my $class = shift;

	my $table =  shift;
	my $oncol =  shift;
	my $s = shift;

	$oncol = '*' unless defined($oncol);

	my $q = ( (defined($s)) && ($s ne '')) ?  
		"SELECT COUNT($oncol) FROM $table WHERE $s" :  # $s;"
		"SELECT COUNT($oncol)  FROM $table" ; # $s;"
		#"SELECT COUNT(*) FROM $table WHERE $s;" :
		#"SELECT COUNT(*) FROM $table;" ;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class->_tracingB("GET_COUNT:\n\tfrom TABLE $table\n\t$q\n\n");

	my $cursor = $class->{connection}->prepare( $q );

	$class->{cursor} = $cursor;
	$class->{cursor}->execute();

	if ($DBI::err) {
		$class-> _tracingE("getTcount Failure: (CRISIS) $DBI::err -- $DBI::errstr\n returning FALSE (-1)\n");
		# on error return -1, the caller need to check if -1 and get error with $dbhandle->dbierror()
		# example DBI ERROR No:1146 -- Table 'varigene.C001_S00_44751de1cfca9' doesn't exist
		$class-> _internal_state(ISTATE_CRISIS);
		return -1;
	}

	my $count;
	if (my $temp = $class->{cursor}->fetchrow_hashref()) {
		my %hr = %$temp;
		$count = $hr{"COUNT($oncol)"};
		#$count = $hr{'COUNT(*)'};
	}

	$class->{rows} =  $class->{cursor}->rows;
	$class->{cursor}->finish();

	$class->_tracingE("(getTcount OK: >> returning $count\n");
	return $count;
}

########################################################################################
########################################################################################
#DEPRECATED
# will not work with numbers, used to store dyna-matrix data.
# quote everything except attributes ending with _t, _d, _n, _NULL
#*insert=\&insertdumb;
# DEPRECATED, do not document, it is used by the author applications
sub insertdumb {
	my $class = shift;

	my $table =  shift;
	my %h = @_;
	
	my ($s1, $s2, $key);

	foreach $key (keys %h) {
		if ($h{$key} ne '') {
			$s1 .= "$key,";
			my(@T)= split(/_/,$key);
			my($type)=$T[$#T];
				#	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
				#	$class->_tracing("TYPE ==================  $key ++ [$type] ++ $h{$key} \n\n");
			if ( ($type eq 't') ||  ($type eq 'T') ||
				($type eq 'd') || ($type eq 'D') ||
				($type eq 'n') || ($type eq 'N') ||
				($h{$key} eq 'NULL') ) {
				$s2 .= "$h{$key},";	
			}
			else {
				$s2 .= "'$h{$key}',";
			}
		}
		else {
			$s1 .= "$key,";
			$s2 .= "\'\',";
		}
	}
	chop($s1);
	chop($s2);

	my $q = "INSERT INTO $table ($s1) VALUES ($s2) ";

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("INSERTDUMB:\n\t in TABLE $table\n\t$q\n\n");

	my $cursor = $class->{connection}->prepare( $q );

	# hold the cursor in case we will call the insert from within this class
#	my $holdCursor = $class->{cursor};
	$class->{cursor} = $cursor;

	if ($class->{cursor}->execute() ) {
		$class->{rows} =  $class->{cursor}->rows;
		$class->{cursor}->finish();

		$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
		$class-> _tracingE("INSERTDUMB PASSED:\n\t in TABLE $table\n\t$q\n\n");

#		$class->{cursor} = $holdCursor;
		return 1;
	}
	else {
		$class-> _tracingE("INSERTDUMB FAILED: ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");


		$class->{rows} = 0;

#		$class->{cursor} = $holdCursor;
		return 0;
	}

}


########################################################################################
########################################################################################
# insertrec is CS (based in insertnum where you need to quote scalars).
#   inserts numerical values, and none of them are being quoted. For non-numerical
#   attribute, the caller should explicitly quote the value, e.g. $H{lookup} = "'$UID0'";
#
# insertrec() insert a record into a single table name.
# insertrec() takes two arguments:
#   1- a table name
#   2- a record as a Perl hash whose attributes correspond to the table column names
# it is the Perl data type of each attribute that is effectively used by this method to know
# how to handle the insert. Specify SCALAR references for strings
# Numerical data can be simply specified as is.
# If an attribute is a SCALAR reference, insertrec() will dereference the data


# Although the %rec is passed by value, one can always effectively do insert of large records
# by having these attributes that hold large block of data (i.e. BLOB) points their corresponding string.
# The method insertrec() will dereference these string and bind them.

# Refer to method (that will save you even more memory)
sub insertrec {
	my $class = shift;

	my $table =  shift;
	my %h = @_;
	
	my ($s1, $s2, $key);

	my @bind_data_bins=();

	foreach $key (keys %h) {
		if (ref $h{$key} eq 'SCALAR') {
			$s1 .= "$key,";
			$s2 .= "?,";
			#push(@bind_data_bins,${$h{$key}});
			push(@bind_data_bins,qq{${$h{$key}}});
		}
		else {
			$s1 .= "$key,";
			$s2 .= "$h{$key},";
		}
	}
	chop($s1);
	chop($s2);

	my $q = "INSERT INTO $table ($s1) VALUES ($s2) ";

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("insertrec():\n\t in TABLE $table\n\t$q\n\n");

	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	local $class->{connection}->{AutoCommit} if $class->autocommit == 0;
	$class->{connection}->{AutoCommit}=$class->autocommit;

	my $cursor = $class->{connection}->prepare( $q );

	# hold the cursor in case we will call the insert from within this class
	#my $holdCursor = $class->{cursor};
	$class->{cursor} = $cursor;

	if ( $class->{cursor}->execute(@bind_data_bins) ) 
		 {
		$class->{rows} = $class->{cursor}->rows;
		$class->{cursor}->finish();

		$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
		$class-> _tracingE("insertrec() PASSED (DONE)\n\n");

		#$class->{cursor} = $holdCursor;
		return 1;
	}
	else {
		#$class->{rows} = 0;
		###$class->{cursor} = $holdCursor;
		#$class-> _tracingE("insertrec() FAILED: ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n");
		#return 0;

		$class-> _tracingE("insertrec() FAILED: ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n");
		# explicit rollback and disconnect
		$class-> autorollback && $class-> _traceln("<-++ rollback AUTOROLLBACK is set to 1, ALAS ROLLING-BACK\n\n");
		!$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && $class-> _traceln("<-++ BUT ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT=0 THEN WE WILL NOT EXIT AND ROLLBACK -- YOU NEED TO DO IT YOURSELF\n\n");
		#DONE IN DESTROY $class-> autorollback && $class-> rollback;
#		$class-> autorollback && $class-> rollback;
		$class-> _internal_state(ISTATE_CRISIS);
		#########$xprm{DIE_AFTER_ROLLBACK} && $class-> autorollback && $class-> disconnect;
		#######$xprm{DIE_AFTER_ROLLBACK} && $class-> autorollback && die "CRITICAL ERROR IN DO()... ROLLED BACK r> DISCONNECTED DBHANDLE d> PROGRAM TERMINATED x>\n";
		#return 0;
		#$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && (exit);
		#$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && ($class-> DESTROY);

		# if ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT is 1 then check to see whichever exit will be called
		$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && ($PERSISTENT_OBJECT_ENABLED) && ($class-> _persistent_exit);
		$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && (exit);
		# otherwise return undef
		return undef;
	}

}



########################################################################################
########################################################################################
# PRIVATE!
sub sqlRawbnd {
	my $class = shift;
	my $q =  shift;
	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("sqlRawbnd(): $q\n");
	#$class-> _tracingB("sqlRawbnd(): $q ++ @_\n");
	
	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	local $class->{connection}->{AutoCommit} if $class->autocommit == 0;
	$class->{connection}->{AutoCommit}=$class->autocommit;

	#my $tm0 = time;
	my $tm0 = Time::HiRes::clock();
	my $cursor = $class->{connection}->prepare( $q );
	$class->{cursor} = $cursor;
	my @bind_data_bins=();
	if (@_) {
		#@bind_data_bins = @_;
		foreach (@_) {
			# passing string ref is possible, check for these ref and dereference 'em
			#my $bnd = ref $_ eq 'SCALAR' ? ${$_} : $_;
			# WARNING: because this may not work for Oracle, where the qq{} is needed for the string or varchar...
			#   in that case use the sqlbnd, or have it done this way!!! 
			my $bnd = ref $_ eq 'SCALAR' ? qq{${$_}} : $_;
			push(@bind_data_bins, $bnd);
		}
	}
	#if ( $binding && ( $class->{cursor}->execute(@bind_data_bins) ) ) {
	if ( $class->{cursor}->execute(@bind_data_bins) ) {
		$class->{rows} =  $class->{cursor}->rows;
		$class->{cursor}->finish(); 
		#$class->{cumu_conrun} += time - $tm0;
		my $tm1 = Time::HiRes::clock();
		$class->{cumu_conrun} += $tm1 - $tm0;
		my $elapsed = $tm1 - $tm0;
		$class-> _tracingE("sqlRawbnd() PASSED (DONE)(SYSTEM TIME=$elapsed)\n\n");
		return 1;
	}
	else {
		# if we did not exited due to raiseerror, then rolling back is possible
		# and this is useful in complex $q statement where multiple insert may be embedded!
		if ($class-> autorollback && !$class-> autocommit) {
			$class-> _traceln("<-r rollback AUTOROLLBACK IS SET TO 1, ALAS ROLLING-BACK\n\n");
			$class-> rollback;
			##$class-> disconnect;
			##die "CRITICAL ERROR WHEN INSERTING... ROLLED BACK\n"; }
			$class-> _tracingE("sqlRawbnd() FAILED (ROLLBACK IN EFFECT -- ALAS ROLLING-BACK): ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");
		}
		else {
			$class->{rows} = 0; 
			#$class->{cursor} = $holdCursor; 
			$class-> _tracingE("sqlRawbnd() FAILED: ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");
		}
		#$class->{cumu_conrun} += time - $tm0;
		my $tm1 = Time::HiRes::clock();
		$class->{cumu_conrun} += $tm1 - $tm0;
		#return undef;
		return 0; 
	 }
}


########################################################################################
########################################################################################
#
# 
# http://www.physiol.ox.ac.uk/Computing/Online_Documentation/DBI.html
# http://www.easysoft.com/developer/languages/perl/dbi-debugging.html
#use DBD::Oracle qw(:ora_types);
#*insertbnd 
sub sqlbnd {
	my $class = shift;
	# start with a good state upon each entry
	$class-> _internal_state(ISTATE_GOOD);

	my $q =  shift;
	my $o_bnd =  (@_ && (ref $_[0] eq 'ARRAY') && (ref ${$_[0]}[0] eq 'HASH')) ? shift : undef;
	my $o_typ =  (@_ && (ref $_[0] eq 'HASH')) ? shift : undef;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("sqlbnd(): $q\n");
	#$class-> _tracingB("SQLSQL: $q ++ @_\n");
	
	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	local $class->{connection}->{AutoCommit} if $class->autocommit == 0;
	$class->{connection}->{AutoCommit}=$class->autocommit;

	#my $tm0 = time;
	my $tm0 = Time::HiRes::clock();

	# if $o is a pseudo hash then go for the binding
	if ((ref $o_bnd eq 'ARRAY') && (ref $$o_bnd[0] eq 'HASH')) {
		#my $b_canonical;
		my @ord = sort values %{$$o_bnd[0]};
		my %ord = reverse %{$$o_bnd[0]};
		#for (my $i=1; $i<=@ord; $i++) {
		#	$b_canonical .= ':' . $ord{$i} . ',';
		#}
		#chop($b_canonical);
		#my $sql = "BEGIN $pkgspc($b_canonical); END;";
		#my $cursor = $class->{connection}->prepare($sql) or die "Cannot prepare $sql\n";
		my $cursor = $class->{connection}->prepare($q) or die "Cannot prepare $q\n";
		$class->{cursor} = $cursor;
		for (my $i=1; $i<=@ord; $i++) {
			#if ($o->[$i]) {
				my $str;
				$str = (ref $o_bnd->[$i] eq 'SCALAR') ? ${$o_bnd->[$i]} : $o_bnd->[$i];
				# Escape as in /usr/lib/perl5/site_perl/5.8/cygwin/DBD/File.pm : sub quote
				#$str =~ s/\\/\\\\/sg; $str =~ s/\0/\\0/sg;
				#$str =~ s/\'/\\\'/sg; $str =~ s/\n/\\n/sg; $str =~ s/\r/\\r/sg;
				#"'$str'";

				if ( exists $$o_typ{ $ord{$i} } ) {
					$class-> _traceln("................------------------------------........................................ binding $i :$ord{$i} ($$o_typ{ $ord{$i} })\n");
					#$cursor->bind_param($i, qq{$o_bnd->[$i]},  {ora_type=>ORA_BLOB} );
					#$cursor->bind_param($i, qq{$o_bnd->[$i]},  { ora_type=>$o_typ{ $ord{$i} } } );
					$cursor->bind_param($i, qq{$str},  { ora_type=>$$o_typ{ $ord{$i} } } );
				}
				else {
					$class-> _traceln("....................................................................................... binding $i :$ord{$i}\n");
					#$cursor->bind_param($i, qq{$o_bnd->[$i]} );
					$cursor->bind_param($i, qq{$str} );
				}
		}
		$cursor->execute or die __PACKAGE__, "::sqlbnd Cannot execute $q\n", caller,"\n";
		$cursor->finish();
	}
	else {
		my $cursor = $class->{connection}->prepare( $q );
		$class->{cursor} = $cursor;
		my @bind_data_bins=();
		if (@_) {
			#@bind_data_bins = @_;
			foreach (@_) {
				# passing string ref is possible, check for these ref and dereference 'em
				my $bnd = ref $_ eq 'SCALAR' ? ${$_} : $_;
				push(@bind_data_bins, $bnd);
			}
		}
		#if ( $binding && ( $class->{cursor}->execute(@bind_data_bins) ) ) {
		if ( $class->{cursor}->execute(@bind_data_bins) ) {
			$class->{rows} =  $class->{cursor}->rows;
			$class->{cursor}->finish(); 
			#$class->{cumu_conrun} += time - $tm0;
			my $tm1 = Time::HiRes::clock();
			$class->{cumu_conrun} += $tm1 - $tm0;
			my $elapsed = $tm1 - $tm0;
			$class-> _tracingE("sqlbnd() PASSED (DONE)(SYSTEM TIME=$elapsed)\n\n");
			return 1;
		}
		else {
			# if we did not exit due to raiseerror, then rolling back is possible
			# and this is useful in complex $q statement where multiple insert may be embedded!
			if ($class-> autorollback && !$class-> autocommit) {
				$class-> _traceln("<-r rollback AUTOROLLBACK IS SET TO 1, ALAS ROLLING-BACK\n\n");
				$class-> rollback;
				##$class-> disconnect;
				##die "CRITICAL ERROR WHEN INSERTING... ROLLED BACK\n"; }
				$class-> _tracingE("sqlbnd() FAILED (ROLLBACK IN EFFECT -- ALAS ROLLING-BACK): ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");
			}
			else {
				$class->{rows} = 0; 
				#$class->{cursor} = $holdCursor; 
				$class-> _tracingE("sqlbnd() FAILED: ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");
			}
			#$class->{cumu_conrun} += time - $tm0;
			my $tm1 = Time::HiRes::clock();
			$class->{cumu_conrun} += $tm1 - $tm0;
			#return undef;
			return 0; 
		 }
	}
}

# DATATY
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
# need type mapping table, next release
# Test this one with Oracle
#
use constant BBNNDD => 0;
sub typ_insertbnd { #rslt params
	my $class = shift;
	my $table = shift;
	my $UID0 = shift;
	my $targcolumns = shift;
	my $CoL_href = shift;
	my $El2Ty_href = shift;

	my @columns = @{$targcolumns};

	#my %H;
	my %H2O;
	my $xcol; my $yval;
	$xcol = 'LOOKUP,';  $yval = "'$UID0',";

	###$H{LOOKUP} = "'$UID0'";
	#$H{LOOKUP} = \$UID0;

	#Ideally: foreach (@RsColumns) { $H{$_} = \"$$CoL_href{$_}"; }
	#my $El2Ty_href = $class->{_rsltEl2Ty};
	foreach (@columns) {
	#foreach (keys %$CoL_href) {
BBNNDD && print "................................................................................................$_ ++ $$El2Ty_href{$_} ++ $$CoL_href{$_} \n";
		if (($$El2Ty_href{$_} =~ /STRING/i) && ($$El2Ty_href{$_} !~ /STRING\(\s*\^\s*\)/i)) {
			# avoid inserting a NULL by default for empty string
			my $v = ($$CoL_href{$_} eq '') && $xprm{DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING} 
					#? \"' '" 
					#: \"'$$CoL_href{$_}'";
					? "' '" 
					: "'$$CoL_href{$_}'";
			$xcol .= $_ . ',';
			$yval .= $v . ',';
		}
		elsif ($$El2Ty_href{$_} =~ /STRING\(\s*\^\s*\)/) {
			# this is a ref of type string pointer STRING(^)=BLOB=~/_sref$/i
			$xcol .= $_ . ',';
			$yval .= '?,';
			$H2O{$_} = $$CoL_href{$_}; # ${ $$CoL_href{$_} }
		}
		elsif ($$El2Ty_href{$_} =~ /CBOOL/) {
			# this is a ref of type string pointer STRING(^)=BLOB=~/_sref$/i
			$xcol .= $_ . ',';
			$yval .= "'$$CoL_href{$_}'" . ',';
		}
		else {
			$xcol .= $_ . ',';
			$yval .= $$CoL_href{$_} . ',';
		}
	}
	$xcol .= 'RECORDDATE_T'; $yval .= $class-> {SYSDATE};
	#chop($xcol);
	#chop($yval);

	my $SQL = "INSERT INTO $table ($xcol) VALUES ($yval)";
	my $pseudoLeft; my @pseudoRight; my $fldTyp;
	my $i=0;
	foreach my $k (sort keys %H2O) {
		$pseudoLeft .= "$k=>". ++$i . ",";
		#@pseudoRight = (@pseudoRight, $H2O{$k});
		push(@pseudoRight , $H2O{$k});
		$fldTyp .= "$k=>103,";
	}
	chop($pseudoLeft);
	chop($fldTyp);
	
	BBNNDD && print "aaaaaa************************************************************************************\n";
	BBNNDD && print "aaaaaa************************************************************************************ $pseudoLeft\n";
	BBNNDD && print "aaaaaa************************************************************************************ $fldTyp\n";
	#my %pseudoLeft = eval "%{$pseudoLeft}";	
	my %pseudoLeft = eval "($pseudoLeft)";
	my $o_bnd = [ {%pseudoLeft} , @pseudoRight ];
	#my %fldTyp = eval $fldTyp;
	my %fldTyp = eval "($fldTyp)";
	my $o_typ = \%fldTyp;
	if ((ref $o_bnd eq 'ARRAY') && (ref $$o_bnd[0] eq 'HASH')) {
		BBNNDD && print "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy $o_bnd\n";
		my @ord = sort values %{$$o_bnd[0]};
		my %ord = reverse %{$$o_bnd[0]};
		for (my $i=1; $i<=@ord; $i++) {
			my $str;
			$str = (ref $o_bnd->[$i] eq 'SCALAR') ? ${$o_bnd->[$i]} : $o_bnd->[$i];
			if ( exists $$o_typ{ $ord{$i} } ) {
				BBNNDD && print ".............................................. binding $i ++ :$ord{$i} ($$o_typ{ $ord{$i} })\n";
			}
			else {
				BBNNDD && print ".............................................. binding $i ++ :$ord{$i}\n";
			}
		}
	}
	BBNNDD && print "0>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $SQL\n";
	BBNNDD && print "1>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $pseudoLeft\n";
	BBNNDD && print "2>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> @pseudoRight\n";
	BBNNDD && print "3>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $fldTyp\n";
	BBNNDD && print "************************************************************************************\n";


	# start with a good state upon each entry
	$class-> _internal_state(ISTATE_GOOD);

	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	# when $class->autocommit==0   STORE('AutoCommit' undef)= 1
	local $class->{connection}->{AutoCommit} if $class->autocommit == 0;
	# when $class->autocommit==0   STORE('AutoCommit' '0')= 1
	$class->{connection}->{AutoCommit}=$class->autocommit;


	my $tm0 = Time::HiRes::clock();
	#if ($class->{_dbhandle}->sqlbnd($SQL, $o_bnd, $o_typ) ) {
	if ($class-> sqlbnd($SQL, $o_bnd) ) {
		my $tm1 = Time::HiRes::clock();
		$class->{cumu_conrun} += $tm1 - $tm0;
		my $elapsed = $tm1 - $tm0;
	}
	else {
		# $FATAL && die "INTERNAL ERROR ....\n";
		my $err = "INTERBAL ERROR WHEN WRITING TO $table failed: ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n";
		BBNNDD && print STDOUT $err;
		print STDERR $err;
		return 0;
	}

	#$H{RECORDDATE_T}=$SYSDATE;
	#if ($class->{_dbhandle}->insertrec($BASETAB_RSLT_PARAMS, %H)) {}
	#else {
	#	die "INTERNAL ERROR MatrixMapper > storeRSO_MatricesIndexTable! ", $class->{_dbhandle}->dbierror(), "\n";
	#}
}

########################################################################################
# PRIVATE
# need type mapping table, next release
sub typ_updatebnd { #rslt params
	my $class = shift;
	my $table = shift;
#	my $UID0 = shift;
#	my $targcolumns = shift;
	my $CoL_href = shift;
	my $El2Ty_href = shift;
my $wherecond = shift;


	# start with a good state upon each entry
	$class-> _internal_state(ISTATE_GOOD);

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("typ_updatebnd(): $table\n");

	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	# when $class->autocommit==0   STORE('AutoCommit' undef)= 1
	local $class->{connection}->{AutoCommit} if $class->autocommit == 0;
	# when $class->autocommit==0   STORE('AutoCommit' '0')= 1
	$class->{connection}->{AutoCommit}=$class->autocommit;

	#my $TOTAL_ELAPSETIME = sprintf("%.2f", Time::HiRes::tv_interval($INVOTIME0));
	#${$$statCC{$caconn}}{starttime} = [Time::HiRes::gettimeofday];
	#my $tm0 = [Time::HiRes::gettimeofday];
	#my $tm0 = time;
	my $tm0 = Time::HiRes::clock();

#	my @columns = @{$targcolumns};

	#my %H;
	my %H2O;
#	my $xcol; my $yval;
my $xcol_yval = '';
#$xcol = 'LOOKUP,';  $yval = "'$UID0',";

	###$H{LOOKUP} = "'$UID0'";
	#$H{LOOKUP} = \$UID0;

	#Ideally: foreach (@RsColumns) { $H{$_} = \"$$CoL_href{$_}"; }
	#my $El2Ty_href = $class->{_rsltEl2Ty};
#foreach (@columns) {
	foreach (keys %$CoL_href) {
BBNNDD && print "................................................................................................$_ ++ $$El2Ty_href{$_} ++ $$CoL_href{$_} \n";
		if (($$El2Ty_href{$_} =~ /STRING/i) && ($$El2Ty_href{$_} !~ /STRING\(\s*\^\s*\)/i)) {
			# avoid inserting a NULL by default for empty string
			my $v = ($$CoL_href{$_} eq '') && $xprm{DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING}
					#? \"' '" 
					#: \"'$$CoL_href{$_}'";
					? "' '" 
					: "'$$CoL_href{$_}'";
#			$xcol .= $_ . ',';
#			$yval .= $v . ',';
			$xcol_yval .= $_ . '=' . $v . ','
		}
		elsif ($$El2Ty_href{$_} =~ /STRING\(\s*\^\s*\)/) {
			# this is a ref of type string pointer STRING(^)=BLOB=~/_sref$/i
#			$xcol .= $_ . ',';
#			$yval .= '?,';
			$xcol_yval .= $_ . '=?,';
			$H2O{$_} = $$CoL_href{$_}; # ${ $$CoL_href{$_} }
		}
		elsif ($$El2Ty_href{$_} =~ /CBOOL/) {
			# this is a ref of type string pointer STRING(^)=BLOB=~/_sref$/i
#			$xcol .= $_ . ',';
#			$yval .= "'$$CoL_href{$_}'" . ',';
			$xcol_yval .= $_ . "='$$CoL_href{$_}',";
		}
		else {
#			$xcol .= $_ . ',';
#			$yval .= $$CoL_href{$_} . ',';
			$xcol_yval .= $_ . '=' . $$CoL_href{$_} . ',';
		}
	}
#$xcol .= 'RECORDDATE_T'; $yval .= $class-> {SYSDATE};
$xcol_yval .= 'CHANGEDATE_T' . '=' . $class-> {SYSDATE};
	#chop($xcol);
	#chop($yval);

#UPDATE VS001NY_PRSS_JN_INFO SET DISPLAYNAME = 'yyyyyyyyy' WHERE EXISTS (SELECT 1 FROM VS001NY_PRSS_REGISTRY a WHERE VS001NY_PRSS_JN_INFO.LOOKUP = a.LOOKUP);

#my $SQL = "INSERT INTO $table ($xcol) VALUES ($yval)";
my $SQL = "UPDATE $table SET $xcol_yval WHERE $wherecond";

	my $pseudoLeft; my @pseudoRight; my $fldTyp;
	my $i=0;
	foreach my $k (sort keys %H2O) {
		$pseudoLeft .= "$k=>". ++$i . ",";
		#@pseudoRight = (@pseudoRight, $H2O{$k});
		push(@pseudoRight , $H2O{$k});
		$fldTyp .= "$k=>103,";
	}
	chop($pseudoLeft);
	chop($fldTyp);
	
	BBNNDD && print "aaaaaa************************************************************************************\n";
	BBNNDD && print "aaaaaa************************************************************************************ $pseudoLeft\n";
	BBNNDD && print "aaaaaa************************************************************************************ $fldTyp\n";
	#my %pseudoLeft = eval "%{$pseudoLeft}";	
	my %pseudoLeft = eval "($pseudoLeft)";	
	my $o_bnd = [ {%pseudoLeft} , @pseudoRight ];
	#my %fldTyp = eval $fldTyp;
	my %fldTyp = eval "($fldTyp)";
	my $o_typ = \%fldTyp;
	if ((ref $o_bnd eq 'ARRAY') && (ref $$o_bnd[0] eq 'HASH')) {
		BBNNDD && print "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy $o_bnd\n";
		my @ord = sort values %{$$o_bnd[0]};
		my %ord = reverse %{$$o_bnd[0]};
		for (my $i=1; $i<=@ord; $i++) {
			my $str;
			$str = (ref $o_bnd->[$i] eq 'SCALAR') ? ${$o_bnd->[$i]} : $o_bnd->[$i];
			if ( exists $$o_typ{ $ord{$i} } ) {
				BBNNDD && print ".............................................. binding $i ++ :$ord{$i} ($$o_typ{ $ord{$i} })\n";
			}
			else {
				BBNNDD && print ".............................................. binding $i ++ :$ord{$i}\n";
			}
		}
	}
	BBNNDD && print "0>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $SQL\n";
	BBNNDD && print "1>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $pseudoLeft\n";
	BBNNDD && print "2>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> @pseudoRight\n";
	BBNNDD && print "3>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $fldTyp\n";
	BBNNDD && print "************************************************************************************\n";
	#if ($class->{_dbhandle}->sqlbnd($SQL, $o_bnd, $o_typ) ) {
	if ($class-> sqlbnd($SQL, $o_bnd) ) {
		my $tm1 = Time::HiRes::clock();
		$class->{cumu_conrun} += $tm1 - $tm0;
		my $elapsed = $tm1 - $tm0;
		$class-> _tracingE("typ_updatebnd() PASSED (DONE)(SYSTEM TIME=$elapsed)\n\n");
	}
	else {
		$class-> _tracingE("typ_updatebnd() FAILED (ROLLBACK IN EFFECT -- ALAS ROLLING-BACK): ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");
		# $FATAL && die "INTERNAL ERROR ....\n";
		my $err = "INTERBAL ERROR WHEN WRITING TO $table failed: ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n";
		BBNNDD && print STDOUT $err;
		print STDERR $err;
		return 0;
	}

	#$H{RECORDDATE_T}=$SYSDATE;
	#if ($class->{_dbhandle}->insertrec($BASETAB_RSLT_PARAMS, %H)) {}
	#else {
	#	die "INTERNAL ERROR MatrixMapper > storeRSO_MatricesIndexTable! ", $class->{_dbhandle}->dbierror(), "\n";
	#}
}


########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################
# 
# On success:
#    return the number of rows affected
#
# On failure:
#    return undef on failure   if raiseerror=0 and autorollback=0
#    will die (calling destroy) and will explicit-rollback and will not return if raiseerror=0 and autorollback=1
#    will die (calling destroy) and will not return  if raiseerror=1 and autorollback=0
# 
sub do {
	my $class = shift;

	# start with a good state upon each entry
	$class-> _internal_state(ISTATE_GOOD);

	my $q =  shift;
	
	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("DO:\n\t $q\n\n");

	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	# when $class->autocommit==0   STORE('AutoCommit' undef)= 1
	local $class->{connection}->{AutoCommit} if $class->autocommit == 0;
	# when $class->autocommit==0   STORE('AutoCommit' '0')= 1
	$class->{connection}->{AutoCommit}=$class->autocommit;

	#my $TOTAL_ELAPSETIME = sprintf("%.2f", Time::HiRes::tv_interval($INVOTIME0));
	#${$$statCC{$caconn}}{starttime} = [Time::HiRes::gettimeofday];
	#my $tm0 = [Time::HiRes::gettimeofday];
	#my $tm0 = time;
	my $tm0 = Time::HiRes::clock();
#eval {

	#my $second = undef;
	#my @p;
	#if (@_) { $second = shift; }
	#while (@_) {
	#	my $next = shift;
	#	my $p = ref $next eq 'SCALAR' ? qq{$$next} : $next;
	#	push(@p,$p);
	#}
	#my $rr = $class->{connection}->do( $q, $second, @p );

	###if ($class->{connection}->do( $q, @_ ) && ! $DBI::err ) {
	my $rr_do = $class->{connection}->do( $q, @_ );
	# turn old mule "0E0" into plain 0; otherwise number of afftected columns; otherwise undef for false

	# turn "0E0" into 0
	my $rr = defined $rr_do && $rr_do eq '0E0' ? 0 : $rr_do ? $rr_do : undef;

	#TODO: need to benchmark the do() and see if the following assertions may cause a slow down in
	# a long do() harness
	# Add DOCUMENTATION in POD: Warn the user of the behavior of DROP (also used in recreateTable),
	#
	#whenever raiseerror is 0, for a DROP sttm force the return result $rr to 0, so we do not exit
	#because dropping a non-existent table will return undef
	($class->raiseerror == 0) && (!defined $rr) && ($q =~ /^\s*drop\s+/i) && ($rr = 0);
		
	if (defined $rr) {
        $class->_tracingE("DO: PASSED WITH RR=$rr\n");
		#$class->autocommit && $class->{connection}->commit;

		# my $elap = time - $tm0;
		#$class->{cumu_conrun} += time - $tm0;
		my $tm1 = Time::HiRes::clock();
		$class->{cumu_conrun} += $tm1 - $tm0;
		if ($xprm{ENABLE_STATISTICS_ON_DO}) {
			# Adjust statistics for arriving queries
			$class->{_qryStat}{$q}{count} = (defined $class->{_qryStat}{$q}) ? $class->{_qryStat}{$q}{count}+1 : 1;
			$class->{_qryStat}{$q}{tm0} = $tm0;
			#$class->{_qryStat}{$q}{tm1} = time;
			$class->{_qryStat}{$q}{tm1} = Time::HiRes::clock();
		}
		#return 1;
		return $rr;
	}
	else {
		$class-> _tracingE("DO: FAILED\nERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");

		# explicit rollback and disconnect
		$class-> autorollback && $class-> _traceln("<-++ rollback AUTOROLLBACK is set to 1, ALAS ROLLING-BACK\n\n");
		!$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && $class-> _traceln("<-++ BUT ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT=0 THEN WE WILL NOT EXIT AND ROLLBACK -- YOU NEED TO DO IT YOURSELF\n\n");
		#DONE IN DESTROY $class-> autorollback && $class-> rollback;
#		$class-> autorollback && $class-> rollback;
		$class-> _internal_state(ISTATE_CRISIS);
		#########$xprm{DIE_AFTER_ROLLBACK} && $class-> autorollback && $class-> disconnect;
		#######$xprm{DIE_AFTER_ROLLBACK} && $class-> autorollback && die "CRITICAL ERROR IN DO()... ROLLED BACK r> DISCONNECTED DBHANDLE d> PROGRAM TERMINATED x>\n";
		#return 0;
		#$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && (exit);
		#$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && ($class-> DESTROY);

		# if ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT is 1 then check to see whichever exit will be called
		$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && ($PERSISTENT_OBJECT_ENABLED) && ($class-> _persistent_exit);
		$xprm{ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT} && (exit);
		# otherwise return undef
		return undef; # same as  return $rr;
	}
#};

#if ($@) {
#	print "ERROR: \t $@ \n\n";
#	$class->autorollback && $class->{connection}->rollback;
#	return 0;
#}
#return 1;

}


	
########################################################################################
########################################################################################
# Calls the stored procedure $stproc. The first parameter $o can be either a pseudo-hash
# or a scalar. Passing a pseudo-hash is documented as above, passing a scalar need to be
# documented later.
sub spc {
	my $class = shift;
	my $o = shift;
	my $pkgspc = shift;

	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("spc()/EXECUTING STORED PROCEDURE:\n\t $pkgspc\n\n");
	my $tm0 = Time::HiRes::clock();

	# if $o is a pseudo hash then go for the binding
	if ((ref $o eq 'ARRAY') && (ref $$o[0] eq 'HASH')) {
		my $b_canonical;
		my @ord = sort values %{$$o[0]};
		my %ord = reverse %{$$o[0]};
		for (my $i=1; $i<=@ord; $i++) {
			$b_canonical .= ':' . $ord{$i} . ',';
		}

		chop($b_canonical);
		my $sql = "BEGIN $pkgspc($b_canonical); END;";
		my $cursor = $class->{connection}->prepare($sql) or die "Cannot prepare $sql\n";
		$class->{cursor} = $cursor;
		# go in order and bind the parameters, if a parameter is defined then bind_param otherwise bind_param_inout
		for (my $i=1; $i<=@ord; $i++) {
			if ($o->[$i]) {
				$cursor->bind_param(":$ord{$i}", $o->[$i]);
			}
			else {
				#$cursor->bind_param_inout(":$ord{$i}", \$o->[$i], 1) unless $o>;
				$cursor->bind_param_inout(":$ord{$i}", \$o->[$i], 10);
			}
		}
		# die if spc execute fails; users need to test that their spc packages are valids and functioning properly
		$cursor-> execute or die __PACKAGE__, "::spc Cannot execute $sql\n";
		$cursor-> finish();

		if ($o->[1]) {
			# my $elap = time - $tm0;
			#$class->{cumu_conrun} += time - $tm0;
			my $tm1 = Time::HiRes::clock();
			$class->{cumu_conrun} += $tm1 - $tm0;
			if ($xprm{ENABLE_STATISTICS_ON_SPC}) {
				# Adjust statistics for arriving spc's
				$class->{_spcStat}{$pkgspc}{count} = (defined $class->{_spcStat}{$pkgspc}) ? $class->{_spcStat}{$pkgspc}{count}+1 : 1;
				$class->{_spcStat}{$pkgspc}{tm0} = $tm0;
				#$class->{_spcStat}{$pkgspc}{tm1} = time;
				$class->{_spcStat}{$pkgspc}{tm1} = Time::HiRes::clock();
			}
			$class-> _tracingE("spc() PASSED (DONE)\n\n");
			return 1;
		}
		#$o->[1] && return 1;
	}
	#elsif (ref $o eq 'ARRAY') { # simple array list, then simple binding with ?
	#}
	else { # $o is a SCALAR
		my $sql = "BEGIN $pkgspc(?); END;";
		my $cursor = $class->{connection}->prepare($sql) or die "Cannot prepare $sql\n";
		$class->{cursor} = $cursor;

		$cursor-> execute($o) or die __PACKAGE__, "::spc Cannot execute $sql\n";
		$cursor-> finish();

		# my $elap = time - $tm0;
		#$class->{cumu_conrun} += time - $tm0;
		my $tm1 = Time::HiRes::clock();
		$class->{cumu_conrun} += $tm1 - $tm0;
		if ($xprm{ENABLE_STATISTICS_ON_SPC}) {
			# Adjust statistics for arriving spc's
			$class->{_spcStat}{$pkgspc}{count} = (defined $class->{_spcStat}{$pkgspc}) ? $class->{_spcStat}{$pkgspc}{count}+1 : 1;
			$class->{_spcStat}{$pkgspc}{tm0} = $tm0;
			#$class->{_spcStat}{$pkgspc}{tm1} = time;
			$class->{_spcStat}{$pkgspc}{tm1} = Time::HiRes::clock();
		}
		$class-> _tracingE("spc() PASSED (DONE)\n\n");
		return 1;
	}

	return 0;
}



########################################################################################
#DEPRE
#used in chopping cart! 
#  select $s1 from $table where $s2;
#  go over elements from each fetched record, and form a colon ":" seperated string
#  push each colon seperated string on the list reference $L
# *retrieve_inlist {
sub fetchTda_inCoList {
	my $class = shift;

	my $table =  shift;
	my $s1 = shift;
	my $s2 = shift;

	my $elements = shift;
	my $L = shift;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("fetchTda_inCoList():\n\t $table\n$s1\n$s2\n\n");

	my @flds = [];
	if ( ($elements =~ /,/) ) {
		@flds = split(/,/,$elements);
	}
		
	my $q = "SELECT $s1 FROM $table WHERE $s2;";


	my $cursor = $class->{connection}->prepare( $q );

	$class->{cursor} = $cursor;

	$class->{cursor}->execute();
	$class->{rows} =  $class->{cursor}->rows;
	my $temp;
	my $key;
	my $i = 0;
	while ($temp =  $class->{cursor}->fetchrow_hashref()) {
		my %hr = %$temp;
		if ($elements =~ /,/) {
			my $s;
			my $t;
			foreach $t (@flds) {
				$s .= $hr{$t} . ':';

			}
			chop($s) if $s =~ /:$/;
			push(@$L,$s);

		}
		else {
			push(@$L,$hr{$elements});
		}
		$i++;
	}
	$class->{cursor}->finish();

	$class-> _tracingE("fetchTda_inCoList() PASSED (DONE)\n\n");

	return $i;
}


########################################################################################
# DEPRE
# Fetch data from a table that got an extra pseudo ordered column (i.e. ordre).
# After retrieving the records from that table, these records are kept in a hash
# that is reordered properly and pushed to a list. The final result is an ordered
# list.
# The current method work on a single column and is used by Varisphere.
# *retrieve_inOrderedList 
sub fetchTda_inOrderedList {
	my $class = shift;

	my $table =  shift;
	my $s1 = shift;
	my $os2 = shift;
	my $s3 = shift;

	my $L = shift;

	my $q = "SELECT $s1,$os2 FROM $table WHERE $s3 order by $os2;";

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("retrieve_inOrderedList(): \n\tfrom TABLE $table\n\t$q\n\n");

	my $cursor = $class->{connection}->prepare( $q );

	$class->{cursor} = $cursor;

	$class->{cursor}->execute();
	$class->{rows} =  $class->{cursor}->rows;
	my $temp;
	my %hr;
	while ($temp =  $class->{cursor}->fetchrow_hashref()) {
		$hr{ $$temp{$os2} } = $$temp{$s1};
	}
	foreach my $k (sort keys %hr) {
		push(@$L,$hr{$k});
	}

	$class->{cursor}->finish();

	$class-> _tracingE("retrieve_inOrderedList() PASSED (DONE)\n\n");

	return scalar(@$L);
}


########################################################################################
#DEPRE
#
#use it when records are unique, since it returns a single (first encountered) record
#record result is in \%H
#return 1 on success, 0 if no record is found, -1 if DBI error
#
#my @flds = (SKUARCHIVE,TOPICHEAD,TITLE,AUTHOR);
#if ( ($dbhandle->fetchTda_inHash('ARCHIVE', ' SKUARCHIVE,TOPICHEAD,TITLE,AUTHOR,SYNOPSIS   ' ," SKUARCHIVE=\'$skuarchive\' ",\%dbhash, \@flds)) ) {}
#
#if ( ($class->{_dbhandle}->fetchTda_inHash($DBTABLENAME," * " ," id=$i ",\%H) > 0)  ) {
# *retrieve_inhash

sub fetchTda_inHash {
	my $class = shift;
	my $table =  shift;
	my $s1 = shift;
	my $s2 = shift;
	my $hh = shift;

	my $list = @_ ? shift : [];
	
	my $q = "SELECT $s1 FROM $table WHERE $s2"; # $s2;"

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("fetchTda_inHash(): \n\tfrom TABLE $table\n\t$q\n\n");

	my $cursor = $class->{connection}->prepare( $q );

	$class->{cursor} = $cursor;
	$class->{cursor}->execute();
	if ($DBI::err) {
		$class-> _tracingE("fetchTda_inHash() Failed: (CRISIS) $DBI::err -- $DBI::errstr\n returning FALSE (-1)\n");
		$class-> _internal_state(ISTATE_CRISIS);
		return -1;
	}

	$class->{rows} =  $class->{cursor}->rows;
	my $key;

	if (my $temp = $class->{cursor}->fetchrow_hashref()) {
		my %hr = %$temp;
		if (@{$list}) {
			for (my $j=0; $j < @{$list}; $j++) {
				$key = $$list[$j];
				$$hh{$key} = $hr{$key};
	#      			$class->{debhook}->print("++++++++++++++++++++++++>>> $key ++ $$hh{$key} <<<\n");
			}
		}
		else {
			%$hh = %hr;
		}
		$class->{cursor}->finish();
		$class-> _tracingE("fetchTda_inHash(): returned TRUE \n");
		return 1;
	}
	else {
		$class->{cursor}->finish();
		$class-> _tracingE("fetchTda_inHash(): returned FALSE \n");
		return 0;
	}
}



########################################################################################
#
sub fetchQdaO {
	my $class = shift;
	my $q =  shift;
	#my $hrf = shift;
	my $hrf = (ref $_[0] eq 'HASH') ? shift : {};

	#my $list = (@_ && ref $_[0] eq 'ARRAY') ? shift : undef; # [];
	my $list = (ref $_[0] eq 'ARRAY') ? shift : undef; # [];

	my @bindparams = @_;
	
	die "RETURNING AND DOING NOTHING FROM getdaO: CANNOT HAVE * AND SPECIFY LIST!\n" if ($list) && $q =~ /SELECT\s+\*\s+/i;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("fetchQdaO(): \n\t$q\n\n");


	# localize these Lags
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	
	#my $tm0 = time;
	my $tm0 = Time::HiRes::clock();
	#$class->{_qryStat}{$q}{tm0} = time;



	my $cursor = $class->{connection}->prepare( $q );
	$class->{cursor} = $cursor;

	my $i=1;
	foreach (@bindparams) {
		$class-> _traceln("\tfetchQdaO() BINDING: $i  ---to---> $_\n");
		$class->{cursor}->bind_param($i++,$_);
	} 


	$class->{cursor}->execute();
	if ($DBI::err) {
		$class-> _tracingE("getdaO Failure: (CRISIS) $DBI::err -- $DBI::errstr\n returning FALSE (-1)\n");
		$class-> _internal_state(ISTATE_CRISIS);
		return undef;
	}

	$class->{rows} =  $class->{cursor}->rows;

	#if (@{$list}) {
	if ($list) {
		#print "1- In list context <<<<<<<<<<<<<<<<<<<<\n";
		my %temp;
		for (my $j=0; $j < @{$list}; $j++) {
			#print "........................................................... binding $j+1 --to--> hrf $$list[$j]\n";
			#DOES NOT WORK! $class->{cursor}-> bind_col($j+1, \$$hrf{ $$list[$j] });
			$class->{cursor}-> bind_col($j+1, \$temp{ $$list[$j] });
		}
		# eval {};
		$class->{cursor}-> fetch;
		$class->{cursor}-> finish();
		#if ($@) {}
		if ($class->{cursor}->rows) {
			foreach my $k (keys %temp) { $$hrf{$k} = \$temp{$k}; }

			my $tm1 = Time::HiRes::clock();
			$class->{cumu_conrun} += $tm1 - $tm0;
			my $elapsed = $tm1 - $tm0;
			$class-> _tracingE("fetchQdaO(): returned A RECORD with BINDING (SYSTEM TIME=$elapsed)\n");
			return $hrf;
			#return 1;
		}
		else {
			#print "Eeeeeeeeeeeeeeeeeempttttttttttyyyyyyyyyyy\n";
			return $hrf;
			#return 0;
		}
	}
	elsif (my $temp = $class->{cursor}->fetchrow_hashref()) {
		#print "2- in default <<<<<<<<<<<<<<<<<<<<\n";
		##%$hrf = %$temp;
		# get the addresses not the values (not this  %$hrf = %$temp;)
		foreach my $k (keys %$temp) { $$hrf{$k} = \$$temp{$k}; }
		$class->{cursor}->finish();
		my $tm1 = Time::HiRes::clock();
		$class->{cumu_conrun} += $tm1 - $tm0;
		my $elapsed = $tm1 - $tm0;
		$class-> _tracingE("fetchQdaO(): returned A RECORD without any BINDING (SYSTEM TIME=$elapsed)\n");
		return $hrf;
		#return 1;
	}
	else {
		#print "3- zero <<<<<<<<<<<<<<<<<<<<\n";
		$class->{cursor}->finish();
		my $tm1 = Time::HiRes::clock();
		$class->{cumu_conrun} += $tm1 - $tm0;
		my $elapsed = $tm1 - $tm0;
		$class-> _tracingE("fetchQdaO(): returned NO RECORD (SYSTEM TIME=$elapsed)\n");
		return $hrf;
		#return 0;
	}
}



########################################################################################
sub fetchQdaAA
{
	my $class = shift;
	my $q = shift;

#$q = qq{begin $q; end;};
#my $hash;
#$hash = shift @params if ($#params >= 0 && ref($params[0]) eq 'HASH');
#my %h = %{$hash} if $hash;

	# recalling and passing an array ref allow to extend the referenced list, otherwise start fresh
	my $rows = (@_ && ref $_[0] eq 'ARRAY') ? shift : [];
	# have a recalled flag ready
	my $recalled = (@_ && ref $_[0] eq 'ARRAY' && defined ${$_[0]}[0]) ? 1 : 0;

	#my $extras = shift if ref @_[0] eq 'HASH';
	my $extras = shift if ref $_[0] eq 'HASH';
	my @bindparams = @_;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("fetchQdaAA():\n\t $q\n\n");

	# localize these Lags
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	
	#my $tm0 = time;
	my $tm0 = Time::HiRes::clock();
	#$class->{_qryStat}{$q}{tm0} = time;

	#TODO: eval and report error!
	my $cursor = $class->{connection}->prepare($q); #  or die "Cannot prepare $q\n";
	$class->{cursor} = $cursor;

	my $i=1;
	foreach (@bindparams) {
		$class-> _traceln("\tfetchQdaAA() BINDING: $i  ---to---> $_\n");
		$class->{cursor}->bind_param($i++,$_);
	} 

	eval{	
		$class->{cursor}->execute();
	};
	($@) && die "ERROR: $@\n";

	$class->{rows} = $class->{cursor}->rows;

	if ( !$recalled && (($$extras{INCLUDE_HEADER}) || !(defined $$extras{INCLUDE_HEADER})) )
	{
		my @header = ();
		for (my $i=0;$i<$class->{cursor}->{NUM_OF_FIELDS};$i++)
		{
			push(@header,$class->{cursor}->{NAME}->[$i]);
		}
		push(@$rows,\@header);
	}
	#my $cnt = 0;
	my $cnt = -1;
	while (my @r = $class->{cursor}->fetchrow_array)
	#while(my $r = $class->{cursor}->fetchrow_arrayref)
	{
#$class-> _traceln("\t RETRIEVED $cnt ROWS -- \n");
#print STDERR "\t RETRIEVED $cnt ROWS -- \n";
		#push(@$rows,$r); # << FASTER push(@$rows,\@r);
		$cnt++;
		push(@$rows,\@r);
		#$cnt++;
		($cnt%100 == 0) && $class-> _traceln("\t RETRIEVED $cnt ROWS\n");
		($$extras{MAX_ROWS} && $cnt >= $$extras{MAX_ROWS}) &&
			$class->{cursor}->finish && last;
	}
	#$class->{cumu_conrun} += time - $tm0;
	my $tm1 = Time::HiRes::clock();
	$class->{cumu_conrun} += $tm1 - $tm0;
	my $elapsed = $tm1 - $tm0;

	$class-> _tracingE("fetchQdaAA/SELECT_TO_ARRAY (with ROWS=$rows) (SYSTEM TIME=$elapsed)\n");

	return undef if $cnt == -1;
	return $rows;
}


########################################################################################
########################################################################################

sub fetchTdaAA
{
	my $class = shift;
#	my $q = shift;
#	my $flags = shift if ref @_[0] eq 'HASH';
#	my @bindparams = @_;

	my $table =  shift;
	my $selection = shift;
	my $where = shift;

	my $aarf = (@_ && ref $_[0] eq 'ARRAY') ? shift : []; # passing an array ref allow to extend the referenced list, otherwise start fresh
	my @bindparams = @_;

	my $s1 = '';

	my $seeked = 'all';
	my(@A) = ();
	

	# passing the attributes as an array ref. return a 2D array for the table pointed to by aarf
	if (ref($selection) eq 'ARRAY') 
	{
		for (my $j=0; $j < @{$selection}; $j++) 
		{
			push(@A,$$selection[$j]);
			$s1 .= $$selection[$j] . ',';
		}
		chop($s1); $s1 .= ' ';
		$seeked = 'array';
	}
	# a ref to a hash of attributes; (TODO: !!! return an array of hashes)
	elsif (ref($selection) eq 'HASH') 
	{
		my $sel = '';
		foreach (keys %$selection) {
			#$sel .= $_ . ','
			$sel .= $$selection{$_} . ','
		}
		chop($sel);
		$s1 = $sel;
		$seeked = 'skeemamap';
		#@A = split(/,/,$selection);
		#foreach (@A) { s/^\s+//; s/\s+$//; } # trim starting and ending spaces
		#$s1 = $selection;
		#$seeked = 'listed';	
	}
	# a wildcard * for everything; (TODO: !!! return an array of hashes)
	elsif ($selection =~ /^[\s]*\*[\s]*$/) 
	{
		$seeked = 'all';
		$s1 = ' * ';
	}
	# a string of attributes; (TODO: !!! return an array of hashes)
	elsif ($selection =~ /\w/) 
	{
		@A = split(/,/,$selection);
		foreach (@A) { s/^\s+//; s/\s+$//; } # trim starting and ending spaces
		$s1 = $selection;
		$seeked = 'listed';	
	}

	
	my $q;
	if (defined($where) && (length($where)) && !($where =~ /^\s+$/)) {
		$q = "SELECT $s1 FROM $table WHERE $where";
	}
	else {
		$q = "SELECT $s1 FROM $table";
	}

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("fetchTdaAA():\n\t $q\n\n");

	# localize these Lags
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	#my $tm0 = time;
	my $tm0 = Time::HiRes::clock();
	#$class->{_qryStat}{$q}{tm0} = time;

	my $cursor = $class->{connection}->prepare( $q );
	$class->{cursor} = $cursor;
	for (my $i=0; $i<@bindparams; $i++) {
		$b = $i + 1;
		$class-> _traceln("\t BINDING:$b  --to--> $bindparams[$i]\n");
		$class->{cursor}->bind_param($b ,$bindparams[$i]);
	} 

	eval{	
		$class->{cursor}->execute();
	};
	($@) && die "ERROR: $@\n";

	$class->{rows} = $class->{cursor}->rows;

	my $temp;
	my $key;
	my $i = -1; # -1 if nothing returned, but incremented and therefore starting at 0

	my $cnt = 0;

	#my @rows;
	#if ($$flags{INCLUDE_HEADER})
	{
		my @header = ();
		for (my $i=0;$i<$class->{cursor}->{NUM_OF_FIELDS};$i++)
		{
			push(@header,$class->{cursor}->{NAME}->[$i]);
		}
		#push(@rows,\@header);
		push(@{$aarf},\@header);
	}

	while(my @r = $class->{cursor}->fetchrow_array) {
	#while ($temp =  $class->{cursor}->fetchrow_hashref()) {
		$i++; # start counting at 0
		#my %hr = %$temp;

		if ( ($seeked eq 'all') || ($seeked eq 'array') || ($seeked eq 'listed') || ($seeked eq 'skeemamap') ) 
		{
			#foreach my $key (keys %hr) { $$aarf[$i]{$key} = $hr{$key}; }
			push(@{$aarf},\@r); # Equivalent
		}
	#	$cnt++;
	#	($cnt%100 == 0) && $class->_tracing("\t RETRIEVED $cnt ROWS\n");
	#	($$flags{MAX_ROWS} && $cnt >= $$flags{MAX_ROWS}) &&
	#		$class->{cursor}->finish && last;

		#elsif ($seeked eq 'array') 
		#{ # array are ordered following the listed attributes, get them (in order) from @A
		#	foreach my $j (0..$#A) {
		#		#AS 2D ARRAY FOR FASTER ACCESS
		#		$$aarf[$i][$j]=$hr{$A[$j]};
		#	}
		#}
	}
	$class->{cursor}->finish();

#for (my $j=0; $j < $i; $j++){
#	print "$j ++ ";
#	foreach my $k (keys %{$$aarf[$j]}){
#		print "$k=", $$aarf[$j]{$k}, " + ";
#	}
#	print "\n";
#}
#exit;

	#$class->{cumu_conrun} += time - $tm0;
	my $tm1 = Time::HiRes::clock();
	$class->{cumu_conrun} += $tm1 - $tm0;
	$class-> _tracingE("fetchTdaAA():\n\tfrom TABLE $table -- ROWS OK = $class->{rows}\n");

	#return $class->{rows};
	#return $i; # return number of records
	return undef if $i == -1; # return number of records
	return $aarf;
}



########################################################################################
#
#
# July 2005: changed the following to start with an array index at 0: $ahrf[0]{}
# @ahrf is an array of hash that is returned for all records found. @ahrf start counting at 0 
# and that used to be undef before the change (see below)
# *retrieve_in_aobj = *retrieve_inobjects = \&fetchTdaAO;
sub fetchTdaAO {
	my $class = shift;

	# start with a good state upon each entry
	$class-> _internal_state(ISTATE_GOOD);

	my $table =  shift;
	my $selection = shift;
	my $where = shift;

	my $ahrf = @_ ? shift : []; # passing an array ref allow to extend the referenced list, otherwise start fresh

	my $s1 = '';

	my $seeked = 'all';
	my(@A) = ();
	

	# passing the attributes as an array ref. return a 2D array for the table pointed to by ahrf
	if (ref($selection) eq 'ARRAY') 
	{
		for (my $j=0; $j < @{$selection}; $j++) 
		{
			push(@A,$$selection[$j]);
			$s1 .= $$selection[$j] . ',';
		}
		chop($s1); $s1 .= ' ';
		$seeked = 'array';
	}
	# a ref to a hash of attributes; return an array of hashes
	elsif (ref($selection) eq 'HASH') 
	{
		my $sel = '';
		foreach (keys %$selection) {
			#$sel .= $_ . ','
			$sel .= $$selection{$_} . ','
		}
		chop($sel);
		$s1 = $sel;
		$seeked = 'skeemamap';
		#@A = split(/,/,$selection);
		#foreach (@A) { s/^\s+//; s/\s+$//; } # trim starting and ending spaces
		#$s1 = $selection;
		#$seeked = 'listed';	
	}
	# a wildcard * for everything; return an array of hashes
	elsif ($selection =~ /^[\s]*\*[\s]*$/) 
	{
		$seeked = 'all';
		$s1 = ' * ';
	}
	# a string of attributes; return an array of hashes
	elsif ($selection =~ /\w/) 
	{
		@A = split(/,/,$selection);
		foreach (@A) { s/^\s+//; s/\s+$//; } # trim starting and ending spaces
		$s1 = $selection;
		$seeked = 'listed';	
	}

	
	my $q;
	if (defined($where) && (length($where)) && !($where =~ /^\s+$/)) {
		#MYSQL $q = "SELECT $s1 FROM $table WHERE $where;";
		$q = "SELECT $s1 FROM $table WHERE $where";
	}
	else {
		#MYSQL $q = "SELECT $s1 FROM $table;";
		$q = "SELECT $s1 FROM $table";
	}

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("fetchTdaAO/RETRIEVE_IN_AOBJ:\n\t $q\n\n");

	# localize these Lags
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	#my $tm0 = time;
	my $tm0 = Time::HiRes::clock();
	#$class->{_qryStat}{$q}{tm0} = time;

	my $cursor = $class->{connection}->prepare( $q );

	$class->{cursor} = $cursor;

	$class->{cursor}->execute();
	$class->{rows} =  $class->{cursor}->rows;
	my $temp;
	my $key;
	my $i = -1; # -1 if nothing returned, but incremented and therefore starting at 0

	while ($temp =  $class->{cursor}->fetchrow_hashref()) {
		$i++; # start counting at 0, and old start counting at 1 IS DEPRECATED
		my %hr = %$temp;

		if ( ($seeked eq 'all') || ($seeked eq 'listed') || ($seeked eq 'skeemamap') ) 
		{
			#foreach my $key (keys %hr) 
			#{
			#	$$ahrf[$i]{$key} = $hr{$key};
			#}
			push(@{$ahrf},\%hr); # Equivalent
		}
		elsif ($seeked eq 'array') 
		{ # array are ordered following the listed attributes, get them (in order) from @A
			foreach my $j (0..$#A) {
				#AS 2D ARRAY FOR FASTER ACCESS
				$$ahrf[$i][$j]=$hr{$A[$j]};
			}
		}
	}
	$class->{cursor}->finish();

#for (my $j=0; $j < $i; $j++){
#	print "$j ++ ";
#	foreach my $k (keys %{$$ahrf[$j]}){
#		print "$k=", $$ahrf[$j]{$k}, " + ";
#	}
#	print "\n";
#}
#exit;

	# my $elap = time - $tm0;
	#$class->{cumu_conrun} += time - $tm0;
	my $tm1 = Time::HiRes::clock();
	$class->{cumu_conrun} += $tm1 - $tm0;
	$class-> _tracingE("fetchTdaAO/retrieve_in_aobj:\n\tfrom TABLE $table -- ROWS OK = $class->{rows}\n");

	#return $class->{rows};
	#return $i; # return number of records
	return undef if $i == -1; # return number of records
	return $ahrf;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################

########################################################################################
sub commit {
	my $class = shift;
	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("COMMIT (CALLED EXPLICITLY) \n\n");

	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	# when $class->autocommit==0   STORE('AutoCommit' undef)= 1
	local $class->{connection}->{AutoCommit} if $class->autocommit == 0;
	# when $class->autocommit==0   STORE('AutoCommit' '0')= 1
	$class->{connection}->{AutoCommit}=$class->autocommit;

	eval {
		$class->{connection}->commit;
	};
	if ($@) {
		$class-> status($DBI::errstr);
		$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
		$class-> _tracingE("COMMIT: ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");
		return 0;
	}
	$class-> _tracingE("COMMIT ok\n");
	return 1;
}



########################################################################################
sub rollback {
	my $class = shift;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("***rollback() CALLED (DELEGATED TO DBI)*** \n\n");

	# localize variables
	local $class->{connection}->{PrintError} if $class->printerror == 0;
	local $class->{connection}->{RaiseError} if $class->raiseerror == 0;
	$class->{connection}->{PrintError}=$class->printerror;
	$class->{connection}->{RaiseError}=$class->raiseerror;
	# when $class->autocommit==0   STORE('AutoCommit' undef)= 1
	local $class->{connection}->{AutoCommit} if $class->autocommit == 0;
	# when $class->autocommit==0   STORE('AutoCommit' '0')= 1
	$class->{connection}->{AutoCommit}=$class->autocommit;


	#if (!$class-> is_RaiseError && !$class-> is_AutoCommit && $class-> is_AutoRollback) {
	if (!$class-> is_AutoCommit && $class-> is_AutoRollback) {
		eval {
			$class->{connection}->rollback;
		};
		if ($@) {
			###NO state=CONNECTED|DISCONNETED|UNDEF $class-> state('ERROR');
			##$class-> _inside_state(CRISIS); # use constant CRISIS => 1
			$class-> status($DBI::errstr);
			$class-> _tracingE("rollback(): ERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");
			return 0;
		}
		$class-> _tracingE("ROLLBACK ok\n");
		return 1;
	}
	else {
		$class-> _tracingE("rollback() -- CANNOT CALL ROLLBACK BECAUSE THE FOLLOWING CONDITION IS NOT SATISFIED: RaiseError=0 AutoCommit=0 AutoRollback=1\n");
	}
}


########################################################################################
# to finish an opened cursor handle
#
sub finish {
	my $class = shift;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracing("FINISH");
	$class->{cursor}->finish();
}


########################################################################################
sub disconnect {
	my $class = shift;

	if ($PERSISTENT_OBJECT_ENABLED) {
print STDERR
"
You should never call the disconnect on a persistent DBI::BabyConnect object, although
it is possible to call this function, but because many DBI::BabyConnect objects may
be cached by one or more child processes, then you won't be able to keep track of
which one has disconnected, (unless you check the state of DBI::BabyConnect object ...)
and this will lead to more confusion. Let's keep it simple, hence I will not disconnect
this handle because PERSISTENT_OBJECT_ENABLED is 1.
"
	}

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("DISCONNECT");

	$xprm{PRT_CEND} && print STDOUT "ent-> disconnect() ***", $class-> state, "\n";

#$class->{connection}->disconnect() or die "CONNECTION MANAGER: disconnect() failed: $DBI::errstr\n";
#return;
#goto OOO;

	die "
disconnect() PROBLEM:
CALLING disconnect() ON ALREADY DISCONNECTED HANDLER --
ALTHOUGH THE CODE WILL NOT FAIL, BUT DISCONNECT MUST BE
CALLED ONCE FOR PROPER CODING. (state= $class->state)
" 		if ($xprm{CALLER_DISCONNECT} && ($class-> state eq 'DISCONNECTED'));

	die "
disconnect() PROBLEM:
SHOULD NOT CALL DISCONNECT ON AN UNDEF.
THERE HAS NEVER BEEN A CONNECTION ANYWAY!
" 		if ($xprm{CALLER_DISCONNECT} && ($class-> state eq 'UNDEF'));

	#$dbiconnection->disconnect();
	#commit ineffective with AutoCommit enabled:
	#$class->{connection}->commit();	
#OOO:
	$class-> state('DISCONNECTED');
	$class-> status('DISCONNECTED');

	#TODO make sure that DBI:: disconnect() return false on failure
	#$class->{connection}->disconnect() or die "CONNECTION MANAGER: disconnect() failed: $DBI::errstr\n";
	if (! $class->{connection}->disconnect()) {
		$class-> _tracingE("DISCONNECT FAILED (AND PROGRAM EXITING)\nERROR in DBI !\n\t DBI FAILED ON:\t$DBI::err\n\t DBI REASON:\t$DBI::errstr\n\t DBI LED:\t$DBI::state\n\n");
		die "CONNECTION MANAGER: disconnect() failed: $DBI::errstr\n";
	}

	$xprm{PRT_CEND} && print STDOUT "<-don disconnect() ***", $class-> state, "\n";
	$class-> _tracingE("DISCONNECT");

	#do not undef the connection yet, DESTROY will do this:
	#$class->{connection} = undef;

}


########################################################################################
# DESTROY_HOOK() garbage collect the OO file handle if any has been requested
# during the instantiation with new()
sub DESTROY_HOOK 
{
	my $class = shift;
	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _traceln("hstdlog-d> HOOK DESTROY: ALAS NO MORE WRITING!\n");
	return unless $class->{debhook};
	#$class->{debhook}->close();
	$class->{debhook}->DESTROY;
	$class->{debhook} = undef;
}




########################################################################################
sub _persistent_exit
{
	my $class = shift;

	# It is possible to force the execution of the body of this sub DESTROY by calling
	# DESTROY(1), that is setting the $FORCE_USUAL_DESTRUCTION to 1, even if
	# the class has been loaded with DISABLE_DESTROY enabled (set to 1, typically
	# needed when persisting with Apache::BabyConnect). 
	my $FORCE_USUAL_DESTRUCTION = @_ ? shift : 0;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("ent-> DESTROY (CONNECTION STATUS=".$class-> state.")\n");
	$class-> _traceln("_persistent_exit (CONNECTION STATUS=".$class-> state.") FORCE_DESTRUCTION=$FORCE_USUAL_DESTRUCTION, DISABLE_DESTROY=$PERSISTENT_OBJECT_ENABLED\n");


	#return if ($PERSISTENT_OBJECT_ENABLED and !$FORCE_USUAL_DESTRUCTION);
	#return if $PERSISTENT_OBJECT_ENABLED;
	if ($PERSISTENT_OBJECT_ENABLED and !$FORCE_USUAL_DESTRUCTION) {
		if (!$class-> is_RaiseError &&
			 !$class-> is_AutoCommit &&
			 $class-> is_AutoRollback && 
			($class-> _internal_state eq ISTATE_CRISIS)) {
				print STDERR "!!!!!ERROR STATE IN CRISIS, MAY BE DUE TO A FAILING DO!!!!!\n";
				print STDERR "!!!!!WE ARE GOING TO ROLLBACK!!!!!\n";
				#($class-> rollback) 
				#	||  die "STATUS IS IN ERROR AND CANNOT ROLLBACK: ", $class->{connection}->errstr, "\n";
				($class-> rollback)
					||  _traceln("DBI FAILED TO ROLLBACK WITH REASON: ". $class->{connection}->errstr . "\n");
				#$class->{connection}->disconnect || die "ERROR WHEN DESTROY>DISCONNECT: ", $class->{connection}->errstr, "\n";
				#$class->{connection}->DESTROY;
				$class-> _tracingE("<-don DESTROY/PERSISTENT_OBJECT_ENABLED ** (CRISIS) ENDED WITH ERROR (CONNECTION STATUS=".$class-> state.") ******** \n");
				#$class-> DESTROY_HOOK;
				#die "EXITING WITH ERROR: CRISIS, AND ENDING THIS HANDLER CLASS!\n";
		}
		#return;
	}
	# to get to this point you need to have ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT and PERSISTENT_OBJECT_ENABLED,
	# which is typical with mod_perl with Apache::BabyConnect, in which case the following exit() is redirected to
	# the Apache::exit() that will terminate the script only
	exit;
}






########################################################################################
# When $PERSISTENT_OBJECT_ENABLED = 1 (i.e. when using Apache::BabyConnect), the DESTROY
# will also be executed to cleanup the state of the handle. For instance, if
# the ISTATE_CRISIS and Autorollback then the autorollback is called.
# When $PERSISTENT_OBJECT_ENABLED = 1, the DESTROY will never call the disconnect.
#
# it is the reponsibility of the caller to disconnect the dbi handle; therefore,
# the DESTROY of this class will never disconnect the dbhandle.
#sub DESTROY {}
#sub DUNNO_DESTROY
sub DESTROY 
{
	my $class = shift;

	# It is possible to force the execution of the body of this sub DESTROY by calling
	# DESTROY(1), that is setting the $FORCE_USUAL_DESTRUCTION to 1, even if
	# the class has been loaded with DISABLE_DESTROY enabled (set to 1, typically
	# needed when persisting with Apache::BabyConnect). 
	my $FORCE_USUAL_DESTRUCTION = @_ ? shift : 0;

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("ent-> DESTROY (CONNECTION STATUS=".$class-> state.")\n");
	$class-> _traceln("DESTROY (CONNECTION STATUS=".$class-> state.") FORCE_DESTRUCTION=$FORCE_USUAL_DESTRUCTION, DISABLE_DESTROY=$PERSISTENT_OBJECT_ENABLED\n");


	#return if ($PERSISTENT_OBJECT_ENABLED and !$FORCE_USUAL_DESTRUCTION);
	#return if $PERSISTENT_OBJECT_ENABLED;
	if ($PERSISTENT_OBJECT_ENABLED and !$FORCE_USUAL_DESTRUCTION) {
		if (!$class-> is_RaiseError &&
			 !$class-> is_AutoCommit &&
			 $class-> is_AutoRollback && 
			($class-> _internal_state eq ISTATE_CRISIS)) {
				print STDERR "!!!!!ERROR STATE IN CRISIS, MAY BE DUE TO A FAILING DO!!!!!\n";
				print STDERR "!!!!!WE ARE GOING TO ROLLBACK!!!!!\n";
				#($class-> rollback) 
				#	||  die "STATUS IS IN ERROR AND CANNOT ROLLBACK: ", $class->{connection}->errstr, "\n";
				($class-> rollback)
					||  _traceln("DBI FAILED TO ROLLBACK WITH REASON: ". $class->{connection}->errstr . "\n");
				#$class->{connection}->disconnect || die "ERROR WHEN DESTROY>DISCONNECT: ", $class->{connection}->errstr, "\n";
				#$class->{connection}->DESTROY;
				$class-> _tracingE("<-don DESTROY/PERSISTENT_OBJECT_ENABLED ** (CRISIS) ENDED WITH ERROR (CONNECTION STATUS=".$class-> state.") ******** \n");
				#$class-> DESTROY_HOOK;
				#die "EXITING WITH ERROR: CRISIS, AND ENDING THIS HANDLER CLASS!\n";
		}
		return;
	}



	# when $xprm{CALLER_DISCONNECT}, it is mandatory to have the caller disconnecting ...
	#die "IT IS THE RESPONSIBILITY OF THE CALLER TO THIS HANDLER TO DISCONNECT (UNLESS RaiseError!!!)!!!!!!!!!!\n"
	#	if ($xprm{CALLER_DISCONNECT} && ($class-> state ne 'DISCONNECTED'));


#	return if $class-> state eq 'DISCONNECTED';

	#if ($class-> state eq 'DISCONNECTED') {
	if ($xprm{CALLER_DISCONNECT} && $class-> state eq 'DISCONNECTED') {
		#if (!$class-> is_RaiseError && !$class-> is_AutoCommit && $class-> is_AutoRollback && ($class-> _internal_state eq ISTATE_CRISIS)) {
		#  ... in CRISIS but handle already disconnected, then we can do nothing. (should be that the caller is handling this error)
		#}
		#else {
		$class->{connection}->DESTROY;
		$class-> _tracingE("<-don DESTROY ** ENDED CLEANLY WITH (CONNECTION STATUS=".$class-> state." _internal_state=".$class-> _internal_state.") ******** \n");
		# gone for good, alas, no more logging
		$class-> DESTROY_HOOK;
	}
	elsif ($class-> state eq 'UNDEF') {
		#die "STATE of connection is UNDEF!\n";
	}
	elsif ($xprm{CALLER_DISCONNECT} && $class-> state eq 'CONNECTED') {
		if ($class-> is_RaiseError && $DBI::err) { # due to DBI die, but also check ...
			$xprm{PRT_CEND} && print STDOUT "**Rollback**Rollback**Rollback**Rollback**Rollback**Rollback**Rollback**  in DESTROY\n";
			($class-> is_AutoRollback && !$class-> is_AutoCommit) 
				&& (($class-> rollback) 
				||  die "STATUS IS IN ERROR AND CANNOT ROLLBACK: ", $class->{connection}->errstr);
			$class->{connection}->disconnect || die "ERROR WHEN DESTROY>DISCONNECT: ", $class->{connection}->errstr, "\n";
			$class->{connection}->DESTROY;
			# gone for good, alas, no more logging
			#if ( $class->{debhook} ) {
			#	#$class->{debhook}->close();
			#	$class->{debhook}->DESTROY;
			#	$class->{debhook} = undef;
			#}
			$class-> _tracingE("<-don DESTROY ** ENDED WITH DBI-RAISING ERROR ** ROLLBACK OK (CONNECTION STATUS=".$class-> state.") ******** \n");
			$class-> DESTROY_HOOK;
			die "FATAL ERROR: WE ARE IN ERROR DUE TO ROLLBACK, WE ROLLED BACK, AND DIE NOW!\n";
		}
		# TODO: CRISIS whenever _inside_state, i.e. check "sub do"
		# if still CONNECTED and Lags are properly set for rollback and the _inside_state is in CRISIS then rollback 
		elsif (!$class-> is_RaiseError && !$class-> is_AutoCommit && $class-> is_AutoRollback && ($class-> _internal_state eq ISTATE_CRISIS)) {
				print STDERR "!!!!!ERROR STATE IN CRISIS, MAY BE DUE TO A FAILING DO!!!!!\n";
				print STDERR "!!!!!WE ARE GOING TO ROLLBACK, THEN DISCONNECT AND DIE!!!!!\n";
				$xprm{PRT_CEND} && print STDOUT "!!!!!ERROR STATE IN CRISIS, MAY BE DUE TO A FAILING DO!!!!!\n";
				$xprm{PRT_CEND} && print STDOUT "!!!!!WE ARE GOING TO ROLLBACK, THEN DISCONNECT AND DIE!!!!!\n";
				($class-> rollback) 
					||  die "STATUS IS IN ERROR AND CANNOT ROLLBACK: ", $class->{connection}->errstr, "\n";
				$class->{connection}->disconnect || die "ERROR WHEN DESTROY>DISCONNECT: ", $class->{connection}->errstr, "\n";
				$class->{connection}->DESTROY;
				$class-> _tracingE("<-don DESTROY ** (CRISIS) ENDED WITH ERROR (CONNECTION STATUS=".$class-> state.") ******** \n");
				$class-> DESTROY_HOOK;
				die "EXITING WITH ERROR: CRISIS, AND ENDING THIS HANDLER CLASS!\n";
		}
		else {
			print STDERR "!!!!!IT IS THE RESPONSIBILITY OF THE CALLER TO THIS HANDLER TO DISCONNECT!!!!!\n";
			print STDERR "!!!!!WE ARE GOING TO DISCONNECT ANYWAY, AND DIE!!!!!\n";
			$xprm{PRT_CEND} && print STDOUT "!!!!!IT IS THE RESPONSIBILITY OF THE CALLER TO THIS HANDLER TO DISCONNECT!!!!!\n";
			$xprm{PRT_CEND} && print STDOUT "!!!!!WE ARE GOING TO DISCONNECT ANYWAY, AND DIE!!!!!\n";
			$class->{connection}->disconnect;
			$class->{connection}->DESTROY;
			# gone for good, alas, no more logging
			$class-> _tracingE("<-don DESTROY ** ENDED WITH ERROR (CONNECTION STATUS=".$class-> state.") ******** \n");
			$class-> DESTROY_HOOK;
			die "EXITING WITH ERROR: CALLER MUST DISCONNECT BEFORE ENDING THIS HANDLER CLASS!\n";
		}
	}

	#my $c = [caller];
	#print STDOUT "@{$c} -- \n DESSSSSSSSSsssssssssssssssssssssstroyed \n\n";
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################


# STATISTICS Section
########################################################################################
########################################################################################
########################################################################################
########################################################################################
#

sub _statCCreset {
my $kprocess = shift;
my $desc = shift;
my $caconn = "$kprocess$desc";
	${$$statCC{$caconn}}{kprocess} = $kprocess; 
	${$$statCC{$caconn}}{descriptor} = $desc;
	${$$statCC{$caconn}}{counter} = 1;
	#${$$statCC{$caconn}}{systime};
	#${$$statCC{$caconn}}{dbtime};
#Time::HiRes::clock();
#Time::HiRes::clock();

	#my $TOTAL_ELAPSETIME = sprintf("%.2f", Time::HiRes::tv_interval($INVOTIME0));
	#${$$statCC{$caconn}}{starttime} = [Time::HiRes::gettimeofday];
	#${$$statCC{$caconn}}{starttime} = localtime;
	${$$statCC{$caconn}}{starttime} = iso_date();
	${$$statCC{$caconn}}{hires0} = [Time::HiRes::gettimeofday];
	${$$statCC{$caconn}}{clock0} = Time::HiRes::clock();
}

sub _statCC {
my $kprocess = shift;
my $desc = shift;
my $caconn = "$kprocess$desc";
	##${$$statCC{$caconn}}{kprocess} = 
	#${$$statCC{$caconn}}{descriptor} = 
	++${$$statCC{$caconn}}{counter};
	#${$$statCC{$caconn}}{systime};
	#${$$statCC{$caconn}}{dbtime};
	#${$$statCC{$caconn}}{starttime} = ;
}

sub getStatCC {
#my $caconn = shift;
	my $class = shift;
	my $rshr = @_ ? shift : undef;

	foreach my $caconn (keys %$statCC) {
		#my $elapse = sprintf("%.2f", Time::HiRes::tv_interval(${$$statCC{$caconn}}{starttime}));
		${$$statCC{$caconn}}{clock1} = Time::HiRes::clock();
		#my $clock = ${$$statCC{$caconn}}{clock1} - ${$$statCC{$caconn}}{clock0};
		${$$statCC{$caconn}}{clock} = ${$$statCC{$caconn}}{clock1} - ${$$statCC{$caconn}}{clock0};

		#my ${$$statCC{$caconn}}{hires1} = [Time::HiRes::gettimeofday];
		#my $elapse = sprintf("%.2f", Time::HiRes::tv_interval(${$$statCC{$caconn}}{hires0}));
		${$$statCC{$caconn}}{elapse} = sprintf("%.2f", Time::HiRes::tv_interval(${$$statCC{$caconn}}{hires0}));
	}

	(ref $rshr eq 'HASH') && (%$rshr = map{$_=>$$statCC{$_}} (keys %$statCC)) && (return $rshr);
	my $th={};
	(length($rshr) > 2) && (%$th = map{$_=>$$statCC{$_}}(keys %{$$statCC{$rshr}})) && (return $th);

	#return $statCC;

	my $info;
	foreach my $caconn (keys %$statCC) {
		$info .= "
$caconn
	${$$statCC{$caconn}}{kprocess}
	${$$statCC{$caconn}}{descriptor}
	${$$statCC{$caconn}}{counter}
	${$$statCC{$caconn}}{starttime}
	elapse: ${$$statCC{$caconn}}{elapse}
	time: ${$$statCC{$caconn}}{clock}

";
	}
	return $info;
}

sub htmlStatCC {
#my $caconn = shift;
	my $class = shift;

	foreach my $caconn (keys %$statCC) {
		#my $elapse = sprintf("%.2f", Time::HiRes::tv_interval(${$$statCC{$caconn}}{starttime}));
		${$$statCC{$caconn}}{clock1} = Time::HiRes::clock();
		#my $clock = ${$$statCC{$caconn}}{clock1} - ${$$statCC{$caconn}}{clock0};
		${$$statCC{$caconn}}{clock} = ${$$statCC{$caconn}}{clock1} - ${$$statCC{$caconn}}{clock0};

		#my ${$$statCC{$caconn}}{hires1} = [Time::HiRes::gettimeofday];
		#my $elapse = sprintf("%.2f", Time::HiRes::tv_interval(${$$statCC{$caconn}}{hires0}));
		${$$statCC{$caconn}}{elapse} = sprintf("%.2f", Time::HiRes::tv_interval(${$$statCC{$caconn}}{hires0}));
	}


print "

The table below shows the cached connection of this http server process. The columns designation<br>
summary is as follow:
<ul>
	<li><b>id</b> -- unique ID of the connection object formed of kernel process ID + database descriptor</li>
	<li><b>kprocess</b> -- kernel process ID</li>
	<li><b>counter</b> -- number of times the DBI::BabyObject has been requested</li>
	<li><b>starttime</b> -- start time is ISO date format</li>
	<li><b>elapse</b> -- number of seconds since the DBI::BabyObject object has been created</li>
	<li><b>clock</b> -- system+user system time consumed by the specified cached DBI::BabyObject object</li>
</ul>

<table>

";
my @fields = qw(id kprocess counter starttime elapse clock);
print '<tr bgcolor="grey">' , map("<th>$_</th>", @fields) , "</tr>";
shift @fields;

foreach my $caconn (keys %$statCC) {
	print "<tr><td>$caconn</td>", map("<td>${$$statCC{$caconn}}{$_}</td>",@fields) , "</tr>";
}

print "</table>";

}



sub iso_date {
	my $date = (localtime->year() + 1900).'-'._two_digit(localtime->mon() + 1).'-'._two_digit(localtime->mday());
	my $time = _two_digit(localtime->hour()).':'._two_digit(localtime->min()).':'._two_digit(localtime->sec());
	return "$date $time";
}

sub _two_digit {
	my $value = $_[0];
	$value = '0'.$value if( length($value) == 1 );
	return $value;
}



sub get_running_time {
	my $class = shift;
	
	my $clock1 = Time::HiRes::clock();
	my $totclock = $clock1 - $class->{clock0};

	#my $totrun = time - $class->{time0};
	#[Time::HiRes::gettimeofday];
	#my $totrun = Time::HiRes::tv_interval($class->{time0});
	my $totrun = sprintf("%.2f", Time::HiRes::tv_interval($class->{time0}));
	my $conrun = $class->{cumu_conrun};
	return "$conrun / $totclock / $totrun";
}


########################################################################################

sub get_do_stat {
	my $class = shift;
	my $rshr = @_ ? shift : undef;

	my $th={};
	(ref $rshr eq 'HASH') && (%$rshr = map{$_=>$class-> {_qryStat}{$_}}(keys %{$class-> {_qryStat}})) && (return $rshr);
	(length($rshr) > 2) && (%$th = map{$_=>$class-> {_qryStat}{$_}}(keys %{${$class-> {_qryStat}}{$rshr}})) && (return $th);

	my $info;
	foreach my $k (keys %{$class-> {_qryStat}}) {
	my $elap =  $class-> {_qryStat}{$k}{tm1} -  $class-> {_qryStat}{$k}{tm0};
	$info .= "
Query: $k
count: ". $class-> {_qryStat}{$k}{count}."
tm0: ". $class-> {_qryStat}{$k}{tm0}."
tm1: ". $class-> {_qryStat}{$k}{tm1}."
elapse: ". $elap."

";
}

	return $info;
}
		
########################################################################################
sub get_spc_stat {
	my $class = shift;
	my $rshr = @_ ? shift : undef;

	my $th={};
	(ref $rshr eq 'HASH') && (%$rshr = map{$_=>$class-> {_spcStat}{$_}}(keys %{$class-> {_spcStat}})) && (return $rshr);
	(length($rshr) > 2) && (%$th = map{$_=>$class-> {_spcStat}{$_}}(keys %{${$class-> {_spcStat}}{$rshr}})) && (return $th);

	my $info;
	foreach my $k (keys %{$class-> {_spcStat}}) {
	my $elap =  $class-> {_spcStat}{$k}{tm1} -  $class-> {_spcStat}{$k}{tm0};
	$info .= "
Spc: $k
count: ". $class-> {_spcStat}{$k}{count}."
tm0: ". $class-> {_spcStat}{$k}{tm0}."
tm1: ". $class-> {_spcStat}{$k}{tm1}."
elapse: ". $elap."

";
}

	return $info;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################


# META Section
########################################################################################
########################################################################################
########################################################################################
########################################################################################
sub snapTableDescription {
	my $class = shift;
	my $table = shift;

	return unless ($class-> dbdriver =~ /Mysql/i);

	#my $tabinfo = $class->{connection}->table_info();

# Use the cursor to get a description of the 'onusers' table
#my $cursor = $class->{connection}->prepare( $q );
my $cursor = $class->{connection}->prepare("DESCRIBE $table");
$cursor->execute();
my $info = sprintf "%s", DBI::dump_results($cursor);
$cursor->finish();
#print DBI::dump_results($cursor);

#open(FILE,">foo");
#print DBI::dump_results($cursor,undef,undef,undef,*FILE);
#close(FILE);
#$cursor->finish();

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class->_tracingB("(snapTableDescription) RETRIEVE TABLE DESCRIPTION FOR $table:\n\tTABLE $info\n\n");
	$class->_tracingE("\n");

	return $info;
}

########################################################################################

sub snapTablesInfo {
	my $class = shift;

	return unless ($class-> dbdriver =~ /Mysql/i);

	my $tabinfo = $class->{connection}->table_info();

	my $info = "\n\n";
	$info .= "Table Name                    Type     Qualifier  Owner         Remarks\n";
	$info .= "============================  =======  =========  ============  ================\n";
	while (my ($qual,$owner,$name,$type,$remarks) = $tabinfo->fetchrow_array()  ) {
		foreach ($qual,$owner,$name,$type,$remarks) {
			$_ = "NULL" unless defined $_;
		}
		#$info .= sprintf "%-28s  %-7s  %-9s  %-12s  %-16s\n", $name,$type,$qual,$owner,$remarks;
		$info .= sprintf "%-28s  %7s  %9s  %12s  %16s\n", $name,$type,$qual,$owner,$remarks;
		#$info .=  "$qual  $owner  $name    $type   $remarks \n";
	}

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class->_tracingB("(snapTablesInfo) RETRIEVE ALL TABLES INFO:\n\tTABLE $info\n\n");
	$class->_tracingE("");

	return $info;
}

my %SQLTY_COMMON_MAP = (
SQL_CHAR => 1,
SQL_NUMERIC => 2,
SQL_DECIMAL => 3,
SQL_INTEGER => 4,
SQL_SMALLINT => 5,
SQL_FLOAT => 6,
SQL_REAL => 7,
SQL_DOUBLE => 8,
SQL_DATE => 9,
SQL_TIME => 10,
SQL_TIMESTAMP => 11,
SQL_VARCHAR => 12,
SQL_LONGVARCHAR => -1,
SQL_BINARY => -2,
SQL_VARBINARY => -3,
SQL_LONGVARBINARY => -4,
SQL_BIGINT => -5,
SQL_TINYINT => -6,
SQL_BIT => -7,
SQL_WCHAR => -8,
SQL_WVARCHAR => -9,
SQL_WLONGVARCHAR => -10,
);

my %SQLTY_INV = _inverse_hash (%SQLTY_COMMON_MAP);

sub _inverse_hash
{
	my (%hash) = @_;
	my (%inv);
	foreach my $key (keys %hash)
	{
		my $val = $hash{$key};
		die "Double mapping for key value $val ($inv{$val}, $key)!"
			if (defined $inv{$val});
		$inv{$val} = $key;
	}
	return %inv;
}
# Refer to t_const.pl

# /usr/lib/perl5/vendor_perl/5.8.8/i386-linux-thread-multi/DBI.pm
# /usr/lib/perl5/vendor_perl/5.8.8/i386-linux-thread-multi/DBD/File.pm
# /usr/lib/perl5/vendor_perl/5.8.8/i386-linux-thread-multi/DBI/PurePerl.pm
# /usr/lib/perl5/vendor_perl/5.8.8/i386-linux-thread-multi/auto/DBI/dbi_sql.h
# /usr/lib/perl5/vendor_perl/5.8.8/i386-linux-thread-multi/DBD/Sponge.pm
# in File.pm:  sub quote  ,  sub type_info_all

########################################################################################

sub snapTableMetadata {
	my $class = shift;
	my $table =  shift;

	return unless ($class-> dbdriver =~ /Mysql/i);

	my $info = "\nMETADATA FOR TABLE $table\n\n";
	$info  .= "ATTRIBUTE NAME               TYPE              PREC  SCALE NULLABLE\n";
	$info .=  "============================ ================= ===== ===== ========\n";

	my $q = "SELECT * FROM $table;";

	my $cursor = $class->{connection}->prepare( $q );
	$cursor->execute();
	my $fields = $cursor->{NUM_OF_FIELDS};

	my ($name,$scale,$precision,$type,$nullable);
	for (my $i=0; $i<$fields; $i++) {
		$name = $cursor->{NAME}->[$i];
		$scale = $cursor->{SCALE}->[$i];
		$precision = $cursor->{PRECISION}->[$i];
		$type = $SQLTY_INV{ $cursor->{TYPE}->[$i] }; # %5d or %-17s
		$nullable = ('No','NULL','Unknown')[$cursor->{NULLABLE}->[$i]];
		$info .= sprintf "%-28s %17s %5d %5d %8s\n", $name,$type,$precision,$scale,$nullable;
		# %32s %4d %4d %-17s  %-7s
	}
	$info .= "\n\n";
	$cursor->finish();

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("(snapTableMetadata) RETRIEVE TABLE META DATA FOR:\n\tTABLE $table\n\n");
	$class-> _tracingE("");

	return $info;
}

########################################################################################
# To retrieve the meta data of a table info

sub strucTableMetadata {
	my $class = shift;
	my $table =  shift;
	my @TI;

	my $q = "SELECT * FROM $table;";

	my $cursor = $class->{connection}->prepare( $q );
	$cursor->execute();
	my $fields = $cursor->{NUM_OF_FIELDS};

	for (my $i=0; $i<$fields; $i++) {
		$TI[$i]{NAME} = $cursor->{NAME}->[$i];
		$TI[$i]{SCALE} = $cursor->{SCALE}->[$i];
		$TI[$i]{PRECISION} = $cursor->{PRECISION}->[$i];
		$TI[$i]{TYPE} = $SQLTY_INV{ $cursor->{TYPE}->[$i] }; # %5d or %-17s
		#$TI[$i]{NULLABLE} = ('NoNULL','NULL','Unknown')[$cursor->{NULLABLE}->[$i]];
		$TI[$i]{NULLABLE} = $cursor->{NULLABLE}->[$i];
		# %32s %4d %4d %-17s  %-7s
	}
	$cursor->finish();

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("(getstruct_tableMetadata) RETRIEVE TABLE META DATA FOR:\n\tTABLE $table\n\n");
	$class-> _tracingE("");

	return \@TI;
}


########################################################################################
########################################################################################
# TODO: move this function from OraPool.
#oraDBMS_getDLL
#C<oraDBMS_getDLL()> works only with Oracle. This method uses Oracle DBMS to
#get the DLL of a specific table.
#
#*oraDBMS=\&oraDBMS_getDLL;
#*dbms=\&oraDBMS_getDLL;
sub oraDBMS_getDLL {
	my $class = shift;
	my $table = shift;

	return unless ($class-> dbdriver =~ /Oracle/i);

	my $username = uc $class-> dbusername;
	my $qry = qq{select dbms_metadata.get_ddl('TABLE','$table','$username') from dual};
	#$class->{connection}-> do($qry);

	my $cursor = $class->{connection}->prepare( $qry );

	$class->{cursor} = $cursor;

	$class->{cursor}->execute();
	$class->{rows} =  $class->{cursor}->rows;
	my $temp;
	my $key;
	my $i = -1; # -1 is nothing fetched

	while ($temp =  $class->{cursor}->fetchrow_hashref()) {
		$i++; # start counting at 0
		my %hr = %$temp;

		###push(@{$hh},\%hr); # Equivalent
		#foreach my $k (keys %hr) {
		#	print "$k <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n $hr{$k} ----\n\n";
		#}
	}
	$class->{cursor}->finish();

	#my $info = "\n\n";
	#$info .= "TABLE_SCHEMA   TABLE_NAME                               TABLE_ROWS CREATE_TIME          UPDATE_TIME\n";
	#$info .= "============== ======================================== ========== ==================== ====================\n";
	#for (my $i=0; $i < @$hh; $i++) {
	#	$info .= sprintf "%-14s %-40s %-10s %-20s %-20s\n", $$hh[$i]{TABLE_SCHEMA}, $$hh[$i]{TABLE_NAME},$$hh[$i]{TABLE_ROWS},$$hh[$i]{CREATE_TIME} ,$$hh[$i]{UPDATE_TIME};
	#}

	#$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	#$class->_tracing("RETRIEVE_INOBJECTS:\n\tfrom TABLE $infotable -- ROWS OK = $class->{rows} \n\t$q\n\n");

}

##############################################################################
#
# schema1.txt

#*dbstatus {
sub dbschema {
	my $class = shift;

	#TODO: die unless $dbb eq 'mysql' ... CHECK AS WELL THE VERSION!
	return unless ($class-> dbdriver =~ /Mysql/i);

	my $infotable =  'INFORMATION_SCHEMA.TABLES';

	my $dbname = shift;

	my $tablelike = shift;

	my $s2 = "TABLE_SCHEMA = '$dbname' AND TABLE_NAME LIKE '$tablelike\%'";

	my $hh = shift;

	my $seeked = 'all';
	my(@A) = ();
	
	my $s1 = '';
	my @infoelms = qw(TABLE_SCHEMA TABLE_NAME CREATE_TIME UPDATE_TIME TABLE_ROWS);
	for (my $j=0; $j < @infoelms; $j++) 
	{
		push(@A,$infoelms[$j]);
		$s1 .= $infoelms[$j] . ',';
	}
	chop($s1); $s1 .= ' ';

	my 	$q = "SELECT $s1 FROM $infotable WHERE $s2;";

	my $cursor = $class->{connection}->prepare( $q );

	$class->{cursor} = $cursor;

	$class->{cursor}->execute();
	$class->{rows} =  $class->{cursor}->rows;
	my $temp;
	my $key;
	my $i = -1; # -1 is nothing fetched

	while ($temp =  $class->{cursor}->fetchrow_hashref()) {
		$i++; # start counting at 0
		my %hr = %$temp;

		push(@{$hh},\%hr); # Equivalent
	}
	$class->{cursor}->finish();

	my $info = "\n\n";
	$info .= "TABLE_SCHEMA   TABLE_NAME                     TABLE_ROWS CREATE_TIME          UPDATE_TIME\n";
	$info .= "============== ============================== ========== ==================== ====================\n";
	for (my $i=0; $i < @$hh; $i++) {
		$info .= sprintf "%-14s %-30s %-10s %-20s %-20s\n", $$hh[$i]{TABLE_SCHEMA}, $$hh[$i]{TABLE_NAME},$$hh[$i]{TABLE_ROWS},$$hh[$i]{CREATE_TIME} ,$$hh[$i]{UPDATE_TIME};
	}

	$class->{src} = [caller]; push(@{$class->{src}},(caller 1)[3] || '');
	$class-> _tracingB("RETRIEVE_INOBJECTS:\n\tfrom TABLE $infotable -- ROWS OK = $class->{rows} \n\t$q\n\n");

	return $info;
}

##############################################################################
#
# schema2.txt

sub getInfoSchema {
	my $class = shift;

#mysql> describe  INFORMATION_SCHEMA.statistics;
# select SEQ_IN_INDEX,TABLE_SCHEMA,TABLE_NAME,CARDINALITY,COLUMN_NAME from INFORMATION_SCHEMA.statistics WHERE TABLE_SCHEMA='VARIGENE' AND TABLE_NAME='VS00000001_PROCESSORS_RSLTPARAMS';
my @infsch_statistics = qw(
 TABLE_CATALOG 
 TABLE_SCHEMA 
 TABLE_NAME  
 NON_UNIQUE 
 INDEX_SCHEMA  
 INDEX_NAME   
 SEQ_IN_INDEX 
 COLUMN_NAME 
 COLLATION  
 CARDINALITY 
 SUB_PART   
 PACKED    
 NULLABLE  
 INDEX_TYPE 
 COMMENT
);

#mysql> describe  INFORMATION_SCHEMA.columns;
my @infsch_columns = qw(
 TABLE_CATALOG
 TABLE_SCHEMA      
 TABLE_NAME       
 COLUMN_NAME     
 ORDINAL_POSITION 
 COLUMN_DEFAULT  
 IS_NULLABLE    
 DATA_TYPE     
 CHARACTER_MAXIMUM_LENGTH 
 CHARACTER_OCTET_LENGTH  
 NUMERIC_PRECISION      
 NUMERIC_SCALE         
 CHARACTER_SET_NAME   
 COLLATION_NAME      
 COLUMN_TYPE        
 COLUMN_KEY        
 EXTRA            
 PRIVILEGES      
 COLUMN_COMMENT 
	);

	die "ConnectionManager > getInfoSchema IS NOT IMPLEMENTED!\n";
}
########################################################################################
########################################################################################
########################################################################################
########################################################################################
sub textFormattedAO {
my $class = shift;
my $ah = shift;
my $_titlen = shift;
my $labmap = @_ ? shift : undef;

my @_titlen = $_titlen ? @$_titlen : ();
#my @_titlen = @$_titlen;
my $titlen = \@_titlen;

	# to keep order and for any reason nothing is given, then ...
	my @realmap;
	my @reallen;
	foreach my $k (sort keys %{$$ah[0]}) {
		push(@realmap,$k);
		my $len = 18;
		push(@reallen,$len);
	}

my @titmap;
my @titlen;
while (my($tit,$len)=splice @$titlen, 0, 2) {
	push(@titmap,$tit);
	push(@titlen,$len);
}
# If for any reason nothing is given, then ...
if (!@titmap) { @titmap=@realmap; @titlen=@reallen; }

my @labmap = $labmap ? map($$labmap{ $titmap[$_] },(0..@titmap)) : @titmap;

my @sprt;
my $underline = '';
my $info = "\n\n";
for (my $i=0; $i< @titmap; $i++) {
	# my $tit = $titmap[$i];
	my $tit = $labmap[$i];
	my $len = $titlen[$i];
	my $clab = (length($tit) <= $len) ? $tit : substr $tit,0,$len;
	$info .= $clab;
	my $hump = $len - length($tit) + 1;
	$info .= ' ' x $hump;
	$underline .= '*' x $len;
	$underline .= ' ';
	push(@sprt, "%-" . $len . 's');
}
$info .= "\n";
$info .= $underline;
$info .= "\n";
#	$info .= "Processorid             Author                   Prss Type\n";
#	$info .= "**********************  *********************  ****************\n";

	#my @a = qw(processorid author prsstype);
	#my @a = @$titmap;
	#my $ah = $prrg->listProcessors();
	#my $count = @$ah;
	for (my $i=0; $i < @$ah; $i++) {
	    my(@a) = @{ %{$$ah[$i]} } { @titmap };
        #$info .= sprintf "%-22s  %-22s  %-16s \n", $processorid,$author,$prsstype;
		for (my $i=0; $i<@a; $i++) {
			my $sprt = $sprt[$i];
			my $val = $a[$i];
			#$info .= sprintf "%-22s ",$_;
			$info .= sprintf "$sprt ",$val;
		}
		$info .= "\n";
	}
return @$ah ? $info : '';
#print $info if @$ah;
}


########################################################################################
########################################################################################
sub datalinesFormattedAO {
my $class = shift;
my $ah = shift;
my $_titlen = shift;
my $labmap = @_ ? shift : undef;

my @_titlen = $_titlen ? @$_titlen : ();
#my @_titlen = @$_titlen;
my $titlen = \@_titlen;

my $lninfo = {
	TITLE_LINE => '',
	UNDERLINE => '',
	DATA_LINES => [],
};

	# to keep order and for any reason nothing is given, then ...
	my @realmap;
	my @reallen;
	foreach my $k (sort keys %{$$ah[0]}) {
		push(@realmap,$k);
		my $len = 18;
		push(@reallen,$len);
	}

my @titmap;
my @titlen;
while (my($tit,$len)=splice @$titlen, 0, 2) {
	push(@titmap,$tit);
	push(@titlen,$len);
}
# If for any reason nothing is given, then ...
if (!@titmap) { @titmap=@realmap; @titlen=@reallen; }

my @labmap = $labmap ? map($$labmap{ $titmap[$_] },(0..@titmap)) : @titmap;

my @sprt;
my $underline = '';
my $info = "\n\n";
for (my $i=0; $i< @titmap; $i++) {
	# my $tit = $titmap[$i];
	my $tit = $labmap[$i];
	my $len = $titlen[$i];
	my $clab = (length($tit) <= $len) ? $tit : substr $tit,0,$len;
	$info .= $clab;
	my $hump = $len - length($tit) + 1;
	$info .= ' ' x $hump;
	$underline .= '*' x $len;
	$underline .= ' ';
	push(@sprt, "%-" . $len . 's');
}
$info .= "\n";
$$lninfo{TITLE_LINE} = $info;
$info .= $underline;
$info .= "\n";
$$lninfo{UNDERLINE} = "$underline\n";
	#$info .= "Processorid             Author                   Prss Type\n";
	#$info .= "**********************  *********************  ****************\n";

	#my @a = qw(processorid author prsstype);
	#my @a = @$titmap;
	#my $ah = $prrg->listProcessors();
	#my $count = @$ah;
	for (my $i=0; $i < @$ah; $i++) {
		my $ln;
	    my(@a) = @{ %{$$ah[$i]} } { @titmap };
		#$info .= sprintf "%-22s  %-22s  %-16s \n", $processorid,$author,$prsstype;
		for (my $i=0; $i<@a; $i++) {
			my $sprt = $sprt[$i];
			my $val = $a[$i];
			#$info .= sprintf "%-22s ",$_;
			$info .= sprintf "$sprt ",$val;
			$ln .= sprintf "$sprt ",$val;
		}
		$info .= "\n";
		$ln .= "\n";
		push(@{$$lninfo{DATA_LINES}},$ln);
	}
return @$ah ? $lninfo : undef;
#return @$ah ? $info : '';
#print $info if @$ah;
}


########################################################################################
########################################################################################
sub textFormattedAA {
my $class = shift;
my $aa = shift;
my $_titlen = shift;
my $labmap = @_ ? shift : undef;

my @_titlen = $_titlen ? @$_titlen : ();
#my @_titlen = @$_titlen;
my $titlen = \@_titlen;

	# to keep order and for any reason nothing is given, then ...
	my @realmap;
	my @reallen;
	my $i=0;
	my(@a) = @{ $$aa[$i] };
	for (my $i=0; $i<@a; $i++) {
		push(@realmap,$a[$i]);
		my $len = 18;
		push(@reallen,$len);
	}

my @titmap;
my @titlen;
while (my($tit,$len)=splice @$titlen, 0, 2) {
	push(@titmap,$tit);
	push(@titlen,$len);
}
# If for any reason nothing is given, then ...
if (!@titmap) { @titmap=@realmap; @titlen=@reallen; }


my @labmap = $labmap ? map($$labmap{ $titmap[$_] },(0..@titmap)) : @titmap;

my @sprt;
my $underline = '';
my $info = "\n\n";
for (my $i=0; $i< @titmap; $i++) {
	# my $tit = $titmap[$i];
	my $tit = $labmap[$i];
	my $len = $titlen[$i];
	my $clab = (length($tit) <= $len) ? $tit : substr $tit,0,$len;
	$info .= $clab;
	my $hump = $len - length($tit) + 1;
	$info .= ' ' x $hump;
	$underline .= '*' x $len;
	$underline .= ' ';
	push(@sprt, "%-" . $len . 's');
}
$info .= "\n";
$info .= $underline;
$info .= "\n";

	#for (my $i=0; $i < @$aa; $i++) {
	for (my $i=1; $i < @$aa; $i++) {
	    #my(@a) = @{ %{$$aa[$i]} } { @titmap };
	    my(@a) = @{ $$aa[$i] };
		my %rec = map{$realmap[$_]=>$a[$_]}(0..@realmap);
		my @z = @{ %rec } { @titmap };
		#for (my $i=0; $i<@a; $i++) {
		for (my $i=0; $i<@z; $i++) {
			my $sprt = $sprt[$i];
			#my $val = $a[$i];
			my $val = $z[$i];
			$info .= sprintf "$sprt ",$val; # "%-22s ",$_
		}
		$info .= "\n";
	}
return @$aa ? $info : '';
}


########################################################################################
########################################################################################
sub datalinesFormattedAA {
my $class = shift;
my $aa = shift;
my $_titlen = shift;
my $labmap = @_ ? shift : undef;

#PERL 6!: return $class-> textFormattedAA($aa,$_titlen,$labmap) unless wanthash();


my @_titlen = $_titlen ? @$_titlen : ();
my $titlen = \@_titlen;

my $lninfo = {
	TITLE_LINE => '',
	UNDERLINE => '',
	DATA_LINES => [],
};

	# to keep order and for any reason nothing is given, then ...
	my @realmap;
	my @reallen;
	my $i=0;
	my(@a) = @{ $$aa[$i] };
	for (my $i=0; $i<@a; $i++) {
		push(@realmap,$a[$i]);
		my $len = 18;
		push(@reallen,$len);
	}

my @titmap;
my @titlen;
while (my($tit,$len)=splice @$titlen, 0, 2) {
	push(@titmap,$tit);
	push(@titlen,$len);
}
# If for any reason nothing is given, then ...
if (!@titmap) { @titmap=@realmap; @titlen=@reallen; }

my @labmap = $labmap ? map($$labmap{ $titmap[$_] },(0..@titmap)) : @titmap;

my @sprt;
my $underline = '';
my $info = "\n\n";
for (my $i=0; $i< @titmap; $i++) {
	# my $tit = $titmap[$i];
	my $tit = $labmap[$i];
	my $len = $titlen[$i];
	my $clab = (length($tit) <= $len) ? $tit : substr $tit,0,$len;
	$info .= $clab;
	my $hump = $len - length($tit) + 1;
	$info .= ' ' x $hump;
	$underline .= '*' x $len;
	$underline .= ' ';
	push(@sprt, "%-" . $len . 's');
}
$info .= "\n";
$$lninfo{TITLE_LINE} = $info;
$info .= $underline;
$info .= "\n";
$$lninfo{UNDERLINE} = "$underline\n";

	#for (my $i=0; $i < @$aa; $i++) {
	for (my $i=1; $i < @$aa; $i++) {
		my $ln;
	    #my(@a) = @{ %{$$aa[$i]} } { @titmap };
	    my(@a) = @{ $$aa[$i] };
		my %rec = map{$realmap[$_]=>$a[$_]}(0..@realmap);
		my @z = @{ %rec } { @titmap };
		#for (my $i=0; $i<@a; $i++) {
		for (my $i=0; $i<@z; $i++) {
			my $sprt = $sprt[$i];
			#my $val = $a[$i];
			my $val = $z[$i];
			$info .= sprintf "$sprt ",$val; # "%-22s ",$_
			$ln .= sprintf "$sprt ",$val;
		}
		$info .= "\n";
		$ln .= "\n";
		push(@{$$lninfo{DATA_LINES}},$ln);
	}
#return @$aa ? $info : '';
return @$aa ? $lninfo : undef;
}

########################################################################################
########################################################################################
########################################################################################
########################################################################################

1;

########################################################################################
{
package DBI::BabyConnect::Deb;

# IO::Socket needed for the autoflush() in the PRINT sub
# we will include this once and for all, instead of including 
# it in the caller packages (in particular need by the author
# application to debug Varisphere multithread DVARs)
use IO::Socket;

use strict;
#use Carp;
use Symbol;

sub _no_filter { return $_[0]; }

sub TIEHANDLE
{
	my ($class, %args) = @_;
	my $handle = gensym();

	my $impl = bless {handle => gensym() }, $class;
	$impl->OPEN(%args);
	return $impl;
}

sub OPEN {
	my ($impl, %args) = @_;
	#open $impl->{handle}, $args{file} or croak "Could not open that '$args{file}'";
	open $impl->{handle}, $args{file} or die "Could not open that '$args{file}'";
	$impl->{in_filter} = $args{in} || \&_no_filter,
	$impl->{out_filter} = $args{out} || \&_no_filter,
}

sub SEEK {
	my ($impl, $position, $whence) = @_;
	return sysseek($impl->{handle}, $position, $whence);
}

sub WRITE {
	my ($impl, $buffer, $length, $offset) = @_;
	$buffer = $impl->{out_filter}->($buffer);
	syswrite($impl->{handle}, $buffer, $length, $offset||0);
}

sub PRINT {
	my ($impl, @data) = @_;
	my $filter = $impl->{out_filter};
	@data = map { $filter->($_) } @data;
	print { $impl->{handle} } @data;
	#$|=1;
	$impl->{handle}->autoflush();
}

sub PRINTF {
	my ($impl, $format, @data) = @_;
	my $filter = $impl->{out_filter};
	print { $impl->{handle} } $filter->(sprintf $format, @data);
	#$impl->{handle}->autoflush();
}

sub READ {
	my ($impl, $data, $length, $offset) = @_;
	my $result = sysread($impl->{handle}, $data, $length);
	substr($_[1],$offset||0,$length) = $impl->{in_filter}->($data);
	return $result;
}

sub GETC {
	my ($impl) = @_;
	$impl->{in_filter}->(getc $impl->{handle});
}

sub READLINE {
	my $impl = @_;
	$impl->{in_filter}->(scalar readline *{$impl->{handle}});
}

sub CLOSE {
	my $impl = @_;
	close $impl->{handle};
}


sub new {
	my ($class, %args) = @_;
	my $self = gensym();
	tie *{$self}, $class, %args;
	bless $self, $class;
}

sub AUTOLOAD {
	use vars qw( $AUTOLOAD );   # keep use strict
	my ($self, @args) = @_;
	return if $AUTOLOAD =~ /::DESTROY$/;	
	$AUTOLOAD =~ s/.*:://;
	$AUTOLOAD =~ tr/a-z/A-Z/;
	tied(*{$self})->$AUTOLOAD(@args);
}

1;

}


########################################################################################
# Pooling, package DBI::BabyConnect::BabiesPool
#
# DBI::BabyConnect::BabiesPool
# DBI::BabyConnect::BabiesPool::InitAndLoad
# DBI::BabyConnect::BabiesPool::Free
# DBI::BabyConnect::BabiesPool::ReconnectConnector
# DBI::BabyConnect::BabiesPool::DupConnector
# DBI::BabyConnect::BabiesPool::AddConnector
# DBI::BabyConnect::BabiesPool::FreeConnector
# DBI::BabyConnect::BabiesPool::StatConnector
# DBI::BabyConnect::BabiesPool::ChildConnector
# DBI::BabyConnect::BabiesPool::Stat
#

__END__

=head1 NAME

DBI::BabyConnect - creates an object that holds a DBI connection to a database

=head1 SYNOPSIS

  use DBI::BabyConnect;

  # get a DBI::BabyConnect object to access the database as described by 
  # the database descriptor BABYDB_001
  my $bbconn = DBI::BabyConnect->new('BABYDB_001');

  # direct all STDERR to be appended to /tmp/error.log
  $bbconn->HookError(">>/tmp/error.log");

  # append trace information to /tmp/db.log and print DBI::trace set to level 1
  $bbconn->HookTracing(">>/tmp/db.log",1);

  # create the table TABLE1 based on the schema coded in TEST_TABLE.mysql, if
  # table TABLE1 is found, then drop it first then recreate it
  $bbconn->recreateTable('TEST_TABLE.mysql','TABLE1');

  my $sql = qq{
       INSERT INTO TABLE1
       (DATASTRING,DATANUM,IMAGE,RECORDDATE_T)
       VALUES
       (?,?,?,SYSDATE())
     };
  $bbconn-> sqlbnd($sql,$dataStr,1000,$imgGif);


=head1 DESCRIPTION

This class is the base class for all DBI connection objects instantiated
by the DBI::BabyConnect module.  A DBI::BabyConnect instance
is an object that holds the database handler attributes and an active DBI
connection handle to a specific database.
The current module support many drivers that can be loaded by the DBD, but
it has been tested using the C<DBD::MySQL>, with a limited testing using C<DBD::Oracle> driver
and the C<DBD::ODBC> driver.
The class enclude the fundamental methods to insert, update, and get data from
the database, and it hides the complexity of the many DBI methods that are
required otherwise to be programmed by yourself. Programmers do not need
to do binding of data or use the may form of fetch methods.
The methods should work for any database, and currently they have been tested with
MySQL and Oracle.

=head2 NOTE

Before using the module DBI::BabyConnect, make sure that you understand how the module C<DBI> works,
and in particular the attributes that can affect a DBI connection as such: RaiseError, AutoCommit ...
In addition, if you want to understand how this module work from the inside out, you need to
have knowledge about the following Perl programming topics: how to localize a variable, how to
tie to a file handle, how to redirect IO, how to redirect Perl signals, and the meaning of exit(),
die() and DESTROY.

=head2 NOMENCLATURE AND CONVENTIONS

The following conventions are used in this document:

  $bbconn       a variable that is assigned an instance of a DBI::BabyConnect object
  BABYCONNECT   environment variable that is set to the URI where DBI::BabyConnect will find its configuration files
  databases.pl  the file that contains descriptors, each of which describe how to connect to a database using DBI
  globalconf.pl the file that contains settable flags that will control globally the behavior of a DBI::BabyConnect object
  BBCO          a DBI::BabyConnect object

=head2 Architecture of an Application using DBI::BabyConnect

  +-----------------+
  |Perl             |   +----------------+
  |script           |   |                |---|BBCO1|--|DBI XYZ Driver|----|XYZ Engine|----|some database| 
  |using            |---+DBI::BabyConnect|---|BBCO2|--|DBI XYZ Driver|----|XYZ Engine|----|some database| 
  |DBI::BabyConnect |   |                |--- ...
  |                 |   +----------------+
  +-----------------+

The DBI::BabyConnect creates an object instance to access a data source as being
described by a database descriptor.

The XYZ driver can be any driver that is loaded by DBI. The current distribution has
been tested with MySQL and Oracle.

BBCO's do not need to be using the same driver for all simultaneous connection. For instance BBCO1
can be using MySQL driver and BBCO2 can be using an Oracle driver. Therefore, an
application using DBI::BabyConnect should be able to access many different data sources
from the same program.

If your application needs only to read data from the database then you should be able to use
DBI::BabyConnect to access the database concurrently by starting several processes
with DBI::BabyConnect objects.

If your application need to write to the data source, you can still use DBI::BabyConnect objects
to write concurrently, however you need to be known what you are doing.


=head1 GETTING STARTED

The DBI::BabyConnect distribution comes with a set of sample programs to assist you in
testing your installation. All programs are located in eg/ directory. The file eg/README
show a roadmap on how to use the programs. You need to have MySQL installed, and you need
to create the database BABYDB.

The distribution also comes with a configuration/ directory. You need to locate the
file configuration/dbconf/databases.pl and make the proper moditication to
the descriptors so that you can access the databases.

=head1 USAGE

This class has the following methods:

=head2  new

  new( $descriptor )

Given a valid database descriptor name, this method returns a DBI::BabyConnect object 
connected to the datasource that is described by the database descriptor.
In other words, given a valid database descriptor name, this method returns an object
blessed into the appropriate DBD driver subclass. The object holds
the attributes of the database handle as initially requested
when instantiating the connection. The object also holds a pointer
or a reference to the active connection.

The class provides methods to alter the attributes of the active
connection held in the object, allowing to enable or disable the exceptions raised
by the DBI module, along with the print error, the auto commit,
and the rollback of transactions (that pertain to the active database
handle).

You can call C<new()> with different descriptors, hence allowing you to connect
to multiple data sources from the same program.


=head2 HookError

  HookError( $filename )

Given a valid instance of a DBI::BabyConnect object, this method hooks
the STDERR filehandle to a filename.
The writing of information to STDERR is then directed to the specified file.
This is useful in situations where you want to debug CGI programs that
use the DBI::BabyConnect or for developers who want to debug the module
itself. DBI error messages will also be redirected to the handle
open by the method HookError().

=head2 HookTracing

 HookTracing( $filename [,tracelevel] )

Given a valid instance of a DBI::BabyConnect object, this method hooks
a filehandle to a filename, and sets the trace flag
of the module to true. The logging of information is then directed to
the specified file. 

Optionally, if you pass a tracelevel as the second argument, then the
DBI::trace is enabled with that level. Select a level
of 0 for no DBI::trace, 1 for minimal information, 2 for more information, etc.
For instance, if tracelevel is set to 3 then
a select statement (such as C<fetchQdaAA()>) will log extensive information
to the file, writing the result to the file.
Setting the tracelevel to 1 will always reveal the query statements passed
to DBI.

In a production environment, it is B<strongly> recommended that you do not
specify any tracelevel by setting tracelevel to 0 or by not calling
this method HookTracing() at all.


=head1 BABYCONNECT Environment Variable

The module DBI::BabyConnect looks for the environment variable BABYCONNECT to
locate its configuration directory. The configuration directory holds the
database descriptors file (databases.pl), database configuration files (*.conf files),
a global configuration file (globalconf.pl), and skeletons for SQL tables.

A typical configuration tree is shown below:

    configuration/
    |-- SQL
    |   `-- TABLES
    |       |-- TEST_BABYCONNECT.mysql
    |       |-- TEST_TABLE.mysql
    |       `-- TEST_TABLE.ora
    `-- dbconf
        |-- databases.pl
        `-- globalconf.pl


The B<globalconf.pl> file contains global configuration parameters that affect
all connections to the data sources. The B<globalconf.pl> file is explained in the
section L<"Database Global Configuration File">.

The B<databases.pl> file contains a set of database descriptors each of which describes
the connection to a data source. The B<databases.pl> file is explained in the 
section L<"Database Descriptors File">.

Skeleton tables are located in ./configuration/SQL/TABLES/, these tables are used by
C<recreateTable> method to drop and recreate database
tables.

Setting the environment variable can be achieved by exporting the environment
variable. For instance if your configuration directory is in /opt/DBI-BabyConnect-0.93:
  export BABYCONNECT=/opt/DBI-BabyConnect-0.93/configuration

In a Perl script or a Perl module, you can programmatically set the environment variable in
the BEGIN block:

  BEGIN{ $ENV{BABYCONNECT}='/opt/DBI-BabyConnect-0.93/configuration'; }

If you are using persitent DBI::BabyConnect objects by loading the C<Apache::BabyConnect>
module in Apache MD2, then you need to setup the variable prior to loading
the module; the simplest way is to use the Apache configuration directive PerlSetEnv:

  PerlSetEnv BABYCONNECT /opt/DBI-BabyConnect-0.93/configuration

Refer to C<Apache::BabyConnect> for more information about using DBI::BabyConnect
persistence with Apache MD2.

=head1 Database Global Configuration File

The B<globalconf.pl> contains several settable parameters that are
global to the DBI::BabyConnect object. The following is a list of
these parameters:

L<"CALLER_DISCONNECT">

L<"ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT">

L<"DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING">

L<"ENABLE_STATISTICS_ON_DO">

L<"ENABLE_STATISTICS_ON_SPC">

=head2 CALLER_DISCONNECT

The B<CALLER_DISCONNECT> enforces a check up on whether the caller has disconnected
or not from DBI before DBI::BabyConnect::DESTROY method is called. If you want to
depend on DBI::BabyConnect to disconnect automatically upon the object destruction
then set this to 0. Typically, you do not need to call disconnect on a live DBI::BabyConnect
object, because such an object is always connected with the same DBI handle for the duration of the
object.

Set CALLER_DISCONNECT to 1 if you want to explicitly call DBI::BabyConnect::disconnect on
a live DBI::BabyConnect object so that you disconnect the obejct from DBI yourself.
Whenever you L<"disconnect"> or whenever the DBI::BabyConnect
object is destroyed it will check whether you have explicitly disconnected or not, and print
to STDERR the state of your DBI::BabyConnect. It will also check if you are trying to
disconnect on an already disconnected DBI::BabyConnect object. Such information is useful to keep
in control of the DBI handles.

For simplicity, set CALLER_DISCONNECT=0, to allow automatic disconnection and delegate the
disconnection to the DBI::BabyConnect object.

=begin comment more about this

It is the responsibility of the caller to disconnect. The state of
the DBI::BabyConnect handle is being checked either when you explicitly call disconnect,
or when DESTROY is being called (since it is necessary to disconnect upon
destruction (unless the DBI::BabyConnect instance has been loaded with
PERSISTENT_OBJECT_ENABLED set to 1)

=end comment


=head2 ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT

You may not need to set ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT
to 1 to rollback if you call exit() from within your program
(since exit() will eventually call DBI::BabyConnect::DESTROY),
or if you end the class or program that uses DBI::BabyConnect
(as the DESTROY is the last to be called even in Apache::BabyConnect)
In either case, whenever DESTROY is called, if the autorollback is 1 and autocommit is 0
and the DBI execute has returned with failure, then the rollback is in effect.

The caller can always catch and check the return value of a DBI::BabyConnect method
to see if it has failed a DBI execute. Typically DBI::BabyConnect methods return undef
whenever a DBI execute fails and therefore the caller can check the return
value and decide on whether to call the DBI::BabyConnect object method rollback himself or not,
therefore allowing the caller to continue to work with the instance of DBI::BabyConnect object
and its open DBI connection.
Yet, you can configure the behavior of the DBI::BabyConnect object methods globally
and tell the object methods to automatically rollback and exit on failure.

This option is settable and will work only if AutoRollback is in effect for the
DBI, because DBI::BabyConnect objects delegate all rollbacks to the DBI itself.

  DBI rollback is in effect if and only if:
  RaiseError is 0 (it should be off because otherwise the DBI would have exited earlier due to the error)
  AutoCommit is 0 (DBI will have no effect on rollback is AutoCommit is set to 1)

DBI::BabyConnect will keep track of the success or failure of DBI execute(), hence deciding on
what to do on failure.

DBI will not exit if the conditions on the rollback are not met, but it will
continue without effectively rolling back.

For these DBI::BabyConnect objects that have been instantiated by loading the
DBI::BabyConnect with PERSISTENT_OBJECT_ENABLED set to 1

  use DBI::BabyConnect 1, 1;

this option will do a rollback but the exit() is redirected to Apache::exit() as it
is documented by mod_perl, in which case only the perl script will exit at this point.
See eg/perl/testrollback.pl

If for any reason the HTTP child is terminated, or the CORE::exit() is called, or CORE::die()
is called, or anything that will terminate the program and call the DESTROY of a DBI::BabyConnect
instance, then this DESTROY will still check to see if a rollback conditions are met
to do an effective rollback; this is different than the behavior of other application
that do persistence using Apache, as the mechanism of rollback is carried externally of Apache
handlers and is being dispatched within the DBI::BabyConnect object itself.

=head2 DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING

When inserting new data, a scalar that refers to an empty string "" will normally
keep the default value of the attribute in the database, i.e. NULL. You can
set DBSETTING_FORCE_SINGLESPACE_FOR_EMPTY_STRING=1 to force the writing of
a single space instead of keeping the default NULL.

=head2 ENABLE_STATISTICS_ON_DO

When ENABLE_STATISTICS_ON_DO is set to 1, a DBI::BabyConnect object maintains
a table to hold statistics about the L<"do">'s requested by identifying each entry
with the query string being passed to the L<"do"> method. The programmer can
then call get_do_stat() to get the object that hold the statistics.
Do not enable this unless you need to collect statistics, for instance in
data warehousing environment the queries to do() are limited in format
and are time consuming, so you may desire to collect statistics about these
do()'s queries.


=head2 ENABLE_STATISTICS_ON_SPC

When ENABLE_STATISTICS_ON_SPC is set to 1, a DBI::BabyConnect object maintains
a table to hold statistics about the spc()'s requested by identifying each entry
with the stored procedure name passed to the spc() method. The programmer can
then call get_spc_stat() to get the object that hold the statistics.
Do not enable this unless you need to collect statistics, for instance in
data warehousing environment the stored procedure names passed spc() are limited in number
and are time consuming, so you may desire to collect statistics about these
spc()'s stored procedures.


=head1 Database Descriptors File

The databases.pl file holds a set of database descriptors. The database descriptor
is an object whose attributes describe a specific connection to a data source, that is
to what database to connect, how to connect, and to handle the connection
programmatically in case of failure.



	BABYDB_001 =>
	{
		Driver => 'Mysql',
		Server=>'',
		UserName=>'admin',
		Password=>'adminxyz',
		# Mysql defines a database name, CAREFUL it may be case sensitive!
		DataName=>'BABYDB',
		PrintError=>1,
		RaiseError=>1,
		AutoRollback => 1,
		AutoCommit=>1,
		LongTruncOk=>1,
		LongReadLen => 900000,
	}

A descriptor specifies the driver name, the database name, and how to authenticate to connect
to the database. DBI::BabyConnect allows you to have multiple descriptors each of which
can be used by a DBI::BabyConnect object instance to connect to the data source.

Because it is possible to have multiple descriptors, and you can instantiate multiple
DBI::BabyConnect objects, then it is possible to connect to several data sources 
from a single program. For example, it is possible to connect concurrently from the same
program to MySQL database located on a server A, to another MySQL database located
on server B, to an Oracle database located on server C, and so on.

=head2 Database Handle Attributes

For each of the active database connection, there are six attributes
that are defined:

=over 2

=item 1 
RaiseError 

=item 2
PrintError 

=item 3
AutoCommit 

=item 4
AutoRollback 

=item 5
LongTruncOk

=item 6
LongReadLen

=back

The first two attributes, LongTruncOk and LongReadLen, are defined for the
duration of the active database connection. These two attributes cannot be
altered after instantiating an initial connection.

The first four attributes, RaiseError, PrintError, AutoCommit, and AutoRollback,
are boolean attributes and can be modified during the run time of a DBI::BabyConnect
object. To change or check any of these attributes, the class provides setter
and getter methods.

For an instance of a DBI::BabyConnect object, the flag attributes can be altered during
run time. Altering the flag attributes allow you to control the behavior of
an active database connection before and during each query (i.e.
using a C<do()>, C<spc()>, C<getQdaAA()>, C<getTdaAA()>, etc). 

When the attribute AutoRollback is set to true, the module will handle
the rollback of a transaction on failure; this assumes that the AutoCommit has
been set to false. If the AutoCommit has been set to true, and a database
transaction fails than the AutoRollback has no effect, and the DBD::DBI will
return a string I<rollback ineffective with AutoCommit enabled>.
Note also that you need to have L<"ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT"> set to 1.

=head1 Connection Attribute Functions

This class contains several functions to retrieve, store, or set the attributes 
of the DBI::BabyConnect object.


=head2 getActiveDescriptor

getActiveDescriptor() returns the information about the current DBI::BabyConnect object
that is initialized with the specified descriptor.

getActiveDescriptor() takes an optional argument, a hash reference,
the method returns the information in that hash reference.

If no argument is passed then the method returns a string of information describing
the DBI::BabyConnect object.

You can gather the DBI::BabyConnect object itself by passing a hash reference, then
dereferencing it. For example:

    $bbconn-> getActiveDescriptor($h);
    my $bbconn2 = $$h{Connection};
	# now $bbconn and $bbconn2 are the same

    my $bbconn3 = $bbconn-> connection;
    # now $bbconn, $bbconn2, and $bbconn3 are all the same

    # you can get the DBI::db handle used by the DBI::BabyConnect
    my $dbh = $$h{DBIhandle};

Usually you do not need to use the method getActiveDescriptor(). This method is provided
to experiment with multi-threaded DBI::BabyConnect objects.

=head2 saveLags

Given a C<DBI::BabyConnect> object, this method save the attribute flags:
PrintError, RaiseError, AutoCommit, and AutoRollback, to a temporary object.

=head2 restoreLags

Given a C<DBI::BabyConnect> object, this method restore the attribute flags:
PrintError, RaiseError, AutoCommit, and AutoRollback, from the temporary object.

=head2 resetLags

Given a C<DBI::BabyConnect> object, this method reset the attribute flags:
PrintError, RaiseError, AutoCommit, and AutoRollback, to their original values
as they have been set at object initialization. These are the values of
the database descriptor used when creating the C<DBI::BabyConnect> object. See
L<"Database Descriptors File">.

=head2 connection

Given a C<DBI::BabyConnect> object, this method returns the DBI::db handle to
the data source to which the object is connected.

=head2 dbname

Given a C<DBI::BabyConnect> object, this method returns the name of the
data source to which the object is connected.

=head2 dbserver

Given a C<DBI::BabyConnect> object, this method returns the server
name where the data source is located.

=head2 dbdriver

Given a C<DBI::BabyConnect> object, this method returns the driver name
being used by the object to connect to the data source.

=head2 dbusername

Given a C<DBI::BabyConnect> object, this method returns the username used
to authenticate the connection to the data source.

=head2 printerror

Given a C<DBI::BabyConnect> object, this method returns the state of the
B<PrintError> attribute flag as it is being set to the active connection of the object. 

If you pass an argument (0 or 1) to this method, then the method
acts as a setter, setting the flag to that value.

If PrintError is set to true (1) then the DBI will print warning and
error to STDERR.

Initially, when a DBI::BabyConnect object is created (using the C<new()> method),
this flag is set to the value read from the database descriptor. Refer to L<"Database Descriptors File">.

The current state of the flag can also be revealed by printing the
information string returned by C<get_handle_flags()>


=head2 raiseerror

Given a C<DBI::BabyConnect> object, this method returns the state of the
B<RaiseError> attribute flag as it is being set to the active connection of the object. 

If you pass an argument (0 or 1) to this method, then the method
acts as a setter, setting the flag to that value.

If RaiseError is set to true (1) then the connection will break if
the DBD::DBI encounter an error, that is because DBD::DBI will raise
the error and exit.

Initially, when a DBI::BabyConnect object is created (using the C<new()> method),
this flag is set to the value read from the database descriptor. Refer to L<"Database Descriptors File">.

The current state of the flag can also be revealed by printing the
information string returned by C<get_handle_flags()>


=head2 autorollback

Given a C<DBI::BabyConnect> object, this method returns the state of the
B<AutoRollback> attribute flag as it is being set to the active connection of the object. 

If you pass an argument (0 or 1) to this method, then the method
acts as a setter, setting the flag to that value.

If AutoRollback is set to true (1) then if a DBI execute fails within
a transaction, DBI::BabyConnect rollback.

Initially, when a DBI::BabyConnect object is created (using the C<new()> method),
this flag is set to the value read from the database descriptor. Refer to L<"Database Descriptors File">.

Note, that the attribute AutoRollback is not one of the predefined attributes
used by the DBI module, and its behavior is defined internally to the
class DBI::BabyConnect.
The AutoRollback flag has no effect if set to true and AutoCommit flag
(settable with C<autocommit()>) is set to true. A rollback is not possible
if AutoCommit is set to true.

The current state of the flag can also be revealed by printing the
information string returned by C<get_handle_flags()>

=head2 autocommit

Given a C<DBI::BabyConnect> object, this method returns the state of the
B<AutoCommit> attribute flag as it is being set to the active connection of the object.

If you pass an argument (0 or 1) to this method, then the method
acts as a setter, setting the flag to that value.

If AutoCommit is set to true (1) then all transactions are being committed
to the database. If AutoCommit is set to true (1) then it is not possible
to rollback, and calling the rollback() will have no effect.

Initially, when a DBI::BabyConnect object is created (using the C<new()> method),
this flag is set to the value read from the database descriptor. Refer to L<"Database Descriptors File">.

The current state of the flag can also be revealed by printing the
information string returned by C<get_handle_flags()>

=head2 longtruncok

Given a C<DBI::BabyConnect> object, this method returns the state of the
B<LongTruncOk> attribute flag as it is being set to the active connection of the object.

=head2 longreadlen

Given a C<DBI::BabyConnect> object, this method returns the value of the
B<LongReadLen> attribute as it is being set to the active connection of the object.

=head1 Class Methods

Once a new DBI::BabyConnect instance is created successfully, then the instance has
a established a successfull database connection to a data source, and the C<new()> class
method will return a blessed object reference holding a database
connection handle which is established with the DBI, and storing internally
within the class object the initial database attributes.
We will refer to the I<instance object returned by DBI::BabyConnect> simply
with the I<BBCO>.

For each DBI::BabyConnect object that has been instantiated with the C<new()> method
of the C<DBI::BabyConnect> module, the module provides the
following methods:

=head2 recreateTable

  recreateTable( $table_template, $table_name )

Read a table template and create a table named $table_name. If the table name
exists then drop it and recreate it. See eg/createtables.pl for an example.

Note that the table template is read from one of the skeletons located in the directory $ENV{BABYCONNECT}/SQL/TABLES.
The skeleton files are text flat files that contains SQL commands. These files use the
tilda ~ as a seperator, and -- starting at the beginning of the line for comments.

=head2 recreateTableFromString

  recreateTableFromString( $tableStr, $table_name )

recreateTableFromString() is similar to recreateTable(), except that it takes
a table template as a string. See eg/recreateTableFromString_mysql.pl and eg/recreateTableFromString_ora.pl.

=head2 getTcount

  getTcount( $table, $column, $where )

getTcount() takes a database table name, a specific column name, and return the count of rows
where the $where condition is satisfied.

See eg/getTcount.pl for an example.

=for comment insertdumb( )
=for comment insertrec( )
=for comment sqlRawbnd( )

=head2 insertrec

  insertrec( $table, %rec )

insertrec() is a method that simply inserts a record in a database table. The method
takes two parameters: a table name, and a hash. The record is passed as a hash,
and the attributes specify the values of the data to be inserted. For all data that
is to be inserted as characters or binary, use a reference to a SCALAR. See eg/insertrec.pl
for an example.

For more constructive SQL inserts, use the method L<"sqlbnd">.

=head2 sqlbnd

sqlbnd() executes a SQL whose elements are specified by order and by type.

    sqlbnd( $sql, $o_bnd, $o_typ )

$sql is the SQL to be executed by the method

$o_bnd is a pseudo hash with the first element being a hash reference that specify the order
in which the elements will appear, and the following ordered elements specify the values of the elements.

$o_typ is a hash reference that maps each data element to its corresponding SQL type.
If you are using MySQL, you can set $o_typ to undef, since the MySQL DBD driver knows
how to handle the type. If you are using a different database than MySQL, such as
Oracle, then you need to specify the proper SQL type mapping for the elements. For instance,
when inserting a BLOB into Oracle, the SQL type for the BLOB element is 103.

Consult your driver manual for the SQL types of the driver you are using. Recall that
a DBI::BabyConnet object is initially created with the driver that is specified by
the database descriptor (see L<"Database Descriptors File">).

=for comment typ_insertbnd( $table, ... )

=for comment  typ_updatebnd( $table, $col, $e2Ty, $where)

=head2 do

  do( $query )

 On success:
   return the number of rows affected

 On failure:
    return undef on failure   if raiseerror=0 and autorollback=0
    will die (calling destroy) and will explicit-rollback and will not return if raiseerror=0 and autorollback=1
    will die (calling destroy) and will not return  if raiseerror=1 and autorollback=0


=head2 spc

  spc( $o, $stproc )

Calls the stored procedure $stproc whose parameters are prepared from the pseudo-hash
passed in $o.

spc method, takes a pseudo-hash as a first argument, and the
fully specified name of a stored procedure name as the second
argument. The method will setup the bindings of the parameters
before executing the stored procedure; if the value passed to
a parameter is undef, then the method will do a bind_param_inout,
otherwise it will simply bind it as bind_param.
On return, the method will set undefined parameters of the pseudo-hash
to the known values returned from the stored procedure.
Returns 1 on success and 0 on failure. The pseudo-hash contains the data values
returned by the stored procedure.

Currently, this method will call die() if it fails to execute the SQL of the stored procedure.

spc() works with Oracle stored procedure, the following code shows the package
that will dequeue messages from a persistent database queue:

 
 package DataManagement::Queue;
 
 use DBI::BabyConnect;
 
 # this mini sub-package only knows how to to dequeue
 # from our persisted database queue
 @ISA=(Queue);
 sub new {
     my $type = shift;
     my $db_descriptor = shift;
     my $_ORA_PKG  = 'PKG_DATA_MANAGEMENT';
     my $_QTABLE     = 'TASK_QUEUE';
 
     my $_bbconn =  DBI::BabyConnect->new($db_descriptor);
     #$_bbconn->HookTracing(">>/tmp/db.log",1);
     $_bbconn->printerror(1);
     $_bbconn->raiseerror(0);
     $_bbconn->autorollback(1);
     $_bbconn->autocommit(1);
     my $this = {
         _bbconn => DBI::BabyConnect->new($db_descriptor),
         _ORA_PKG  => $_ORA_PKG,
         _QTABLE     => $_QTABLE,
     };
     bless $this, $type;
 }
 
 sub hasNext {
     my $this = shift;
     my $o = shift;
 
     my $ORA_PKG = $this->{_ORA_PKG};
     $this{_bbconn}-> spc($o,"$ORA_PKG.spc_DequeueTask") && return 1;
     return 0;
 }
 sub getNext {
     my $this = shift;
     my $o = [ {task_key=>1,task_type=>2,task_arguments=>3}, undef,undef,undef];
     
     return undef unless $this-> hasNext($o);
     if (defined $$o{tsq_param}) {
         $this->{task_key}=$$o{task_key};
         $this->{task_type}=$$o{task_type};
         $this->{task_arguments}=$$o{task_arguments};
     }
     return $o;
 }
 
 1;

The package DataManagement::Queue use the Oracle stored procedure spc_DequeueTask stored
in the package ACME_DATAWAREHOUSE.PKG_DATA_MANAGEMENT.

 CREATE OR REPLACE PACKAGE BODY ACME_DATAWAREHOUSE.PKG_DATA_MANAGEMENT
	PROCEDURE spc_DequeueTask
	(
	task_key_out IN OUT TASK_QUEUE.TASK_KEY%TYPE,
	task_type_out IN OUT TASK_QUEUE.TASK_TYPE%TYPE,
	task_arguments_out IN OUT TASK_QUEUE.TASK_ARGUMENTS%TYPE
	)
	AS
	PRAGMA AUTONOMOUS_TRANSACTION;
	BEGIN
		BEGIN
		SELECT
		TASK_KEY, TASK_TYPE, TASK_ARGUMENTS INTO task_key_out, task_type_out, task_arguments_out
		FROM TASK_QUEUE
		WHERE STATUS_CODE = 'WAITING'
		AND ROWNUM <= 1
		FOR UPDATE;
		EXCEPTION WHEN NO_DATA_FOUND THEN
		ROLLBACK;
		END;

		UPDATE TASK_QUEUE
		SET STATUS_CD = 'INPROCESS',
		DEQUEUED_DATE = SYSDATE
		WHERE TASK_KEY = task_key_out;
		COMMIT;
	END;
  END PKG_DATA_MANAGEMENT
 /


The package DataManagement::Queue shows how to use spc(), but it does not include the
detailed implementation of the database Queue in Oracle.

=head2 fetchQdaO

  fetchQdaO( $qry, ,$recref ,\@list ,@bindparams )

fetchQdaO() fetches a record from the data source as specified by the SQL query, and it returns
a single B<first encountered> record in the result. The method returns the hash reference holding
the fetched record.

fetchQdaO() takes the following 4 arguments:

1- the SQL query, it can be a simple query or a join.

2- an optional hash reference pointing to the record whose attributes will be set to the ones of the fetched record.
If you do not specify a hash reference, then a new hash reference is created within this method
to hold the result to be returned to the caller.
On DBI error, this method will return undef.

3- an optional array reference to list the fields that you specified in the query. The listed elements
must be ordered the same way as they are listed in the query or you will end up with unpredictable
results. Although you will be constrained by following the order of the fields as they
appear in the query, this option allows a more efficient memory usage when
retrieving fields that consume large chunk of memory (i.e. BLOB) because it does not do mutiple
memory allocation or copy by value when fetching the fields, rather it assign the references
of the fetched data to the appropriate fields of the records. You need to dereference the data
retrieved in the record, See eg/fetchrec1.pl and eg/fetchrec2.pl.

4- an optional list of binding parameters used to replace the place holder ? in the query.


Here is a simple example:

 my $rec= $bbconn-> fetchQdaO(
      "SELECT * FROM TABLE1 WHERE DATASTRING='This is a flower ...' ",
    );

 foreach my $k (keys %$rec) {
    print "$k -- ${$$rec{$k}}\n";
 }

Here is another example:

 my $rec= $bbconn-> fetchQdaO(
      "SELECT DATASTRING, DATANUM,BIN_SREF,RECORDDATE_T FROM TABLE1 WHERE DATASTRING='This is a flower ...' ",
    );

 foreach my $k (keys %$rec) {
    print "$k -- ${$$rec{$k}}\n";
 }

The following example is not productive but it shows the usage of this method:

  my %rec;
  $bbconn-> fetchQdaO(
     "SELECT a.LOOKUP,b.DATASTRING, b.DATANUM,b.BIN_SREF,a.RECORDDATE_T FROM TABLE1 a, TABLE2 b WHERE a.DATASTRING=? ",
     \%rec,
     ['LOOKUP','DATASTRING','DATANUM','BIN_SREF','RECORDDATE_T'],
    'This is a flower ...',
  );

  print "${$rec{DATASTRING}}\n";
  print "${$rec{RECORDDATE_T}}\n";


=head2 fetchQdaAA

 fetchQdaAA( $qry ,$aaref ,$href ,@bindparams )

Given a DBI::BabyConnect object, this method takes a query
string as an argument to fetch data from the database and return
the data in an array of array, that is into a 2D array.
The method uses the DBI prepare() method, and binds any
parameters if provided in the method argument, then DBI execute()
the query, and finally fetch the data by iterating through
the DBI cursor fetchrow_arrayref.

fetchQdaAA() takes four parameters in the following order:

    1- the SQL query
    2- an optional array reference to hold the returned fetched records
    3- an optional hash reference to specify the following INCLUDE_HEADER, MAX_ROWS
    4- an optional list of binding params

The $href is optional and is a reference to a hash that
holds two attributes: MAX_ROWS and INCLUDE_HEADER. MAX_ROWS enforces a maximum
number of the rows to be fetched, and if you want to fetch everything 
just do not specify it. INCLUDE_HEADER if set to true then the first row
of the returned data is a header that contains the attribute names. To omit
the header just specify nothing or set INCLUDE_HEADER to 0. If you want to
view the retrieved data, you can use the formatting methods. See L<Formatter Functions>.
However for any of the formatting methods to work properly you need to include
the header.

In this example C<fetchQdaAA> returns the $rows:

    my $qry = qq{SELECT * FROM FR_XDRTABLE1 WHERE ID < ? AND FLD1 = ? };
    my $rows = $dbhandle-> fetchQdaAA($qry, {INCLUDE_HEADER=>1,MAX_ROWS=>10});
    my $rows = $dbhandle-> fetchQdaAA($qry,14,'u4_1');

In this example we pass the $rows to C<fetchQdaAA>:

    # define an array ref, fill it in and expand it
    my $rows=[]; # must specify $rows as an array reference before calling below
    $dbhandle-> fetchQdaAA($qry,$rows,{INCLUDE_HEADER=>1},14,'u4_1');

See eg/fetchQdaAA.pl for an example.



=head2 fetchTdaAA

  fetchTdaAA( $table, $selection, $where ,$aaref ,@bindparams )

The method fetchTdaAA() retrieves selected data from the specified database table,
where the $where condition apply. You can specify a reference to an array of array
to be expanded with the new data rows. The method returns a reference to the array
that holds the final results.

 fetchTdaAA() method takes the following arguments:

 1- table name
 2- what to select that follows the SELECT keyword
 3- condition that follows the WHERE keyword
 4- optional array reference that is extended with the new elements being selected. If no array reference
   is passed, then a new array is created within this method to hold the result. The method returns
   a reference to the array that holds the final results; otherwise, it returns undef in case there is no result.
 5- binding parameters

For example to fetch data from the FR_XDRTABLE1 table where ID < 54 AND FLD1='u4_1'

    my $xdr = fetchTdaAA('FR_XDRTABLE1', ' * '  ,  " ID < ? AND FLD1 = ? ",54,'u4_1')

See eg/fetchTdaAA.pl for an example.

=head2 fetchTdaAO

  fetchTdaAO( $table, $selection, $where ,$ahref ,$href ,@bindparams )

The method fetchTdaAO() retrieves object records of data using fetchrow_hashref

 fetchTdaAO() takes the following arguments:

 1- the table name
 2- what to select from the table, that is what will follow the SELECT keyword. This parameter type will determine
   the type of the array reference being returned by this method as shown below:

    Selection                                          Return
    ------------------------------------------         -----------------
    a literal: "ID,UID,TMD0,FLD1,CHANGEDATE_T"         Array of Objects
    a wildcard * literal :  " * "                      Array of Objects
    a hash ref: {...}                                  Array of Objects
    an array: ('ID','UID','TMD0')                      Array of Array (preserving the order)

 3- condition that follows the WHERE keyword
 4- An optional array reference set by the caller, allowing to expand an already allocated array
   with the new records being selected. If no array reference
   is passed, then a new array is created within this method to hold the result. The method returns
   a reference to the array that holds the final results; otherwise, it returns undef in case there is no result.
 5- binding parameters

See eg/fetchTdaAO.pl for an example.

=head1 Closing Functions

Because DBI::BabyConnect objects are live objects that are connected to data sources, programmers
can invoke methods to execute SQL transactions on the data sources.

After you have executed a SQL transaction with a DBI::BabyConnect object, usually DBI requires
that you end the transaction by committing if it passes, by rolling back or raising error if it
fails, by calling finish on the cursor, and by disconnecting the handle.

However DBI::BabyConnect objects are designed to be persisted and to be pooled
within an application. Programmers, 
do not need to call any of the functions aforementioned because 
DBI::BabyConnect will do that transparently for you. You use DBI::BabyConnect so that
you can work with an object whose connection is persisted to a data source, and
the object will do all clean up upon object destruction.

The following functions are provided so that if you chose to port an application that
uses DBI directly, you can easily make use of DBI::BabyConnect without making extensive changes
to the application.

=head2 commit

Call commit() on the handle open by DBI::BabyConnect object. This method is provided to ease
portability of programs using DBI directly.

=head2 rollback

rollback() delegates the rollback to DBI::rollback method, except that the localization
of DBI variables will take place prior to calling DBI::rollback. The localization is necessary
because DBI::BabyConnect allows you to modify the behavior of rollback during run time,
even after you have created a DBI::BabyConnect object.

Usually, you do not need to call the rollback explicitly, as it is being called from other methods (i.e. DBI::BabyConnect::do()
or DBI::BabyConnect::sqlbnd(), etc.) whenever a DBI exeucte() fails and the rollback
conditions are met. Refer to DBI::BabyConnect::do() and ON_FAILED_DBIEXECUTE_ROLLBACK_AND_EXIT
settable variable for more information on how this method is being invoked.

You can always call this method explicitly if you wish to handle the rollback from within
your program.

=head2 finish

Call finish() on the cursor held by DBI::BabyConnect object. Provided to ease portability
of programs using DBI directly.

=head2 disconnect

Call the disconnect() explicitly on a DBI::BabyConnect object, hence delegating the
disconnection to DBI disconnect. You do not need to disconnet during the life time
of a DBI::BabyConnect object, however, if you do so, then you need to C<reconnect> 
by calling C<DBI::BabyConnect::reconnect> if you want to keep on using the same
DBI::BabyConnect object.

disconnect() will call DBI disconnect on the DBI::BabyConnect object. Usually you need
to disconnect the DBI::BabyConnect object from the data source once you are done
working with the object. Yet, you can rely on DBI::BabyConnect to do the disconnection
upon exit or object destruction, by setting C<CALLER_DISCONNECT=0>. Refer to L<"CALLER_DISCONNECT">.


=head1 Error Functions

=head2 dbierror

Returns the $DBI::err as returned by the DBI for the active handle of a DBI::BabyConnect
object. If a DBI::BabyConnect method returns an error then you can check for the
DBI error by calling dbierror(). For example:

  $bbconn-> do($sql) || die $bbconn-> dbierror;

See eg/error_do.pl and eg/error_die.pl.

=head1 Statistical Functions

DBI::BabyConnect can collect statistics about the cumulative run time and the system
time consumed by DBI::BabyConnect objects (while accessing the data sources).

The following three statistical functions collect statistics per DBI::BabyConnect object:
get_do_stats, get_spc_stats, get_running_time

The DBI::BabyConnect::getStatCC returns statistics about all DBI::BabyConnect objects
whenever using DBI::BabyConnect with connection caching and persistence.

DBI::BabyConnect with connection caching and persistence is being used by L<Apache::BabyConnect>.

=for comment Refer to Apache::BabyConnect for more information on using DBI::BabyConnect with Apache2 MD2.

=head2 getStatCC

getStatCC() returns the statistics collected on the open DBI handles owned by
the DBI::BabyConnect objects. The caching of the handles will only work whenever
you instantiate the DBI::BabyConnect by enabling ENABLE_CACHING and PERSISTENT_OBJECT_ENABLED
For example:
  use DBI::BabyConnect 1,1;
will load the DBI::BabyConnect and set ENABLE_CACHING and PERSISTENT_OBJECT_ENABLED to
true.

use DBI::BabyConnect (1,1) is typically called whenever using L<Apache::BabyConnect>, or
whenever loading the module from a Perl script that is run under mod_perl.

 The method getStatCC() takes one optional argument:
 - if you do not pass any argument, then this method will return a string containing the statistics collected on all open handles
 - if you pass a hash reference as the first argument then the statistics table is copied to this hash reference
   and the method will also return the reference to that hash
 - if you pass anything else (as a string), then the method will return a hash reference containing the statistics collected
   on the cached descriptor that matches that string.

See eg/perl/statcc.pl for an example.

=head2 get_running_time

get_running_time() returns a string containing time related information about the DBI::BabyConnect object.
The string returned has the following format:
cumulative-system-time / added-system-time / total-run-time

All three times are expressed in seconds and 1/100 second.
cumulative-system-time represents the system+user time used by the DBI::BabyConnect object
added-system-time represents the system+user time slices added per each DBI method call, and they hould add up to be close to cumulative-system-time
total-run-time represents the time since the DBI::BabyConnect object was instantiated

=head2 htmlStatCC

htmlStatCC() prints in HTML format the statistics collected on the open DBI handles owned by
the DBI::BabyConnect objects. This function is provided so that you can quickly print the
statistical table of all DBI::BabyConnect objects that have been cached by a specific process,
such as the http server process, or one of its child process.

The printing is in HTML format, therefore you need to use this function from a Perl script
that is served under Apache. For an example, see any of the following scripts
eg/perl/testbaby.pl, eg/perl/testcache.pl, or eg/perl/onemore.pl.

See L<"getStatCC"> for description of this the cached statistical table of DBI::BabyConnect
objects.

=head2 get_do_stats 

 This method get_do_stat() takes one optional argument:
 - if you do not pass any argument, then this method will return a string containing the statistics collected
 - if you pass a hash reference as the first argument then the do()'s statistics table is copied to this hash reference
   and the method will also return the reference to that hash
 - if you pass anything else (as a string), then the method will return a hash reference containing the statistics collected
   on the do() query that match that string.

get_do_stat() returns the statistics collected on the do() method. You should have
enabled to collect the statistics by seting L<"ENABLE_STATISTICS_ON_DO"> to 1, otherwise
the statictics table is empty.
Before setting ENABLE_STATISTICS_ON_DO to 1, just know what you are doing otherwise
you will imply a huge penalty on the DBI::BabyConnect object by acquiring an unecessary
data structure to hold the statistics of all do()'s statement. Refer to the section
L<"ENABLE_STATISTICS_ON_DO">.

I added the ENABLE_STATISTICS_ON_DO for some system integrators working in data warehouse,
where the do() robots are usually repetitive for the same set of queries and are time consuming.
If your do() query is taking too long, and your do() queries are limited in number, and
you want to know how many time the same query is being called (and how much system time it is
consuming) then enable ENABLE_STATISTICS_ON_DO, and use the method get_do_stat() to get the
statistics of all your do()'s that have been invoked by a DBI::BabyConnect object.

=head2 get_spc_stats 

Similar to L<"get_do_stats"> but statistics are collected on Stored Procedures whenever
you call spc().

=head1 Database Status and Schema

DBI::BabyConnect provides several functions that can request meta data and schema
information about tables that resides in the data source
to which a DBI::BabyConnect is connected. These functions provide
statistics about the meta data saved within the database, and about
the schema of the database tables. While these functions should be generic and
work with any database, currently they support only MySQL, and they have been
tested with mysql  Ver 14.12 Distrib 5.0.27.

=head2 dbschema

  dbschema( $database, $tablelike )

C<dbschema()> retrieves information about tables from MySQL INFORMATION_SCHEMA.TABLES,
matching these tables that pertains to the specified $database and whose
names are like $tablelike.

Use this method with MySQL to quickly reveal inserts, updates, or any changes on
specific tables. This method may not work with any MySQL release, but it has
been tested with Ver 14.12 Distrib 5.0.27.

For example, given the database name BABYDB, get the status of all these table names
containing TABL in their names. See eg/dbschema.pl for an example.

  print $bbconn-> dbschema('BABYDB','TABL');


=head2 snapTablesInfo

C<snapTablesInfo()> list all the tables that are defined within the database
to which the DBI::BabyConnect object is connected. See eg/tablesinfo.pl for an example.

=head2 snapTableDescription

  snapTableDescription( $table )

C<snapTableDescription()> returns the description of the specified table. However,
the table should be defined within the database that the DBI::BabyConnect object 
is connected to. See eg/tabledescription.pl for an example.

=head2 snapTableMetadata

  snapTableMetadata( $table )

C<snapTableMetadata()> returns a string describing the meta data of a table. However,
the table should be defined within the database that the DBI::BabyConnect object 
is connected to. See eg/tablemeta.pl for an example.

=head2 strucTableMetadata

  strucTableMetadata( $table )

C<strucTableMetadata()> returns a hash reference describing the meta data of a table. However,
the table should be defined within the database that the DBI::BabyConnect object 
is connected to. See eg/tablemeta_struc.pl for an example.


=head1 Formatter Functions

Four methods are provided within DBI::BabyConnect module to assist the
programmer in getting a snapshot of the data retrieved from the database.

B<textFormattedAO>, B<datalinesFormattedAO>, B<textFormattedAA>,
and B<datalinesFormattedAA> are typically used to format the data that you
have fetched using L<"fetchQdaAA">, L<"fetchTdaAO">, and L<"fetchTdaAA">.

=head2 datalinesFormattedAA

  datalinesFormattedAA( $rows ,$attributesList  ,attributesRenaming )

C<datalinesFormattedAA()> is a text formatter method that I included in this
module to assist you in getting a quick snapshot at what you may have
fetched from a database.

C<datalinesFormattedAA()> takes an array reference holding the data as returned by
either L<"fetchQdaAA"> or L<"fetchTdaAA"> and returns the data formatted into text
format.

datalinesFormattedAA() takes $rows as a first argument, followed optionally
by a list of attributes and a hash mapping to rename the attributes.

datalinesFormattedAA() returns a hash reference that contains the data layout
in text format.
 For example, if the data layout is returned in $dataLines, then
 - the header lines are in: $$dataLines{TITLE_LINE} and $$dataLines{UNDERLINE}
 - and the formatted data lines are in @{$$dataLines{DATA_LINES}}

If you call datalinesFormattedAA( $rows ) by passing only the $rows, then
the method will return the formatted data of all fields found by default
in the header (first row).

You can optionally pass as a second argument an array reference that
list the attributes to be printed. The list must be of the following format:
C<attribute1, length1, attribute2, length2, ...> where each attribute is followed
by the desired formatted length.

The following is an example:
 
 use DBI::BabyConnect;
 
 my $bbconn = DBI::BabyConnect->new('BABYDB_001');
 $bbconn-> HookError(">>/tmp/error.log");
 $bbconn-> HookTracing(">>/tmp/db.log",1);
 
 my $qry = qq{SELECT * FROM TABLE2 WHERE ID < ? };
 
 # $rows is an array reference to be filled by fetchQdaAA()
 my $rows=[];
 
 # fetch data from query, and put data into $rows. Do not exceed 2000 rows
 # and include the header.
 if ($bbconn-> fetchQdaAA($qry,$rows,{INCLUDE_HEADER=>1,MAX_ROWS=>2000},15) ) {
     # we will use the formatting method datalinesFormattedAA() to print the fetched data
     my $dataLines = $bbconn-> datalinesFormattedAA(
         $rows,
         ['ID',6,'DATASTRING',22,'DATANUM',10],
         {ID=>'Id', DATASTRING=>'Data', DATANUM => 'Data Number'}
     );
     for (my $i=0; $i<@{ $$dataLines{DATA_LINES} }; $i++) {
         if ($i % 10 == 0) {
             print $$dataLines{TITLE_LINE};
             print $$dataLines{UNDERLINE};
         }    
         print ${$$dataLines{DATA_LINES}}[$i];
     }
 }
 else {
     print "NONE!!!!!!!!\n";
 }
 
See eg/fetchQdaAA.pl and eg/fetchTdaAA.pl for examples.

=head2 textFormattedAA

  textFormattedAA( $AA ,$attributesList  ,attributesRenaming )

textFormattedAA() is similar to datalinesFormattedAA() but it returns a
string containing the formatted data.

See eg/etchTdaAA.pl for an example.

=head2 datalinesFormattedAO

  datalinesFormattedAO( $AO ,$attributesList  ,attributesRenaming )

datalinesFormattedAO() is similar to datalinesFormattedAA() but it takes
an array of hash as input. It is designed to work with L<"fetchTdaAO">.

See eg/fetchTdaAO.pl for an example.

=head2 textFormattedAO

  textFormattedAO( $AO ,$attributesList  ,attributesRenaming )

textFormattedAO() is similar to datalinesFormattedAO() but it returns a
string containing the formatted data.

See eg/fetchTdaAO.pl for an example.

=head1 Logging and Tracing

This module provides a tie to a filehandle so that information can be logged
during run time of the module. In addition, the filehandle can be shared with
the C<DBI::trace()> allowing to redirect the trace output to that file.

You can initialize the hook after getting the database connection
by simply calling HookTracing() in which case the tracing is
automatically enabled and run time information is printed to the log file.
Refer to L<"HookTracing">.

You can redirect all STDERR output to a file by calling HookError().
Refer to L<"HookError">.

The hook can be ignored, and therefore no information will be logged. This is useful
in a production environment after the DBI::BabyConnect objects have been tested,
you can simply comment out the hook.

=head1 SUPPORT

Support for this module is provided via the E<lt>bbconn@pugboat.comE<gt> email.
A mailing list will soon be provided at babyconnect@pugboat.com.

=head1 AUTHOR

Bassem W. Jamaleddine, E<lt>bassem@pugboat.comE<gt>

=head1 MAINTAINER

PUGboat (Processors User Group), E<lt>bbconn@pugboat.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2007 by Bassem W. Jamaleddine, 2007 by the
Processors User Group (PUGboat.COM). All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

Persisting DBI::BabyConnect objects with B<Apache::BabyConnect>

This module is being used by Varisphere Processing Server powering the
web site www.youprocess.com

=cut

