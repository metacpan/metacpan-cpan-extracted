use strict;
use warnings;
use ExtUtils::MakeMaker;

my $repo = 'oodler577/p5-Alien-OpenMP';
(my $file = (my $pkg = 'Alien::OpenMP')) =~ s#::#/#g;
$file = "lib/$file.pm";
WriteMakefile(
  NAME         => $pkg,
  VERSION_FROM => $file,
  ABSTRACT_FROM => $file,
  AUTHOR           => q{OODLER 577 <oodler@cpan.org>},
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.010001',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.10',
  },
  TEST_REQUIRES => {
  },
  PREREQ_PM => {
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#pdl',
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
