use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.008;

WriteMakefile(
    NAME          => 'Bookmarks::Parser',
    AUTHOR        => 'Marcus Ramberg <mramberg@cpan.org>',
    VERSION_FROM  => 'lib/Bookmarks/Parser.pm',
    ABSTRACT_FROM => 'lib/Bookmarks/Parser.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'        => 0,
        'HTML::TreeBuilder' => 0,
        'Net::Delicious'    => 0,
        'WWW::A9Toolbar'    => 0,
        'XML::Simple'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Bookmarks-Parser-*' },
);
