use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Business::Cashcow',
    'VERSION_FROM' => 'Cashcow.pm', # finds $VERSION
    'LIBS'	=> ['-L/usr/src/cashcow -L/usr/local/ssl/lib -lcashcow -lssl -lcrypto'],   # e.g., '-lm'
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
