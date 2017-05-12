use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Authen::Krb5Password',
    'VERSION_FROM' => 'Krb5Password.pm',
    'LIBS'	=> ['-L/usr/local/lib -lkrb5 -lcom_err'],
    'OBJECT'	=> 'kpass.o Krb5Password.o',
    'DEFINE'	=> '-DNO_REPLAYCACHE',
#    'DEFINE'	=> '',                          # for Heimdal
    'INC'	=> '-I/usr/local/include',
);
