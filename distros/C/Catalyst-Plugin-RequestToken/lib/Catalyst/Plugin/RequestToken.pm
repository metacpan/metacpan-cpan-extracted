package Catalyst::Plugin::RequestToken;

use strict;
use warnings;

use NEXT;
use Catalyst::Exception ();
use Digest();
use overload();

our $VERSION = '0.06';

sub setup {
    my $c = shift;

    $c->config->{token}->{session_name} ||= 'token';
    $c->config->{token}->{request_name} ||= 'token';
	
    return $c->NEXT::setup(@_);
}

sub finalize {
    my $c = shift;

    if ( $c->{_prepare_token} ) {
        $c->{_prepare_token} = undef;
        my $name  = $c->config->{token}->{request_name};
        my $token = $c->create_token;
        my $body  = $c->response->{body};
        $body =~ s/(<form\s*.*?>)/$1\n<input type="hidden" name="$name" value="$token">/isg;
        $c->response->output($body);
    }

    return $c->NEXT::finalize(@_);
}

sub prepare_token {
    my $c = shift;

    $c->{_prepare_token} = 1;
}

my $counter;

sub create_token {
    my $c = shift;

    my $digest = $c->_find_digest();
    my $seed = join("", ++$counter, time, rand, $$, {}, overload::StrVal($c));
    $digest->add( $seed );
    my $token = $digest->hexdigest;
    $c->log->debug("start create token : $token") if $c->debug;
    $c->session->{$c->config->{token}->{session_name}} = $token;
    $c->req->params->{ $c->config->{token}->{request_name} } = $token;
    return $token;
}

sub remove_token {
    my $c = shift;

    undef $c->session->{$c->config->{token}->{session_name}};
}

sub validate_token {
    my $c = shift;

    my $session = $c->session->{$c->config->{token}->{session_name}};
    my $request = $c->req->param($c->config->{token}->{request_name});

    my $res;
    if ($session && $request) {
        $res = $session eq $request;
    }
    if ($c->isa('Catalyst::Plugin::FormValidator::Simple') && !defined($res)) {
        $c->set_invalid_form($c->config->{token}->{request_name} => 'TOKEN');
    }
    return $res; 
}

# following code is from Catalyst::Plugin::Session
my $usable;

sub _find_digest () {
    unless ($usable) {
        foreach my $alg (qw/SHA-1 SHA-256 MD5/) {
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

1;
__END__

=head1 NAME

Catalyst::Plugin::RequestToken - (DEPRECATED) Handling transaction token for Catalyst

=head1 DEPRECATION NOTICE

B<This module has been deprecated> in favor of L<Catalyst::Controller::RequestToken>.
Please do not use it in new code. It has known compatibility issues and is absolutely
not supported by anyone. It remains only in case you have existing code that
relies on it.

=head1 SYNOPSIS

in your application class:

    use Catalyst qw/
        Session
        Session::State::Cookie
        Session::Store::FastMmap
        RequestToken 
        FillInForm
    /;

in your contoller class:
    
    sub input : Local {
        my ( $self, $c ) = @_;

        $c->stash->{template} = 'input.tt';
        $c->forward($c->view('TT'));
    }

    sub confirm : Local {
        my ( $self, $c ) = @_;

        $c->create_token;
        $c->stash->{template} = 'confirm.tt';
        $c->forward($c->view('TT'));
        $c->fillform;
    }

    sub complete : Local {
        my ( $self, $c ) = @_;

        if ($c->validate_token) {
            $c->res->output('Complete');
        } else {
            $c->res->output('Invalid Token');
        }
        $c->remove_token;
    }

F<root/input.tt> TT template:

    <html>
    <body>
    <form action="confirm" method="post">
    <input type="submit" name="submit" value="confirm"/>
    </form>
    </body>
    </html>

F<root/confirm.tt> TT template:

    <html>
    <body>
    <form action="complete" method="post">
    <input type="hidden" name="token"/>
    <input type="submit" name="submit" value="complete"/>
    </form>
    </body>
    </html>

or you can call prepare_token instead of a bunch of methods.
And you don't have to write '<input type="hidden" name="token"... >' for token in your template.

    sub input : Local {
        my ( $self, $c ) = @_;

        $c->stash->{template} = 'input.tt';
        $c->prepare_token;
    }

if you loaded L<Catalyst::Plugin::FormValidator::Simple> and fail to validate token, C::P::FormValidator::Simple->set_invalid_form will call automatically in validate_token method (constraint name is 'TOKEN').

    sub complete : Local {
        my ( $self, $c ) = @_;

        $c->form(
            name => [qw/NOT_BLANK ASCII/]
            ...
        );

        $c->validate_token;
        
        my $result = $c->form;
        
        if ( $result->has_error) {
            $c->res->body('Error');
        } else {
            $c->res->body('Success');
        }
    }


=head1 DESCRIPTION

This plugin create, remove and validate transaction token, to be used for enforcing a single request for some transaction, for exapmle, you can prevent duplicate submits.

Note:
REQUIRES a session plugin like L<Catalyst::Plugin::Session> to store server side token.


=head1 METHODS

=over 4

=item prepare_token

automatically append token hidden tag to response body.

=item create_token

Create new token, it uses SHA-1, MD5 or SHA-256, depending on the availibility of these modules.

=item remove_token

Remove token from server side session.

=item validate_token

Validate token.

=back


=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Catalyst::Plugin::FormValidator::Simple>


=head1 AUTHOR

Hideo Kimura C<< <<hide@hide-k.net>> >>


=head1 LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.



=cut
