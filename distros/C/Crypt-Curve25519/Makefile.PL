use ExtUtils::MakeMaker;
use Config;

my $x64 = $Config{ptrsize} == 8 ? 1 : 0;

WriteMakefile(
    NAME              => 'Crypt::Curve25519',
    VERSION_FROM      => 'lib/Crypt/Curve25519.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM  => 'lib/Crypt/Curve25519.pm', # retrieve abstract from module
    AUTHOR         => 'Alex J. G. Burzyski <ajgb\@cpan.org>',
    DEFINE            => "-DUSE_X64=$x64",
);

