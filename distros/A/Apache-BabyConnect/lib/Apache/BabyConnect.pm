package Apache::BabyConnect;

our @ISA = qw();
our $VERSION = '0.93';

use strict;

die "
Apache::BabyConnect cannot start without setting the environment
variable BABYCONNECT. You may have forgotten to set BABYCONNECT
environment variable prior to loading the Apache::BabyConnect
module.
In the /etc/httpd/conf.d/perl.conf you need to setup the environment
variable before loading the Apache::BabyConnect module. For instance,
if you have loaded the Apache::BabyConnect from a startup script
using the PerlRequire directive, you can setup the BABYCONNECT
environment variable simply by using the directive PerlSetEnv prior
to loading the startup script:

PerlSetEnv BABYCONNECT /opt/DBI-BabyConnect-$VERSION/configuration
PerlRequire /opt/DBI-BabyConnect-$VERSION/startupscripts/babystartup.pl
Alias /perl /var/www/perl
<Directory /var/www/perl>
    SetHandler perl-script
    PerlResponseHandler ModPerl::Registry
    PerlOptions +ParseHeaders
    Options +ExecCGI
</Directory>

" unless $ENV{BABYCONNECT};
use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION} &&
					 $ENV{MOD_PERL_API_VERSION} == 2) ? 1 : 0;

BEGIN {
	if (MP2) {
		require mod_perl2;
		require Apache2::Module;
		require Apache2::ServerUtil;
	}
	elsif (defined $modperl::VERSION && $modperl::VERSION > 1 &&
			 $modperl::VERSION < 1.99) {
		require Apache;
	}
}

########################################################################################
# DBI::BabyConnect needs to be called with caching and persistence enabled
use DBI::BabyConnect(1,1);

use Carp ();

$Apache::BabyConnect::VERSION = '1.00';

$Apache::BabyConnect::DEBUG = 3;

my @ChildConnect; # connections to be established with each httpd child
my $parent_pid;

########################################################################################
########################################################################################
sub debug {
  print STDERR "$_[1]\n" if $Apache::BabyConnect::DEBUG >= $_[0];
}

########################################################################################
########################################################################################
# connect_on_init is called in the script babystartup.pl to provide a PerlChildInitHandler
# that will be hooked to a DBI::BabyConnect instance.
# 
# The connect_on_init will request a DBI::BabyConnect instance to manage a DBI connection whose
# parameters are being described with the database descriptor. Each child
# is hooked to such an instance, and the instance is being persisted during the
# life time of the child.
# Because all childs are being started with the same database descriptor, therefore
# they can access the database concurrently. You should be careful on how to use
# the connection. Refer to Apache::BabyConnect documentation, and the script testbaby.pl
# to understand how the pool of connections work.
# You can request new connection from any Perl script, and the connection will be cached
# only if the database descriptor cannot be found within the child (httpd child) own
# DBI::BabyConnect instance cache.
# The caching of connection per each httpd child (or its hooked instance DBI::BabyConnect instance)
# is maintained within the DBI::BabyConnect itself, and each entry in the cache is
# identified with the concatenation of the child kernel process ID and the database descriptor.
# 
sub connect_on_init {
	if (MP2) {
		if (!@ChildConnect) {
			my $s = Apache2::ServerUtil->server;
			debug(1, "\n***!!!!!!!!! $$ connect_on_init / MP2 Apache2::ServerUtil->server NOT ChildConnect === @ChildConnect\n\n");
			$s-> push_handlers(PerlChildInitHandler => \&childinit);
		}
	}
	else {
		Carp::carp("Apache.pm was not loaded\n")
			  and return unless $INC{'Apache.pm'};

		if (!@ChildConnect and Apache->can('push_handlers')) {
			Apache->push_handlers(PerlChildInitHandler => \&childinit);
		}
	}

	debug(1, "\n*** connect_on_init / store connections ===  $$   @_\n\n");

	# store connections
	$parent_pid = $$;
	push @ChildConnect, [@_];
	#foreach (@ChildConnect) { print STDERR "************** Childconnect: @$_\n"; #} 
}

