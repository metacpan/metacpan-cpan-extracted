
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Crypt::Perl',
    VERSION_FROM => 'lib/Crypt/Perl.pm',            # finds \$VERSION
    AUTHOR       => 'Felipe Gasper, with contributions from Mohammad S Anwar',
    ABSTRACT_FROM => 'lib/Crypt/Perl.pm',
    LICENSE      => 'perl',
    MIN_PERL_VERSION => '5.8.0',
    PREREQ_PM    => {
        'autodie'                  => 0,
        'constant'                 => 1.23,
        'parent'                   => 0.225,
        'Bytes::Random::Secure::Tiny' => 1.008,
        'Class::Accessor::Fast' => 0.34,
        'Convert::ASN1' => 0.27,
        'Crypt::Format'            => 0.06,
        'Digest::SHA'              => 0,
        'Math::BigInt' => 1.999805,     #min version, yes
        'Math::ProvablePrime'   => 0.043,
        'Math::Utils'   => 1.07,    #need floor()
        'MIME::Base64' => 3.11,
        'Symbol::Get' => 0.02,
        'Try::Tiny'        => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-Crypt-Perl.git',
                web  => 'https://github.com/FGasper/p5-Crypt-Perl',
            },
        },
    },
    TEST_REQUIRES => {
        'Call::Context' => 0,
        'File::Slurp'     => 0,
        'File::Which' => 0,
        'Test::Class'     => 0.4,
        'Test::More'      => 1.0,
        'Test::Deep'      => 0,
        'Test::Exception' => 0.40,
        'Test::NoWarnings' => 0,
        'Test::FailWarnings' => 0,
    },
);
