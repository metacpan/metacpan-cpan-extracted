package Captcha::AreYouAHuman;
$VERSION = 0.00003;

# Are You a Human Perl Integration Library
# Copyright December 5, 2011  Are You a Human LLC
#
# Sign up for a publisher key at www.areyouahuman.com!
#
# AUTHOR:
#    Jonathan Brown - jonathan@areyouahuman.com
#
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

use LWP::UserAgent;
use URI::Escape;
use JSON;

# Create a new instance;
# parameters are passed with key => value
# with parameters server, publisher_key, and scoring_key
sub new {
        # make a hash-based object
        my $class = shift;
        my $self = {};
        bless($self, $class);

        my %params = @_;

        if ($params{"server"} ne "") {
                $self->{"server"} = $params{"server"};
        } else {
                $self->{"server"} = "ws.areyouahuman.com";
        }

        if ($params{"publisher_key"} eq "") {
                $self->errorLog("Called Captcha::AreYouAHuman integration without publisher_key");
        } else {
                $self->{"publisher_key"}  = $params{"publisher_key"};
        }

        if ($params{"scoring_key"} eq "") {
                $self->errorLog("Called Captcha::AreYouAHuman integration without scoring_key");
        } else {
                $self->{"scoring_key"}  = $params{"scoring_key"};
        }

        return $self;
}


# Get the HTML that gets embedded
# Returns the string to be echoed out to the browser.
sub getPublisherHTML {
        my $self = shift;

        # Get the variables out
        my $server = $self->{"server"};
        my $publisher_key = $self->{"publisher_key"};

	return "<div id='AYAH'></div><script src='https://" .
		$server . "/ws/script/"  . uri_escape($publisher_key) . 
		"'></script>";
}

# Score the results
# parameters are passed with key => value
# with parameters client_ip and session_secret
# 
# If you are using CGI.pm, call as
# $cgi = new CGI();
# my $ayah = new Captcha::AreYouAHuman;
# my $result = $ayah->scoreResult(
#    'session_secret' => $cgi->param('session_secret'),
#    'client_ip' => $cgi->remote_host()
# );
#
# Returns 0/false if failed; true if passed.
# 
sub scoreResult {
        my $self = shift;

        my %params = @_;

        # get the variables out
        my $server = $self->{"server"};
        my $client_ip = "";
	my $session_secret = "";

        if ($params{"session_secret"} eq "") {
                $self->errorLog("Called Captcha::AreYouAHuman::scoreResult without a session_secret");
		return 0;
        } else {
	        $session_secret = $params{"session_secret"};
        }

	if ($params{"client_ip"} eq "") {
                $self->errorLog("Called Captcha::AreYouAHuman::scoreResult without a client_ip");
		return 0;
        } else {
	        $client_ip = $params{"client_ip"};
        }


        # Make the request
        my $ua = LWP::UserAgent->new;
        my $req = HTTP::Request->new(POST => 'https://' . $server .
                        '/ayahwebservices/index.php/ayahwebservice/scoreGame');
        $req->content_type('application/x-www-form-urlencoded');
        $req->content('session_secret=' . uri_escape($session_secret) . '&client_ip=' . 
			uri_escape($client_ip));
        my $res = $ua->request($req);

        if ($res->is_success) {
                # JSON decode and evaluate result
                my $results;
                eval {
                        $results = decode_json($res->content);
                };

                if ($@) {
                        $self->errorLog("Could not JSON decode: " . $res->content);
                        return 0;
                } else {
                        return ($results->{'status_code'} == 1);
                }
        } else {
                $self->errorLog("Error: Internal error: " . $res->status_line);
                return 0;
        }
}

# Record the conversion
# parameters are passed with key => value
# with parameters session_secret
# 
# If you are using CGI.pm, call as
# $cgi = new CGI();
# my $ayah = new Captcha::AreYouAHuman;
# my $result = $ayah->scoreResult(
#    'session_secret' => $cgi->param('session_secret')
# ); 
#
# Returns the HTML string to be inserted into the conversion page. (Hidden iframe)
# 
sub recordConversion {
        my $self = shift;

        my %params = @_;

        # get the variables out
        my $server = $self->{"server"};
	my $session_secret = "";

        if ($params{"session_secret"} eq "") {
                $self->errorLog("Called Captcha::AreYouAHuman::scoreResult without a session_secret");
		return "";
        } else {
	        $session_secret = $params{"session_secret"};
        }

        return '<iframe style="border: none;" height="0" width="0" src="https://' . 
		$server . '/ws/recordConversion/' . $session_secret . '"></iframe>';
}

