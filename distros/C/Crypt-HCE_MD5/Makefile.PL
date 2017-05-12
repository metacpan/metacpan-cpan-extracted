use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Crypt::HCE_MD5',
    'VERSION_FROM' => 'HCE_MD5.pm', # finds $VERSION
    'PREREQ_PM' => {'Digest::MD5' => 2, 
		    'MIME::Base64' => 2}
);
