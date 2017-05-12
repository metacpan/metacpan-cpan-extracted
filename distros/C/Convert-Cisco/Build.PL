use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Convert::Cisco',
    license             => 'perl',
    dist_author         => 'Mark O\'Connor <marko@cpan.org>',
    dist_version_from   => 'lib/Convert/Cisco.pm',
    build_requires => {
		'Module::Build' => 0.2801,
		'Log::Log4perl' => 1.04,
		'YAML' => 0.62,
		'DateTime' => 0.3,
		'XML::Writer' => 0.601,
		'Test::Unit' => 0.25,
    },
    add_to_cleanup      => [ 'Convert-Cisco-*' ],
);

$builder->create_build_script();
