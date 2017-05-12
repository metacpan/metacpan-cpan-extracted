use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::CryptHash',
    'PREREQ_PM'		=> {	'Crypt::CapnMidNite'	=> '1.00',
				'MIME::Base64'		=> '2.11', },
    'VERSION_FROM'	=> 'CryptHash.pm', # finds $VERSION
    'PM'		=> {'CryptHash.pm' => '$(INST_LIBDIR)/CryptHash.pm'},
    'dist'		=> {COMPRESS=>'gzip', SUFFIX=>'gz'}
);
