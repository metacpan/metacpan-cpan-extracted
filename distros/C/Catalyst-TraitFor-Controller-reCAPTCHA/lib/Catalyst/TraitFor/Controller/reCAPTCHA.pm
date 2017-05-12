package Catalyst::TraitFor::Controller::reCAPTCHA;
{
  $Catalyst::TraitFor::Controller::reCAPTCHA::VERSION = '1.122510';
}
# ABSTRACT: authenticate people and read books!

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

use Captcha::reCAPTCHA;
use Carp 'croak';

has recaptcha => ( is => 'ro', default => sub { Captcha::reCAPTCHA->new } );

sub captcha_get :Private {
    my ( $self, $c ) = @_;

    my $recaptcha = $self->recaptcha->get_html(
        $c->config->{recaptcha}{pub_key},
        $c->stash->{recaptcha_error},
        $c->req->secure,
        $c->config->{recaptcha}{options}
    );

    $c->stash( recaptcha => $recaptcha );
}

sub captcha_check :Private {
    my ( $self, $c ) = @_;

    my $challenge = $c->req->param('recaptcha_challenge_field');
    my $response  = $c->req->param('recaptcha_response_field');

    unless ( $response && $challenge ) {
        $c->stash->{recaptcha_error} = 'User appears not to have submitted a recaptcha';
        return;
    }

    my $res = $self->recaptcha->check_answer(
        $c->config->{recaptcha}{priv_key},
        $c->req->address,
        $challenge,
        $response
    );
    
    croak 'Failed to get valid result from reCaptcha'
        unless ref $res eq 'HASH';

    unless ( $res->{is_valid} ) {
        $c->stash( recaptcha_error => $res->{error} || 'Invalid recaptcha' );
    }

    $c->stash( recaptcha_ok => $res->{is_valid} );
    return $res->{is_valid};
}

1;


__END__
=pod

=head1 NAME

Catalyst::TraitFor::Controller::reCAPTCHA - authenticate people and read books!

=head1 VERSION

version 1.122510

=head1 SYNOPSIS

In your controller

    package MyApp::Controller::Comment;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller' }
    with 'Catalyst::TraitFor::Controller::reCAPTCHA';

    sub example : Local {
        my ( $self, $c ) = @;

        # validate received form
        if ( $c->forward('captcha_check') ) {
            $c->detach('my_form_is_ok');
        }

        # Set reCAPTCHA html code
        $c->forward('captcha_get');
    }

    1;

=head1 SUMMARY

Catalyst::Controller role around L<Captcha::reCAPTCHA>.  Provides
a number of C<Private> methods that deal with the recaptcha.

This module is based/copied from L<Catalyst::Controller::reCAPTCHA>,
it just adds support for option passing and automatically sets ssl
when used on a secure request.

If you are using L<Catalyst::Controller::reCAPTCHA> and want to move
to this role, you only need to stop extending L<Catalyst::Controller>
and apply this role as shown in the SYNOPSIS.

=head2 CONFIGURATION

In MyApp.pm (or equivalent in config file):

 __PACKAGE__->config->{recaptcha} = {
    pub_key  => '6LcsbAAAAAAAAPDSlBaVGXjMo1kJHwUiHzO2TDze',
    priv_key => '6LcsbAAAAAAAANQQGqwsnkrTd7QTGRBKQQZwBH-L',
    options  => { theme => 'white' }
 };

(the two keys above work for http://localhost unless someone hammers the
reCAPTCHA server with failures, in which case the API keys get a temporary
ban).

=head2 METHODS

=head3 captcha_get : Private

Sets $c->stash->{recaptcha} to be the html form for the L<http://recaptcha.net/> reCAPTCHA service which can be included in your HTML form.

=head3 captcha_check : Private

Validates the reCaptcha using L<Captcha::reCAPTCHA>.  sets
$c->stash->{recaptcha_ok} which will be 1 on success. The action also returns
true if there is success. This means you can do:

 if ( $c->forward(captcha_check) ) {
   # do something based on the reCAPTCHA passing
 }

or alternatively:

 $c->forward(captcha_check);
 if ( $c->stash->{recaptcha_ok} ) {
   # do something based on the reCAPTCHA passing
 }

If there's an error, $c->stash->{recaptcha_error} is
set with the error string provided by L<Captcha::reCAPTCHA>.

=head1 SEE ALSO

=over 4

=item *

L<Captcha::reCAPTCHA> 

=item *

L<Catalyst::Controller> 

=item *

L<Catalyst>

=back

=head1 ACKNOWLEDGEMENTS

This module is almost copied from Kieren Diment L<Catalyst::Controller::reCAPTCHA>.

=head1 AUTHOR

Diego Kuperman <diego@freekeylabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Diego Kuperman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

