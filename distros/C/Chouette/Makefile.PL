use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Chouette',
    VERSION_FROM => 'lib/Chouette.pm',
    PREREQ_PM => {
      'common::sense' => 0,
      'EV' => 0,
      'AnyEvent' => 0,
      'JSON::XS' => 0,
      'Regexp::Assemble' => 0,
      'Feersum' => 0,
      'Plack' => 0,
      'Plack::Request::WithEncoding' => 0,
      'YAML' => 0,

      ## hoytech stuff
      'AnyEvent::Task' => '0.804',
      'Callback::Frame' => 0,
      'Session::Token' => 0,
      'Log::Defer' => 0,
      'Log::File::Rolling' => 0,
      'Log::Defer::Viz' => 0,
    },
    TEST_REQUIRES => {
      'AnyEvent::HTTP' => 0,
      'File::Temp' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/Chouette.git',
        bugtracker => 'https://github.com/hoytech/Chouette/issues',
      },
    },
);

WriteMakefile(%args);
