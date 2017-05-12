package Captcha::Peoplesign;

BEGIN {
  $Captcha::Peoplesign::VERSION = '0.00005';
}

use strict;
use warnings;

use Carp qw/croak/;
use HTML::Tiny;
use LWP::UserAgent;

use constant MODULE_VERSION => $Captcha::Peoplesign::VERSION;

use constant PEOPLESIGN_HOST => 'peoplesign.com';

use constant PEOPLESIGN_GET_CHALLENGE_SESSION_ID_URL =>
    'http://'.PEOPLESIGN_HOST.'/main/getChallengeSessionID';

use constant PEOPLESIGN_CHALLENGE_URL =>
    'http://'.PEOPLESIGN_HOST.'/main/challenge.html';

use constant PEOPLESIGN_GET_CHALLENGE_SESSION_STATUS_URL =>
    'http://'.PEOPLESIGN_HOST.'/main/getChallengeSessionStatus_v2';

use constant PEOPLESIGN_CHALLENGE_SESSION_ID_NAME => 'challengeSessionID';
use constant PEOPLESIGN_CHALLENGE_RESPONSE_NAME => 'captcha_peoplesignCRS';

use constant PEOPLESIGN_IFRAME_WIDTH => '335';
use constant PEOPLESIGN_IFRAME_HEIGHT => '335';

use constant PEOPLESIGN_CSID_SESSION_VAR_TIMEOUT_SECONDS => 3600;

use constant PEOPLESIGN_PLUGIN_VERSION => 'Captcha_Peoplesign_perl_' . MODULE_VERSION;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my $args = shift || {};

    croak "new must be called with a reference to a hash of parameters"
        unless ref $args eq 'HASH';
        
    $self->{_html_mode} = $args->{html_mode} || 'html';

    return $self;
}

sub _html {
    my $self = shift;
    
    $self->{_html} ||= HTML::Tiny->new(
        mode => $self->{_html_mode}
    );
}

sub get_html {
    my ($self, $args) = @_;
    
    ref $args eq 'HASH' || croak 'Arguments must be an hashref';
    my $ps_key = $args->{ps_key} || croak 'Provide a key';
    my $ps_location = $args->{ps_location} || croak 'Provide a location';
    my $ps_clientip = $args->{ps_clientip} || croak 'Provide the IP address of the client';
    my $ps_options = $args->{ps_psoptions} || '';
    my $ps_sessionid = $args->{ps_sessionid} || '';
    
    # TODO: remove this
    my $ps_wversion = '';

    my $status = '';
    ($status, $ps_sessionid) = $self->_get_peoplesign_sessionid(
       $ps_key,
       $ps_clientip,
       $ps_options,
       $ps_location,
       $ps_wversion,
       $ps_sessionid,
    );

    if ($status eq 'success') {
        # An iframe will only be displayed if javascript is disabled
        # in the browser.
        my $iframe_width = $args->{iframe_width} || PEOPLESIGN_IFRAME_WIDTH;
        my $iframe_height = $args->{iframe_height} || PEOPLESIGN_IFRAME_HEIGHT;
        
        return $self->_get_html_js(
            $ps_sessionid,
            $iframe_width,
            $iframe_height,
        );
    }
    
    return $self->_html->p('peoplesign is unavailable ($status)');
}

sub check_answer {
    my ($self, $args) = @_;

    ref $args eq 'HASH' || croak 'Arguments must be an hashref';
    my $ps_key = $args->{ps_key} || croak 'Provide ps_key';
    my $ps_location = $args->{ps_location} || croak 'Provide ps_location';
    my $ps_sessionid = $args->{ps_sessionid} || 'Provide ps_sessioid';
    my $ps_response = $args->{ps_response} || croak 'Provide ps_response';

    my $status = $self->_get_peoplesign_session_status(
        $ps_sessionid,
        $ps_response,
        $ps_location,
        $ps_key,
    );

    # If CAPTCHA is solved correcly, pass
    return { is_valid => 1 } if $status eq 'pass';

    # Usual states for which the user can not pass
    return { is_valid => 0, error => $status } if
        $status eq 'fail' || $status eq 'notRequested'
        || $status eq 'awaitingResponse';
    
    # If Peoplesign server has problems, do not pass but return
    # error so call decide if he/she wants to pass in such case
    return { is_valid => 0, error => $status }
        if $status eq 'badHTTPResponseFromServer';

    # If $status is invalidChallengeSessionID we can not allow the user to pass.
    # It's highly unusual for this to occur, and probably means the
    # peoplesignSession expired and the client session was still alive.
    # We now abandon this client session. This will trigger a new client session
    # and a new peoplesign session.
    return { is_valid => 0, error => $status . ' [' .$self->_get_caller_info_string() . ']' }
        if $status eq 'invalidChallengeSessionID';
        
    # All other cases are an exception, so croak!
    croak "Exception processing Peoplesign response: [status $status]"
        . $self->_get_caller_info_string();
}

