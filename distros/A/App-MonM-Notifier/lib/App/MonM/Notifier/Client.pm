package App::MonM::Notifier::Client; # $Id: Client.pm 43 2017-12-01 16:30:32Z abalama $
use strict;
use utf8;

=head1 NAME

App::MonM::Notifier::Client - monotifier client

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Client;

    my $client = new App::MonM::Notifier::Client(
    		url => "http://localhost/monotifier"
    	);

    my $client = new App::MonM::Notifier::Client(
        uri         => $uri,
        debug       => 1,
        verbose     => 1,
        timeout     => 180, # default: 180
    );

    my $status = $client->check;
    if ($status) {
        debug("OK $url: ".$client->code);
        debug(Dumper($client->res));
    } else {
        debug("ERROR $url: ".$client->code);
        debug($client->error);
    }

=head1 DESCRIPTION

Client for interaction with MToken server.
This module provides client methods

The module based on L<MToken::Client>.

=head2 METHODS

=over 8

=item B<new>

    my $client = new App::MonM::Notifier::Client(
        url     => "http://localhost/monotifier",
        user    => $user, # optional
        password => $password, # optional
        timeout => $timeout, # default: 180
    );

Returns client

=item B<check>

    my $status = $client->check;
    my $status = $client->check( "GET" ); # Default: HEAD

Returns check-status of server. 0 - Error; 1 - Ok

See README file for details of data format

=item B<code>

    my $code = $client->code;

Returns HTTP code of the response

=item B<credentials>

    $client->credentials("username", "password", "realm")

Set credentials for User Agent by Realm (name of basic authentication)

=item B<error>

    print $client->error;

Returns error string

=item B<info>

    my %rec = $client->info( $token, $id );

Returns record by ID

=item B<req>

    my $request = $client->req;

Returns request hash

=item B<request>

    my $json = $client->request("METHOD", "PATH", "DATA");

Send request

=item B<res>

    my $response = $client->res;

Returns response hash

=item B<status>

    my $status = $client->status;

Returns object status value. 0 - Error; 1 - Ok

=item B<send>

    my $id = $client->send(
        token   => $params{token},
        ident   => $params{ident},
        level   => $params{level},
        to      => $params{to},
        from    => $params{from},
        subject => $params{subject},
        message => $params{message},
        pubdate => $params{pubdate},
        expires => $params{expires},
    );

Send message and returns ID or false

=item B<remove>

    my $status = $client->remove( $token, $id );

Removes message by ID and returns status. 0 - Error; 1 - Ok

=item B<update>

    my $status = $client->send(
        id      => $params{id},
        token   => $params{token},
        ident   => $params{ident},
        level   => $params{level},
        to      => $params{to},
        from    => $params{from},
        subject => $params{subject},
        message => $params{message},
        pubdate => $params{pubdate},
        expires => $params{expires},
    );

Update message and returns status

=item B<trace>

    my $trace_array = $client->trace;
    $client->trace("New trace record");

Gets trace stack or pushes new trace record to trace stack

=item B<cleanuptrace>

    $client->cleanuptrace;

Cleanup trace and returns client object

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>, L<LWP>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>, L<MToken::Client>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use CTK::Util qw/ :API /;
use CTK::TFVals qw/ :ALL /;
use CTK::ConfGenUtil;
use Try::Tiny;
use File::Basename qw/basename/;
use JSON;

# LWP (libwww)
use URI;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;
use HTTP::Headers::Util;
use HTTP::Request::Common qw//;

use App::MonM::Notifier::Util;

use constant {
        HTTP_TIMEOUT        => 180,
        TRANSACTION_MASK    => "%s %s >>> %s %s for %d sec",
        CONTENT_TYPE        => "application/json",
        NO_JSON_RESPONSE    => 1,
    };

$SIG{INT} = sub { die "Interrupted\n"; };
$| = 1;  # autoflush

