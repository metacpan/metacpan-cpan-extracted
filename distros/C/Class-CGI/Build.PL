use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Class::CGI',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Class/CGI.pm',
    requires          => {
        'Test::More'                => 0,
        'Test::Exception'           => 0.21,
        'CGI::Simple'               => 0.077,
        'Config::Std'               => '0.0.3',
        'File::Spec::Functions'     => 1.3,
        'HTML::Entities'            => 1.32,
    },
    add_to_cleanup     => ['Class-CGI-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
