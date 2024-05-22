use v5.28;
use ExtUtils::MakeMaker::CPANfile;
use Path::Tiny 0.062;

# The Perl toolchain doesn't know about feature class yet, so we
# must specify all namespaces in META using the provides key.
my %provides;
path('lib')->visit(
  sub {
    my ($path) = @_;
    $path =~ /\.pm$/ or return;
    my ($namespace, $version) = $path->slurp_raw =~
      m/ \s (?:class|package) \s+ ([A-Za-z0-9_:]+) \s+ ([v0-9.]+) \b /x
      or die "No namespace found in $path";
    $provides{$namespace} = {
      file => "$path",
      version => $version,
    };
  },
  { recurse => 1 },
);

WriteMakefile(
  ABSTRACT => 'SCS archive controller',
  AUTHOR => 'nautofon <nautofon@cpan.org>',
  EXE_FILES => [
    'script/scs_archive',
  ],
  LICENSE => 'perl_5',
  META_MERGE => {
    'dynamic_config' => 0,
    'meta-spec' => {
      version => 2,
    },
    'provides' => \%provides,
    'release_status' => 'stable',
    'resources' => {
      bugtracker => {
        web => 'https://forum.scssoft.com/viewtopic.php?t=330746',
      },
      homepage => 'https://forum.scssoft.com/viewtopic.php?t=330746',
      repository => {
        type => 'git',
        url => 'git://github.com/nautofon/Archive-SCS.git',
        web => 'https://github.com/nautofon/Archive-SCS',
      },
    },
  },
  MIN_PERL_VERSION => '5.038',
  NAME => 'Archive::SCS',
  NO_MYMETA => 1,
  VERSION => '0.02',
  test => {
    RECURSIVE_TEST_FILES => 1,
  },
);