sub new {
    my $class = shift;
    my %args  = @_;

    # General
    $args{status} = 1; # Ok
    $args{error} = "";
    $args{code} = 0;
    my @trace = ();

    # Debugging
    $args{debug} ||= 0; # Display transaction headers
    $args{verbose} ||= 0; # Display content

    # Other defaults
    $args{req} = undef;
    $args{res} = undef;

    # Initial URI & URL
    if ($args{uri}) {
        $args{url} = scalar($args{uri}->canonical->as_string);
    } else {
        if ($args{url}) {
            $args{uri} = new URI($args{url});
        } else {
            croak("Can't defined URL or URI");
        }
    }

    # User Agent
    $args{timeout} ||= HTTP_TIMEOUT; # TimeOut
    unless ($args{ua}) {
        my %uaopt = (
                agent                   => __PACKAGE__."/".$VERSION,
                max_redirect            => 10,
                timeout                 => $args{timeout},
                #requests_redirectable   => ['GET','HEAD','POST','PUT','DELETE'],
                requests_redirectable   => ['GET','HEAD'],
                protocols_allowed       => ['http', 'https'],
            );
        my $ua = new App::MonM::Notifier::Client::UserAgent(%uaopt);
        $ua->default_header('Cache-Control' => "no-cache");
        $args{ua} = $ua;
    }

    # Credentials: Set User & Password
    $args{user} //= '';
    $args{password} //= '';
    $args{realm} //='';

    # URL Replacement (Redirect)
    $args{redirect} = {};
    my $turl = $args{url};
    if ($args{redirect}->{$turl}) {
        $args{url} = $args{redirect}->{$turl};
        $args{uri} = new URI($args{url});
    } else {
        my $tres = $args{ua}->head($args{url});
        my $dst_url;
        foreach my $r ($tres->redirects) { # Redirects detected!
            next unless $r->header('location');
            $dst_url = $r->header('location');
            my $src_uri = $r->request->uri; my $src_url = $src_uri->canonical->as_string;
            push(@trace, sprintf("Redirect detected (%s): %s ==> %s", $r->status_line, $src_url, $dst_url)) if $args{debug};
        }
        if ($dst_url) {
            $args{redirect}->{$turl} = $dst_url; # Set SRC_URL -> DST_URL
            $args{url} = $dst_url;
            $args{uri} = new URI($dst_url);
            #$args{ua}->credentials($args{uri}->host_port, $args{realm}, $args{user}, $args{password}) if defined $args{user};
        }
    }

	$args{trace} = [@trace];
    my $self = bless {%args}, $class;
    return $self;
}
sub credentials {
    my $self = shift;
    my $user = shift;
    my $password = shift;
    my $realm = shift || $self->{realm};

    $self->{user} = $user;
    $self->{password} = $password;
    #$self->req->authorization_basic( $user, $password ) if defined $user;
    $self->{ua}->credentials($self->{uri}->host_port, $realm, $user, $password) if defined $user;
    #$self->{ua}->add_handler( request_prepare => sub {
    #        my($req, $ua, $h) = @_;
    #        $req->authorization_basic( $user, $password ) if defined $user;
    #        return $req;
    #    } );

    return 1;
}
sub request {
    my $self = shift;
    my $method = shift || "GET";
    my $path = shift;
    my $data = shift;
    my $no_json_response = shift;

    # UserAgent
    my $ua = $self->{ua};

    # URI
    my $uri_orig = $self->{uri}; # Get default
    my $uri = $uri_orig->clone;
    $uri->path($path) if defined $path;

    # Prepare Request
    my $req = new HTTP::Request(uc($method), $uri);
    if ($method eq "POST") {
        unless (defined($data) && ( is_hash($data) or !ref($data) )) {
            croak("Data not specified! Please use HASH-ref or text data");
        }
        my ($req_content, $boundary);
        if (is_hash($data)) { # form-data
            my $ct = "multipart/form-data"; # "application/x-www-form-urlencoded"
            ($req_content, $boundary) = HTTP::Request::Common::form_data($data, HTTP::Request::Common::boundary(6), $req);
            $req->header('Content-Type' =>
                    HTTP::Headers::Util::join_header_words( $ct, undef, boundary => $boundary )
                ); # might be redundant
        } else {
            $req->header('Content-Type', CONTENT_TYPE);
            $req_content = $data;
        }
        if (defined($req_content)) {
            $req->header('Content-Length' => length(Encode::encode("utf8", $req_content))) unless ref($req_content);
            $req->content(Encode::encode("utf8", $req_content));
        } else {
            $req->header('Content-Length' => 0);
        }
        #say(Dumper({parameters => \@parameters, }));
    } elsif ($method eq "PUT") {
        my $req_content;
        if (is_hash($data)) { # json-data
            $req->header('Content-Type', CONTENT_TYPE);
            $req_content = to_json($data, { utf8  => 0, pretty => 1, });
        } else {
            $req->header('Content-Type', 'application/octet-stream');
            $req_content = $data;
        }
        if (length($req_content)) {
            $req->header('Content-Length' => length(Encode::encode("utf8", $req_content)));
            $req->content(Encode::encode("utf8", $req_content));
        } else {
            $req->header('Content-Length', 0);
        }
    }
    $self->{req} = $req;

    # Send Request
    my $is_callback = ($data && ref($data) eq 'CODE') ? 1 : 0;
    my $res = $is_callback ? $ua->request($req, $data) : $ua->request($req);
    $self->{res} = $res;
    my ($stat, $line, $code);
    my $req_string = sprintf("%s %s", $method, $res->request->uri->canonical->as_string);
    $stat = $res->is_success ? 1 : 0;
    $code = $res->code;
    $self->code($code);
    $line = $res->status_line;

    # Debugging
    if ($self->{debug}) {
        # Request
        $self->trace($req_string);
        $self->trace($res->request->headers_as_string);
        if ($self->{verbose}) {
            $self->trace(sprintf("-----BEGIN REQUEST CONTENT-----\n%s\n-----END REQUEST CONTENT-----", $req->content));
        }
        # Response
        $self->trace($line);
        $self->trace($res->headers_as_string);
        if ($self->{verbose}) {
            $self->trace(sprintf("-----BEGIN RESPONSE CONTENT-----\n%s\n-----END RESPONSE CONTENT-----", $res->content));
        }
    }

    # Response
    $self->status($stat);
    $self->error(sprintf("%s >>> %s", $req_string, $line)) unless $stat;
    if ($no_json_response || $method eq "HEAD") {
        return ( json => "", status => 1 ) if $stat;
        return ( json => "", status => $stat, error  => [{code => $code, message => $res->message}] );
    }
    my %json = _read_json($stat ? $res->decoded_content : undef);
    if ($stat) {
        my $err = _check_response(\%json);
        if ($err) {
            $self->status(0);
            $self->error($err);
            return %json;
        }
    }
    return %json;
}
sub error {
    my $self = shift;
    my $e = shift;
    $self->{error} = $e if defined $e;
    return $self->{error};
}
sub status {
    my $self = shift;
    my $s = shift;
    $self->{status} = $s if defined $s;
    return $self->{status};
}
sub code {
    my $self = shift;
    my $c = shift;
    $self->{code} = $c if defined $c;
    return $self->{code};
}
sub trace {
    my $self = shift;
    my $v = shift;
    if (defined($v)) {
    	my $a = $self->{trace};
    	push @$a, $v;
    	return 1;
    }
    return $self->{trace};
}
sub cleanuptrace {
    my $self = shift;
    $self->{trace} = [];
    return $self;
}
sub req {
    my $self = shift;
    return $self->{req};
}
sub res {
    my $self = shift;
    return $self->{res};
}

