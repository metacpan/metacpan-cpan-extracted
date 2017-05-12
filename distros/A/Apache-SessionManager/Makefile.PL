# Allow us to skip prompt and (and for) tests
use Getopt::Std qw(getopts);
use vars qw($opt_n);
getopts('n');

#unless (getopts("n")) {
#    die "Usage: $0 [-n]\n";
#}   

my($errors, $warnings);
my $necessary_modules = {
#	'Apache' => 'The Apache Perl API',
	'Apache::Session 1.54' => 'A persistence framework for session data'
};

my $optional_modules = {
	'Apache::Request 0.33' => 'Apache API to manage HTTP cookies (CGI::Cookie will be used instead)',
	'CGI::Cookie' => 'CGI library to manage HTTP cookies (used only if Apache::Request isn\'t installed)'
};

print "Checking for REQUIRED modules...\n";

# Check mod_perl version
my ($mp1,$mp2) = which_mod_perl();
print " --> mod_perl... ";
if ( ! $mp1 && ! $mp2 ) {
	$errors++;
	print "NOT FOUND\n";
	print "     !!! Please install either mod_perl (version 1 or 2) in order to use Apache::SessionMananger!\n";
}
else {
	print 'found (version 1: ' . (($mp1) ? $mp1 : 'none') . ', version 2: ' . (($mp2) ? $mp2 : 'none') . ")\n";
}

for (sort keys %$necessary_modules) {
	eval 'use ' . $_ ;
	my $module_display = $_;
	$module_display =~ s/( [\d\.]+)$/ \>\=$1/isg;
	print " --> $module_display... ";
	if ($@) {
		$errors++;
		print "NOT FOUND\n";
		print "     !!! you need module: $module_display\n";
		print "         CAUSE: $necessary_modules->{$_}\n";
	}
	else {
		print "found.\n";
	}
}

print "\nChecking for OPTIONAL modules...\n";
for (sort keys %$optional_modules) {
	my $data = $optional_modules->{$_};
	my $message = ref($data) ? $data->{message} : $data;

	# if there is a test for this module run it and if returns false
	# skip this module's message, first so UNIX users don't see 
	# message about, ad ex., Win32::OLE
	if (ref($data) && $data->{test} && ! eval($data->{test})) {
		next;
	}

	{
		local $SIG{__DIE__} = sub { die(@_); };
		eval 'use ' . $_ ;
		my $module_display = $_;
		$module_display =~ s/( [\d\.]+)$/ \>\=$1/isg;
		print " --> $module_display... ";
		if ($@) {
			$warnings++;
			print "NOT FOUND\n";
			print "     ??? you may need module: $module_display\n";
			print "         CAUSE: $optional_modules->{$_}\n";
#			print "   ERROR: $@\n";
		} 
		else {
			print "found.\n";
		}
	}
}

my $CPAN = <<CPAN;

-=-= CPAN HELP =-=-

There are many modules that have to be installed in order to begin using
Apache::SessionManager. The easiest way to install modules is with CPAN.pm.
To use its command line shell, execute the following: 

% perl -MCPAN -e shell

Then to install any required modules, like Apache::Session:

  cpan> install Apache::Session

and cpan will do this for you. For more information, please view the CPAN 
docs with:

% perldoc CPAN

-=-= CPAN HELP =-=-

CPAN

if ($errors) {
	print "\n***\n*** Required modules not founded!\n***\n";
	print $CPAN,"\n";
} 
elsif ($warnings) {
	print $CPAN;
} 
else {
	print "\nRequired modules founded!\n";
}

# Check Apache / mod_perl test
my ($apache_Test,$apache_testold) = which_test_suite($mp1,$mp2);

