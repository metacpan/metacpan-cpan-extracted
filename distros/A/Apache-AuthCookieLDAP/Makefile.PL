use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'      => 'Bjorn Ardo (f98ba@efd.lth.se)',
    'NAME'	=> 'Apache::AuthCookieLDAP',
    'VERSION_FROM' => 'AuthCookieLDAP.pm', # finds $VERSION
    'PREREQ_PM'   => {
        'Apache::AuthCookie'    => '0', # or a minimum workable version
	}
);
