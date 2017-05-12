use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Crypt::RSA::Parse',
    VERSION_FROM => 'lib/Crypt/RSA/Parse.pm',    # finds \$VERSION
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    ABSTRACT     => 'Parse RSA keys',
    PREREQ_PM    => {
        'Convert::ASN1'         => 0.27,
        'Crypt::Format'         => 0.06,
        'MIME::Base64'          => 3.15,
        'Class::Accessor::Fast' => 0.34,
        'parent'                => 0,
    },
    TEST_REQUIRES => {
        'Test::Simple' => 0.44,
        'Test::NoWarnings' => 0.01,
        'Test::More' => 0.01,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-Crypt-RSA-Parse.git',
                web  => 'https://github.com/FGasper/p5-Crypt-RSA-Parse',
            },
        },
    },
);