# ## Private methods ##

# Contacts the peoplesign server to validate the user's response.
# Return: string ('pass', 'fail', 'awaitingResponse', 'badHTTPResponseFromServer')
sub _get_peoplesign_session_status {
    my $self = shift;
    my $peoplesignSessionID = shift || croak 'Provide challengeSessionID';
    my $peoplesignResponseString = shift || croak 'Provide response string';
    my $clientLocation = shift || "default";
    my $peoplesignKey = shift;

    $peoplesignResponseString = $self->_trim($peoplesignResponseString);

    my $ua = LWP::UserAgent->new();

    # Note that the constant values are referenced below using CONSTANT()
    # when they are needed as hash names. 
    my $response = $ua->post(
        PEOPLESIGN_GET_CHALLENGE_SESSION_STATUS_URL, {
            PEOPLESIGN_CHALLENGE_SESSION_ID_NAME()  => $peoplesignSessionID,
            PEOPLESIGN_CHALLENGE_RESPONSE_NAME()    => $peoplesignResponseString,
            privateKey                              => $peoplesignKey,
            clientLocation                          => $clientLocation
        }
    );

    return $self->_trim( $response->content )
        if ($response->is_success);
    
    $self->_print_error("bad HTTP response from server: " .$response ->status_line."\n", $self->_get_caller_info_string());
    return 'badHTTPResponseFromServer';
}

# Return value : array with 2 elements (status, eoplesignSessionID)
# A peoplesignSessionID is assigned to a given visitor and is valid
# until he/she passes a challenge
sub _get_peoplesign_sessionid {
    my $self = shift;
    my $peoplesignKey = shift;
    my $visitorIP = shift;
    my $peoplesignOptions = shift;
    my $clientLocation = shift || "default";
    my $pluginWrapperVersionInfo = shift;
    my $peoplesignSessionID = shift;

    my $ua = LWP::UserAgent->new();

    my $status;

    # Peoplesign callenge option string
    if (ref($peoplesignOptions) ne "HASH") {
       my %hash = ();

       # decode the encoded string into a hash
       $peoplesignOptions = $self->_html->url_decode($peoplesignOptions);
       foreach my $pair (split('&',$peoplesignOptions)){
           my ($key,$value) = split('=', $pair);
           $hash{$key} = $value;
        }
        $peoplesignOptions = \%hash;
    }

    $peoplesignKey = $self->_trim($peoplesignKey);
    $visitorIP  = $self->_trim($visitorIP);
 
    # Ensure private key is not the empty string
    if ($peoplesignKey eq '') {
        $self->_print_error("received a private key that was all whitespace or empty\n", $self->_get_caller_info_string());
        return ('invalidPrivateKey', '');
    }

    # Ensure visitorIP is ipv4
    if ( !($visitorIP =~ /^\d\d?\d?\.\d\d?\d?\.\d\d?\d?\.\d\d?\d?$/) ) {
        $self->_print_error("invalid visitorIP: $visitorIP\n", $self->_get_caller_info_string());
        return ('invalidVisitorIP', '');
    }

    my $response = $ua->post(
        PEOPLESIGN_GET_CHALLENGE_SESSION_ID_URL, {
            privateKey                              => $peoplesignKey,
            visitorIP                               => $visitorIP,
            clientLocation                          => $clientLocation,
            pluginInfo                              => $pluginWrapperVersionInfo
                .' '.PEOPLESIGN_PLUGIN_VERSION,
            PEOPLESIGN_CHALLENGE_SESSION_ID_NAME()  => $peoplesignSessionID,
            %{$peoplesignOptions},
        }
    );

   if ($response->is_success){
        ($status, $peoplesignSessionID) = split(/\n/, $response->content);
        if ($status ne 'success') {
            $self->_print_error("Unsuccessful attempt to get a peoplesign "
                ."challenge session: ($status)\n", $self->_get_caller_info_string());
        }
   } else {
        $self->_print_error("bad HTTP response from server:  "
            . $response ->status_line."\n", $self->_get_caller_info_string());
        $status = "invalidServerResponse";
        $peoplesignSessionID = "";
   }

    return ($status, $peoplesignSessionID);
}


