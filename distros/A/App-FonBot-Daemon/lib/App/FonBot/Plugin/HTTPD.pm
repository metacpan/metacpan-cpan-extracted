package App::FonBot::Plugin::HTTPD;

our $VERSION = '0.001';

use v5.14;
use strict;
use warnings;

use Apache2::Authen::Passphrase qw/pwcheck/;
use HTTP::Status qw/HTTP_BAD_REQUEST HTTP_OK HTTP_NO_CONTENT HTTP_FORBIDDEN HTTP_UNAUTHORIZED/;
use JSON qw/encode_json/;
use Log::Log4perl;
use POE::Component::Server::HTTP qw/RC_OK RC_DENY RC_WAIT/;

use DB_File;
use MIME::Base64 qw/decode_base64/;
use Storable qw/freeze thaw/;
use Text::ParseWords qw/shellwords/;

use App::FonBot::Plugin::Config qw/$httpd_port/;
use App::FonBot::Plugin::Common;

##################################################

my $log=Log::Log4perl->get_logger(__PACKAGE__);

my $httpd;
my %waiting_userrequests;
my %responses;

sub init{
	$log->info('initializing '.__PACKAGE__);
	%waiting_requests = ();
	%waiting_userrequests = ();
	$httpd = POE::Component::Server::HTTP->new(
		Port => $httpd_port,
		PreHandler => { '/' => [\&pre_auth, \&pre_get, \&pre_userget], },
		ContentHandler =>{ '/send' => \&on_send, '/get' => \&on_get, '/ok' => \&on_ok, '/userget' => \&on_userget, '/usersend' => \&on_usersend },
		ErrorHandler => { '/' => sub { RC_OK }},
		Headers => { 'Cache-Control' => 'no-cache' },
	);
}

sub fini{
	$log->info('finishing '.__PACKAGE__);
	POE::Kernel->call($httpd, 'shutdown');
}

##################################################

