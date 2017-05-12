use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Algorithm::VectorClocks',
    license             => 'perl',
    dist_author         => 'Takeru INOUE <takeru.inoue _ gmail.com>',
    dist_version_from   => 'lib/Algorithm/VectorClocks.pm',
    requires => {
        'version'    => 0,
	'Class::Accessor::Fast' => 0,
	'Class::Data::Inheritable' => 0,
	'JSON::Any' => 0,
	'List::MoreUtils' => 0,
	'List::Util' => 0,
	'Perl6::Export::Attrs' => 0,
	'Sys::Hostname' => 0,
    },
    build_requires => {
        'Test::More' => 0,
        'Test::NoWarnings' => 0,
#        'Test::Perl::Critic' => 0,
#        'Test::Pod'            => 1.14,
#        'Test::Pod::Coverage'  => 1.04,
    },
    add_to_cleanup      => [ 'Algorithm-VectorClocks-*' ],
);

$builder->create_build_script();
