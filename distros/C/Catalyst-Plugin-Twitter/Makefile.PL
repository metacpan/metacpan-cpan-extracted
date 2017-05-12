use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Catalyst::Plugin::Twitter',
    VERSION_FROM => 'lib/Catalyst/Plugin/Twitter.pm',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Catalyst'                       => 0,
        'Net::Twitter'                   => 0,
        'Test::WWW::Mechanize::Catalyst' => 0,
        'Sub::Override'                  => 0,
        'Data::Dumper'                   => 0,
    },
);
