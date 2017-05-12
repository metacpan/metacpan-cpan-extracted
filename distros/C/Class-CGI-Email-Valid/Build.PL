use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Class::CGI::Email::Valid',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Class/CGI/Email/Valid.pm',
    requires          => {
        'Test::More'   => 0,
        'Email::Valid' => 0.15,
        'Class::CGI'   => 0.20,
    },
    add_to_cleanup     => ['Class-CGI-Email-Valid-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
