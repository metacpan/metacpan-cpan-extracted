#! perl

use strict;
use warnings;

exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010001;

# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

# For binaries/scripts.
my @bins = qw( pdfolay );

my $master = 'lib/App/PDF/Overlay.pm';
my $version = MM->parse_version($master);

WriteMakefile(
    NAME                => 'App::PDF::Overlay',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION             => $version,
    ABSTRACT	        => 'pdfolay - insert a PDF document over/under another document',
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
      'PDF::API2'	    => 2.042,
      'Pod::Find'	    => 0,
      'Pod::Usage'	    => 0,
      'ExtUtils::MakeMaker' => 6.5503, # for META_MERGE, LICENSE, *_REQUIRES
      'Test::More'          => 0,
    },

    TEST_REQUIRES  => {
		    'Test::More'                  => 0,
    },

    META_MERGE => {
      resources    => {
        repository => 'https://github.com/sciurius/pdfolay',
        bugtracker => "https://github.com/sciurius/pdfolay/issues",
        license    => "https://dev.perl.org/licenses/",
      },
      provides => {
	 pdfolay => { file => "script/pdfolay",
		       version => $version },
	 'App::PDF::Overlay' => { file => $master,
		       version => $version },
      },
      'meta-spec' => {
        version => '2',
        url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
      },
    },
);
