use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# That's the minimum.
use 5.006;

use Config;

# Check for Log::Log4perl;
eval { require Log::Log4perl; };
if($@) {
	die <<'Log::Log4perl_Not_Installed;';

Log::Log4perl must be installed prior to building ClearCase::Region
and I can't find it in the standard library directories. You can
download Log4perl from a http://www.cpan.org mirror site.

Log::Log4perl_Not_Installed;
}

@extras = ();

push(@extras,
     CAPI => 'TRUE')
    if ($PERL_VERSION >= 5.005 and $OSNAME eq 'MSWin32'
	and $Config{archname} =~ /-object\b/i);

push(@extras,
     ABSTRACT_FROM => 'lib/ClearCase/Region.pm',
     AUTHOR        => 'Les Paul (Leslie.D.Paul@bankofamerica.com)')
    if ($ExtUtils::MakeMaker::Version >= 5.4301);
     
WriteMakefile(
	'NAME'  		=> 'ClearCase::Region',
	'VERSION_FROM'	=> 'lib/ClearCase/Region.pm', # finds $VERSION
	'PREREQ_PM'		=> { Log::Log4perl => 0.31, },
	'clean'         => {FILES => "*.tar.gz *.ppd pod2htm*"},
	@extras
);