sub check {
    my $self = shift;
    my $meth = shift || "HEAD";
    $self->request($meth, @_);
    return 0 unless $self->status;
    return 1;
}
sub send { # Returns id or false when occurred errors
    my $self = shift;
    my %params = @_;

    my %json = $self->request("POST", undef, {
        token   => $params{token},
        ident   => $params{ident},
        level   => $params{level},
        to      => $params{to},
        from    => $params{from},
        subject => $params{subject},
        message => $params{message},
        pubdate => $params{pubdate},
        expires => $params{expires},
    });

    my $id = 0;
    if ($self->status) {
        $id = $json{id};
        unless ($id && is_num($id)) {
            $self->error("Incorrect ID in json");
            $self->status(0);
            return 0;
        }
    } else {
        return 0;
    }

    return $id;
}
sub info {
    my $self = shift;
    my $token = shift;
    my $id = shift;

    unless ($id && is_num($id)) {
        $self->error("Incorrect ID");
        $self->status(0);
        return;
    }

    my $tmpuri = $self->{uri}->clone;
    $self->{uri}->query_form( action => "check", token => $token, id => $id );
    my %json = $self->request("GET");
    $self->{uri} = $tmpuri;

    return unless $self->status;
    return $json{message};
}
sub remove {
    my $self = shift;
    my $token = shift;
    my $id = shift;

    unless ($id && is_num($id)) {
        $self->error("Incorrect ID");
        $self->status(0);
        return 0;
    }

    my $tmpuri = $self->{uri}->clone;
    $self->{uri}->query_form( token => $token, id => $id );
    my %json = $self->request("DELETE");
    $self->{uri} = $tmpuri;

    return 0 unless $self->status;
    return 1;
}
sub update { # Returns true or false when occurred errors
    my $self = shift;
    my %params = @_;

    unless ($params{id} && is_num($params{id})) {
        $self->error("Incorrect ID");
        $self->status(0);
        return 0;
    }
    my %json = $self->request("PUT", undef, {%params});

    return 0 unless $self->status;
    return 1;
}

