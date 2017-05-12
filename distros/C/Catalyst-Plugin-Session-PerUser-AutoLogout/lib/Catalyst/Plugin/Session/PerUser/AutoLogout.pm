package Catalyst::Plugin::Session::PerUser::AutoLogout;
use Moose;
extends 'Catalyst::Plugin::Session::PerUser';

after set_authenticated => sub {
    my $c = shift;
    if (my $existing_session = $c->user_session->{session_id}) {
        $c->delete_session($existing_session);
    }
    $c->user_session->{session_id} = $c->sessionid;
};

1;

=head1 NAME

Catalyst::Plugin::Session::PerUser::AutoLogout - Log a user out of other sessions

=head1 DESCRIPTION

For some reason, you might want to ensure each user is only logged in once. This
plugin extends L<Catalyst::Plugin::Session::PerUser> and automatically removes a
user's previous session whenever they log in again, thus forcing that other
session to end and logging them out.

I<You> would probably not want to do this, but you might be being paid by
someone who does want that.
