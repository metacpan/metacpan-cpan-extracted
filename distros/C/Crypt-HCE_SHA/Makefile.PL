use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Crypt::HCE_SHA',
    'VERSION_FROM' => 'HCE_SHA.pm', # finds $VERSION
    'PREREQ_PM' => {'Digest::SHA' => 0,
		    'MIME::Base64' => 2}
);
