use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Crypt::xDBM_File',
    'VERSION_FROM' => 'xDBM_File.pm', # finds $VERSION
    'PREREQ_PM'  => {
	'Crypt::Blowfish'	=> '0', # or a minimum workable version
    }

);
