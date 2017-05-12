use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Convert::Bencode_XS',
    VERSION_FROM    => 'lib/Convert/Bencode_XS.pm',
    PREREQ_PM       => {
        Test::More  =>  0,
    }, 
    ABSTRACT_FROM   => 'lib/Convert/Bencode_XS.pm', 
    AUTHOR          => 'Giulio Motta <giulienk@cpan.org>',
    LIBS            => [''], # e.g., '-lm'
    DEFINE          => '', # e.g., '-DHAVE_SOMETHING'
    INC             => '-I.', # e.g., '-I. -I/usr/include/other'
);
