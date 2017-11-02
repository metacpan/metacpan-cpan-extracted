use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Dancer2::Plugin::GraphQL',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/Dancer2/Plugin/GraphQL.pm',
  ABSTRACT_FROM    => 'lib/Dancer2/Plugin/GraphQL.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => "5.006",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => '6.63_03',
  },
  "PREREQ_PM" => {
    "Dancer2" => "0.200000",
    "Dancer2::Core::Types" => 0,
    "Dancer2::Plugin" => 0,
    "strict" => 0,
    "warnings" => 0,
    "GraphQL" => '0.20', # convert plugin
  },
  "TEST_REQUIRES" => {
    "Dancer2" => "0.200000",
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "HTTP::Request::Common" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Plack::Test" => 0,
    "Test::More" => "0.92",
    "blib" => "1.01"
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:graphql-perl/Dancer2-Plugin-GraphQL.git',
        web => 'https://github.com/graphql-perl/Dancer2-Plugin-GraphQL',
      },
      bugtracker  => {
        web => 'https://github.com/graphql-perl/Dancer2-Plugin-GraphQL/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
          'Test::Pod::Coverage' => '1.08',
          'Test::Pod' => '1.22',
          'Pod::Markdown' => 0,
        },
      },
    },
  },
);

sub MY::postamble {
  <<EOF;
pure_all :: README.md

README.md : lib/Dancer2/Plugin/GraphQL.pm
\tpod2markdown \$< >\$\@
EOF
}
