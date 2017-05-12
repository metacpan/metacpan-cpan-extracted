package Catalyst::Plugin::Authentication::CDBI;

use strict;
use NEXT;

our $VERSION = '0.10';

=head1 NAME

Catalyst::Plugin::Authentication::CDBI - CDBI Authentication for Catalyst

=head1 SYNOPSIS

    use Catalyst 'Authentication::CDBI';
    __PACKAGE__->config->{authentication} = {
        user_class           => 'PetStore::Model::CDBI::Customer',
        user_field           => 'email',
        role_class           => 'PetStore::Model::CDBI::Role',
        user_role_class      => 'PetStore::Model::CDBI::CustomerRole',
        user_role_user_field => 'customer'
    };
    $c->login( $user, $password );
    $c->logout;
    $c->session_login( $user, $password );
    $c->session_logout;
    $c->roles(qw/customer admin/);

    CREATE TABLE customer (
        id INTEGER PRIMARY KEY,
        email TEXT,
        password TEXT
    );

    CREATE TABLE role (
        id INTEGER PRIMARY KEY,
        name TEXT
    );

    CREATE TABLE customer_role (
        id INTEGER PRIMARY KEY,
        customer INTEGER REFERENCES customer,
        role INTEGER REFERENCES role
    );

=head1 DESCRIPTION

This plugin allows you to authenticate your web users using database
tables accessed through C<Class::DBI> classes.

Note that this plugin requires a session plugin such as
C<Catalyst::Plugin::Session::FastMmap>.

This module is now well past the teatime of it's lifespan, and
no new features will be added. For new applications, you probably
want to look at L<Catalyst::Plugin::Authentication> and friends
instead

=head1 CONFIGURATION

This plugin is configured by passing an "authentication" hash
reference to your application's config method.  The following keys are
supported:

=over 4

=item user_class

the name of the class that represents a user object (no default)

=item user_field

the name of the column holding the user identifier (defaults to "C<user>")

=item password_field

the name of the column holding the user's password (defaults to "C<password>")

=item password_hash

specifies the hashing method for password values; one of: C<SHA> or
C<MD5> (the values are not case-sensitive and the default is empty,
i.e. no hashing).

=item role_class

the name of the role class

=item role_field

name of the role field


=item user_role_class


=item user_role_user_field

(defaults to "C<uer>")

=item user_role_role_field

(defaults to "C<role>")

=back


=head2 METHODS

=over 4

=item login

Attempt to authenticate a user. Takes username/password as arguments,

    $c->login( $user, $password );

The user remains authenticated until end of request.  See
C<session_login> for persistent login.

=cut

sub login {
    my ( $c, $user, $password ) = @_;
    return 1 if $c->request->{user};
    my $user_class     = $c->config->{authentication}->{user_class};
    my $user_field     = $c->config->{authentication}->{user_field} || 'user';
    my $password_field = $c->config->{authentication}->{password_field}
      || 'password';
    my $password_hash = $c->config->{authentication}->{password_hash} || '';
    if ( $password_hash =~ /sha/i ) {
        require Digest::SHA;
        $password = Digest::SHA::sha1_hex($password);
    }
    elsif ( $password_hash =~ /md5/i ) {
        require Digest::MD5;
        $password = Digest::MD5::md5_hex($password);
    }
    if (
        my $user_obj=$user_class->search(
            { $user_field => $user, $password_field => $password }
        )->next
      )
    {
        $c->request->{user} = $user;
        $c->request->{user_id} = $user_obj->id;
        return 1;
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
    $c->request->{user_id} = undef;
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
    $c->session->{user_id} = $c->req->{user_id};
    return 1;
}

=item session_logout

Session logout. will delete the user object from the session.

=cut

sub session_logout {
    my $c = shift;
    $c->logout;
    $c->session->{user} = undef;
    $c->session->{user_id} = undef;
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
    $c->request->{user_id} = $c->session->{user_id};
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
    my $user_class      = $c->config->{authentication}->{user_class};
    my $user_field      = $c->config->{authentication}->{user_field} || 'user';
    my $role_class      = $c->config->{authentication}->{role_class};
    my $role_field      = $c->config->{authentication}->{role_field} || 'name';
    my $user_role_class = $c->config->{authentication}->{user_role_class};
    my $user_role_user_field =
      $c->config->{authentication}->{user_role_user_field} || 'user';
    my $user_role_role_field =
      $c->config->{authentication}->{user_role_role_field} || 'role';

    if ( my $user =
        $user_class->search( { $user_field => $c->request->{user} } )->first )
    {
        for my $role (@$roles) {
            if ( my $role =
                $role_class->search( { $role_field => $role } )->first )
            {
                return 0
                  unless $user_role_class->search(
                    {
                        $user_role_user_field => $user->id,
                        $user_role_role_field => $role->id
                    }
                  );
            }
            else { return 0 }
        }
    }
    else { return 0 }
    return 1;
}

=back


=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session::FastMmap>

=head1 AUTHOR

Sebastian Riedel <sri@cpan.org>,
Marcus Ramberg <mramberg@cpan.org>,
Andrew Ford <a.ford@ford-mason.co.uk>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
