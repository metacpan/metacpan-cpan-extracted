use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::FormBuilder::Config::Simple',
    AUTHOR              => q{Hugh Esco <hesco@campaignfoundations.com>},
    VERSION_FROM        => 'lib/CGI/FormBuilder/Config/Simple.pm',
    ABSTRACT_FROM       => 'lib/CGI/FormBuilder/Config/Simple.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
                        'Cwd' => 0,
                        'DBI' => 0,
                       'Carp' => 0,
                 'Test::More' => 0,
               'Data::Dumper' => 0,
             'Config::Simple' => 0,
             'WWW::Mechanize' => 0,
           'CGI::FormBuilder' => 0,
          'Test::DatabaseRow' => 0,
        'ExtUtils::MakeMaker' => 0,
  'Test::WWW::Mechanize::CGI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-FormBuilder-Config-Simple-*' },
);

