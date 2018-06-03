use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache2_4::AuthCookieMultiDBI',
    'VERSION_FROM'	=> 'lib/Apache2_4/AuthCookieMultiDBI.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'strict'                    => 0,
        'warnings'                  => 0,
        'Apache2_4::AuthCookie'     => '3.26 ',
        'Date::Calc'                => '6.4',
        'DBI'                       => '1.641',
        'Digest::MD5'               => '2.55',
        'English'                   => '1.10',

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'lib/Apache2_4/AuthCookieMultiDBI.pm', # retrieve abstract from module
        AUTHOR     => 'Details <details -at- cpan -dot- org>') : ()
    ),

    BUILD_REQUIRES => {
     	  'Test::More' => '1.302136'
    },
);