# Error logging function; override if you don't want this making noise.
# Parameter: Error message
# Default behavior: Outputs to the STDERR
sub errorLog {
        my $self = shift;
        my $message = shift;

        print STDERR "Error: Captcha::AreYouAHuman: " . $message . "\n";
}

# EOF
1;
__END__

=head1 NAME

Captcha::AreYouAHuman - Integrate the AreYouAHuman.com CAPTCHA alternative
human verification into your Perl application

=head1 SYNOPSIS

    use Captcha::AreYouAHuman;

    my $publisher_key = "BAADBEEFBAADBEEF";
    my $scoring_key = "BEEFBEEFBEEFBEEF";

    my $ayah = new Captcha::AreYouAHuman(
            "publisher_key" => $publisher_key,
            "scoring_key" => $scoring_key
    );

    # output a form
    print $ayah->getPublisherHTML();

    # score the result;
    use CGI;
    my $cgi = new CGI;
    my $result = $ayah->scoreResult(
            "session_secret" => $cgi->param('session_secret'),
            "client_ip" => $cgi->remote_host()
    );

    if ($result) {
        print "You're a human!\n";
    } else {
        print "Not a human\n":
    }

    # eecho a hidden iframe for conversion tracking
    print $ayah->recordConversion(
            "session_secret" => $cgi->param('session_secret')
    );


=head1 DESCRIPTION

CAPTCHA's suck. Are You a Human's PlayThru is a CAPTCHA alternative 
that replaces the twisted, distorted text with games.

PlayThru replaces the awful user experience of normal CAPTCHAs with 
short and simple games. They are easy for your users and difficult 
for bots to break.

Are You a Human's PlayThru provides security for your site's comments 
and registration sections. It is easy to install and difficult for 
spammers to circumvent. We collect lots of data about how a visitor 
plays our game, which we feed into our algorithm to continuously 
improve our security. Please learn more about PlayThru at the 
Are You a Human website.

Installing PlayThru requires a Publisher Key, which can be acquired 
from the Are You a Human publisher portal. To get your publisher key, 
please create an account on our registration page.

We love feedback and would like to hear from you. Please leave us 
some on our support forum. We also like to get some shout outs on 
our Facebook page.

Thank you and fight bots with fun!

L<http://areyouahuman.com>

=head1 INTERFACE

=over

=item C<< new >>

Arguments: %params

Create a new C<< Captcha::AreYouAHuman >> object.

=over 

=item C<< server >>

Sets the server name to use; if not specified, 
defaults to ws.areyouahuman.com.

=item C<< publisher_key >>

(Required) Publisher key as provided by the areyouahuman.com portal
when you register a domain.

=item C<< scoring_key >>

(Required) Scoring key as provided by the areyouahuman.com portal
when you register a domain.

=back

=item C<< getPublisherHTML >>

Returns HTML to be output to browser.

=item C<< scoreResult >>

Arguments: %params

Scores a game play; returns true on pass, false otherwise.

=over

=item C<< session_secret >>

(Required) The value of the form input I<<session_secret>>

=item C<< client_ip >> 

(Required) The remote client IP.

=back

=item C<< recordConversion >>

Arguments: %params

Returns HTML for display to the client to record a conversion.

=over

=item C<< session_secret >>

(Required) The value of the form input I<<session_secret>>

=back

=item C<< errorLog >>

Arguments: $string to record to the error log

Handles an error log; for default, it will send to STDERR.

=back


=head1 CONFIGURATION

To use Are You a Human, sign up as a publisher here:

L<http://areyouahuman.com>

Once you register your domain, you will receive a publisher key
and a scoring key.  Pass these as parameters to the constructor.

=head1 AUTHOR

Jonathan Brown C<< <jonathan@areyouahuman.com> >>

Heavily based on the Captcha::PeopleSign Perl library by 
Michele Beltrame.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 AreYouAHuman.com

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself. See L<perlartistic>.
