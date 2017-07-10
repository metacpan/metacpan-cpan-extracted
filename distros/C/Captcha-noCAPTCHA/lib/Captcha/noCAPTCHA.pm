package Captcha::noCAPTCHA;

use warnings;
use strict;
use HTTP::Tiny;
use JSON::PP qw();

our $VERSION = '0.16'; # VERSION

sub new {
	my ($class,$args) = @_;
	my $self = bless {} ,$class;
	$self->site_key($args->{site_key}) || die "site_key required";
	$self->secret_key($args->{secret_key}) || die "secret_key required";
	$self->theme($args->{theme} || 'light');
	$self->noscript($args->{noscript} || 0);
	$self->api_url($args->{api_url} || 'https://www.google.com/recaptcha/api/siteverify');
	$self->api_timeout($args->{api_timeout} || 10);
	return $self;
}

sub site_key { return shift->_get_set('site_key',@_); }
sub secret_key { return shift->_get_set('secret_key',@_); }
sub theme { return shift->_get_set('theme',@_); }
sub noscript { return shift->_get_set('noscript',@_); }
sub api_url { return shift->_get_set('api_url',@_); }
sub api_timeout { return shift->_get_set('api_timeout',@_); }
sub errors { return shift->{_attrs}->{errors}; }
sub response { return shift->{_response}; }

sub html {
	my ($self) = @_;
	my $key = $self->site_key || die "site_key required!";
	my $theme = $self->theme;
	my $output=<<EOT;
<script src="https://www.google.com/recaptcha/api.js" async defer></script>
<div class="g-recaptcha" data-sitekey="$key" data-theme="$theme"></div>
EOT

	if ($self->noscript) {
		$output.=<<EOT;
<noscript>
  <div style="width: 302px; height: 462px;">
    <div style="width: 302px; height: 462px; position: relative;">
      <div style="width: 302px; height: 422px; position: absolute;">
        <iframe src="https://www.google.com/recaptcha/api/fallback?k=$key" frameborder="0" scrolling="no" style="width: 302px; height:422px; border-style: none;"></iframe>
      </div>
      <div style="width: 300px; height: 60px; border-style: none; bottom: 0px; left: 0px; margin: 0px; padding: 0px; right: 0px; background: #f9f9f9; border: 1px solid #c1c1c1; border-radius: 3px; position: absolute;">
        <textarea id="g-recaptcha-response" name="g-recaptcha-response" class="g-recaptcha-response" style="width: 250px; height: 40px; border: 1px solid #c1c1c1; margin: 10px 25px; padding: 0px; resize: none;"></textarea>
      </div>
    </div>
  </div>
</noscript>
EOT
	}

	return $output;
}

sub verify {
	my ($self,$value,$ip) = @_;
	my $params = $self->_build_request($value,$ip);
  my $http = HTTP::Tiny->new(timeout => $self->api_timeout);
  my $response = $http->post_form( $self->api_url, $params );
	return $self->_parse_response($response);
}

sub _build_request {
	my ($self,$value,$ip) = @_;
	$self->{_attrs}->{errors} = [];
	my $args = { secret => $self->secret_key };
	$args->{response} = $value if ($value);
	$args->{remoteip} = $ip if ($ip);
	return $args;
}

sub _parse_response {
	my ($self,$response) = @_;
	if (!$response || !ref($response)) {
		$self->{_attrs}->{errors} = ['http-tiny-no-response'];
		return;
	}
	if (!$response->{success}) {
		my $status = $response->{status} || 0;
		$self->{_attrs}->{errors} = [sprintf('status-code-%d',$status)];
		return;
	}
	if (!$response->{content}) {
		$self->{_attrs}->{errors} = ['no-content-returned'];
		return;
	}
	my $json = eval {JSON::PP::decode_json($response->{content})};
	if (!$json) {
		$self->{_attrs}->{errors} = ['invalid-json'];
		return;
	}
	$self->{_response} = $json;
	$self->{_attrs}->{errors} = $json->{'error-codes'};
	return $json->{success};
}

sub _get_set {
	my ($self,$name,@args) = @_;
	$self->{_attrs}->{$name} = $args[0] if (@args);
	return $self->{_attrs}->{$name};
}

1;

=head1 NAME

Captcha::noCAPTCHA - Simple implementation of Google's noCAPTCHA reCAPTCHA for perl

=head1 SYNOPSIS

The following is example usage to include captcha in page.

	my $cap = Captcha::noCAPTCHA->new({site_key => "your site key",secret_key => "your secret key"});
	my $html = $cap->html;

	# Include $html in your form page.

The following is example usage to verify captcha response.


	my $cap = Captcha::noCAPTCHA->new({site_key => "your site key",secret_key => "your secret key"});
	my $cgi = CGI->new;
	my $captcha_response = $cgi->param('g-recaptcha-response');

	if ($cap->verify($captcha_response',$cgi->remote_addr)) {
		# Process the rest of the form.
	} else {
		# Tell user he/she needs to prove his/her humanity.
	}

=head1 METHODS

=head2 html

Accepts no arguments.  Returns CAPTCHA html to be rendered with form.

=head2 verify($g_captcha_response,$users_ip_address?)

Required $g_captcha_response. Input parameter from form containing g_captcha_response
Optional $users_ip_address.

=head2 errors()

Returns an array ref of errors if verify call fails. List of possible errors:

missing-input-secret    The secret parameter is missing.
invalid-input-secret	  The secret parameter is invalid or malformed.
missing-input-response	The response parameter is missing.
invalid-input-response	The response parameter is invalid or malformed.
http-tiny-no-response   HTTP::Tiny did not return anything. No further information available.
status-code-DDD         Where DDD is the status code returned from the server.
no-content-returned     Call was successful, but no content was returned.

=head2 response()

Returns the response hashref for the most recent captcha response.

=head1 FIELD OPTIONS

Support for the following field options, over what is inherited from
L<HTML::FormHandler::Field>

=head2 site_key

Required. The site key you get when you create an account on L<https://www.google.com/recaptcha/>

=head2 secret_key

Required. The secret key you get when you create an account on L<https://www.google.com/recaptcha/>

=head2 theme

Optional. The color theme of the widget. Options are 'light ' or 'dark' (Default: light)

=head2 noscript

Optional. When true, includes the <noscript> markup in the rendered html. (Default: false)

=head2 api_url

Optional. URL to the Google API. Defaults to https://www.google.com/recaptcha/api/siteverify

=head2 api_timeout

Optional. Seconds to wait for Google API to respond. Default is 10 seconds.

=head1 SEE ALSO

The following modules or resources may be of interest.

L<HTML::FormHandlerX::Field::noCAPTCHA>

=head1 AUTHOR

Chuck Larson C<< <clarson@cpan.org> >>

=head1 CONTRIBUTORS

leejo C<< <leejo@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2017, Chuck Larson C<< <chuck+github@endcapsoftwware.com> >>

This projects work sponsered by End Cap Software, LLC.
L<http://www.endcapsoftware.com>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
