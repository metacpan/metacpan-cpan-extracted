use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

my %params = (
    NAME          => 'Archive::Any::Lite',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Archive/Any/Lite.pm',
    ABSTRACT_FROM => 'lib/Archive/Any/Lite.pm',
    LICENSE       => 'perl',
    META_MERGE => {
       resources => {
           repository => 'https://github.com/charsbar/archive-any-lite',
       },
    }
);

WriteMakefile(%params);