sub _read_json { # JSON -> Structure
    my $json = shift;
    my $out = {
            json    => "",
            status  => 0,
            error   => [{code => 204, message => "No input data"}],
        };
    return %$out unless $json;
    try {
        my $in = from_json($json, {utf8 => 0});
        if ($in && ((ref($in) eq 'HASH') || ref($in) eq 'ARRAY')) {
            if (ref($in) eq 'ARRAY') {
                $out = shift(@$in) || {};
            } else { # HASH
                $out = $in;
            }
        } else {
            $out = { error => [{code => 1002, message => "Bad JSON format"}] };
        }
        $out->{error} ||= [{code => 1001, message => "Incorrect input data"}];
    } catch {
        $out = { error => [{code => 1003, message => sprintf("Can't load JSON from request: %s", $_)}] };
    };
    $out->{json} = $json;
    $out->{status} ||= 0;
    return %$out;
}
sub _check_response { # Returns error string when status = 0 and error is not empty
    my $res = shift;
    # Returns:
    #  "..." - errors!
    #  undef - no errors
    my @error;
    if (is_hash($res)) {
        return undef if value($res => "status"); # OK
        my $errors = array($res => "error");
        foreach my $err (@$errors) {
            if (is_hash($err)) {
                push @error, sprintf("E%04d %s", uv2zero(value($err => "code")), uv2null(value($err => "message")));
            }
        }
    } else {
        return "The response has not valid JSON format";
    }
    return join "; ", @error;
}
sub _fbytes {
    my $n = int(shift);
    if ($n >= 1024 * 1024) {
        return sprintf "%.3g MB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KB", $n / 1024.0;
    } else {
        return "$n bytes";
    }
}

1;

# We make our own specialization of LWP::UserAgent that asks for
# user/password if document is protected.
package # Hide it from PAUSE
    App::MonM::Notifier::Client::UserAgent;
use LWP::UserAgent;
use App::MonM::Notifier::Const;
use CTKx;
use CTK::ConfGenUtil;
use base 'LWP::UserAgent';
sub get_basic_credentials {
    my($self, $realm, $uri, $proxy) = @_;
    my ($user, $password);
    my $netloc = $uri->host_port;
	my $c = CTKx->instance->c();
    my $config_client = node($c->config() => "client");

    $user = value($config_client => "user");
    $password = value($config_client => "password");

    if (defined($user) && length($user)) {
        return ($user, $password);
    } elsif (-t) {
        print STDERR "Enter username for $realm at $netloc: ";
        $user = <STDIN>;
        chomp($user);
        return (undef, undef) unless length $user;
        print STDERR "Password: ";
        system("stty -echo") unless MSWIN;
        $password = <STDIN>;
        system("stty echo") unless MSWIN;
        print STDERR "\n";  # because we disabled echo
        chomp($password);
        return ($user, $password);
    } else {
        return (undef, undef);
    }
    return if $proxy;
    return $self->credentials($uri->host_port, $realm);
}

1;

__END__