########################################################################################
########################################################################################
# The PerlChildInitHandler creates all connections during server startup.
# Note: this handler runs in every child server, but not in the main server.
sub childinit {
	my $prefix = "	   $$ Apache::BabyConnect			";
	debug(2, "$prefix PerlChildInitHandler");

	while (@ChildConnect) {
		for my $aref (@ChildConnect) {
			debug(2, "\n\n************** Childconnect: @$aref");
			my @da = @$aref;
			shift @da;
			my %da;
			while (my($l,$r)=splice @da, 0, 2) {
				$da{$l} = $r;
			}
			my ($arg_iconf,$arg_errlog,$arg_tralog,$arg_tralev) =
				@{ %da } { qw(DESCRIPTOR ERROR_FILE TRACE_FILE TRACE_LEVEL) };
			$arg_errlog ||= "";
			$arg_tralog ||= "";
			$arg_tralev ||= "";
			#my $arg_iconf = ${@$aref}[1];
			#my $arg_errlog = ${@$aref}[2] || "";
			#my $arg_tralog = ${@$aref}[3] || "";
			#my $arg_tralev = ${@$aref}[4] || "";
			debug(2, "        Child / ${@$aref}[0] requesting an instance of Apache::BabyConnect($arg_iconf) ");
			debug(2, "              HookError($arg_errlog)");
			debug(2, "              HookTracing($arg_tralog)  with TraceLevel=$arg_tralev) ");
			my $cnn = DBI::BabyConnect->new($arg_iconf);
			# this redirection seems to work, but the need need debugging because it is altering the args!!!!!!!!
			length($arg_errlog) > 2 && $cnn ->HookError(">>$arg_errlog");
			#${@$aref}[2] && $cnn ->HookError(">>$arg_errlog");
			$arg_tralev ||= 1; # if trace level not specified then assume 1 
			length($arg_tralog) > 2 && $cnn ->HookTracing(">>$arg_tralog",$arg_tralev);
			#${@$aref}[3] && $cnn ->HookTracing(">>$arg_tralog",$arg_tralev);
		}
		shift @ChildConnect;
		# fudge this for now, need debugging!!!!!!!!
		last if @ChildConnect == 1;
	}

	1;
}

########################################################################################
########################################################################################
# The cleanup phase from within mod_perl will execute some code immediately after the
# request has been served (the client went away) and before the request object is destroyed.
#
# The PerlCleanupHandler does nothing since Apache::BabyConnect relies on DBI::BabyConnect
# to handle all DBI functions such as rollback when AutoCommit is off
sub cleanup {

	1;
}

########################################################################################
########################################################################################
# ref: http://perl.apache.org/docs/2.0/api/Apache2/ServerUtil.html

sub get_child_init_handlers {
	my $s = Apache2::ServerUtil->server;
	my $handlers_list = $s-> get_handlers('PerlChildInitHandler');
	#a list of references to the handler subroutines
	return $handlers_list;
}

sub get_child_exit_handlers {
	my $s = Apache2::ServerUtil->server;
	my $handlers_list = $s-> get_handlers('PerlChildExitHandler') || [];
	return $handlers_list;
}

sub parent_pid {
	return $parent_pid;
}

sub cpids {
	my @a = split(/\n/,`ps  --ppid $parent_pid`);
	my @cpid;
	foreach (@a) {
		if ($_ =~ m/^(\d+)/) {
			push(@cpid,$1);
		}
	}
	return @cpid;
}
########################################################################################
########################################################################################

if (MP2) {
	if (Apache2::Module::loaded('Apache2::Status')) {
		Apache2::Status->menu_item(
								   'BabyConnect' => 'BabyConnet for DBI connections',
								  );
	}
}
else {
	if ($INC{'Apache.pm'}		# is Apache loaded?
			and Apache->can('module')   # really loaded?
			and Apache->module('Apache::Status')) { # and has an Apache::Status?
		Apache::Status->menu_item(
								'BabyConnect' => 'BabyConnect for DBI connections',
								);
	}
}

1;

__END__

=head1 NAME

Apache::BabyConnect - uses DBI::BabyConnect to initiate persistent database connections


=head1 SYNOPSIS

 # Configuration in perl.conf and babystartup.pl:

 PerlSetEnv BABYCONNECT /opt/DBI-BabyConnect/configuration
 PerlRequire /opt/Apache-BabyConnect/startupscripts/babystartup.pl


