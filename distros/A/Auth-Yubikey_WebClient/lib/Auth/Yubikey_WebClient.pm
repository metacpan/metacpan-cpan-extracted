package Auth::Yubikey_WebClient;

use warnings;
use strict;
use MIME::Base64;
use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use LWP::UserAgent;
use URI::Escape;

=head1 NAME

Auth::Yubikey_WebClient - Authenticating the Yubikey against the Yubico Web API

=head1 VERSION

Version 4.02

=cut

our $VERSION = '4.02';

=head1 SYNOPSIS

Authenticate against the Yubico server via the Web API in Perl

Sample CGI script :-

	#!/usr/bin/perl

	use CGI;
	use strict;

	my $cgi = new CGI;
	my $otp = $cgi->param("otp");

	print $cgi->header();
	print "<html>\n";
	print "<form method=get>Yubikey : <input type=text name=otp size=40 type=password></form>\n";

	use Auth::Yubikey_WebClient;

	my $id = "<enter your id here>";
	my $api = "<enter your API key here>";
	my $nonce = "<enter your nonce here>";

	if($otp)
	{
        	my $result = Auth::Yubikey_WebClient::yubikey_webclient($otp,$id,$api,$nonce);
		# result can be either ERR or OK

        	print "Authentication result : <b>$result</b><br>";
	}

	print "</html>\n";


=head1 FUNCTIONS

=head2 new

Creates a new Yubikey Webclient connection

   use Auth::Yubikey_WebClient;

   my $yubi = Auth::Yubikey_WebClient->new({
        id => <enter your id here> ,
        api => '<enter your API key here>' ,
        nonce => '<enter your nonce if you have one>',
	verify_hostname => 0	# optional - defaults to 1.  Can be set to 0 if you do not want to check the validity of the SSL certificate when querying the Yubikey server
        });

You can overwrite the URL called if you want to call an alternate authentication server as well :-

   use Auth::Yubikey_WebClient;

   my $yubi = Auth::Yubikey_WebClient->new({
        id => <enter your id here> ,
        api => '<enter your API key here>' ,
        nonce => '<enter your nonce if you have one>',
	url => 'http://www.otherserver.com/webapi.php'
        });

=cut

sub new
{
	my ($class,$options_ref) = @_;
	my $self = {};

	bless $self, ref $class || $class;

	if(! defined $options_ref) {
		die "You did not pass any parameters to the Yubikey Web Client initialization";
	}
	my %options = %{$options_ref};

	# grab the variables from the initialization
	if(defined $options{id}) {
        	$self->{id} = $options{id};
	} else {
		die "Can not start without a Yubikey ID";
	}

	if(defined $options{api}) {
		$self->{api} = $options{api};

		if(length($self->{api}) % 4 != 0) {
			die "Your API key must be in 4 byte lengths";
		}
  	} else {
		die "Can not start without a Yubikey API key";
	}

	$self->{nonce} = defined $options{nonce} ? $options{nonce} : '';

	$self->{url} = defined $options{url} ? $options{url} : 'https://api2.yubico.com/wsapi/2.0/verify';

	$self->{verify_hostname} = defined $options{verify_hostname} ? $options{verify_hostname} : 1;

	return $self;
}

=head2 debug

Displays the debug info

   $yubi->debug();

Prints out some debug information.  Useful to be called after authentication to see what Yubico sent back.  You can also call the variables yourself, for example if you'd like to see what the token ID is, call $yubi->{publicid}.  The same goes for all the other variables printed in debug.

=cut

sub debug
{
	my ($self) = @_;

	print "id             = $self->{id}\n";
	print "api            = $self->{api}\n";
	print "url            = $self->{url}\n";
	print "nonce          = $self->{nonce}\n";
	print "params         = $self->{params}\n";
	print "status         = $self->{status}\n";
	print "otp            = $self->{otp}\n";
	print "publicid       = $self->{publicid}\n";
	print "t              = $self->{t}\n";
	print "sl             = $self->{sl}\n";
	print "timestamp      = $self->{timestamp}\n";
	print "sessioncounter = $self->{sessioncounter}\n";
	print "sessionuse     = $self->{sessionuse}\n";

#	print "response = $self->{response}\n";

}

=head2 yubikey_webclient

=cut

sub yubikey_webclient
{
	my ($otp,$id,$api,$nonce) = @_;

	my $yubi_tmp = new Auth::Yubikey_WebClient ( { id => $id, api => $api, nonce => $nonce } );

	return $yubi_tmp->otp($otp);
}

