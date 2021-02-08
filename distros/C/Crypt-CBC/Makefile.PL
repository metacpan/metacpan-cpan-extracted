use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Crypt::CBC',
    'VERSION_FROM' => 'lib/Crypt/CBC.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Digest::MD5'        => 0,
	'Digest::SHA'        => 0,
        'Crypt::PBKDF2'      => 0,
	'Crypt::Cipher::AES' => 0,
    },
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'dist'      => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
	            'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'}

);
