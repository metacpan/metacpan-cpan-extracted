use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Crypt::SMimeEngine',
    VERSION_FROM => 'lib/Crypt/SMimeEngine.pm', # finds \$VERSION
    AUTHOR       => 'Flavio Fanton (flavio.fanton@staff.aruba.it)',
    ABSTRACT     => 'Interface to OpenSSL for SMIME commands',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
    LIBS         => ['-lssl -lcrypto'],
    INC          => '-I.',
    clean        => {FILES => "t/mail/mail.txt.signed"}
);
