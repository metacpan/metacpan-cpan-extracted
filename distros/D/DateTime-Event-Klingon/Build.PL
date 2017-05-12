#
# $Id: /svn/DateTime-Event-Klingon/tags/VERSION_1_0_1/Build.PL 330 2008-04-03T21:27:52.043282Z jaldhar  $
#
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DateTime::Event::Klingon',
    license             => 'perl',
    dist_author         => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
    #dist_version_from   => 'lib/DateTime/Event/Klingon.pm',
    dist_version        => '1.0.1',
    build_requires => {
        'DateTime'              => 0,
        'Module::Signature'     => 0,
        'Pod::Coverage'         => 0.18,
        'Pod::Usage'            => 0,
        'Test::More'            => 0,
        'Test::Pod'             => 1.22,
        'Test::Pod::Coverage'   => 1.08,
    },
    requires => {
        'Carp'                  => 0,
        'Filter::Util::Call'    => 0,
        'UNIVERSAL'             => 0,
    },
    add_to_cleanup     => [ 'DateTime-Event-Klingon-*' ],
    create_makefile_pl => 'traditional',
    sign               => 1,
);

$builder->create_build_script();
