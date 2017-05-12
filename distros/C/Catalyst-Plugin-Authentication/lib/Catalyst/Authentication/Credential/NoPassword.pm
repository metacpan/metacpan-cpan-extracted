package Catalyst::Authentication::Credential::NoPassword;

use Moose;
use utf8;

has 'realm'  => (is => 'ro', required => 1);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 3 ) {
        my ($config, $app, $realm) = @_;
        return $class->$orig( realm => $realm );
    }
    else {
        return $class->$orig(@_);
    }
};

sub authenticate {
    my ($self, $c, $realm, $authinfo) = @_;
    $self->realm->find_user($authinfo, $c);
}

1;

__END__

=head1 NAME

Catalyst::Authentication::Credential::NoPassword - Authenticate a user
without a password.

=head1 SYNOPSIS

    use Catalyst qw/
      Authentication
      /;

    package MyApp::Controller::Auth;

    sub login_as_another_user : Local {
        my ($self, $c) = @_;

        if ($c->user_exists() and $c->user->username() eq 'root') {
            $c->authenticate( {id => c->req->params->{user_id}}, 'nopassword' );
        }
    }

=head1 DESCRIPTION

This authentication credential checker takes authentication information 
(most often a username) and retrieves the user from the store. No validation
of any credentials is done. This is intended for administrative backdoors,
SAML logins and so on when you have identified the new user by other means.

=head1 CONFIGURATION

    # example
    <Plugin::Authentication>
        <nopassword>
            <credential>
                class = NoPassword
            </credential>
            <store>
                class = DBIx::Class
                user_model = DB::User
                role_relation = roles
                role_field = name
            </store>
        </nopassword>
    </Plugin::Authentication>

=head1 METHODS

=head2 authenticate ( $c, $realm, $authinfo )

Try to log a user in.

=cut
