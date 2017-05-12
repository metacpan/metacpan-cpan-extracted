package Catalyst::Controller::RequestToken;
use Moose;
BEGIN { extends 'Catalyst::Controller' }

use Digest;
use Catalyst::Exception;
use namespace::autoclean;

our $VERSION = '0.07';

has [qw/ session_name request_name /] => (
    is => 'ro',
    default => '_token'
);

sub BUILD {
    my $self = shift;

    Catalyst::Exception->throw("Catalyst::Plugin::Session is required")
        unless $self->_application->isa('Catalyst::Plugin::Session');
}

sub token {
    my ( $self, $ctx, $arg ) = @_;

    confess("ARGH") unless $ctx && blessed($ctx);
    if ( defined $arg ) {
        $ctx->session->{ $self->_ident() } = $arg;
        return $arg;
    }

    return $ctx->session->{ $self->_ident() };
}

sub create_token {
    my ( $self, $c, $arg ) = @_;

    $c->log->debug("create token") if $c->debug;
    my $digest = _find_digest();
    my $seed = join( time, rand(10000), $$, {} );
    $digest->add($seed);
    my $token = $digest->hexdigest;
    $c->log->debug("token is created: $token") if $c->debug;

    return $self->token($c, $token);
}

sub remove_token {
    my ( $self, $c, $arg ) = @_;

    $c->log->debug("remove token") if $c->debug;
    undef $c->session->{ $self->_ident() };
    $self->token($c, undef);
}

sub validate_token {
    my ( $self, $c, $arg ) = @_;

    $c->log->debug('validate token') if $c->debug;
    my $session = $self->token($c);
    my $request = $c->req->param( $self->{request_name} );

    $c->log->debug( "session:" . ( $session ? $session : '' ) ) if $c->debug;
    $c->log->debug( "request:" . ( $request ? $request : '' ) ) if $c->debug;

    if ( ( $session && $request ) && $session eq $request ) {
        $c->log->debug('token is valid') if $c->debug;
        $c->stash->{ $self->_ident() } = 1;
    }
    else {
        $c->log->debug('token is invalid') if $c->debug;
        if ( $c->isa('Catalyst::Plugin::FormValidator::Simple') ) {
            $c->set_invalid_form( $self->{request_name} => 'TOKEN' );
        }
        undef $c->stash->{ $self->_ident() };
    }
}

sub is_valid_token {
    my ( $self, $ctx, $arg ) = @_;

    confess("ARGH") unless blessed($ctx);
    return $ctx->stash->{ $self->_ident() };
}

sub _ident {    # secret stash key for this template'
    return '__' . ref( $_[0] ) . '_token';
}

# following code is from Catalyst::Plugin::Session
my $usable;

sub _find_digest () {
    unless ($usable) {
        foreach my $alg (qw/SHA-256 SHA-1 MD5/) {
            if ( eval { Digest->new($alg) } ) {
                $usable = $alg;
                last;
            }
        }
        Catalyst::Exception->throw(
                  "Could not find a suitable Digest module. Please install "
                . "Digest::SHA1, Digest::SHA, or Digest::MD5" )
            unless $usable;
    }

    return Digest->new($usable);
}

sub _parse_CreateToken_attr {
    my ( $self, $app_class, $action_name, $vaue, $attrs ) = @_;

    return ( ActionClass =>
            'Catalyst::Controller::RequestToken::Action::CreateToken' );
}

sub _parse_ValidateToken_attr {
    my ( $self, $app_class, $action_name, $vaue, $attrs ) = @_;

    return ( ActionClass =>
            'Catalyst::Controller::RequestToken::Action::ValidateToken' );
}

sub _parse_RemoveToken_attr {
    my ( $self, $app_class, $action_name, $vaue, $attrs ) = @_;

    return ( ActionClass =>
            'Catalyst::Controller::RequestToken::Action::RemoveToken' );
}

sub _parse_ValidateRemoveToken_attr {
    my ( $self, $app_class, $action_name, $vaue, $attrs ) = @_;

    return ( ActionClass =>
            'Catalyst::Controller::RequestToken::Action::ValidateRemoveToken'
    );
}

1;

__END__

=head1 NAME

Catalyst::Controller::RequestToken - Handling transaction tokens across forms

=head1 SYNOPSIS

requires Catalyst::Plugin::Session module, in your application class:

    use Catalyst qw/
        Session
        Session::State::Cookie
        Session::Store::FastMmap
        FillInForm
     /;

in your controller class:

    use base qw(Catalyst::Controller::RequestToken);

    sub form :Local {
        my ($self, $c) = @_;
        $c->stash( template => 'form.tt' );
    }

    sub confirm :Local :CreateToken {
        my ($self, $c) = @_;
        $c->stash( template => 'confirm.tt' );
    }

    sub complete :Local :ValidateToken {
        my ($self, $c) = @_;

        if ($self->valid_token($c)) {
            $c->response->body('complete.');
        }
        eles {
            $c->response->body('invalid operation.');
        }
    }

form.tt

    <html>
    <body>
    <form action="confirm" method="post">
    <input type="submit" name="submit" value="confirm"/>
    </form>
    </body>
    </html>

confirm.tt

    <html>
    <body>
    <form action="complete" method="post">
    <input type="hidden" name="_token" values="[% c.req.param('_token') %]"/>
    <input type="submit" name="submit" value="complete"/>
    </form>
    </body>
    </html>

=head1 DESCRIPTION

This controller enables to enforce a single transaction across multiple forms.
Using a token, you can prevent duplicate submits and protect your app from CSRF atacks.

This module REQUIRES Catalyst::Plugin::Session to store server side token.

=head1 ATTRIBUTES

=over 4

=item CreateToken

Creates a new token and puts it into request and session. 
You can return content with request token which should be posted 
to server.

=item ValidateToken

After CreateToken, clients will post token request, so you need to
validate whether it is correct or not.

The ValidateToken attribute wil make your action validate the request token 
by comparing it to the session token which is created by the CreateToken attribute.

If the token is valid, the server-side token will be expired. Use is_valid_token()
to check wheter the token in this request was valid or not.

=item RemoveToken

Removes the token from the session. The request token will no longer be valid.

=back

=head1 METHODS

All methods must be passed the request context as their first parameter.

=over 4

=item token

=item create_token

=item remove_token

=item validate_token

Return whether token is valid or not.  This will work correctly only after 
ValidateToken.

=item is_valid_token

=back

=head1 CONFIGRATION

in your application class:

    __PACKAGE__->config('Controller::TokenBasedMyController' => {
        session_name => '_token',
        request_name => '_token',
    });

=over 4

=item session_name

Default: _token

=item request_name

Default: _token

=item validate_stash_name

Default: _token

=back


=head1 SEE ALSO

=over

=item L<Catalyst::Controller::RequestToken::Action::CreateToken>

=item L<Catalyst::Controller::RequestToken::Action::ValidateToken>

=item L<Catalyst>

=item L<Catalyst::Controller>

=item L<Catalyst::Plugin::Session>

=item L<Catalyst::Plugin::FormValidator::Simple>

=back

=head1 AUTHOR

Hideo Kimura C<< <<hide<at>hide-k.net>> >>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

