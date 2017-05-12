#
# $Id: /local/DateTime-Indic/trunk/Build.PL 342 2008-05-24T18:02:40.063670Z jaldhar  $
#
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_name           => 'DateTime-Indic',
    license             => 'perl',
    dist_author         => 'Jaldhar H. Vyas <jaldhar@braincells.com>',
    dist_abstract       => 'Manipulate dates in various traditional Indian calendar systems.',
    dist_version        => '0.2',
    build_requires => {
        'DateTime'                      => 0,
        'DateTime::Event::Sunrise'      => 0,
        'DateTime::Util::Calc'          => 0.13,
        'Params::Validate'              => 0,
        'Test::More'                    => 0,
    },
    add_to_cleanup      => [ 'DateTime-Indic-*' ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/jaldhar/panchanga/tree/master/perl'
        }
    },
    create_makefile_pl => 'traditional',
    sign                => 1,
);

$builder->create_build_script();
