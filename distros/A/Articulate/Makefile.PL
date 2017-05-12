use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
  NAME         => 'Articulate',
  AUTHOR       => q{Daniel Perrett <perrettdl@googlemail.com>},
  VERSION_FROM => 'lib/Articulate.pm',
  ABSTRACT     => 'Lightweight Perl CMS Framework',
  (
    $eumm_version >= 6.3001
    ? ( 'LICENSE' => 'perl' )
    : ()
  ),
  META_MERGE => {
    resources => {
      repository => 'http://github.com/pdl/Articulate',
      bugtracker => 'http://github.com/pdl/Articulate/issues',
      homepage   => 'http://github.com/pdl/Articulate',
    },
  },
  MIN_PERL_VERSION => 5.010_001,
  PL_FILES         => {},
  PREREQ_PM        => {
    'Class::Inspector'  => 0,       # Used by Articulate::Role::Service
    'DateTime'          => 1.18,
    'Data::DPath'       => 0.50,
    'DBIx::Class'       => 0.082,   # Until we separate out Storage::Local
    'DBD::SQLite'       => 1.46,    # Until we separate out Storage::Local
    'Digest::SHA'       => 0,
    'Exporter::Declare' => 0.113,
    'File::Path'        => 0,       # implied by IO::All but just in case
    'Hash::Merge'       => 0.2,
    'IO::All'           => 0,
    'JSON'              => 0,
    'Module::Load'      => 0,
    'Moo'               => 1.004000,
    'MooX::Singleton'   => 0,       # for now at least
    'SQL::Translator'   => 0.11018,
    'Test::More' =>
      0.98, # needs a reasonably modern version for things like subtest
    'Text::Markdown' => 0,       # chances are you'll need it
    'Throwable'      => 0.200012,
    'Try::Tiny'      => 0,
    'YAML'           => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Articulate-*' },
);
