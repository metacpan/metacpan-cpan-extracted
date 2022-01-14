package Captcha::reCAPTCHA::V3;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use Carp qw(carp croak);
use JSON qw(decode_json);
use LWP::UserAgent;
my $ua = LWP::UserAgent->new();

use overload(
    '""'  => sub { $_[0]->name() },
    'cmp' => sub { $_[0]->name() cmp $_[1] },
    '0+'  => sub {
        carp __PACKAGE__, " shouldn't be treated as a Number";
        return $_[0]->name();
    },
);

sub new {
    my $class = shift;
    my $self  = bless {}, ref $class || $class;
    my %attr  = @_;

    # Initialize the values for API
    $self->{'sitekey'}    = $attr{'sitekey'}    || '';    # No need to set sitekey in server-side
    $self->{'secret'}     = $attr{'secret'}     || croak "missing param 'secret'";
    $self->{'query_name'} = $attr{'query_name'} || 'g-recaptcha-response';

    $self->{'widget_api'} = 'https://www.google.com/recaptcha/api.js';
    $self->{'verify_api'} = 'https://www.google.com/recaptcha/api/siteverify';
    return $self;
}

sub name {
    my $self = shift;
    return $self->{'query_name'} unless my $value = shift;
    $self->{'query_name'} = $value;
}

sub sitekey {
    my $self = shift;
    return $self->{'sitekey'} unless my $value = shift;
    $self->{'sitekey'} = $value;
}

# verifiers =======================================================================
sub verify {
    my $self     = shift;
    my $response = shift;
    croak "Extra arguments have been set." if @_;

    my $params = {
        secret   => $self->{'secret'},
        response => $response || croak "missing response token",
    };

    my $res = $ua->post( $self->{'verify_api'}, $params );
    return decode_json $res->decoded_content() if $res->is_success();

    croak "something wrong to POST by " . $ua->agent(), "\n";
}

sub deny_by_score {
    my $self     = shift;
    my %attr     = @_;
    my $response = $attr{'response'} || croak "missing response token";
    my $score    = $attr{'score'}    || 0.5;
    croak "invalid score was set: $score" if $score < 0 or 1 < $score;

    my $content = $self->verify($response);
    if ( $content->{'success'} and $content->{'score'} == 1 || $content->{'score'} < $score ) {
        unshift @{ $content->{'error-codes'} }, 'too-low-score';
        $content->{'success'} = 0;
    }
    return $content;
}

sub verify_or_die {
    my $self    = shift;
    my $content = $self->deny_by_score(@_);
    return $content if $content->{'success'};
    die 'fail to verify reCAPTCHA: ', $content->{'error-codes'}[0], "\n";
}

# aroud javascript =======================================================================
sub scriptURL {
    my $self    = shift;
    my %attr    = @_;
    my $sitekey = $attr{'sitekey'} || $self->{'sitekey'} || croak "missing 'sitekey'";
    return $self->{'widget_api'} . "?render=$sitekey";
}

sub scriptTag {
    my $self    = shift;
    my %attr    = @_;
    my $sitekey = $attr{'sitekey'} || $self->{'sitekey'} || croak "missing 'sitekey'";
    my $url     = $self->scriptURL( sitekey => $sitekey );
    return qq|<script src="$url" defer></script>|;
}

sub scripts {
    my $self    = shift;
    my %attr    = @_;
    my $sitekey = $attr{'sitekey'} || $self->{'sitekey'} || croak "missing 'sitekey'";
    my $simple  = $self->scriptTag(@_);
    my $id      = $attr{'id'} or croak "missing the id for Form tag";
    my $action  = $attr{'action'} || 'homepage';
    my $comment = '// ' unless $attr{'debug'};
    return <<"EOL";
$simple
<script defer>
let rf = document.getElementById("$id");
rf.onsubmit = function(event){
    grecaptcha.ready(function() {
        grecaptcha.execute('$sitekey', { action: '$action' }).then(function(token) {
            ${comment}console.log(token);
            rf.insertAdjacentHTML('beforeend', '<input type="hidden" name="$self" value="' + token + '">');
            rf.submit();
        });
    });
    event.preventDefault();
    return false;
}
</script>
EOL
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
     sitekey => '__YOUR_SITEKEY__', # Optional
     secret  => '__YOUR_SECRET__',  # Required
 );
 
 ...
 
 my $content = $rc->verify($param{$rc});
 unless ( $content->{'success'} ) {
    # code for failing like below
    die 'fail to verify reCAPTCHA: ', @{ $content->{'error-codes'} }, "\n";
 }
 
