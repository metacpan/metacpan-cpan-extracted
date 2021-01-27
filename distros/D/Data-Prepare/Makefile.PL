use strict;
use warnings;
use ExtUtils::MakeMaker;

my $repo = 'mohawk2/data-prepare';
(my $file = (my $pkg = 'Data::Prepare')) =~ s#::#/#g;
$file = "lib/$file.pm";
WriteMakefile(
  NAME         => $pkg,
  VERSION_FROM => $file,
  ABSTRACT_FROM => $file,
  AUTHOR           => q{Ed J <etj@cpan.org>},
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.008003', # first with right Exporter
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.10',
  },
  TEST_REQUIRES => {
    'Test::Snapshot' => '0.06',
  },
  PREREQ_PM => {
    'Exporter' => '5.57', # importable 'import'
    'Text::CSV' => '2.00',
    'YAML' => '1.30',
  },
  EXE_FILES => [ glob 'scripts/*' ],
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => "git\@github.com:$repo.git",
        web => "https://github.com/$repo",
      },
      bugtracker  => {
        web => "https://github.com/$repo/issues",
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod::Coverage' => '1.08',
          'Pod::Coverage' => '0.18',
          'Test::Pod' => '1.00',
          'Pod::Markdown' => 0,
        },
      },
      runtime => {
        suggests => {
          'Text::CSV_XS' => 0,
        },
      },
      test => {
        recommends => {
          'App::Prove' => '3.00', # prove -j4
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
