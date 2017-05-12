use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MY_YAPP = `which yapp`;
chomp $MY_YAPP;
$MY_YAPP eq '' and die "install Parse::Yapp";

my $MY_PERL = `which perl`;
chomp $MY_PERL;
my $bin = 'bin/navegante';

`$MY_YAPP -b $MY_PERL -o $bin lib/App/Navegante.yp`;
`chmod 755 $bin`;

WriteMakefile(
    NAME                => 'App::Navegante',
    AUTHOR              => 'Nuno Carvalho <smash@cpan.org>',
    VERSION_FROM        => 'lib/App/Navegante.pm',
    ABSTRACT_FROM       => 'lib/App/Navegante.pm',
    EXE_FILES           => [ $bin ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Request'  => 0,
        'URI::URL'       => 0,
        'CGI'            => 0,
        'XML::DT'        => '0.51',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => "App-Navegante-* $bin" },
);