sub _get_html_js {
    my $self = shift;
    my $peoplesignSessionID = shift;

    # iframe will only be displayed if javascript is disabled in browser
    my $iframeWidth = shift || PEOPLESIGN_IFRAME_WIDTH;
    my $iframeHeight = shift || PEOPLESIGN_IFRAME_HEIGHT;

    if ( $peoplesignSessionID eq "" ) {return "";}

    my $h = $self->_html;

    my $htmlcode = $h->script({
        type    => 'text/javascript',
        src     => PEOPLESIGN_CHALLENGE_URL . '?' . PEOPLESIGN_CHALLENGE_SESSION_ID_NAME
            . '=' . $peoplesignSessionID . '&addJSWrapper=true&ts=\''
            . '+\(new Date\(\)\).getTime\(\) +\'" id="yeOldePeopleSignJS">'
    })
    . $h->noscript(
        $self->_get_html_iframe($peoplesignSessionID, $iframeWidth, $iframeHeight)
    );

    return $htmlcode;
}

sub _get_html_iframe {
    my $self = shift;
    my $peoplesignSessionID = shift;
    my $width = shift || PEOPLESIGN_IFRAME_WIDTH;
    my $height = shift || PEOPLESIGN_IFRAME_HEIGHT;
    if ( $peoplesignSessionID eq "") {return "";}
    
    my $h = $self->_html;

    my $htmlcode = $h->iframe({
        src                 => PEOPLESIGN_CHALLENGE_URL . '?' . PEOPLESIGN_CHALLENGE_SESSION_ID_NAME,
        height              => $width,
        width               => $height,
        frameborder         => 0,
        allowTransparency   => 'true',
        scrolling           => 'auto',
      },
      $h->p(
        'Since it appears your browser does not support "iframes", you need to click '
        . $h->a({
            href    => PEOPLESIGN_CHALLENGE_URL
        }, 'here')
        . ' to verify you\'re a human.'
      )
      . $h->input({
          name  => PEOPLESIGN_CHALLENGE_SESSION_ID_NAME,
          type  => 'hidden',
          value => $peoplesignSessionID,
      })
    );
    
    return $htmlcode;
}

sub _get_caller_info_string {
    my $self = shift;
    # For the second subroutine up the call stack return the following:
    # file: subroutine:  line number
    return (caller(2))[1] .": " .(caller(2))[3] .": line " .(caller(2))[2];
}

sub _print_error {
    my $self = shift;
    my $message = shift;

    # If an error source was passed here, print it.  Else
    # we have to determine it;
    my $errorSourceInfo = shift || $self->_get_caller_info_string();

    print STDERR "ERROR: peoplesign client: $errorSourceInfo: $message\n";
    return;
}

sub _trim {
    my ($self, $string) = @_;
    $string =~ s/^\s*//;
    $string =~ s/\s*$//;
    return $string;
}

1;
__END__

=head1 NAME

Captcha::Peoplesign - Easily integrate Peoplesign CAPTCHA in your
Perl application

=head1 SYNOPSIS

    use Captcha::Peoplesign;

    my $ps = Captcha::Peoplesign->new;

    # Output form
    print $ps->get_html({
        ps_key      => 'your_key',
        ps_location => 'your_location',
        ps_options  => 'options_string',
        ps_sessionid=> 'challengeSessionID',
        ps_clientip => 'nnn.nnn.nnn.nnn',
    });

    # Verify submission
    my $result = $ps->check_answer({
        ps_key      => 'your_key',
        ps_location => 'your_location',
        ps_sessionid=> $challengeSessionID,
        ps_responde => $challengeResponseString,
    });

    if ( $result->{is_valid} ) {
        print "You're human!";
    }
    else {
        # Error
        $error = $result->{error};
    }