sub httpdie (\$$;$){
	my ($response,$errstr,$errcode)=@_;

	$$response->code($errcode // HTTP_BAD_REQUEST);
	$$response->header(Content_Type => 'text/plain');
	$$response->message($errstr);

	die 'Bad Request';
}

sub pre_auth{
	my ($request, $response)=@_;

	eval {
		my $authorization=$request->header('Authorization') // die 'No Authorization header';
		$authorization =~ /^Basic (.+)$/ or die 'Invalid Authorization header';
		my ($user, $password) = decode_base64($1) =~ /^(.+):(.*)$/ or die 'Invalid Authorization header';
		eval { pwcheck $user, $password; 1 } or die 'Invalid user/password combination';
		$request->header(Username => $user);
		$log->debug("HTTP request from $user to url ".$request->url);
	};
	if (my $error = $@) {
		$response->code(HTTP_UNAUTHORIZED);
		$response->message('Bad username or password');
		$response->header(Content_Type => 'text/plain');
		$response->header(WWW_Authenticate => 'Basic realm="fonbotd"');
		$response->content('Unauthorized');
		$log->debug("Request denied: $error");
		return RC_DENY
	}

	$response->content('');
	RC_OK
}

sub pre_get{
	my ($request, $response)=@_;
	my $user=$request->header('Username');
	return RC_OK if $response->code;
	return RC_OK unless $user;
	return RC_OK unless $request->uri =~ m,/get,;

	unless (exists $commands{$user}) {
		$log->debug("No pending commands for $user, entering RC_WAIT");
		$waiting_requests{$user}->continue if exists $waiting_requests{$user};
		$waiting_requests{$user}=$response;
		return RC_WAIT
	}

	RC_OK
}

sub pre_userget{
	my ($request, $response)=@_;
	my $user=$request->header('Username');
	return RC_OK if $response->code;
	return RC_OK unless $user;
	return RC_OK unless $request->uri =~ m,/userget,;

	unless (exists $responses{$user}) {
		$log->debug("No pending responses for $user, entering RC_WAIT");
		$waiting_userrequests{$user}->continue if exists $waiting_userrequests{$user};
		$waiting_userrequests{$user}=$response;
		return RC_WAIT
	}

	RC_OK
}

sub on_ok{
	my ($request, $response)=@_;
	return RC_OK if $response->code;

	$response->code(HTTP_OK);
	RC_OK
}

sub on_get{
	my ($request, $response)=@_;
	return RC_OK if $response->code;

	eval {
		my $user=$request->header('Username');
		$log->debug("on_get from user $user");

		if (exists $commands{$user}) {
			my $json=encode_json thaw $commands{$user};
			$log->debug("Sending JSON: $json to $user");
			$response->content($json);
			$response->code(HTTP_OK);
			$response->message('Commands sent');
		} else {
			$log->debug("Sending back 204 No Content");
			$response->code(HTTP_NO_CONTENT);
			$response->message('No pending commands');
		}

		delete $commands{$user}
	};

	$log->error("ERROR: $@") if $@ && $@ !~ /^Bad Request /;

	RC_OK
}

sub on_userget{
	my ($request, $response)=@_;
	return RC_OK if $response->code;

	eval {
		my $user=$request->header('Username');
		$log->debug("on_userget from user $user");

		if (exists $responses{$user}) {
			my $json=encode_json $responses{$user};
			$log->debug("Sending JSON: $json to $user");
			$response->content($json);
			$response->code(HTTP_OK);
			$response->message('Responses sent');
		} else {
			$log->debug("Sending back 204 No Content");
			$response->code(HTTP_NO_CONTENT);
			$response->message('No pending responses');
		}

		delete $responses{$user}
	};

	$log->error("ERROR: $@") if $@ && $@ !~ /^Bad Request /;

	RC_OK
}

sub on_send{
	my ($request, $response)=@_;
	return RC_OK if $response->code;

	eval {
		httpdie $response, 'All requests must use the POST http method' unless $request->method eq 'POST';
		my $user=$request->header('Username');

		my $destination=$request->header('X-Destination') // httpdie $response, 'Missing destination address';
		my ($driver, $address)=shellwords $destination;

		my $content=$request->content // httpdie $response, 'Content is undef';

		if ($driver eq 'HTTP') {
			$responses{$user}//=[];
			push @{$responses{$user}}, $content;
			if (exists $waiting_userrequests{$user}) {
				$waiting_userrequests{$user}->continue;
				delete $waiting_userrequests{$user}
			}
		} else {
			unless ($ok_user_addresses{"$user $driver $address"}) {
				$response->code(HTTP_FORBIDDEN);
				$response->message("$user is not allowed to send messages to $address");
				return
			}

			POE::Kernel->post($driver, 'send_message', $address, $content) or $log->error("Driver not found: $driver");
		}

		$response->code(HTTP_NO_CONTENT);
		$response->message('Message sent');
	};

	$log->error("ERROR: $@") if $@ && $@ !~ /^Bad Request /;
	$log->debug('Responding to send from $user with '.$response->code.' '.$response->message);
	RC_OK
}

sub on_usersend{
	my ($request, $response)=@_;
	$log->debug("asdasd asd");
	return RC_OK if $response->code;

	eval{
		httpdie $response, 'All requests must use the POST http method' unless $request->method eq 'POST';
		my $user=$request->header('Username');

		my $content=$request->content // httpdie $response, 'Content is undef';

		sendmsg $user, $request->header('X-Requestid'), HTTP => shellwords $_ for split '\n', $content;

		$response->code(HTTP_NO_CONTENT);
		$response->message('Command sent');
	};

	$log->error("ERROR: $@") if $@ && $@ !~ /^Bad Request /;
	$log->debug('Responding to usersend from $user with '.$response->code.' '.$response->message);
	RC_OK
}

1;
__END__

=encoding utf-8

=head1 NAME

App::FonBot::Plugin::HTTPD - FonBot webserver plugin, used for communication with phones

=head1 SYNOPSIS

	use App::FonBot::Plugin::HTTPD;
	App::FonBot::Plugin::HTTPD->init;
	...
	App::FonBot::Plugin::HTTPD->fini;

=head1 DESCRIPTION

This FonBot plugin provides a webserver for interacting with fonbotd. All requests use Basic access authentication.

The available calls are:

=over

=item GET C</get>

Returns a JSON array of pending commands for the current user. Uses long polling — the server does not respond immediately if there are no pending commands.

=item GET C</ok>

Returns a 200 OK.

=item POST C</send>

Sends a message to an address. The address is given in the C<X-Destination> header. The message is in the POST data.

=item GET C</userget>

Returns a JSON array of pending messages for the current user. Uses long polling — the server does not respond immediately if there are no pending commands.

=item POST C</usersend>

Sends a command to the sender's phone. The optional C<X-Requestid> header sets the request ID. The command is in the POST data

=back

=head1 CONFIGURATION VARIABLES

=over

=item C<$httpd_port>

The HTTPD listens on this port.

=back

=head1 AUTHOR

Marius Gavrilescu C<< marius@ieval.ro >>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2015 Marius Gavrilescu

This file is part of fonbotd.

fonbotd is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

fonbotd is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with fonbotd.  If not, see <http://www.gnu.org/licenses/>


=cut
