package Module::Build::Custom;

use 5.006;
use strict;
use warnings;
use Module::Build;

require DBIx::Class::Optional::Dependencies;

my %requires = (
    'perl'                                   => 5.006,
    'Carp'                                   => 0,
    'Cwd'                                    => 0,
    'DBD::SQLite'                            => 0,
    'DBD::CSV'                               => 0,
    'DBI::Const::GetInfoType'                => 0,
    'DBI'                                    => 0,
    'DBIx::Class::Helper::ResultSet::Random' => 2.016004,
    'DBIx::Class::Optional::Dependencies'    => 0,
    'DBIx::Class::Relationship'              => 0,
    'DBIx::Class::Schema::Loader'            => 0,
    'DBIx::RunSQL'                           => 0,
    'SQL::Abstract'                          => 0,
    'File::Basename'                         => 0,
    'File::Spec'                             => 0,
    'List::Util'                             => 0,
    'Moo'                                    => 0,
    'Readonly'                               => 0,
    'Test::Exception'                        => 0,
    'aliased'                                => 0,
    'Data::GUID'                             => 0,
);

sub add_requires {
    my ($req_hash_ref) = @_;
    for ( keys %$req_hash_ref ) {
        $requires{$_} = $req_hash_ref->{$_};
    }
}

foreach ( ('deploy') ) {
    add_requires( DBIx::Class::Optional::Dependencies->req_list_for($_) );
}

my $custom_build = Module::Build->subclass(
    class => "Module::Build::Custom",
    code  => <<'SUBCLASS' );

sub ACTION_authortest {
    my ($self) = @_;

    $self->depends_on('build');
    $self->depends_on('manifest');
    $self->depends_on('distmeta');

    $self->test_files( qw( t xt ) );
    $self->recursive_test_files(1);

    $self->depends_on('test');

    return;
}
SUBCLASS

my $builder = $custom_build->new(
    module_name       => 'DBIx::Table::TestDataGenerator',
    license           => 'perl',
    dist_author       => q{Jose Diaz Seng <josediazseng@gmx.de>},
    dist_version_from => 'lib/DBIx/Table/TestDataGenerator.pm',
    build_requires    => {
        'Test::More'           => 0,
        'Pod::Coverage'        => 0,
        'Pod::Coverage::Moose' => 0,
        'Test::CheckManifest'  => 0,
        'Test::Pod'            => 0,
        'Test::Pod::Coverage'  => 0,
    },
    requires           => \%requires,
    add_to_cleanup     => ['DBIx-Table-TestDataGenerator-*'],
    create_makefile_pl => 'traditional',
    configure_requires => {
        'Module::Build' => 0.40,
        'DBIx::Class'   => '0.08203',
    },
);

$builder->create_build_script();
