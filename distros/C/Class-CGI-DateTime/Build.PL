use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Class::CGI::DateTime',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Class/CGI/DateTime.pm',
    requires          => {
        'Test::More'   => 0,
        'Class::CGI'   => 0.20,
        'DateTime'     => 0.30,
        'Scalar::Util' => '',     # Does the version matter for this?
    },
    add_to_cleanup     => ['Class-CGI-DateTime-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