# Skip test with -n command line option 
unless ( $opt_n ) {
	# Tests under Apache::Test are coming soon... :-)
	if ( $mp2 || $apache_Test ) {
		print "\n*** Sorry, Apache::Test has been detected, but there aren't (not yet) tests under this suite.";
	}
	# Run tests under Apache::testold
	if ( $mp1 ) {
		if ( ! $apache_testold ) {
			print "\n*** Sorry, the mod_perl 1 version ($mp1) is too old to run Apache::testold tests.\n*** Please install a version >= 1.27 in order to run tests.";
		}
		else {
			print "\n*** Configuring test under Apache::testold suite...\n";
			print "*** Note that Apache::testold suite can run only under Apache 1.x/mod_perl 1.x\n";
			# Currently, there is only Apache::testold tests :-(...
			require Apache::testold;
			my %params = Apache::testold->get_test_params();
			Apache::testold->write_httpd_conf( %params, include => join('', <DATA>) );
			*MY::test = sub { Apache::testold->MM_test(%params) }; 
		}
	}
	print "\n\n";
}
else {
	print "\n*** You've launched Makefile.PL with '-n' option. Tests will be skipped.\n\n";
}

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'         => 'Apache::SessionManager',
	'AUTHOR'       => 'Enrico Sorcinelli <enrico@sorcinelli.it>',
	'ABSTRACT'     => 'Apache mod_perl module to manage HTTP sessions',
	'VERSION_FROM'	=> 'SessionManager.pm', # finds $VERSION
	'PREREQ_PM'		=> {
                      'mod_perl'        => 1.24,
                      'Apache::Session' => 1.54,
                      #"Apache::Request" => "0.33",
                     }, # e.g., Module::Name => 1.1
	'clean'        => {FILES => 't/httpd.conf t/error_log t/httpd'},							
);

sub which_mod_perl {
	my ($mp1,$mp2);
	
	# First, we check mod_perl version in standard dir
	$mp1 = require_mod_perl();
	
	# Check if mod_perl installed version is mp1 or mp2 generation
	if ( $mp1 >= 1.99 ) {
		$mp2 = $mp1;
		$mp1 = 0;
	}
	# Check mp2 under Apache2 dir
	else {
	   $mp2 = require_mod_perl(2);
	}
	return ($mp1,$mp2);
}

sub require_mod_perl {
	my $mp = shift;
	# Check mod_perl 2 under Apache2 dir
	if ( $mp == 2 ) {
		delete $INC{'mod_perl.pm'};
		eval { require Apache2 };
		return 0 if ($@);
	}
	eval { require mod_perl };
	unless ($@) {
		return $mod_perl::VERSION;
	}
	return 0;
}

sub which_test_suite {
	my ($mp1,$mp2) = @_;
	# default: no mod_perl at all
	my ($apache_Test, $apache_testold) = (0,0);
	
	if ( $mp1 ) {
		$apache_testold = ($mp1 >= 1.28) ? 1 : 0;
		eval { require Apache::Test };
		$apache_Test = 1 unless ($@);
	}
	if ( $mp2 ) {
		$apache_Test = 1;
	}
	return ($apache_Test, $apache_testold);
}

__DATA__
# Enable perl-status console
PerlModule Apache::Status
<Location /perl-status>
	SetHandler perl-script
	PerlHandler Apache::Status
</Location>

# Apache::SessionManager configuration section
PerlModule Apache::SessionManager
PerlTransHandler Apache::SessionManager
PerlSetVar SessionManagerTracking On
PerlSetVar SessionManagerDebug 5

# These documents require cookies session
<Location /session>
	SetHandler perl-script
	PerlHandler PrintEnv
	PerlSetVar SessionManagerExpire 0
	PerlSetVar SessionManagerStore File
	PerlSetVar SessionManagerLock Null
	PerlSetVar SessionManagerCookieArgs "Path => /session, Secure => 0, Extras => some_value"
	PerlSetVar SessionManagerStoreArgs "Directory => /tmp"
	PerlSetVar SessionManagerSetEnv On
</Location>

# These documents require cookies session (OO Apache::SessionManager interface)
<Location /session-OO>
	SetHandler perl-script
	PerlHandler PrintEnvOO
	PerlSetVar SessionManagerStore File
	PerlSetVar SessionManagerLock Null
	PerlSetVar SessionManagerCookieArgs "Path => /session-OO, Secure => 0, Extras => some_value"
	PerlSetVar SessionManagerStoreArgs "Directory => /tmp"
	PerlSetVar SessionManagerSetEnv On
