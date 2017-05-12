package CatalystX::Crudite::Form::User;
use HTML::FormHandler::Moose;
extends 'CatalystX::Crudite::Form::Base';
has '+item_class' => (default => 'User');
has_field 'name' => (
    type     => 'Text',
    required => 1,
    unique   => 1,
    size     => 10,
);
has_field uuid => (
    type     => 'Text',
    label    => 'UUID',
    disabled => 1,
    html_attr => { style => 'width: 350px' },
);
has_field 'password' => (
    type     => 'Password',
    required => 1,
    size     => 10,
    inactive => 1,
);
has_field 'password_repeat' => (
    type     => 'PasswordConf',
    required => 1,
    size     => 10,
    noupdate => 1,
    inactive => 1,
);
has_field 'edit_with_password' => (
    type     => 'Display',
    inactive => 1,
);
has_field 'roles' => (
    type         => 'Multiple',
    widget       => 'checkbox_group',
    label_column => 'display_name',

    # We still - and especially - want to validate if the user has
    # removed ALL roles.
    validate_when_empty => 1,
);
sub field_list { [ $_[0]->submit_button ] }
before 'set_active' => sub {
    my $self = shift;
    $self->inactive([qw(uuid)]) if $self->is_create_mode;
};

sub html_edit_with_password {
    my ($self, $field) = @_;
    my $user_id = $self->item->id;

    # FIXME create URI with c->uri_for ...
    return
qq{<label class="label">Password: </label></td><td><a class="button" href="/users/$user_id/edit_with_password">edit</a></td>};
}

sub validate_roles {
    my ($self, $field) = @_;

    # If we're creating a user, it's no problem.
    return unless $self->item->id;

    # Otherwise we need to make sure that after saving the user we
    # would still have at least one user with the 'can_manage_users'
    # role.
    my $role =
      $self->schema->resultset('Role')->search({ name => 'can_manage_users' })
      ->first;
    my @user_managers =
      $self->schema->resultset('User')
      ->search({ 'user_roles.role_id' => $role->id }, { join => 'user_roles' })
      ->all;

    # If we have more than one user with the 'can_manage_users' role,
    # then no matter what this form stores, it's no problem.
    return if @user_managers > 1;

    # If we have only one user manager but it's not the one we're
    # editing, it's also no problem.
    return if $user_managers[0]->id != $self->item->id;

    # If we're editing the only user manager but he still has the
    # can_manage_users role, it's also no problem.
    return if grep { $_ == $role->id } @{ $field->value };
    $field->add_error('At least one user must be able to manage users');
}
1;