=head1 DESCRIPTION

Captcha::reCAPTCHA::V3 is inspired from L<Captcha::reCAPTCHA::V2>

This one is especially for Google reCAPTCHA v3, not for v2 because APIs are so defferent.

=head2 Basic Usage

=head3 new( secret => I<secret>, [ sitekey => I<sitekey>, query_name => I<query_name> ] )

Requires only secret when constructing.

Now you can omit sitekey (from version 0.0.4).

You have to get them before running from L<here|https://www.google.com/recaptcha/intro/v3.html>.

 my $rc = Captcha::reCAPTCHA::V3->new(
    sitekey => '__YOUR_SITEKEY__', # Optinal
    secret  => '__YOUR_SECRET__',
    query_name => '__YOUR_QUERY_NAME__', # Optinal
 );

According to the official document, query_name defaults to 'g-recaptcha-response'
so if you changed it another, you have to set I<query_name> as same.

=head3 name([I<name>])

You can get/set I<query_name> after constuct the object from version 0.0.4

 my $query_name = $rc->name();  # defaults to 'g-recaptcha-response'
 $rc->name('captcha');          # the I<query_name> is now 'captcha' 

and with overlording, you can get I<query_name> with just like below:

 my $query_name = "$rc";        # means same with $rc->name();

=head3 verify( I<response> )

Requires just only response key being got from Google reCAPTCHA API.

B<DO NOT> add remote address. there is no function for remote address within reCAPTCHA v3.

 my $content = $rc->verify($param{$rc});

The default I<query_name> is 'g-recaptcha-response' and it is stocked in constructor.

But now string-context provides you to get I<query_name> so we don't have to care about it.

The response contains JSON so it returns decoded value from JSON.

 unless ( $content->{'success'} ) {
    # code for failing like below
    die 'fail to verify reCAPTCHA: ', @{ $content->{'error-codes'} }, "\n";
 }

=head3 deny_by_score( response => I<response>, [ score => I<expected> ] )

reCAPTCHA v3 responses have score whether the request was by bot.

So this method provides evaluation by scores that 0.0~1.0(defaults to 0.5)

If the score was lower than what you expected, the verifying is fail
with inserting 'too-low-score' into top of the error-codes.

C<verify()> requires just only one argument because of compatibility for version 0.01. 

In this method, the response pair SHOULD be set as a hash argument(score pair is optional).

=head2 Additional method for lazy(not sudgested)

=head3 verify_or_die( response => I<response>, [ score => I<score> ] )

This method is a wrapper of C<deny_by_score()>, the differense is dying imidiately when fail to verify.

=head3 scripts( id => I<ID>, [ debug => I<Boolen>, action => I<action> ] )

You can insert this somewhere in your E<lt>bodyE<gt> tag.

In ordinal HTMLs, you can set this like below:

 print <<"EOL", scripts( id => 'MailForm' );
 <form action="./" method="POST" id="MailForm">
    <input type="hidden" name="name" value="value">
    <button type="submit">send</button>
 </form>
 EOL

Then you might write less javascript lines.

From 0.0.4 you can set I<debug> flag in this method.
this is just comment-out the below but powerful.

 //console.log(token);

=head1 NOTES

To test this module strictly,
there is a necessary to run javascript in test environment.

I have not prepared it yet.

So any L<PRs|https://github.com/worthmine/Captcha-reCAPTCHA-V3/pulls>
and L<Issues|https://github.com/worthmine/Captcha-reCAPTCHA-V3/issues> are welcome.

=head1 SEE ALSO

=over

=item L<Captcha::reCAPTCHA::V2>

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
