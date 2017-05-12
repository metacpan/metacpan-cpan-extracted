package MyApp::Controller::API::User;

use Moose;

BEGIN { extends 'CatalystX::Eta::Controller::REST' }

__PACKAGE__->config(
    default => 'application/json',

    result      => 'DB::User',
    result_cond => { active => 1 },

    object_key => 'user',
    list_key   => 'users',

    update_roles => [qw/user/],
    create_roles => [qw/superadmin/],
    delete_roles => [qw/user/],

    build_row => sub {
        my ( $r, $self, $c ) = @_;

        return {
            (
                map { $_ => $r->$_ }
                  qw(
                  id name email type
                  )
            ),

        };
    },

    before_delete => sub {
        my ( $self, $c, $item ) = @_;

        $item->update({ active => 0 });

        return 0;
    },

    search_ok => {

    }
);
with 'CatalystX::Eta::Controller::SimpleCRUD';

sub base : Chained('/api/base') : PathPart('users') : CaptureArgs(0) { }

after 'base' => sub {
    my ( $self, $c ) = @_;

    $c->stash->{collection} = $c->stash->{collection}->search(
        {
            'me.id' => $c->user->id
        }
    ) if $c->check_any_user_role('user');

};

sub object : Chained('base') : PathPart('') : CaptureArgs(1) { }

sub result : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') { }

sub result_GET { }

sub result_PUT { }

sub result_DELETE { }

sub list : Chained('base') : PathPart('') : Args(0) : ActionClass('REST') { }

sub list_GET { }

sub list_POST { }

1;
