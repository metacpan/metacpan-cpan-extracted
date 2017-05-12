package Catalyst::Controller::reCAPTCHA;
use strict;
use warnings;
use base 'Catalyst::Controller';
use Captcha::reCAPTCHA;
use Carp 'croak';
our $VERSION = '0.8';


sub captcha_get : Private {
    my ($self, $c) = @_;
    my $cap = Captcha::reCAPTCHA->new;
    $c->stash->{recaptcha} =
        $cap->get_html($c->config->{recaptcha}->{pub_key});
    return;
}

sub captcha_check : Private {
    my ($self, $c) = @_;
    my $cap = Captcha::reCAPTCHA->new;
    my $challenge = $c->req->param('recaptcha_challenge_field');
    my $response  = $c->req->param('recaptcha_response_field');

    unless ( $response && $challenge ) {
        $c->stash->{recaptcha_error} =
            'User appears not to have submitted a recaptcha';
        return;
    }

    my $key = $c->config->{recaptcha}->{priv_key} ||
        croak 'must set recaptcha priv_key in config';

    my $result = $cap->check_answer(
        $key,
        $c->req->address,
        $challenge,
        $response,
    );

    croak 'Failed to get valid result from reCaptcha'
        unless ref $result eq 'HASH' && exists $result->{is_valid};


    $c->stash->{recaptcha_error} = $result->{error} ||
        'Unknown error'
            unless $result->{is_valid};

    $c->stash->{recaptcha_ok} = 1 if $result->{is_valid};
    return 1;
}




=head1 NAME

Catalyst::Controller::reCAPTCHA - authenticate people and read books!

WARNING:  Deprecated.  Please use L<Catalyst::TraitFor::Controller::reCAPTCHA> instead.

=head1 SUMMARY

This module has been deprecated and has been replaced with
L<Catalyst::TraitFor::Controller::reCAPTCHA>.  Please do not use this for new
projects.  Version 0.8 is very likely the last to be released for this module.

Catalyst::Controller wrapper around L<Capatcha::reCAPTCHA>.  Provides
a number of C<Private> methods that deal with the recaptcha.

=head2 CONFIGURATION

In MyApp.pm (or equivalent in config file):

 __PACKAGE__->config->{recaptcha}->{pub_key} =
                          '6LcsbAAAAAAAAPDSlBaVGXjMo1kJHwUiHzO2TDze';
 __PACKAGE__->config->{recaptcha}->{priv_key} =
                          '6LcsbAAAAAAAANQQGqwsnkrTd7QTGRBKQQZwBH-L';

(the two keys above work for http://localhost unless someone hammers the
reCAPTCHA server with failures, in which case the API keys get a temporary
ban).

=head2 METHOD

captcha_get : Private

Sets $c->stash->{recaptcha} to be the html form for the L<http://recaptcha.net/> reCAPTCHA service which can be included in your HTML form.

=head2 METHOD

captcha_check : Private

Validates the reCaptcha using L<Captcha::reCAPTCHA>.  sets
$c->stash->{recaptcha_ok} which will be 1 on success. The action also returns
true if there is success. This means you can do:

 if ( $c->forward(captcha_check) ) {
   # do something based on the reCAPTCHA passing
 }

or alternatively:

 if ( $c->stash->{recaptcha_ok} ) {
   # do something based on the reCAPTCHA passing
 }


If there's an error, $c->stash->{recaptcha_error} is
set with the error string provided by L<Captcha::reCAPTCHA>.

=head2 EXAMPLES

See the t/lib/TestApp example in the
L<Catalyst::Controller::reCAPTCHA> distribution.

=head2 BUGS

This module is deprecated.  Please report any bugs you find against
L<Catalyst::TraitFor::Controller::reCAPTCHA>.

=head1 SEE ALSO

L<Captcha::reCAPTCHA>, L<Catalyst::Controller>, L<Catalyst>.

=head1 AUTHOR and Copyright

Kieren Diment L<zarquon@cpan.org>.

=head1 LICENCE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
