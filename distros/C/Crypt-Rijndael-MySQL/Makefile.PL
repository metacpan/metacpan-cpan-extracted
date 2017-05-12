use ExtUtils::MakeMaker;

require 5.006;

WriteMakefile(
    NAME            => 'Crypt::Rijndael::MySQL',
    VERSION_FROM    => 'lib/Crypt/Rijndael/MySQL.pm',
    PREREQ_PM       => {
        'Crypt::Rijndael'   => 1.09,
        'Test::More'        => 0.94,
    },
    ABSTRACT_FROM   => 'lib/Crypt/Rijndael/MySQL.pm',
    AUTHOR          => 'Ivan Fomichev <ifomichev@cpan.org>',
);
