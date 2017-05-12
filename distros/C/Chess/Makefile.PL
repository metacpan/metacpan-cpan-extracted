use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Chess',
    VERSION_FROM      => 'lib/Chess.pm',
    PREREQ_PM         => { 'List::Compare' => '0' },
    ($] >= 5.005 ?
       (AUTHOR         => 'Brian Richardson <bjr@cpan.org>') : ()),
    INC               => '-I.'
);
