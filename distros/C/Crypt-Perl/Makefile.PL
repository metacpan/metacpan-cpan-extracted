
use ExtUtils::MakeMaker::CPANfile;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Crypt::Perl',
    VERSION_FROM => 'lib/Crypt/Perl.pm',            # finds \$VERSION
    AUTHOR       => 'Felipe Gasper, with contributions from Mohammad S Anwar',
    ABSTRACT_FROM => 'lib/Crypt/Perl.pm',
    LICENSE      => 'perl_5',
    MIN_PERL_VERSION => '5.8.0',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/FGasper/p5-Crypt-Perl.git',
                web  => 'https://github.com/FGasper/p5-Crypt-Perl',
            },
        },
        recommends => {
            'Math::BigInt::GMP' => 0,
        },
    },
);