=head1 DESCRIPTION

This module initiates persistent database connections using DBI::BabyConnect.

This module is best understood by going through the roadmap file and the
sample programs provided with this distribution. The roadmap file is
eg/README, and the sample programs are in eg/perl.

When loading the Apache::BabyConnect module, the
module looks if the environment variable BABYCONNECT has been set to the
URI location where it can read the configuration files, and if the 
the module DBI::BabyConnect has been loaded.
The startup script instantiates DBI::BabyConnect objects with caching
and persistence enabled. Each object is connected to a data source
that is described by the database descriptor. See L<DBI::BabyConnect> for
a clarification of database descriptors.

If you create a DBI::BabyConnect object from a Perl script, then if the
descriptor is found in the DBI::BabyConnect cache, you will be using
the cached object. Otherwise, a new DBI::BabyConnect is created with that
descriptor, and it is added to the cache.

Any Perl script can use DBI::BabyConnect to create as many DBI::BabyConnect objects;
however, DBI::BabyConnect will only create a new object if not found in the cache.
Programmers do not need to keep track of what is being cached, and they
can write code as if the script is to be run from the command prompt.

It is recommended that you use a set of prefedined database descriptors
that you load at the startup of Apache. See B<babystartup.pl> script later
in this document. However, you can always use a new database descriptor
to create a DBI::BabyObject. 

Unlike the Apache::DBI module, there is no request forwarding between
the DBI module and the Apache::BabyConnect. All caching is handled by the
DBI::BabyConnect. B<Do not load the Apache::DBI module> whenever you are using
Apache::BabyConnect, otherwise you will imply a penalty on the caching
mechanism, and you will be limited to the caching mechanism of Apache::DBI.

The Apache::BabyConnect module does not have the same limitation as Apache::DBI.
DBI::BabyConnect objects are persisted on per process basis, and a user can 
access several times a database from different http servers. The Apache::BabyConnect
objects will never share the same handle. Each Apache::BabyConnect object
contains its own handle, and DBI::db handle are never cached or shared. For this
reason B<you should not load the Apache::DBI module>.

Caching of the Apache::BabyConnect is maintained within the DBI::BabyConnect
module itself, and each entry in the cache is uniquely identified by the
concatenation of: the kernel process number of the http server + the database
descriptor.

=head1 GETTING STARTED

The Apache::BabyConnect distribution comes with a startup script (L<"babystartup.pl">), a roadmap
for installation and testing in eg/README file, and a set of sample programs to assist you in
testing your installation.

 The directory startupscripts/ contains the file startupscripts/babystartup.pl
 The directory eg/ contains the roadmap file eg/README
 The directory eg/perl contains the sample scripts

Using mod_perl, modify your perl.conf as follow:

 PerlSetEnv BABYCONNECT /opt/DBI-BabyConnect/configuration
 PerlRequire /opt/Apache-BabyConnect-0.93/startupscripts/babystartup.pl

 Alias /perl /var/www/perl
 <Directory /var/www/perl>
     SetHandler perl-script
     PerlResponseHandler ModPerl::Registry
     PerlOptions +ParseHeaders
     Options +ExecCGI
 </Directory>

You will then copy the sample scripts from eg/perl to /var/www/perl. Restart
the http server and test with the scripts. For more instruction refer to eg/README.


=head1 CONFIGURATION

Before loading the module, you need to setup the BABYCONNECT environment
variable to point to the DBI::BabyConnect configuration directory. After,
setting the environment variable BABYCONNECT, you should load the
Apache::BabyConnect upon startup of the Apache daemon.

Add the following line to your perl.conf:

 PerlSetEnv BABYCONNECT /p9/BABYCONNECT/DBI-BabyConnect/configuration
 PerlRequire /p9/BABYCONNECT/Apache-BabyConnect/startupscripts/babystartup.pl

Write a startup script to be loaded via the PerlRequire directive. For an example,
see the L<"babystartup.pl">.

B<NOTE: You do not need to load the Apache::DBI module>.

=head1 connect_on_init

To achieve a persistent connection upon http server startup, you will call the
method connect_on_init:

 Apache::BabyConnect->connect_on_init(
    DESCRIPTOR => datasource_descriptor,
    ERROR_FILE => error_log,
    TRACE_FILE => trace_log,
    TRACE_LEVEL => trace_level,
 );

