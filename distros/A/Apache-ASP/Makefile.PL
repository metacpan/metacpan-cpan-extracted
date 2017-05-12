#!/usr/local/bin/perl

use strict;

$| = 1;

my $mtime_makefile = (stat('Makefile'))[9] || 0;
my $fresh_makefile = ($mtime_makefile > time() - 1200) ? 1 : 0;

my $necessary_modules = {
#    'Apache' => 'Make sure your installation of mod_perl is complete',
    'Class::Struct' => "Apache::ASP->Loader() precompile scripts functionality",
    'MLDBM' => 'This is used for reading and writing multi-level hashes on disk',
    'MLDBM::Sync 0.25' => 'Support for State dbms like $Session & $Application',		 
    'SDBM_File' => 'Internal databases used for state files, like $Session',
    'Data::Dumper' => 'Serializes data for MLDBM',
    'Fcntl' => 'Used for file locking constants',
    'File::Basename' => "Used for tests during 'make test'",
    'Digest::MD5' => '32 byte hash algorithm for cookie session-id',
    'Carp' => 'Provides critical error messaging with confess()',
};

my $optional_modules = 
  {
   'Devel::Symdump' => 'Used for StatINC setting, which reloads modules dynamically',
   'Win32::OLE' => { 
		    test => '$^O eq \'MSWin32\'',
		    message => 'Required for access to ActiveX objects on Win32, like ADO.',
		   },
   'CGI' => 'Required for file upload, make test, and command line ./cgi/asp script',
   'Compress::Zlib' => "Required for html gzip text compression for browsers that support it",
#   'DB_File' => 'Optional module for StateDB & CacheDB config options',
   'MLDBM::Sync::SDBM_File' => 'Optional module for StateDB config option that is faster than DB_File on Linux.  Also default CacheDB for XSLT caching, but DB_File may also be used as well as Tie::TextDir.',
   'HTML::Clean' => 'Compress text/html with Clean config or $Response->{Clean} set to 1-9',
   'HTML::FillInForm' => 
   'Enables FormFill feature which will auto fill forms from $Request->Form data',
   'Apache::Filter' => 'Full SSI support via Apache::Filter & Apache::SSI',
   'Apache::SSI' => 'Full SSI support via Apache::Filter & Apache::SSI',
   'Net::SMTP' => 'Runtime errors can be mailed to the webmaster with MailErrorTo config',
   'Net::Config' => 'Config options for use with Net::SMTP',
   'Time::HiRes' => 'Sub second Apache::ASP response timing with Debug 3/-3 turned on.',
#   'Tie::TextDir .04' => 'Fast cache for CacheDB setting for things like large XSLT transformations.',
   'XML::XSLT 0.32' => 'XSLT, written in perl so makes for an easy install after installing Bundle::XML from CPAN.',
   'XML::Sablotron' => 'XSLT that is 10 times faster than XML::XSLT',
   'XML::LibXSLT' => 'XSLT that is 2 times faster than XML::Sablotron',
};
	    
print "Checking for the REQUIRED modules...\n";
my($errors, $warnings);
for(sort keys %$necessary_modules) {
    eval 'use ' . $_ ;
    my $module_display = $_;
    $module_display =~ s/( [\d\.]+)$/ \>\=$1/isg;
    if($@) {
	$errors++;
	print " !!! you need the module: $module_display\n";
	print "     WHY: $necessary_modules->{$_}\n";
    } else {
	print " ... found $module_display !\n";
    }
}

print "\n";
if(! $errors) {
    print "GOOD NEWS!  You have all the required modules installed for Apache::ASP.\n";
} else {
    print "OTHER MODULES NEEDED! You need to install the above required modules before installing Apache::ASP.\n";
}

print "\n";
sleep(2) unless $fresh_makefile;
print "Checking for the OPTIONAL modules...\n";
sleep(2) unless $fresh_makefile;

for(sort keys %$optional_modules) {
    my $data = $optional_modules->{$_};
    my $message = ref($data) ? $data->{message} : $data;

    # if there is a test for this module run it and if returns false
    # skip this module's message, first so UNIX users don't see 
    # message about Win32::OLE
    if(ref($data) && $data->{test} && ! eval($data->{test})) {
	next;
    }

    {
	local $SIG{__DIE__} = sub { die(@_); };
	eval 'use ' . $_ ;
	my $module_display = $_;
	$module_display =~ s/( [\d\.]+)$/ \>\=$1/isg;
	if($@) {
	    $warnings++;
	    print " ??? you may want module: $module_display\n";
	    print "     WHY: $optional_modules->{$_}\n";
#	    print "   ERROR: $@\n";
	} else {
	    print " ... found $module_display !\n";
	}
    }
}
if($warnings) {
    print "\n--- OPTIONAL modules missing.  You can install Apache::ASP without these. ---\n";
    sleep(2) unless $fresh_makefile;
}

my $CPAN = <<CPAN;

=-=-= CPAN HELP -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=

There are many modules that have to be installed in order
to begin using Apache::ASP.  The easiest way to install
modules is with CPAN.pm.  To use its command line shell,
execute the following:

> perl -MCPAN -eshell

Then to install any required modules, like MLDBM::Sync

 cpan> install MLDBM::Sync

To install the modules commonly used with Apache::ASP, do:

 cpan> install Bundle::Apache::ASP

and cpan will do all the work for you.  For more 
information, please view the CPAN docs with 

> perldoc CPAN

=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=

CPAN
  ;

if($errors) {
    print "\n";
    print $CPAN;
    print "\n";
    print "** You do not have the required modules for Apache::ASP.  Do not run 'make install' **\n\n";
} else {
    if($warnings) {
	print $CPAN;
    }
    print "+++ Looks good!  You are ready to install Apache::ASP! +++ \n\n";
} 

use ExtUtils::MakeMaker;
&WriteMakefile(
	       'NAME' => "Apache::ASP",
	       'VERSION_FROM' => 'CHANGES', # finds $VERSION
	       'PREREQ_PM' => {
			       'Carp' => 0,
			       'Class::Struct' => 0,
			       'Data::Dumper' => 0,
			       'Fcntl' => 0,
			       'File::Basename' => 0,
			       'Digest::MD5' => 0,
			       'MLDBM' => 0,
			       'SDBM_File' => 0,
			       'MLDBM::Sync' => 0,
			      },
               'EXE_FILES' => [ 'asp-perl' ],
	       'clean' => { FILES => 't/long_directory_path_test t/.cache t/.state t/session_events/.state t/null/.state Makefile.old' },
	      );

