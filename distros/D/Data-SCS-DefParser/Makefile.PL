use v5.32;
use ExtUtils::MakeMaker::CPANfile;

# The Perl toolchain doesn't know about feature class yet, so we
# must specify all namespaces in META using the provides key.
my %provides = (
  'Data::SCS::DefParser' => {
    file => 'lib/Data/SCS/DefParser.pm',
    version => '0.11',
  },
);

WriteMakefile(
  ABSTRACT => 'Parse SCS def SII files',
  AUTHOR => 'nautofon <nautofon@cpan.org>',
  LICENSE => 'perl_5',
  META_MERGE => {
    'dynamic_config' => 0,
    'meta-spec' => {
      version => 2,
    },
    'provides' => \%provides,
    'release_status' => 'stable',
    'resources' => {
      repository => {
        type => 'git',
        url => 'https://github.com/nautofon/Data-SCS-DefParser.git',
        web => 'https://github.com/nautofon/Data-SCS-DefParser',
      },
    },
  },
  NAME => 'Data::SCS::DefParser',
  NO_MYMETA => 1,
  VERSION => $provides{'Data::SCS::DefParser'}{version},
  dist => {
    TAR => 'ptar',
  },
  realclean => {
    FILES => 'MANIFEST MANIFEST.bak',
  },
);
