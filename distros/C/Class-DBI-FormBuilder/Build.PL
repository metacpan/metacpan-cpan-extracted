use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Class::DBI::FormBuilder',
    license             => 'perl',
    dist_author         => 'David Baird <cpan@riverside-cms.co.uk>',
    dist_version_from   => 'lib/Class/DBI/FormBuilder.pm',
    requires => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'CGI::FormBuilder' => 3,
        'Class::Data::Inheritable' => 0,
        'Class::DBI' => 0,
        'List::Util' => 0,
        'UNIVERSAL::require' => 0,
        'Class::DBI::AbstractSearch' => 0,
    },
    add_to_cleanup      => [ 'Class-DBI-FormBuilder-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
