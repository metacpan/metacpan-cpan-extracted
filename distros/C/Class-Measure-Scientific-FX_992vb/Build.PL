use strict;
use warnings;
use Module::Build;
Module::Build->new(
    module_name => 'Class::Measure::Scientific::FX_992vb',
    license     => 'perl',
    dist_author => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    requires    => {
        'perl'             => '5.16.0',
        'Class::Measure'   => 0.08,
        'Log::Log4perl'    => 0,
        'Moose'            => 0,
        'MooseX::NonMoose' => 0,
        'Readonly'         => 1.03,
        'List::MoreUtils'  => 0,
    },
    build_requires => {},
    test_requires  => {
        'Test::More'       => 0.86,
        'Test::NoWarnings' => 0,
        'Test::Warn'       => 0,
    },
    meta_merge => {
        resources => {
            repository =>
'https://bitbucket.org/rolandvanipenburg/class-measure-scientific-fx_992vb',
        },
    },
    sign => 1,
)->create_build_script;
