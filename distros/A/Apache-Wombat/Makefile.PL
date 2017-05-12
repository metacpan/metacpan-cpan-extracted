# -*- Mode: Perl; indent-tabs-mode: nil; -*-

require 5.6.0;

use strict;
use warnings;

use Config;
use Cwd;
use ExtUtils::MakeMaker;
use File::Spec;

print "\nHi. I'm going to ask for some installation locations now. Feel free
to use '.' in your answers to specify the current working directory. If you
don't specify anything, the default will be used.\n\n";

# find installation directory
my $installdir = $Config{installprefix};
print "Installation root (defaults to the location of perl; another common\n";
print "choice is your Apache ServerRoot):\n[$installdir] ";
chomp(my $selection = <STDIN>);
if ($selection) {
    $selection =~ s/~/$ENV{HOME}/;
    $installdir = -d $selection || -l $selection ?
        Cwd::abs_path($selection) : $selection;
}
print "Using PREFIX $installdir\n\n";

# find apache conf directory
my $configdir = File::Spec->catdir($installdir, 'conf');
print "Config file directory:\n[$configdir] ";
chomp($selection = <STDIN>);
if ($selection) {
    $selection =~ s/~/$ENV{HOME}/;
    $configdir = -d $selection || -l $selection ?
        Cwd::abs_path($selection) : $selection;
}
print "Config files will be placed in $configdir\n\n";
my $apacheconfigfile = File::Spec->catfile($configdir, 'wombat.conf');
my $serverconfigfile = File::Spec->catfile($configdir, 'server.xml');

# find log directory
my $logdir = File::Spec->catdir($installdir, 'logs');
print "Log file directory:\n[$logdir] ";
chomp($selection = <STDIN>);
if ($selection) {
    $selection =~ s/~/$ENV{HOME}/;
    $configdir = -d $selection || -l $selection ?
        Cwd::abs_path($selection) : $selection;
}
print "Log file will be placed in $logdir\n\n";
my $logfile = File::Spec->catfile($logdir, 'wombat.log');

# find webapp directory
my $fullwebappdir;
my $webappdir = File::Spec->catdir($installdir, 'webapps');
print "Looking for previously installed webapps in\n$webappdir...\n";
$fullwebappdir = $webappdir;
if (-d $webappdir || -l $webappdir) {
    $webappdir = 'webapps';
    print "Found it.\n\n";
} else {
    print "Can't find your webapps. Chances are you haven't installed them yet.
When you do that, where will you put them?\n[$webappdir] ";
    chomp($selection = <STDIN>);
    if ($selection) {
        $selection =~ s/~/$ENV{HOME}/;
        $webappdir = -d $selection || -l $selection ?
            Cwd::abs_path($selection) : $selection;
        $fullwebappdir = $webappdir;
    }
    print "Using webapps in $webappdir\n\n";
}

# write private config file
open CFG, "> .cfg" or
    die "can't open .cfg: $0\n";
print CFG qq(
package Apache::Wombat::cfg;

\$installdir = '$installdir';
\$configdir = '$configdir';
\$apacheconfigfile = '$apacheconfigfile';
\$serverconfigfile = '$serverconfigfile';
\$logdir = '$logdir';
\$logfile = '$logfile';
\$webappdir = '$webappdir';
\$fullwebappdir = '$fullwebappdir';

1;
);
close CFG;

my @PREFIX = $installdir ne $Config{installprefix} ?
    (PREFIX => $installdir) : ();

WriteMakefile(
              NAME         => 'Apache::Wombat',
              VERSION_FROM => 'lib/Apache/Wombat.pm',
              PREREQ_PM    => {
                               'Apache' => 0,
                               'Apache::Request' => 0,
                               'Apache::Util' => 0,
                               'IPC::ShareLite' => 0,
                               'Cache::SharedMemoryCache' => 0,
                               'Wombat' => '0.7.1',
                              },
              PL_FILES     => { 'conf/server.xml.PL' => 'conf/server.xml',
                                'conf/wombat.conf.PL' => 'conf/wombat.conf' },
              clean        => { FILES => 'conf/server.xml .cfg' },
              @PREFIX,
             );

package MY;

sub MY::postamble {
    return
        q(

POD2HTML=pod2html

docs/api/%.html : lib/%.pm
	@(echo generating $@; \
	$(MKPATH) `dirname $@`; \
	slashes=`$(FULLPERL) -e 'print "../" x ((split /\//, $$ARGV[0])-1)' $<`; \
	$(POD2HTML) --htmlroot=$${slashes}api \
	            --css=$${slashes}wombat.css \
	            --infile=$< \
	            --outfile=$@)

WOMBAT_HTML_1=$(subst .pm,.html,$(TO_INST_PM))
WOMBAT_HTML=$(subst lib/,docs/api/,$(WOMBAT_HTML_1))

html: pm_to_blib $(WOMBAT_HTML)

CP = $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) -MExtUtils::Command -e cp

INSTCONF = ) .

    $configdir .

        q(

INSTLOGS = ) .

    $logdir .

        q(

pure_site_install ::
	@$(MKPATH) $(INSTCONF)
	@if [ -e $(INSTCONF)/server.xml ]; then \
		echo Preserving existing config file $(INSTCONF)/server.xml; \
	else \
		echo Installing $(INSTCONF)/server.xml; \
		$(CP) conf/server.xml $(INSTCONF); \
	fi
	@if [ -e $(INSTCONF)/wombat.conf ]; then \
		echo Preserving existing config file $(INSTCONF)/wombat.conf; \
	else \
		echo Installing $(INSTCONF)/wombat.conf; \
		$(CP) conf/wombat.conf $(INSTCONF); \
	fi
	@if [ -e $(INSTLOGS)/wombat.log ]; then \
		echo Preserving existing log file $(INSTLOGS)/wombat.log; \
	else \
		echo Installing $(INSTLOGS)/wombat.log; \
		$(TOUCH) $(INSTLOGS)/wombat.log; \
	fi
);
}
