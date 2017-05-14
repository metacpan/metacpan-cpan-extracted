use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use ExtUtils::testlib;
use lib qw(../blib/lib ../blib/arch ../lib);

use Apache::src ();
my $src = Apache::src->new;

$necessary_modules = {
	'Apache' => 'Make sure your installation of mod_perl is complete',
	'LWP::UserAgent' => 'You need to install the LWP modules',
	'URI::URL' => 'You need to install URI::URL',
	'Apache::Table' => 'mod_perl needs to have Table enabled',
	'Apache::Util' => 'mod_perl needs to have Util enabled'
};

my($errors, $warnings);
for(sort keys %$necessary_modules) {
    eval 'require ' . $_ ;
    if($@) {
        $errors++;
        print " ERROR: could not find  $_\n";
        print "     WHY: $necessary_modules->{$_}\n";
    } else {
        print " ... found $_ !\n";
    }
}

WriteMakefile(
    'NAME'      => 'Apache::RewritingProxy',
    'VERSION_FROM' => 'RewritingProxy.pm', # finds $VERSION
    'LIBS'      => [''],   # e.g., '-lm'
    'DEFINE'    => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'       => $src->inc,     # e.g., '-I/usr/include/other'
);


