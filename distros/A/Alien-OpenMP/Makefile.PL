use strict;
use warnings;
use ExtUtils::MakeMaker;
use Devel::CheckLib;
use lib q{lib};
use Config ();

# all supported compilers must be registered in @SUPPORTED_CCNAMES
my @SUPPORTED_CCNAMES = (qw/gcc/);

_assert_supported_environment( $Config::Config{ccname} );

my $repo = 'oodler577/p5-Alien-OpenMP';
(my $file = (my $pkg = 'Alien::OpenMP')) =~ s#::#/#g;
$file = "lib/$file.pm";
WriteMakefile(
    NAME               => $pkg,
    VERSION_FROM       => $file,
    ABSTRACT_FROM      => $file,
    AUTHOR             => q{OODLER 577 <oodler@cpan.org>},
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => '5.008009',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::CheckLib'     => 0,
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Devel::CheckLib'     => 0,
    },
    TEST_REQUIRES => {
        'Test::More'      => 0,
        'Devel::CheckLib' => 0,
    },
    PREREQ_PM => {
        'Test::More' => 0,
        'Devel::CheckLib' => 0,
    },
    META_MERGE => {
        "meta-spec"    => { version => 2 },
        dynamic_config => 0,
        resources      => {
            x_IRC      => 'irc://irc.perl.org/#pdl',
            repository => {
                type => 'git',
                url  => "git\@github.com:$repo.git",
                web  => "https://github.com/$repo",
            },
            bugtracker => {
                web => "https://github.com/$repo/issues",
            },
            license => ['http://dev.perl.org/licenses/'],
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::Pod::Coverage' => '1.08',
                    'Pod::Coverage'       => '0.18',
                    'Test::Pod'           => '1.00',
                    'Pod::Markdown'       => 0,
                    'Inline::C'           => 0,
                    'Devel::CheckLib'     => 0,
		    'Dist::Zilla'         => 0,
                },
            },
            test => {
                recommends => {
                    'App::Prove' => '3.00',    # prove -j4
                },
            },
        },
    },
);

# OpenMP specific assertion that leverages Devel::CheckLib and
# information that should be provided for the compiler being test
# but the Alien::OpenMP module itself
sub _assert_supported_environment {
    my $ccname = shift;

    # fail out the boat for macos since clang masks as gcc and needs
    # to be handled as a new compiler type integration
    die qq{OS unsupported\n} if $^O eq q{darwin};

    if ( grep { $_ =~ /$Config::Config{ccname}/ } @SUPPORTED_CCNAMES ) {
        require Alien::OpenMP;
        my $ao = bless {}, q{Alien::OpenMP};
        local $/ = undef;    # slurp mode for main() body in __DATA__
        check_lib_or_exit(
            lib      => $ao->_check_libs,
            header   => $ao->_check_headers,
            ccflags  => $ao->cflags,
            ldflags  => $ao->lddlflags,
            function => <DATA>,
        );
        return;
    }
    die qq{OS unsupported\n};
}

__DATA__
/*
   start of main() implied via use of Devel::CheckLib
   the following should only pass if running in a properly
   supported OpenMP environment; modifications to this should
   ensure it's not just testing for a successful compile and link
*/
  // done before thread fork
  omp_set_num_threads(3);
  int ans = 42;
  // thread section follows
  #pragma omp parallel
    #pragma omp master
      ans = omp_get_num_threads(); // done in parallel section, but only by master thread (0)
  if (3 == ans)
    return 0;   // good
  return 1;     // bad
// end of implicit main