Here is an example:

 Apache::BabyConnect->connect_on_init(
    DESCRIPTOR =>'BABYDB_001',
    ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_001.log',
    TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_001.log',
    TRACE_LEVEL => 2
 );

connect_on_init() takes a hash with a DESCRIPTOR attribute that is mandatory, followed
by three optional attributes ERROR_FILE, TRACE_FILE, and TRACE_LEVEL, that are optional.

The DESCRIPTOR specifies the database descriptor to be persisted by the http server. Apache::BabyConnect
will instantiate an DBI::BabyConnect object with connection persistence and caching for
such an object.

The ERROR_FILE attribute is optional and it is the file name where STDERR will be redirected.
See the note L<"IMPORTANT REMARK"> about the effect of redirecting STDERR during
startup.

The TRACE_FILE attribute is optional and it is the file name where all tracing will be written.

The TRACE_LEVEL attribute is optional and it is the DBI trace level to be written to the trace
file specified in the previous argument.

=head1 babystartup.pl

  use strict;
  
  $ENV{MOD_PERL} or die "not running under mod_perl!";
  
  # Set up the ENV for BABYCONNECT in the perl.conf just before requiring the babystartup.pl as follow:
  #   PerlSetEnv BABYCONNECT /opt/DBI-BabyConnect/configuration
  #   PerlRequire /opt/Apache-BabyConnect/startupscripts/babystartup.pl
  #
  # alternatively you can uncomment the line below:
  #BEGIN { $ENV{BABYCONNECT} = '/opt/DBI-BabyConnect/configuration'; }
  
  use ModPerl::Registry ();
  use LWP::UserAgent ();
  
  use Apache::BabyConnect ();
  
  use Carp ();
  $SIG{__WARN__} = \&Carp::cluck;
  
  $Apache::BabyConnect::DEBUG = 2;
  
  #ATTENTION: this is only a sample example to test with Apache::BabyConnect,
  #  in production environment, do not enable logging and tracing. To do so
  #  just call connect_on_init() with the database descriptor only. For example:
  #Apache::BabyConnect->connect_on_init(DESCRIPTOR=>'BABYDB_001');
  
  Apache::BabyConnect->connect_on_init(
      DESCRIPTOR =>'BABYDB_001',
      ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_001.log',
      TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_001.log',
      TRACE_LEVEL => 2
  );

  Apache::BabyConnect->connect_on_init(
      DESCRIPTOR =>'BABYDB_002',
      ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_002.log',
      TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_002.log',
      TRACE_LEVEL => 2
  );

  Apache::BabyConnect->connect_on_init(
      DESCRIPTOR => 'BABYDB_003',
      ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_003.log',
      TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_003.log',
      TRACE_LEVEL => 2
  );

  Apache::BabyConnect->connect_on_init(
      DESCRIPTOR => 'BABYDB_004',
      ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_004.log',
      TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_004.log',
      TRACE_LEVEL => 2
  );
  
  1;
  

=head1 IMPORTANT REMARK

The redirection of STDERR during the startup of Apache may result in
confusing messages printed to Apache error_log. If you specify the
attribute ERROR_FILE during startup, and you enable debugging
C<$Apache::BabyConnect::DEBUG = 2;>, as shown in the script above,
the messages printed to Apache error_log, and to the error log for
each of the descriptor will be intermixed and out of order. This may
result in confusion when the administrator is configuring Apache::BabyConnect.

If you want to view the startup properly, in the startup script L<"babystartup.pl">
comment out all the lines where ERROR_FILE attribute is specified. Restart
the server and view the error_log.

=head1 PREREQUISITES

=head2 MOD_PERL 2.0

Apache::DBI version 0.96 and higher should work under mod_perl 2.0 RC5 and later
with httpd 2.0.49 and later.

=head2 MOD_PERL 1.0

Note that this module needs mod_perl-1.08 or higher, apache_1.3.0.

=head1 SEE ALSO

L<DBI::BabyConnect>

=head1 AUTHORS

Bassem W. Jamaleddine is the author of Apache::BabyConnect.

=head1 COPYRIGHT

The Apache::BabyConnect module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

