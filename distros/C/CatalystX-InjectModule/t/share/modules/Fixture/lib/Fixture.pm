package Fixture;

use Moose;
with 'CatalystX::InjectModule::Fixture';

sub install {
    my ($self, $module, $mi) = @_;

    $self->install_fixtures($module, $mi);
}

sub uninstall {
    my ($self, $module, $mi) = @_;

     my $schema = $mi->ctx->model->schema;

    # Delete admin and anonymous users
    $schema->resultset('User')->search( { username => 'admin'     })->delete_all;
    $schema->resultset('User')->search( { username => 'anonymous' })->delete_all;

    # Delete admin and anonymous roles
    $schema->resultset('Role')->search( { name => 'admin'     })->delete_all;
    $schema->resultset('Role')->search( { name => 'anonymous' })->delete_all;
}



1;
