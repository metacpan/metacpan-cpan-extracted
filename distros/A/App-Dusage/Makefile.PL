#! perl

use strict;
use warnings;

exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010001;

die("OS unsupported\n") if $^O eq 'MSWin32';

# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

# For binaries/scripts.
my @bins = qw( dusage );

my $master = "script/$bins[0].pl";
my $version = MM->parse_version($master);

WriteMakefile(
    NAME                => 'App::Dusage',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION             => $version,
    ABSTRACT            => 'provide disk usage statistics',
    LICENSE             => 'perl_5',
    PL_FILES            => {},
    MIN_PERL_VERSION    => '5.010001',

    @bins == 0 ? () : (
      EXE_FILES         => [ map { "script/$_" } @bins ],
      PL_FILES          => {
                             'script/pp.PL' => [ map { "script/$_" } @bins ]
                           },
    ),

    PREREQ_PM => {
      'ExtUtils::MakeMaker' => 6.5503, # for META_MERGE, LICENSE, *_REQUIRES
      'Test::More'          => 0,
    },

    META_MERGE => {
      provides => {
        dusage => { file => "script/dusage",
		    version => $version },
        "App::Dusage"
               => { file => "lib/App/Dusage.pm",
                    version => $version },
     },
      resources    => {
        repository => 'https://github.com/sciurius/dusage',
        bugtracker => "https://github.com/sciurius/dusage/issues",
        license    => "http://dev.perl.org/licenses/",
      },
      'meta-spec' => {
        version => '2',
        url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
      },
    },
);
