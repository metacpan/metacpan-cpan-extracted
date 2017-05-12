use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DateTime::Format::Human::Duration',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/DateTime/Format/Human/Duration.pm',
    build_requires => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'FindBin'    => 0,
    },
    requires => { },
    add_to_cleanup      => [ 'DateTime-Format-Human-Duration-*' ],
);

$builder->create_build_script();
