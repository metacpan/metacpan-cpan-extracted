use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Wiki::Store::Mediawiki',
    license             => 'perl',
    dist_author         => 'Derek Price <derek@ximbiot.com>',
    dist_version_from   => 'lib/CGI/Wiki/Store/Mediawiki.pm',
    requires => {
	'CGI::Wiki::Store::Database' => 0,
	'Carp' => 0,
	'Time::Piece::Adaptive' => 0,
	'Time::Seconds' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'CGI-Wiki-Store-Mediawiki-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
