use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'CGI::FormBuilder::Template::HTC',
    requires => {
        'CGI::FormBuilder'         => 0,
        'HTML::Template::Compiled' => '0.82',
        },
    recommends => {
    },
    create_readme      => 0,
    sign               => 0,
    dist_abstract      => 'FormBuilder interface to HTML::Template::Compiled',
);
$build->create_build_script;
