use v5.32;
use Config;
use ExtUtils::CppGuess;
use ExtUtils::MakeMaker::CPANfile;
use Path::Tiny 0.062;

$Config{use64bitint} or die "Can't build on 32-bit perl, aborting.";

# The Perl toolchain doesn't know about feature class yet, so we
# must specify all namespaces in META using the provides key.
# This is a great opportunity to check versions as well.
my %provides;
my $main_module = 'Archive::SCS';
my $main_module_version;
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
    $namespace eq $main_module and $main_module_version = $version;
  },
  { recurse => 1 },
);

my @versions = reverse sort map { version->parse($_->{version}) } values %provides;
$versions[0] eq version->parse($main_module_version)
  or die "$main_module version is $main_module_version; should be $versions[0]";

path('Changes')->slurp_raw =~ m/^\Q$main_module_version\E\s/m
  or die "$main_module version ($main_module_version) is not in Changes";

WriteMakefile(
  ExtUtils::CppGuess->new->makemaker_options,
  ABSTRACT => 'SCS archive controller',
  AUTHOR => 'nautofon <nautofon@cpan.org>',
  EXE_FILES => [
    'script/scs_archive',
  ],
  INC => '-Iinc',
  LICENSE => 'perl_5',
  MAGICXS => 1,
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
  NAME => $main_module,
  NO_MYMETA => 1,
  VERSION => $main_module_version,
  XSMULTI => 1,
  XSOPT => '-C++',
  dist => {
    TARFLAGS => '--format=ustar -c -v -f', # avoid PaxHeader in tarball
  },
  test => {
    RECURSIVE_TEST_FILES => 1,
  },
);
