package TestApp::Model::UserAuth;
our $VERSION = '0.01';

use base qw/Catalyst::Model/;
use strict;

sub auth {
    my ( $self, $c, $user_info ) = @_;

    my $where;
    if ( exists $user_info->{id} ) {
        $where = { id => $user_info->{id} };
    }
    elsif ( exists $user_info->{username} ) {
        $where = { username => $user_info->{username} };
    }
    else { return; }

    my $user = $c->model('TestApp')->resultset('User')->search($where)->first;

    if ( exists $user_info->{status} and ref $user_info->{status} eq 'ARRAY' ) {
        unless ( grep { $_ eq $user->status } @{ $user_info->{status} } ) {
            return;
        }
    }

=pod
    
    # get user roles
    my $role_rs = $c->model('TestApp')->resultset('UserRole')->search( {
        user => $user->id
    } );
    while (my $r = $role_rs->next) {
        my $role = $c->model('TestApp')->resultset('Role')->find( {
            id => $r->roleid
        } );
#        push @{$user->{roles}}, $role->role;
    }

=cut

    return $user;
}

1;
