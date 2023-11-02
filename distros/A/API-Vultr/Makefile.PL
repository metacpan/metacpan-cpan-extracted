use strict;
use warnings;

use utf8;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'API::Vultr',
    VERSION_FROM => 'lib/API/Vultr.pm',
    ABSTRACT     => qq{A simple interface to the Vultr v2 API},
    license      => 'artistic_2',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => { version   => 2 },
        no_index       => { directory => [ 'examples', 't' ] },
        prereqs        => { runtime   => { requires => { perl => 'v5.8.1' } } },
        resources      => {
            bugtracker =>
              { web => 'https://github.com/rawleyfowler/API-Vultr/issues' },
            license =>
              [qq{http://www.opensource.org/licenses/artistic-license-2.0}],
            repository => {
                type => 'git',
                url  => 'https://github.com/rawleyfowler/API-Vultr'
            }
        },
    },
    PREREQ_PM => {
        'LWP::UserAgent'       => '6.72',
        'URI'                  => '5.21',
        'Test::Simple'         => '1.302195',
        'Test::LWP::UserAgent' => '0.036'
    },
    test => { TESTS => 't/*.t t/*/*.t it/*.t it/*/*.t' }
);
