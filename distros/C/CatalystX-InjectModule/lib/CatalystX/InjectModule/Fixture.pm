use utf8;
package CatalystX::InjectModule::Fixture;
$CatalystX::InjectModule::Fixture::VERSION = '0.12';
use Moose::Role;
use DBIx::Class::Fixtures;



sub install_fixtures {
    my ($self, $module, $mi) = @_;


    my $fixtures_conf = $module->{dbix_fixtures};

    if ( $fixtures_conf ){
        $mi->log("  - Install fixtures");

        my $schema = $mi->ctx->model->schema;
        my $c_inf  = $schema->storage->connect_info->[0];
        die "connect_info is not defined !" if ! defined $c_inf;
        my $connection_details = [ $c_inf->{dsn}, $c_inf->{user}, $c_inf->{pass} ];

        my $fixtures = DBIx::Class::Fixtures->new({
            config_dir => $module->{path} . '/' . $fixtures_conf->{conf}->{config_dir},
            debug      => $fixtures_conf->{conf}->{debug},
        });

        # To help to build fixtures
        #     $fixtures->dump({
        #         config => 'all_tables.json', # config file to use. must be in the config
        #                                # directory specified in the constructor
        #         schema => $schema,
        #         directory => $module->{path} . '/share/fixtures/1/all_tables2/',
        #     });

        foreach my $fix_name (keys %{$fixtures_conf->{populate}}  ) {
            $mi->log("      > Fix $fix_name");

            my $fix = $fixtures_conf->{populate}->{$fix_name};
            $fix->{directory} = $module->{path} . '/' . $fix->{directory};
            $fix->{connection_details} = $connection_details;
            $fix->{schema} = $schema;
            $fixtures->populate( $fix ) || die "Error : $!";
        }

    }
}

=head1 NAME

CatalystX::InjectModule::Fixture Role to populate fixture data

=head1 VERSION

version 0.12

=head1 SYNOPSIS

package MyModule;

use Moose;
with 'CatalystX::InjectModule::Fixture';

sub install {
    my ($self, $module, $mi) = @_;

    $self->install_fixtures($module, $mi);
}

1;


=head1 SUBROUTINES/METHODS

=head2 install_fixtures ($module, $mi)

=head1 AUTHOR

Daniel Brosseau, C<< <dabd at catapulse.org> >>

=cut

1;
