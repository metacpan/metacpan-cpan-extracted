use ExtUtils::MakeMaker;
use 5.008;

WriteMakefile(
    NAME         => 'Crypt::AppleTwoFish',
    VERSION_FROM => 'lib/Crypt/AppleTwoFish.pm', # finds $VERSION
    AUTHOR       => 'William Hererra (whererra@skylightview.com)',
    ABSTRACT     => 'An Apple iTMS internal key descrambling algorithm',
    PREREQ_PM    => { Carp => 0, Digest::SHA => 0, Math::BigInt => 0 },
    LICENSE      => 'Other',
);
