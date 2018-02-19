use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'API::MikroTik',
    VERSION_FROM => 'lib/API/MikroTik.pm',
    ABSTRACT     => 'Non-blocking MikroTik API interface',
    AUTHOR       => 'Andre Parker <andreparker@gmail.com>',
    LICENSE      => 'artistic_2',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {directory => ['t']},
        prereqs        => {runtime => {requires => {perl => '5.010001'}}},
        resources      => {
            bugtracker =>
                {web => 'https://github.com/anparker/api-mikrotik/issues'},
            license =>
                ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository => {
                type => 'git',
                url  => 'https://github.com/anparker/api-mikrotik.git',
                web  => 'https://github.com/anparker/api-mikrotik',
            },
        },
    },
    PREREQ_PM => {'Mojolicious' => '7.00'},
    test      => {TESTS         => 't/*.t'},
);

