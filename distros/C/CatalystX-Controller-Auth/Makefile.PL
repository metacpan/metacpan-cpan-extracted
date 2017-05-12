use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CatalystX::Controller::Auth',
    AUTHOR              => q{Rob Brown <rob@intelcompute.com>},
    VERSION_FROM        => 'lib/CatalystX/Controller/Auth.pm',
    ABSTRACT_FROM       => 'lib/CatalystX/Controller/Auth.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose' => 0,
        'Catalyst::Controller' => 0,
        'HTML::FormHandlerX::Form::Login' => 0,
        'Catalyst::Plugin::StatusMessage' => 0,
        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CatalystX-Controller-Auth-*' },
);
