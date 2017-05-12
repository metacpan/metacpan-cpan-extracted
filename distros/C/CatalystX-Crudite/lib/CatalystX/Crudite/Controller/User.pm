package CatalystX::Crudite::Controller::User;
use Moose;
use namespace::autoclean;
use CatalystX::Crudite::Util qw(merge_configs);
BEGIN { extends 'CatalystX::Crudite::Controller::Resource' }
sub _trait_namespace { 'CatalystX::Resource::TraitFor::Controller::Resource' }

sub config_user_controller {
    my ($class, %args) = @_;
    my %config = (
        form_class             => 'CatalystX::Crudite::Form::User',
        activate_fields_create => [qw(password password_repeat)],
        activate_fields_edit   => [qw(edit_with_password)],
        actions                => {
            map {
                $_ => {

                    # Use an array ref for 'Does' so the merge will work when
                    # the user adds ActionRoles using his own array ref.
                    Does         => [qw(ACL)],
                    RequiresRole => 'can_manage_users',
                    ACLDetachTo  => '/denied',
                  }
            } qw(list create edit delete show),
        }
    );
    my $merged_config = merge_configs(\%config, \%args);
    $class->config_resource_controller(%$merged_config);
}

sub edit_with_password : Method('GET') Method('POST') Chained('base_with_id')
  PathPart('edit_with_password') Args(0) {
    my ($self, $c) = @_;
    $c->stash(activate_form_fields => [qw(password password_repeat)]);
    $c->forward($self->action_for('edit'));
}
1;
