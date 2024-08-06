use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::BookmarkFeed',
  VERSION_FROM     => 'lib/App/BookmarkFeed.pm',
  ABSTRACT_FROM    => 'lib/App/BookmarkFeed.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.36.0',
  EXE_FILES        => [
    'script/bookmark-feed',
  ],
  PREREQ_PM => {
    'Mojolicious' => 0, # for Mojo::Template
    'Mojo::SQLite' => 0,
    'File::Slurper' => 0,
    'DateTime' => 0,
    'DateTime::Format::ISO8601' => 0,
    'CommonMark' => 0,
  },
  TEST_REQUIRES => {
    'XML::RSS' => 0,
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.52',
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://src.alexschroeder.ch/bookmark-feed.git',
	web  => 'https://src.alexschroeder.ch/bookmark-feed.git',
      },
    },
  },
);

package MY;
use File::ShareDir::Install;

sub postamble {
  my $self = shift;
  my @ret = File::ShareDir::Install::postamble($self);
  push @ret, <<'EOT';
README.md: script/bookmark-feed
	pod2markdown --utf8 $< $@
EOT
  return join "\n", @ret;
}
