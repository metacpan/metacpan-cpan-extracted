use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'App::cpanel',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/App/cpanel.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => "5.016",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => '6.63_03',
  },
  "PREREQ_PM" => {
    "Mojolicious" => '8.50',
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.92",
  },
  EXE_FILES => [ 'script/cpanel' ],
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/App-cpanel.git',
        web => 'https://github.com/mohawk2/App-cpanel',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/App-cpanel/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
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

README.md : \$(VERSION_FROM)
\tpod2markdown \$< >\$\@
EOF
}
