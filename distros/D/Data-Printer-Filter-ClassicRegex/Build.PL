use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Printer::Filter::ClassicRegex',
    license             => 'perl',
    dist_author         => 'Breno G. de Oliveira <garu@cpan.org>',
    dist_version_from   => 'lib/Data/Printer/Filter/ClassicRegex.pm',
    requires => {
        'Test::More' => '0.88',
    },
    add_to_cleanup      => [ 'Data-Printer-Filter-ClassicRegex-*' ],
);

$builder->create_build_script();
