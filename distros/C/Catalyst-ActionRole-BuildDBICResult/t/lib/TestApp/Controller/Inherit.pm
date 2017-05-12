package # hide from PAUSE
  TestApp::Controller::Inherit;

use Moose;
use namespace::autoclean;

BEGIN {
    extends 'Catalyst::Controller';
}

__PACKAGE__->config(
    action_args => {
        'store_as_str' => {
            store => 'User',
        },
        'find_cond_as_str' => {
            find_condition => 'unique_email',
        },
        'find_cond_as_cond' => {
            find_condition => {
                constraint_name => 'social_security',
            },
        },
        'find_cond_as_cond2' => {
            find_condition => {
                columns => ['id'],
            },
        },
        'user_default' => {
            store => 'Schema::User',
            find_condition => [ 'primary', ['email'] ],
        },
        'user_detach_error' => {
            store => 'Schema::User',
            find_condition => [ 'primary', ['email'] ],
            auto_stash => 'user',
            handlers => {
                error => {detach => 'local_error'},
                notfound => {detach => 'local_notfound'},
            },
        },
        'user_accessor_store' => {
            store => {accessor => 'user_rs' },
            find_condition => [ 'primary', ['email'] ],
            auto_stash => 'user',
        },
        'user_code_store' => {
            store => {
                code => sub {
                    my ($controller, $action, $ctx, @args) = @_;
                    return $controller->user_rs;
                },
            },
            find_condition => [ 'primary', ['email'] ],
            auto_stash => 'user',
        },
        'user_code_store2' => {
            store => {
                code => 'get_user_code_store2',
            },
            find_condition => [ 'primary', ['email'] ],
            auto_stash => 'user',
        },
        'user_role' => {
            store => {stash => 'user_role_rs' },
            find_condition => {
                constraint_name => 'primary',
                match_order => [qw/fk_role_id fk_user_id/],
            },
            auto_stash => 1,
        },
    },
);

has user_rs => (
    is => 'ro',
    lazy_build => 1,
);

sub _build_user_rs {
    my $self = shift @_;
    return $self->_app->model('Schema::User');
}

sub defaults
  :Path('defaults') 
  :ActionClass('+TestApp::Action::BuildDBICResult') {}

sub store_as_str
  :Path('store_as_str') 
  :ActionClass('+TestApp::Action::BuildDBICResult') {}

sub find_cond_as_str
  :Path('find_cond_as_str') 
  :ActionClass('+TestApp::Action::BuildDBICResult') {}

sub find_cond_as_cond
  :Path('find_cond_as_cond') 
  :ActionClass('+TestApp::Action::BuildDBICResult') {}

sub find_cond_as_cond2
  :Path('find_cond_as_cond2') 
  :ActionClass('+TestApp::Action::BuildDBICResult') {}


sub user_default
  :ActionClass('+TestApp::Action::BuildDBICResult')
  :Path('user_default')
  :Args(1)
{
    my ($self, $ctx, $id) = @_;
    push @{$ctx->stash->{res}}, 'user_default';
}

    sub user_default_FOUND :Action {
        my ($self, $ctx, $user, $id) = @_;
        push @{$ctx->stash->{res}}, $user->email;
    }

    sub user_default_NOTFOUND :Action {
        my ($self, $ctx, $user, $id) = @_;
        push @{$ctx->stash->{res}}, 'notfound';
    }

    sub user_default_ERROR :Action {
        my ($self, $ctx, $err, $id) = @_;
        ($err) = ($err=~m/^(.+?)\!/); 
        push @{$ctx->stash->{res}}, 'error', $err;
    }

sub user_detach_error
  :ActionClass('+TestApp::Action::BuildDBICResult')
  :Path('user_detach_error')
  :Args(1)
{
    my ($self, $ctx, $id) = @_;
    push @{$ctx->stash->{res}}, 'user_detach_error';
}

    sub local_notfound :Private {
        my ($self, $ctx) = @_;
        push @{$ctx->stash->{res}}, 'local_notfound';
    }

sub user_accessor_store 
  :ActionClass('+TestApp::Action::BuildDBICResult')
  :Path('user_accessor_store')
  :Args(1)
{
    my ($self, $ctx, $id) = @_;
    push @{$ctx->stash->{res}}, 'user_accessor_store';
}

sub user_code_store 
  :ActionClass('+TestApp::Action::BuildDBICResult')
  :Path('user_code_store')
  :Args(1)
{
    my ($self, $ctx, $id) = @_;
    push @{$ctx->stash->{res}}, 'user_code_store';
}

sub user_code_store2
  :ActionClass('+TestApp::Action::BuildDBICResult')
  :Path('user_code_store2')
  :Args(1)
{
    my ($self, $ctx, $id) = @_;
    push @{$ctx->stash->{res}}, 'user_code_store2';
}


sub get_user_code_store2 {
    my ($controller, $action, $ctx, @args) = @_;
    return $controller->user_rs;
};

sub role_value_store 
  :ActionClass('+TestApp::Action::BuildDBICResult')
  :Path('role_value_store')
  :Args(1)
{
    my ($self, $ctx, $id) = @_;
    push @{$ctx->stash->{res}}, 'role_value_store';
}

sub user_role_root 
  :Chained('/')
  :PathPrefix 
  :CaptureArgs(0)
{  
    my ($self, $ctx, $uid, $rid) = @_;
    my $user_role_rs = $ctx->model('Schema::UserRole');
    $ctx->stash(user_role_rs => $user_role_rs);
}

    sub user_role
      :ActionClass('+TestApp::Action::BuildDBICResult')
      :Chained('user_role_root')
      :CaptureArgs(2)
    {
        my ($self, $ctx, $uid, $rid) = @_;
        push @{$ctx->stash->{res}}, 'user_role_root';
    }

        sub user_role_display
          :Chained('user_role')
          :Args(0)
        {
            my ($self, $ctx) = @_;
            my $role = $ctx->stash->{user_role}->role->name;
            push @{$ctx->stash->{res}}, $role;

        }

sub end :Private {
    my ($self, $ctx) = @_;
    if(my $role = $ctx->stash->{role}) {
        my $name = $role->name;
        push @{$ctx->stash->{res}}, $name
    }
    if(my $user = $ctx->stash->{user}) {
        my $email = $user->email;
        push @{$ctx->stash->{res}}, $email;
    }
    if(my $res = $ctx->stash->{res}) {
        my $body = join(',', grep { $_ } @{$res||[]});
        $ctx->res->body($body);

    }
}

sub NOTFOUND :Action {
    my ($self, $ctx) = @_;
    push @{$ctx->stash->{res}}, 'global_not_found';
}

1;
