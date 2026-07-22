package Captcha::Cloudflare::Turnstile;
require 5.10.1;
use strict;
use warnings;

our $VERSION = "0.02";

use parent 'Captcha::reCAPTCHA::V3';
use Carp qw(carp croak);

sub new {
    my $class = shift;
    my $self  = bless {}, ref $class || $class;
    my %attr  = @_;

    $self->{sitekey}    = $attr{sitekey}    || '';    # No need to set sitekey in server-side
    $self->{secret}     = $attr{secret}     || croak "missing param 'secret'";
    $self->{query_name} = $attr{query_name} || 'cf-turnstile-response';
    $self->{widget_api} = 'https://challenges.cloudflare.com/turnstile/v0/api.js';
    $self->{verify_api} = 'https://challenges.cloudflare.com/turnstile/v0/siteverify';

    return $self;
}

# aroud javascript =======================================================================
sub scriptURL {
    my $self = shift;
    return $self->{widget_api};
}

sub widgetTag {
    my $self    = shift;
    my %attr    = @_;
    my $sitekey = $attr{sitekey} || $self->{sitekey} || croak "missing 'sitekey'";
    my $action  = $attr{action} ? qq| data-action="$attr{action}"| : '';
    return qq|<div class="cf-turnstile" data-sitekey="$sitekey"$action></div>|;
}

sub scripts {
    my $self    = shift;
    my %attr    = @_;
    my $sitekey = $attr{sitekey} || $self->{sitekey} || croak "missing 'sitekey'";
    my $action  = $attr{action} || 'homepage';
    my $simple  = $self->scriptTag(%attr);
    return <<"EOL";
$simple
<div class="cf-turnstile" data-sitekey="$sitekey" data-action="$action"></div>
EOL
}

# verifiers =======================================================================
sub deny_by_score {
    my $self     = shift;
    my %attr     = @_;
    my $response = $attr{response} || croak "missing response token";
    carp "deny_by_score() is not applicable for Cloudflare Turnstile (no score); use verify() instead";
    return $self->verify($response);
}

sub verify_or_die {
    my $self     = shift;
    my %attr     = @_;
    my $response = $attr{response} || croak "missing response token";
    my $content  = $self->verify($response);
    return $content if $content->{success};
    die 'fail to verify Turnstile: ', $content->{'error-codes'}[0], "\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

Captcha::Cloudflare::Turnstile - A Perl implementation for Cloudflare Turnstile

=head1 SYNOPSIS

 use Captcha::Cloudflare::Turnstile;
 my $ts = Captcha::Cloudflare::Turnstile->new(
     sitekey => '__YOUR_SITEKEY__', # Optional
     secret  => '__YOUR_SECRET__',  # Required
 );

 # In your HTML template, inside a <form> tag:
 print $ts->scripts( action => 'login' );
 # or separately:
 print $ts->scriptTag;
 print $ts->widgetTag( action => 'login' );

 # Server-side verification:
 my $content = $ts->verify($param{$ts});
 unless ( $content->{'success'} ) {
    die 'fail to verify Turnstile: ', @{ $content->{'error-codes'} }, "\n";
 }

=head1 DESCRIPTION

Captcha::Cloudflare::Turnstile is a subclass of L<Captcha::reCAPTCHA::V3> that implements
the L<Cloudflare Turnstile|https://www.cloudflare.com/products/turnstile/> CAPTCHA service.

It inherits C<verify()>, C<name()>, C<sitekey()>, and the utility methods from the base class,
and overrides the API endpoints and JavaScript helpers for Turnstile.

=head2 Basic Usage

=head3 new( secret => I<secret>, [ sitekey => I<sitekey>, query_name => I<query_name> ] )

Requires only secret when constructing.

You have to get them from L<Cloudflare Turnstile dashboard|https://dash.cloudflare.com/?to=/:account/turnstile>.

 my $ts = Captcha::Cloudflare::Turnstile->new(
    sitekey    => '__YOUR_SITEKEY__', # Optional
    secret     => '__YOUR_SECRET__',
    query_name => '__YOUR_QUERY_NAME__', # Optional, defaults to 'cf-turnstile-response'
 );

=head3 name([I<name>])

Get/set the form field name (I<query_name>). Defaults to C<'cf-turnstile-response'>.

 my $query_name = "$ts";   # stringification returns query_name

=head3 verify( I<response> )

Sends the token to the Cloudflare Turnstile siteverify endpoint and returns the decoded JSON response.

 my $content = $ts->verify($param{$ts});
 unless ( $content->{'success'} ) {
    die 'fail to verify Turnstile: ', @{ $content->{'error-codes'} }, "\n";
 }

=head3 verify_or_die( response => I<response> )

Calls C<verify()> and dies immediately on failure.

=head3 deny_by_score( response => I<response> )

Not applicable for Turnstile (no score is returned). Issues a warning and delegates to C<verify()>.

=head3 scriptURL()

Returns the Turnstile JavaScript API URL:
C<https://challenges.cloudflare.com/turnstile/v0/api.js>

No sitekey parameter is required in the URL for Turnstile.

=head3 scriptTag()

Returns C<< <script src="...api.js" defer></script> >>.

=head3 widgetTag( [ sitekey => I<sitekey>, action => I<action> ] )

Returns the Turnstile widget C<< <div> >> to place inside a C<< <form> >> tag.

 print $ts->widgetTag( action => 'login' );
 # <div class="cf-turnstile" data-sitekey="..." data-action="login"></div>

Turnstile automatically injects a hidden C<cf-turnstile-response> input into the form
when the challenge is completed.

=head3 scripts( [ sitekey => I<sitekey>, action => I<action> ] )

Returns C<scriptTag()> and C<widgetTag()> combined. Place this B<inside> the C<< <form> >> tag.

 print <<"EOL";
 <form action="./" method="POST">
    <input type="hidden" name="name" value="value">
    @{[ $ts->scripts( action => 'submit' ) ]}
    <button type="submit">send</button>
 </form>
 EOL

=head1 NOTES

To test this module strictly,
there is a necessary to run javascript in test environment.

Cloudflare provides dummy test keys for automated testing:

=over

=item Always passes: sitekey C<1x00000000000000000000AA>, secret C<1x0000000000000000000000000000000AA>

=item Always blocks: sitekey C<2x00000000000000000000AB>, secret C<2x0000000000000000000000000000000AA>

=back

=head1 SEE ALSO

=over

=item L<Captcha::reCAPTCHA::V3>

=item L<Cloudflare Turnstile|https://www.cloudflare.com/products/turnstile/>

=item L<Cloudflare Turnstile API document|https://developers.cloudflare.com/turnstile/>

=back

=head1 LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

worthmine E<lt>worthmine@gmail.comE<gt>

=cut
