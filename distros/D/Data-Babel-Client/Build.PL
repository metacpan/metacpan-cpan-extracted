use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Babel::Client',
    license             => 'perl',
    dist_author         => q{Victor Cassen <phonybone@gmail.com>},
    dist_version_from   => 'lib/Data/Babel/Client.pm',
    build_requires => {
        'Test::More' => 0,
	'Class::AutoClass' => 1.54,
	'Carp' => 0,
	'Data::Dumper' => 0,
	'HTTP::Request::Common' => 0,
	'JSON' => 0,
	'LWP::UserAgent' => 0,
    },
    add_to_cleanup      => [ 'Data-Babel-Client-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
