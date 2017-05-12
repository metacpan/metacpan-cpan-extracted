package <% dist_module %>::Controller::<% resource_name %>;
use Moose;
use namespace::autoclean;
BEGIN { extends 'CatalystX::Crudite::Controller::Resource' }
__PACKAGE__->config_resource_controller(
    actions => {
        (   map {
                $_ => {
                    Does         => 'ACL',
                    RequiresRole => 'can_foo',
                    ACLDetachTo  => '/denied',
                  }
            } qw(list create edit)
        ),
        delete => {
            Does         => [qw(ACL RejectIfUsed)],
            RequiresRole => 'can_foo',
            ACLDetachTo  => '/denied',
            UsedReason => 'Cannot delete "%s" because it is used.',
        },
    },
);
1;
