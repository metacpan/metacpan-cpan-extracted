package Catalyst::Plugin::Authentication::Simple;

use strict;
use NEXT;

our $VERSION = '1.00';

=head1 NAME

Catalyst::Plugin::Authentication::Simple

    $c->login( $user, $password );
    $c->logout;
    $c->session_login( $user, $password );
    $c->session_logout;

=head1 DESCRIPTION

Note that this plugin requires a session plugin like
C<Catalyst::Plugin::Session::FastMmap>.

=head2 METHODS

=over 4

=item login

Attempt to authenticate a user. Takes username/password as arguments,

    $c->login( $user, $password );

User remains authenticated until end of request.

    Format of user_file:
    <username1>:<password1>:<role1>,<role2>,<role3>,...
    <username2>:<password2>:<role1>,<role2>,<role3>,...

    OR array ref of those values in 'users' key

Note: users_file will NOT get reloaded if you change it
BUT you CAN change the 'users' arrayref w/o a restart...

=cut

sub login {
    my ( $c, $user, $password ) = @_;
    return 1 if $c->request->{user};
    my $password_hash = $c->config->{authentication}->{password_hash} || '';
    if ( $password_hash =~ /sha/i ) {
        require Digest::SHA;
        $password = Digest::SHA::sha1_hex($password);
    }
    elsif ( $password_hash =~ /md5/i ) {
        require Digest::MD5;
        $password = Digest::MD5::md5_hex($password);
    }

    unless ($c->config->{authentication}->{users}) {
        my $user_file = $c->config->{authentication}->{user_file};
        die "Must provide user_file!!" unless $user_file;
        open(USERS, $user_file) || die "Can't open user_file $user_file: $!";
        my @users = <USERS>;
        close(USERS);
        $c->config->{authentication}->{users} = [ @users ];
    }

    foreach my $u_line (@{$c->config->{authentication}->{users}}) {
        chomp $u_line;
        my($f_user, $f_pass, $roles) = split /:/, $u_line;
        if ($f_user eq $user && $f_pass eq $password) {
            $c->request->{user} = $user;
            $c->request->{user_roles} = { map { $_ => 1 } split /,/, $roles };
            return 1;
        }
    }

    return 0;
}

=item logout

Log out the user. will not clear the session, so user will still remain
logged in at next request unless session_logout is called.

=cut

sub logout {
    my $c = shift;
    $c->request->{user} = undef;
}

=item process_permission

check for permissions. used by the 'roles' function.

=cut

sub process_permission {
    my ( $c, $roles ) = @_;
    if ($roles) {
        return 1 if $#$roles < 0;
        my $string = join ' ', @$roles;
        if ( $c->process_roles($roles) ) {
            $c->log->debug(qq/Permission granted "$string"/) if $c->debug;
        }
        else {
            $c->log->debug(qq/Permission denied "$string"/) if $c->debug;
            return 0;
        }
    }
    return 1;
}

=item roles

Check permissions for roles and return true or false.

    $c->roles(qw/foo bar/);

Returns an arrayref containing the verified roles.

    my @roles = @{ $c->roles };

=cut

sub roles {
    my $c = shift;
    $c->{roles} ||= [];
    my $roles = ref $_[0] eq 'ARRAY' ? $_[0] : [@_];
    if ( $_[0] ) {
        my @roles;
        foreach my $role (@$roles) {
            push @roles, $role unless grep $_ eq $role, @{ $c->{roles} };
        }
        return 1 unless @roles;
        if ( $c->process_permission( \@roles ) ) {
            $c->{roles} = [ @{ $c->{roles} }, @roles ];
            return 1;
        }
        else { return 0 }
    }
    return $c->{roles};
}

=item session_login

Persistently login the user. The user will remain logged in
until he clears the session himself, or session_logout is
called.

    $c->session_login( $user, $password );

=cut

sub session_login {
    my ( $c, $user, $password ) = @_;
    return 0 unless $c->login( $user, $password );
    $c->session->{user} = $c->req->{user};
    return 1;
}

=item session_logout

Session logout. will delete the user object from the session.

=cut

sub session_logout {
    my $c = shift;
    $c->logout;
    $c->session->{user} = undef;
}

=back

=head2 EXTENDED METHODS

=over 4

=item prepare_action

sets $c->request->{user} from session.

=cut

sub prepare_action {
    my $c = shift;
    $c->NEXT::prepare_action(@_);
    $c->request->{user} = $c->session->{user};
}

=item setup

sets up $c->config->{authentication}.

=cut

sub setup {
    my $c    = shift;
    my $conf = $c->config->{authentication};
    $conf = ref $conf eq 'ARRAY' ? {@$conf} : $conf;
    $c->config->{authentication} = $conf;
    return $c->NEXT::setup(@_);
}

=back

=head2 OVERLOADED METHODS

=over 4

=item process_roles 

Takes an arrayref of roles and checks if user has the supplied roles. 
Returns 1/0.

=cut

sub process_roles {
    my ( $c, $roles ) = @_;

    for my $role (@$roles) {
        return 0 unless $c->{user_roles}->{$role};
    }
    return 1;
}

=back

=head1 SEE ALSO

L<Catalyst>.
L<Catalyst::Plugin::Authentication::CDBI>.
L<Catalyst::Plugin::Authentication::LDAP>.

=head1 AUTHOR

Mark Ethan Trostler, C<mark@zoo.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

