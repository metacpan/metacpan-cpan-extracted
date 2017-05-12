use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::TracksBot',
    AUTHOR              => q{Rob Hoelz <rob@hoelz.ro>},
    VERSION_FROM        => 'lib/App/TracksBot.pm',
    ABSTRACT_FROM       => 'lib/App/TracksBot.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    EXE_FILES           => [ 'tracks-bot' ],
    PL_FILES            => {},
    PREREQ_PM => {
        'AnyEvent::WebService::Tracks' => '0.02',
        'AnyEvent::XMPP'               => 0,
        'List::MoreUtils'              => 0,
        'Test::More'                   => 0,
        'YAML'                         => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-TracksBot-*' },
);