=head2 otp

Check a OTP for validity

	$result = $yubi->otp($otp);

Call the otp procedure with the input from the yubikey.  It will return the result.

This function will also setup a few internal variables that was returned from Yubico.

=cut

sub otp
{
        my ($self,$otp) = @_;

	chomp($otp);
	$self->{otp} = $otp;

	# lets do a basic sanity check on the otp, before we blast it off to yubico...
	if($self->{otp} !~ /[cbdefghijklnrtuv]/i || length($self->{otp}) < 32) 	{
		$self->{status} = "ERR_BAD_OTP";
		return $self->{status};
	}

	# Generate nonce unless passed
	$self->{nonce} = hmac_sha1_hex(time, rand()) unless $self->{nonce};

	# Start generating the parameters
	$self->{params} = "id=$self->{id}&nonce=$self->{nonce}&otp=" . uri_escape($self->{otp}) . "&timestamp=1";
	$self->{params} .= '&h=' . uri_escape(encode_base64(hmac_sha1($self->{params}, decode_base64($self->{api})), ''));

	# pass the request to yubico
	my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => $self->{verify_hostname} });
	$ua->env_proxy();	# 4.02
	my $req = HTTP::Request->new(GET => $self->{url} . "?$self->{params}");
	my $res = $ua->request($req);
	if($res->is_success) {
		$self->{response} = $res->content;
	} else {
		print $res->status_line . "\n";
	}
	chomp($self->{response});

	if($self->{response} !~ /status=ok/i) {
		# If the status is not ok, let's not even go through the rest...
		$self->{response} =~ m/status=(.+)/;
		$self->{status} = "ERR_$1";
		$self->{status} =~ s/\s//g;
		return $self->{status};
	}

	#extract each of the lines, and store in a hash...

	my %result;
	foreach (split(/\n/,$self->{response})) {
		chomp;
                if($_ =~ /=/)
                {
                        ($a,$b) = split(/=/,$_,2);
                        $b =~ s/\s//g;
                        $result{$a} = $b;
			$self->{$a} = $b;
                }
        }

        # save the h parameter, that's what we'll be comparing to

        my $signatur=$result{h};
        delete $result{h};
        my $datastring='';

	my $key;
        foreach $key (sort keys %result) {
                $result{$key} =~ s/\s//g;
                $datastring .= "$key=$result{$key}&";
        }
        $datastring = substr($datastring,0,length($datastring)-1);

	# Check that nonce and OTP are the ones we asked for
	$self->{status} = "ERR_MSG_AUTH";

	return "ERR_MSG_AUTH" unless ($self->{nonce} eq $result{nonce} and $self->{otp} eq $result{otp});

  	my $hmac = encode_base64(hmac_sha1($datastring,decode_base64($self->{api})));
	chomp($hmac);
  	if($hmac eq $signatur) {
		$self->{publicid} = substr(lc($self->{otp}),0,12);
		$self->{status} = "OK";
                return "OK";
   } else {
		$self->{status} = "ERR_HMAC";
		return "ERR_HMAC";
	}
}

=head1 USAGE

Before you can use this module, you need to register for an API key at Yubico.  This is as simple as logging onto <https://upgrade.yubico.com/getapikey/> and entering your Yubikey's OTP and your email address.  Once you have the API and ID, you need to provide those details to the module to work.

=head1 AUTHOR

Phil Massyn, C<< <massyn at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-auth-yubikey_webclient at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Auth-Yubikey_WebClient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Auth::Yubikey_WebClient


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Auth-Yubikey_WebClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Auth-Yubikey_WebClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Auth-Yubikey_WebClient>

=item * Search CPAN

L<http://search.cpan.org/dist/Auth-Yubikey_WebClient>

=back

=head1 Version history

0.04 - Fixed bug L<http://rt.cpan.org/Public/Bug/Display.html?id=51121>
1.00 - Added validation of the request to Yubico (Thanks to Kirill Miazine)
2.00 - Added nounce coding (Thanks to Ludvig af Klinteberg)
2.01 - Response turning into an array due to \r bug (Thanks to Peter Norin)
3.00 - Major update
4.01 - 13.10.2016 - Requested by Peter Norin - update to use LWP::UserAgent, and the option to overwrite a valid SSL certificate (verify_hostname).  The API default server is changed to ssl.
4.02 - 2019.04.04 - Request by Alexandre Linte - Support for proxy servers

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2016 Phil Massyn, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

; # End of Auth::Yubikey_WebClient
