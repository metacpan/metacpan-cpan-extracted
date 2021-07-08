use 5.008004;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
  NAME             => 'App::jupiter',
  VERSION_FROM     => 'lib/App/jupiter.pm',
  ABSTRACT_FROM    => 'lib/App/jupiter.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/jupiter',
  ],
  PREREQ_PM => {
    'strict' => 0,
    'warnings' => 0,
    'Modern::Perl' => 1.20180701, # for '2018'
    'Mojolicious' => 0, # for Mojo::Template and Mojo::UserAgent
    'Mojo::UserAgent::Role::Queued' => 0,
    'XML::LibXML' => 0,
    'File::Slurper' => 0,
    'File::ShareDir' => 0,
    'Mojo::JSON' => 0,
    'Encode::Locale' => 0,
    'DateTime' => 0,
    'DateTime::Format::Mail' => 0,
    'DateTime::Format::ISO8601' => 0,
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.52',
    'File::ShareDir::Install' => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://alexschroeder.ch/cgit/planet-jupiter',
	web  => 'https://alexschroeder.ch/cgit/planet-jupiter/about/',
      },
    },
  },
  clean => {
    FILES => "test-[0-9][0-9][0-9][0-9]",
  },
);

package MY;
use File::ShareDir::Install;

sub postamble {
  my $self = shift;
  my @ret = File::ShareDir::Install::postamble($self);
  push @ret, <<'EOT';
README.md: script/jupiter
	pod2markdown $< $@
	grep -L ERROR $@
EOT
  return join "\n", @ret;
}
