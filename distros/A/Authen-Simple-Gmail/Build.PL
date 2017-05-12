use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Authen::Simple::Gmail',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Authen/Simple/Gmail.pm',
    requires          => {
        'Test::More'  => 0,
        'Net::Detect' => 0,
        'File::Slurp' => 0,

        'IO::Socket::SSL'         => 0,
        'Authen::Simple::Adapter' => 0,
        'File::Slurp'             => 0,
    },
    add_to_cleanup => ['Authen-Simple-Gmail-*'],
);

$builder->create_build_script();
