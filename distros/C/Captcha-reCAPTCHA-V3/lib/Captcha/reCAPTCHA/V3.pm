package Captcha::reCAPTCHA::V3;
use 5.008001;
use strict;
use warnings;
use Carp;

use HTTP::Tiny;
use JSON qw(decode_json);

our $VERSION = "0.01";

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %attr = @_;

    # Initialize the user agent object
    $self->{'ua'} = HTTP::Tiny->new(
        agent => __PACKAGE__ . '/' . $VERSION . ' (Perl)'
    );
    $self->{'sitekey'} = $attr{'sitekey'} || croak "missing param 'sitekey'";
    $self->{'secret'} = $attr{'secret'} || croak "missing param 'secret'";
    $self->{'widget_api'} = 'https://www.google.com/recaptcha/api.js?render='. $attr{'sitekey'};
    $self->{'verify_api'} = 'https://www.google.com/recaptcha/api/siteverify';

    return $self;
}

sub verify {
    my $self = shift;
    my $response = shift;
    croak "Extra arguments have been set." if @_;
 
    my $params = {
        secret    => $self->{'secret'},
        response  => $response || croak "missing response token",
    };
 
    my $res = $self->{'ua'}->post_form( $self->{'verify_api'}, $params );

    if($res->{'success'}) {
        return decode_json($res->{'content'});
    }else{
        croak "something wrong to post by HTTP::Tiny";
    }
}

sub script4head {
    my $self = shift;
    my %attr = @_;
    my $action = $attr{'action'} || 'homepage';
    my $id =  $self->get_element_id();
    return <<"EOL";
    <script src="//code.jquery.com/jquery-latest.js"></script>
    <script src="$self->{'widget_api'}"></script>
    <script>
    grecaptcha.ready(function() {
        grecaptcha.execute('$self->{'sitekey'}', {action: '$action'}).then(function(token) {
            \$("#$id").val(token);
//            console.log(token);
        });
    });
    </script>
EOL
}

sub input4form {
    my $self = shift;
    my %attr = @_;
    my $name = $attr{'name'} || 'reCAPTCHA_Token';
    my $id =  $self->get_element_id();
    return qq|<input type="hidden" name="$name" id="$id" />|;
}

sub get_element_id {
    my $self = shift;
    return 'recaptcha_' . substr( $self->{'sitekey'}, 0, 10 );
}

1;
__END__
 
=encoding utf-8

=head1 NAME

Captcha::reCAPTCHA::V3 - A Perl implementation of reCAPTCHA API version v3

=head1 SYNOPSIS

Captcha::reCAPTCHA::V3 provides you to integrate Google reCAPTCHA v3 for your web applications.

 use Captcha::reCAPTCHA::V3;
 my $rc = Captcha::reCAPTCHA::V3->new(
     secret  => '__YOUR_SECRET__',
     sitekey => '__YOUR_SITEKEY__',
 );

 ...
 
 my $content = $rc->verify($param{'reCAPTCHA_Token'});
 if( $content->{'success'} ){
    # code for succeeding
 }else{
    # code for failing
 }

=head1 DESCRIPTION

Captcha::reCAPTCHA::V3 is inspired from L<Captcha::reCAPTCHA::V2|https://metacpan.org/pod/Captcha::reCAPTCHA::V2>

This one is especially for Google reCAPTCHA v3, not for v2 because APIs are so defferent.

=head2 Basic Usage

=head3 new()

Requires secret and sitekey when constructing.
You have to get them before running from L<here|https://www.google.com/recaptcha/intro/v3.html>

=head3 verify()

Requires just only response key being got from Google reCAPTCHA API.
B<DO NOT> add remote address. there is no function for remote address in reCAPTCHA v3

=head2 Additional method for lazy persons(not supported)

=head3 script4head()

You can insert this in your E<lt>headE<gt> tag

=head3 input4form

You can insert this in your E<lt>formE<gt> tag

=head1 SEE ALSO

=over

=item L<Captcha::reCAPTCHA::V2|https://metacpan.org/pod/Captcha::reCAPTCHA::V2>

=item L<Google reCAPTCHA v3|https://www.google.com/recaptcha/intro/v3.html>

=item L<Google reCAPTCHA v3 API document|https://developers.google.com/recaptcha/docs/v3>

=back

=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

worthmine E<lt>worthmine@gmail.comE<gt>

=cut

