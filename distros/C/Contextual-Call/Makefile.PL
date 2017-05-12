use strict;
use warnings;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile qw(my_metafile);

my $requires = {
};
my $build_requires = {
  'Test::More' => 0,
};
my_metafile( 'Contextual::Call' => {
	license => 'perl',
	
	requires => $requires,
	build_requires => $build_requires,
});

WriteMakefile(
    NAME                => 'Contextual::Call',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/Contextual/Call.pm',
    ABSTRACT_FROM       => 'lib/Contextual/Call.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        %$requires, %$build_requires,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Contextual-Call-*' },
);
