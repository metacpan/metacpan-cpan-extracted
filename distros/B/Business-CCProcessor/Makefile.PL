use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::CCProcessor',
    AUTHOR              => 'Hugh Esco <hesco@campaignfoundations.com>',
    VERSION_FROM        => 'lib/Business/CCProcessor.pm',
    ABSTRACT_FROM       => 'lib/Business/CCProcessor.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
  'CGI::FormBuilder' => 0,
           'version' => 0,
              'Carp' => 0,
    'WWW::Mechanize' => 0,
  'Test::HTML::Tidy' => 0,
  'Test::HTML::Lint' => 0,
'Test::Perl::Critic' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-CCProcessor-*' },
);
