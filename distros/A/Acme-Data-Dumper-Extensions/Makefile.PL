use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;

my $GH_NAME  = 'kentnl';
my $DISTNAME = 'Acme-Data-Dumper-Extensions';
( my $PMNAME = $DISTNAME ) =~ s/-/::/g;

my $MAINFILE = 'lib/' . do { ( my $x = $DISTNAME ) =~ s/-/\//g; $x }
  . '.pm';

my %requirements = (
    configure_requires => {
        "ExtUtils::MakeMaker" => 0,
    },
    build_requires   => {},
    runtime_requires => {
        "Data::Dumper" => 0,
    },
    test_requires => {
        "Test::More" => "0.89",
    },
);

my %merged_requirements = (
    "ExtUtils::MakeMaker" => 0,
    "Data::Dumper"        => 0,
    "Test::More"          => 0.89,
);

my %meta = (
    name    => $DISTNAME,
    license => ['perl'],
    prereqs => {
        configure => { requires => $requirements{configure_requires} },
        build     => { requires => $requirements{build_requires} },
        runtime   => { requires => $requirements{runtime_requires} },
        test      => { requires => $requirements{test_requires} },
    },
    resources => {
        repository => {
            url  => 'git://github.com/' . $GH_NAME . '/' . $DISTNAME,
            web  => 'https://github.com/' . $GH_NAME . '/' . $DISTNAME,
            type => 'git',
        },
        bugtracker => {
                web => 'https://github.com/'
              . $GH_NAME . '/'
              . $DISTNAME
              . '/issues',
        },
        homepage => 'https://github.com/' . $GH_NAME . '/' . $DISTNAME,
        license  => ['http://dev.perl.org/licenses/'],
    },
    'meta-spec' => { version => 2 },
);

our %MM_Args = (
    AUTHOR           => 'Kent Fredric <kentnl@cpan.org>',
    NAME             => $PMNAME,
    DISTNAME         => $DISTNAME,
    EXE_FILES        => [],
    MIN_PERL_VERSION => '5.006',
    VERSION_FROM     => $MAINFILE,
    ABSTRACT_FROM    => $MAINFILE,
    test             => {
        TESTS => "t/*.t",
    },
);

sub is_eumm {
    eval { ExtUtils::MakeMaker->VERSION( $_[0] ) };
}

is_eumm(6.30) and $MM_Args{LICENSE} = $meta{license}[0];
is_eumm(6.47_01) or delete $MM_Args{MIN_PERL_VERSION};
is_eumm(6.52)
  and $MM_Args{CONFIGURE_REQUIRES} = $requirements{configure_requires};

is_eumm(6.57_02) and !is_eumm(6.57_07) and $MM_Args{NO_MYMETA} = 1;

if ( is_eumm(6.63_03) ) {
    %MM_Args = (
        %MM_Args,
        TEST_REQUIRES  => $requirements{test_requires},
        BUILD_REQUIRES => $requirements{build_requires},
        PREREQ_PM      => $requirements{runtime_requires},
    );
}
else {
    $MM_Args{PREREQ_PM} = \%merged_requirements;
}

unless ( -f 'META.yml' ) {
    $MM_Args{META_ADD} = \%meta;
    require "./maint/eumm_author.pl";
}

WriteMakefile(%MM_Args);
