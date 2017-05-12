package Catalyst::ActionRole::RequireSameUser;
use Moose::Role;
use namespace::autoclean;
around 'execute' => sub {
    my $orig = shift;
    my $self = shift;
    my ($controller, $c) = @_;
    if ($c->stash->{user}->name eq $c->user->name) {
        $self->$orig(@_);
    } else {
        $c->detach($self->attributes->{UserDetachTo}
              // $self->attributes->{ACLDetachTo} // '/denied');
    }
};
1;
__END__

For controllers whose parent_resource is 'User'. Semantically this
means that this resource belongs only to that user. You might
therefore want to restrict access so only each user only has access to
his own resources.

Something like this:

    package MyApp::Controller::FooResource;
    use Moose;
    use namespace::autoclean;
    BEGIN { extends 'CatalystX::Crudite::Controller::Resource' }
    __PACKAGE__->config_resource_controller(
        parent_resource => 'User',
        actions         => {
            create => {
                Does => [qw(ACL RequireSameUser)],
                AllowedRole => [qw(can_manage_foo)],
                ACLDetachTo => '/denied',
            },
            edit => {
                Does => [qw(RequireSameUser)],
            },
            delete => {
                Does => [qw(RequireSameUser)],
            },
        },
    );

