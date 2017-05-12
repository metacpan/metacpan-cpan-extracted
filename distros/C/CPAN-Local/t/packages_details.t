use strict;
use warnings;
use CPAN::Index::API;
use CPAN::Local::Plugin::PackagesDetails;
use Module::Faker::Dist;
use File::Temp qw(tempdir);
use Path::Class qw(file);
use URI::file;
use File::Copy;
use Dist::Metadata;
use Moose::Meta::Class;
use Test::Most;

### SETUP ###

my @distro_specs = (
    {
        name        => 'File-Which',
        version     => '1.09',
        cpan_author => 'ADAMK',
    },
    {
        name        => 'Any-Moose',
        version     => '0.08',
        cpan_author => 'SARTAK',
    },
    {
        name        => 'Any-Moose',
        version     => '0.09',
        cpan_author => 'SARTAK',
    },
    {
        name        => 'common-sense',
        version     => '3.2',
        cpan_author => 'MLEHMANN',
        provides    => [],
    },
);

my $distro_dir = tempdir;

foreach my $spec ( @distro_specs ) {
    my $distro = Module::Faker::Dist->new($spec);
    my $source = $distro->make_archive;
    my $target = file($distro_dir, file($source)->basename)->stringify;
    File::Copy::copy($source, $target) or die $!;
}

### LOAD ###

my @distribution_roles =
    map { "CPAN::Local::Distribution::Role::$_" }
    CPAN::Local::Plugin::PackagesDetails->requires_distribution_roles;

my $distribution_class = Moose::Meta::Class->create_anon_class(
    superclasses => ['CPAN::Local::Distribution'],
    roles        => \@distribution_roles,
    cache        => 1,
)->name;

my $repo_root = tempdir;
my $repo_uri  = 'http://www.example.com/';

my %args = (
    uri  => $repo_uri,
    root => $repo_root,
    distribution_class => $distribution_class,
);

my $plugin = CPAN::Local::Plugin::PackagesDetails->new(%args);

isa_ok( $plugin, 'CPAN::Local::Plugin::PackagesDetails' );

### INITIALISE ###

$plugin->initialise;

my $index = CPAN::Index::API::File::PackagesDetails->read_from_repo_path($repo_root);

isa_ok( $index, 'CPAN::Index::API::File::PackagesDetails' );

is ( $index->package_count, 0, '02packages.details.txt.gz lines' );

my $packages_details_uri = URI::file->new(
    file($repo_root, 'modules', '02packages.details.txt.gz')->stringify
)->as_string;

is ( $index->uri, $packages_details_uri, '02packages.details uri');

### INDEX ###

my %distros = (
    file_which => $distribution_class->new(
        authorid => 'ADAMK',
        filename => file($distro_dir, 'File-Which-1.09.tar.gz')->stringify,
    ),
    any_moose => $distribution_class->new(
        authorid => 'SARTAK',
        filename => file($distro_dir, 'Any-Moose-0.08.tar.gz')->stringify,
    ),
);

$plugin->index( values %distros );

$index = CPAN::Index::API::File::PackagesDetails->read_from_repo_path($repo_root);

is_deeply (
    [ map $_->{name}, $index->packages ],
    [ 'Any::Moose', 'File::Which' ],
    'injected package names',
);

is (
    $index->package('Any::Moose')->{version}, '0.08',
    'injected package version',
);

is (
    $index->package('Any::Moose')->{distribution},
    'S/SA/SARTAK/Any-Moose-0.08.tar.gz',
    'injected package distribution path',
);


$plugin->index( $distribution_class->new(
    authorid => 'SARTAK',
    filename => file($distro_dir, 'Any-Moose-0.09.tar.gz')->stringify,
) );

$index = CPAN::Index::API::File::PackagesDetails->read_from_repo_path($repo_root);

is (
    $index->package('Any::Moose')->{version}, '0.09',
    'updated package version',
);

$plugin->index( $distribution_class->new(
    authorid => 'MLEHMANN',
    filename => file($distro_dir, 'common-sense-3.2.tar.gz')->stringify,
) );

$index = CPAN::Index::API::File::PackagesDetails->read_from_repo_path($repo_root);

ok ( ! $index->package('common::sense'), 'without auto_provides' );

my $new_plugin = CPAN::Local::Plugin::PackagesDetails->new(
    auto_provides => 1,
    %args,
);

$new_plugin->index( $distribution_class->new(
    authorid => 'MLEHMANN',
    filename => file($distro_dir, 'common-sense-3.2.tar.gz')->stringify,
) );

$index = CPAN::Index::API::File::PackagesDetails->read_from_repo_path($repo_root);

ok ( $index->package('common::sense'), 'with auto_provides' );

done_testing;