For some examples, please see the /examples subdirectory

=head1 DESCRIPTION

Peoplesign is a clever CAPTCHA system which is quite a departure
from the standard ones where you need to guess a difficult word.

To use Peoplesign you need to register your site here:

L<http://peoplesign.com>

=head1 INTERFACE

=over

=item C<< new >> 

Arguments: \%args

Create a new C<< Captcha::Peoplesign >> object.

=over

=item C<< html_mode >>

Sets what kind of HTML the library generates. Default is 'html',
since we are going toward HTML5, but you can pass 'xml' if you
use XHTML.

=back

=item C<< get_html( $pubkey, $error, $use_ssl, $options ) >>

Arguments: \%args

Generates HTML to display the captcha.

    print $ps->get_html({
        ps_key      => 'your_key',
        ps_location => 'your_location',
        ps_clientip => 'client_ip_address',
    });

=over

=item C<< ps_key >>

Required.

Your Peoplesign key, from the API Signup Page on Peoplesign web site.

=item C<< ps_location >>

Required.

Your Peoplesign location, from the API Signup Page on Peoplesign web site.

=item C<< client_ip >>

Required.

The IP address of the client who is resolving the CAPTCHA.

=item C<< ps_sessionid >>

Required when user doesn't pass the CAPTCHA.

The I<ps_sessionid> is generated by Peoplesign and is used by it
in order to recognize the user and display error messages. You should
get it when the form is submitted in the I<challengeSessionID>
query parameter. If the test is not resolved succefully, you
need to pass that session_id to C<get_html> in order for a proper
error message to be displayed to the user.

=item C<< ps_options >>

Optional.

A string which allows to customize the Peoplesign widget. You
can create it on Peopesign web site. I.e.:

 language=english&useDispersedPics=false&numPanels=2&numSmallPhotos=6&useDragAndDrop=false&challengeType=pairThePhoto&category=(all)&hideResponseAreaWhenInactive=false

You can also pass an hashref, such as:

 my $peoplesignOptions = {
    challengeType         => "pairThePhoto",
    numPanels             => "2",
    numSmallPhotos        => "8",
    useDispersedPics      => "false",
    smallPhotoAreaWidth   => ""
};

=back

Returns a string containing the HTML that should be used to display
the Peoplesign CAPTCHA widget.

=item C<< check_answer >>

After the user has filled out the HTML form, use C<< check_answer >>
to check their answer when they submit the form. The user's answer
will be in two form fields, recaptcha_challenge_field and
recaptcha_response_field, which you need to pass to this method.
The Peoplesign library will make an HTTP request to the Peoplesign
server and verify the user's answer.

=over

=item C<< ps_key >>

Required.

Your Peoplesign key, from the API Signup Page on Peoplesign web site.

=item C<< ps_location >>

Required.

Your Peoplesign location, from the API Signup Page on Peoplesign web site.

=item C<< ps_sessionid >>

Required.

The value of the form field I<challengeSessionID>.

=item C<< ps_response >>

Required.

The value of the form field I<captcha_peoplesignCRS>.

=back

Returns a reference to a hash containing two fields: C<is_valid>
and C<error>.

    my $result = $c->check_answer(
        ps_key          => 'your_key',
        ps_location     => 'your_location',
        ps_sessionid    => $challengeSessionId,
        ps_response     => $captcha_peoplesignCRS,
    );

    if ( $result->{is_valid} ) {
        print "You're human!";
    }
    else {
        # Error
        $error = $result->{error};
    }

See the /examples subdirectory for examples of how to call
C<check_answer>.

=back

=head1 CONFIGURATION

To use Peoplesign sign up for a key here:

L<http://peoplesign.com>

=head1 AUTHOR

Michele Beltrame  C<< <mb@italpro.net> >>

Heavily based on the original Peoplesign Perl library by David B. Newquist.

Some documentation and interface taken from L<Captch::reCAPTCHA> module
by Andy Armstrong.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Michele Beltrame C<< <mb@italpro.net> >>.

Copyright (c) 2008-2010 David B Newquist, Myricomp LLC

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself. See L<perlartistic>.