</Location>

# These documents require cookies session (OO Apache::SessionManager interface)
# with header exclusion list
<Location /session-header_exclude>
	SetHandler perl-script
	PerlHandler PrintEnvOO
	PerlSetVar SessionManagerStore File
	PerlSetVar SessionManagerLock Null
	PerlSetVar SessionManagerCookieArgs "Path => /session-header_exclude, Secure => 0"
	PerlSetVar SessionManagerStoreArgs "Directory => /tmp"
	PerlSetVar SessionManagerSetEnv On
	PerlSetVar SessionManagerHeaderExclude "User-Agent = > Opera\s*\d"
	PerlAddVar SessionManagerHeaderExclude "User-Agent => lynx"
	PerlAddVar SessionManagerHeaderExclude "Referer => ^http://localhost"		  
</Location>

# These documents require cookies session (OO Apache::SessionManager interface)
# with ip exclusion list
<Location /session-ip_exclude>
	SetHandler perl-script
	PerlHandler PrintEnvOO
	PerlSetVar SessionManagerStore File
	PerlSetVar SessionManagerLock Null
	PerlSetVar SessionManagerCookieArgs "Path => /session-ip_exclude, Secure => 0"
	PerlSetVar SessionManagerStoreArgs "Directory => /tmp"
	PerlSetVar SessionManagerSetEnv On
	PerlSetVar SessionManagerIPExclude "192.168.0.1 127.0.0.0/8"
</Location>

# These documents require cookies session w/authentication
<Location /session-auth>
	SetHandler perl-script
	PerlHandler PrintEnv
	PerlSetVar SessionManagerStore File
	PerlSetVar SessionManagerLock Null
	PerlSetVar SessionManagerCookieArgs "Path => /session-auth, Secure => 0"
	PerlSetVar SessionManagerStoreArgs "Directory => /tmp"
	PerlSetVar SessionManagerSetEnv On

	AuthName "Reserved Club"
	AuthType Basic
	require valid-user
	PerlAuthenHandler MyAuth
	PerlSetVar MyAuthLogin /protected/login.html 
</Location>

# These documents URI tracking session
<LocationMatch "^/([0-9a-h]+/)?uri-session">
	SetHandler perl-script
	PerlHandler PrintEnv
	PerlSetVar SessionManagerExpire none
	PerlSetVar SessionManagerURITracking On
	PerlSetVar SessionManagerStore File
	PerlSetVar SessionManagerLock Null
	PerlSetVar SessionManagerStoreArgs "Directory => /tmp"
	PerlSetVar SessionManagerSetEnv On
</LocationMatch>

# These documents require cookies session + mod_backhand cookie load-balancing
<Location /session-bh>
	SetHandler perl-script
	PerlHandler PrintEnv
	PerlSetVar SessionManagerStore File
	PerlSetVar SessionManagerLock Null
	PerlSetVar SessionManagerCookieArgs "Path => /session-bh"
	PerlSetVar SessionManagerStoreArgs "Directory => /tmp"
	PerlSetVar SessionManagerEnableModBackhand On
	PerlSetVar SessionManagerSetEnv On
</Location>


# These documents don't require cookies session
<Location /no-session>
	SetHandler perl-script
	PerlHandler PrintEnv
	PerlSetVar SessionManagerTracking Off
</Location>

# These documents require MySQL as backend datastore for cookies session (OO Apache::SessionManager interface)
# Not used in live tests (t/httpd -f `pwd`/t/httpd.conf -DDBI)
<IfDefine DBI>
	PerlModule Apache::DBI
	<Location /session-OO-DBI>
		SetHandler perl-script
		PerlHandler PrintEnvOO
		PerlSetVar SessionManagerName SESSION-MySQL
		PerlSetVar SessionManagerStore MySQL
		PerlSetVar SessionManagerStoreArgs "DataSource => dbi:mysql:sessions, \
		                                    UserName   => sesman, \
		                                    Password   => sesman"
		PerlSetVar SessionManagerCookieArgs "Path => /session-OO-DBI"
		PerlSetVar SessionManagerSetEnv On
	</Location>
</IfDefine>
