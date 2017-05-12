use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MY_YAPP = `which yapp`;
chomp $MY_YAPP;
$MY_YAPP eq '' and die "install Parse::Yapp";

`$MY_YAPP -m Biblio::Thesaurus::ModRewrite::Parser -o lib/Biblio/Thesaurus/ModRewrite/Parser.pm lib/Biblio/Thesaurus/ModRewrite/Parser.yp`;
if ($? == 0) { print "Building lib/Biblio/Thesaurus/ModRewrite/Parser.pm\n"; }
else { print "Building lib/Biblio/Thesaurus/ModRewrite.pm (failed)\n"; }

WriteMakefile(
    NAME                => 'Biblio::Thesaurus::ModRewrite',
    AUTHOR              => 'Nuno Carvalho <smash@cpan.org>',
    VERSION_FROM        => 'lib/Biblio/Thesaurus/ModRewrite.pm',
    ABSTRACT_FROM       => 'lib/Biblio/Thesaurus/ModRewrite.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Output' => 0,
        'Parse::Yapp' => 0,
        'Biblio::Thesaurus' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Biblio-Thesaurus-ModRewrite-*' },
    MAKEFILE_OLD        => '',
);
