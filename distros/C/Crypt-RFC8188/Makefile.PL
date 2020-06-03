use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Crypt::RFC8188',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/Crypt/RFC8188.pm',
  ABSTRACT_FROM    => 'lib/Crypt/RFC8188.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.010000', # pack "*>"
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.10',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.98',
  },
  PREREQ_PM => {
    'CryptX' => '0.068',
    'Exporter' => '5.57',
    'MIME::Base64' => '3.11',
    'Math::BigInt' => '1.999804', # from_bytes
  },
  clean => { FILES => 'Crypt-RFC8188-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/Crypt-RFC8188.git',
        web => 'https://github.com/mohawk2/Crypt-RFC8188',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/Crypt-RFC8188/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
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
