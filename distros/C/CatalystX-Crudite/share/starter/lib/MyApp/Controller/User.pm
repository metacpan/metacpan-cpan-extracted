package <% dist_module %>::Controller::User;
use Moose;
use namespace::autoclean;
BEGIN { extends 'CatalystX::Crudite::Controller::User' }
__PACKAGE__->config_user_controller(
    actions => {
        delete => {
            Does       => [qw(RejectIfUsed Code)],
            UsedReason => 'Cannot delete "%s" because it has orders.',
            Code       => [ \&maybe_prevent_delete ],
        },
    },
);

sub maybe_prevent_delete {
    my $orig   = shift;
    my $action = shift;
    my ($controller, $c) = @_;
    if ($c->stash->{ $controller->resource_key }->name eq $c->user->name) {
        $c->flash(
            error_msg => 'Cannot delete the user that is currently logged in.');
        $controller->_redirect($c);
    } else {
        $action->$orig(@_);
    }
}
1;
