use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Catmandu::Twitter',
    license     => 'perl',
    dist_author => [ 'Patrick Hochstenbach <patrick.hochstenbach@ugent.be>' ],
    dist_version_from => 'lib/Catmandu/Importer/Twitter.pm',
    build_requires    => {
        'Software::License' => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0,
    },
    requires => {
        'perl'              => '5.10.0',
        'Catmandu'          => '0.09',
        'Catmandu::Atom'    => '0.02',       # for twitter2atom.pl
        'Config::Any::JSON' => 0,       # for twitter2atom.pl
        'Moo'               => '0.009011',
        'Net::Twitter'      => '4.00003',
        'Date::Parse'       => '2.30',
        'URI::Escape'       => '3.31',
    },
    add_to_cleanup => [
        qw(
          Catmandu-Twitter-*
          )
    ],
    create_makefile_pl => 'traditional',
    create_license     => 1,
);

$builder->create_build_script;
