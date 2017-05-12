package CGI::Easy::Request;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.0';

use CGI::Easy::Util qw( uri_unescape_plus burst_urlencoded burst_multipart );
use URI::Escape qw( uri_unescape );
use MIME::Base64;

use constant MiB => 1024*1024;  ## no critic(Capitalization)

my $MAX_POST = MiB;

sub new {
    my ($class, $opt) = @_;
    my $self = {
        scheme                  => $ENV{HTTPS} ? 'https' : 'http',
        host                    => undef,
        port                    => $ENV{SERVER_PORT},
        path                    => undef,
        GET                     => {},  # for GET, HEAD, DELETE, …
        POST                    => {},  # for POST, PUT
        filename                => {},
        mimetype                => {},
        cookie                  => {},
        REMOTE_ADDR             => $ENV{REMOTE_ADDR},
        REMOTE_PORT             => $ENV{REMOTE_PORT},
        AUTH_TYPE               => $ENV{AUTH_TYPE},
        REMOTE_USER             => $ENV{REMOTE_USER},
        REMOTE_PASS             => undef,
        ENV                     => { %ENV },
        STDIN                   => q{},
        error                   => q{},
    };
    bless $self, $class;

    my $pre = $opt->{frontend_prefix};
    if (defined $pre) {
        $pre = uc $pre;
        $pre =~ s/-/_/xmsg;
        if (defined $ENV{"HTTP_${pre}REMOTE_ADDR"}) {
            $self->{REMOTE_ADDR} = $ENV{"HTTP_${pre}REMOTE_ADDR"};
            $self->{REMOTE_PORT} = $ENV{"HTTP_${pre}REMOTE_PORT"};
            $self->{scheme}      = $ENV{"HTTP_${pre}HTTPS"} ? 'https' : 'http';
        }
    }

    my $host = $ENV{HTTP_HOST};
    my $path = $ENV{REQUEST_URI};
    if ($path =~ s{\A\w+://(?:[^/@]*@)?([^/]+)}{}xms) {
        $host = $1;
    }
    $host =~ s{:\d+\z}{}xms;
    $path =~ s{[?].*}{}xms;
    $path = uri_unescape($path);  # WARNING nginx allow %2F, apache didn't
    if (!length $path) {
        $path = q{/};
    }
    $self->{host} = $host;
    $self->{path} = $path;

    if ($ENV{HTTP_AUTHORIZATION}) {
        if ($ENV{HTTP_AUTHORIZATION} =~ /\ABasic\s+(\S+)\z/xms) {
            my ($user, $pass) = split /:/xms, decode_base64($1), 2;
            if (defined $pass) {
                $self->{AUTH_TYPE}   = 'Basic';
                $self->{REMOTE_USER} = $user;
                $self->{REMOTE_PASS} = $pass;
            }
        }
        if (!defined $self->{REMOTE_PASS}) {
            $self->{error} = 'failed to parse HTTP_AUTHORIZATION';
        }
    }

    $self->_read_cookie();

    if ($ENV{REQUEST_METHOD} eq 'POST' || $ENV{REQUEST_METHOD} eq 'PUT') {
        $self->_read_post($opt->{max_post});
		if ($opt->{post_with_get}) {
			$self->_read_get();
		}
	} else {
		$self->_read_get();
	}

    if (!$opt->{keep_all_values}) {
        $self->_force_scalar_params();
    }

    if (!$opt->{raw}) {
        $self->_decode_utf8();
    }

	return $self;
}

sub param {
	my ($self, $name) = @_;
    if (defined $name) {
	    my @result;
        for my $method (qw( POST GET )) {
            if (exists $self->{$method}{$name}) {
                my $value = $self->{$method}{$name};
                push @result, ref $value ? @{$value} : $value;
            }
        }
        return wantarray ? @result : $result[0];
    }
    else {
        my %p = map { $_ => 1 } keys %{$self->{POST} || {}}, keys %{$self->{GET} || {}};
        return keys %p;
    }
}

sub _force_scalar_params {
    my ($self) = @_;
    for my $p ($self->{GET}, $self->{POST}, $self->{filename}, $self->{mimetype}) {
        for my $name (keys %{ $p || {} }) {
            if ($name !~ /\[\]\z/xms) {
                $p->{ $name } = $p->{ $name }[0];
            }
        }
    }
    return;
}

sub _decode_utf8 {
    my ($self) = @_;
    utf8::decode($self->{path});
    for my $key (qw( GET POST filename mimetype cookie )) {
        my %tmp;
        for my $name (keys %{ $self->{$key} || {} }) {
            if (ref $self->{$key}{$name}) {
                for my $i (0 .. $#{ $self->{$key}{$name} }) {
                    if (!($key eq 'POST' && defined $self->{mimetype}{$name}[$i])) {
                        utf8::decode($self->{$key}{$name}[$i]);
                    }
                }
            }
            else {
                if (!($key eq 'POST' && defined $self->{mimetype}{$name})) {
                    utf8::decode($self->{$key}{$name});
                }
            }
            my $namestr = $name; utf8::decode($namestr);
            $tmp{ $namestr } = $self->{$key}{$name};
        }
        $self->{$key} = \%tmp;
    }
    return;
}

sub _read_cookie {
    my ($self) = @_;
    foreach (split /;\s?/xms, $self->{ENV}{HTTP_COOKIE} || q{}) {
        s/\s*(.*?)\s*/$1/xms;
        my ($key, $value) = split /=/xms, $_, 2;
        # Some foreign cookies are not in name=value format, so ignore them.
        next if !defined $value;
        $key   = uri_unescape_plus($key);
        $value = uri_unescape_plus($value);
        # A bug in Netscape can cause several cookies with same name to
        # appear.  The FIRST one in HTTP_COOKIE is the most recent version.
        next if exists $self->{cookie}{$key};
        $self->{cookie}{$key} = $value;
    }
    return;
}

sub _read_get {
	my $self = shift;
	$self->{GET} = burst_urlencoded($self->{ENV}{QUERY_STRING});
    return;
}

sub _read_post {
	my ($self, $max_post) = @_;

    $max_post ||= $MAX_POST;
	if ($self->{ENV}{CONTENT_LENGTH} > $max_post) {
        $self->{error} = 'POST body too large';
        return;
    }

	my $buffer = q{};
	if ($self->{ENV}{CONTENT_LENGTH} > 0) {
        binmode STDIN;
        my $n = read STDIN, $buffer, $self->{ENV}{CONTENT_LENGTH}, 0;
        $self->{STDIN} = $buffer;
        if ($n != $self->{ENV}{CONTENT_LENGTH}) {
            $self->{error} = 'POST body incomplete';
            return;
        }
	}

	# Boundaries are supposed to consist of only the following
	# (1-70 of them, not ending in ' ') A-Za-z0-9 '()+,_-./:=?
    my $multipart = qr{\Amultipart/form-data;\s+boundary=(.*)\z}xmsi;
	if ($self->{ENV}{CONTENT_TYPE}) {
        if ($self->{ENV}{CONTENT_TYPE} =~ m/$multipart/xms) {
            my $boundary = $1;
            @{$self}{'POST','filename','mimetype'}
                = burst_multipart($buffer, $boundary);
        }
        elsif ($self->{ENV}{CONTENT_TYPE} eq 'application/x-www-form-urlencoded') {
            $self->{POST} = burst_urlencoded($buffer);
        }
    }
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

CGI::Easy::Request - parse CGI params


=head1 VERSION

This document describes CGI::Easy::Request version v2.0.0


=head1 SYNOPSIS

    use CGI::Easy::Request;

    my $r = CGI::Easy::Request->new();
    my $r = CGI::Easy::Request->new({
        frontend_prefix     => 'X-Real-',
        max_post            => 10*1024*1024,
        post_with_get       => 1,
        raw                 => 1,
        keep_all_values     => 1,
    });

    if ($r->{error}) {  # incorrect HTTP request
        print "417 Expectation Failed\r\n\r\n";
        print $r->{error};
        exit;
    }

    my @all_param_names = $r->param();
    my $myparam = $r->param('myparam'); # first 'myparam' value
    my @myparam = $r->param('myparam'); # all 'myparam' values

    print $r->{GET}{'myarray[]'}[0];
    print $r->{GET}{myparam};       # without keep_all_values=>1
    print $r->{GET}{myparam}[0];    # with keep_all_values=>1

    $uploaded_file      = $r->{POST}{myfile};
    $uploaded_filename  = $r->{filename}{myfile};

    print $r->{cookie}{mycookie};

    print $r->{ENV}{HTTP_USER_AGENT};


=head1 DESCRIPTION

Parse CGI params (from %ENV and STDIN) and provide user with ease to use
hash (object) with all interesting data.

=head2 FEATURES

=over

=item * DoS protection

Maximum size of content in STDIN is B<always> limited.

=item * HTTP Basic authorization support

Provide CGI with remote user name and password.

=item * UTF8 support

Decode path, GET/POST/cookie names and values (except uploaded files content)
and uploaded file names from UTF8 to Unicode.

=item * Frontend web server support

Can take REMOTE_ADDR/REMOTE_PORT and "https" scheme from non-standard HTTP
headers (like X-Real-REMOTE-ADDR) which is usually set by nginx/lighttpd
frontends.

=item * HEAD/GET/POST/PUT/DELETE/… support

Params sent with POST or PUT method will be placed in C<< {POST} >>,
params for all other methods (including unknown) will be placed in C<< {GET} >>.

=back


=head1 INTERFACE 

=over

=item new( [\%opt] )

Parse CGI request from %ENV and STDIN.

Create new object, which contain all parsed data in public fields.
You can access/modify all fields of this object in any way.

If given, %opt may contain these fields:

=over

=item {frontend_prefix}

If there frontend web server used, then CGI executed on backend web server
will not be able to detect user's IP/port and is HTTPS used in usual way,
because CGI "user" now isn't real user, but frontend web server instead.

In this case usual environment variables REMOTE_ADDR and REMOTE_PORT will
contain frontend web server's address, and variable HTTPS will not exists
(because frontend will not use https to connect to backend even if user
connects to frontend using https).

Frontend can be configured to send real user's IP/port/https in custom
HTTP headers (like X-Real-REMOTE_ADDR, X-Real-REMOTE_PORT, X-Real-HTTPS).
For example, nginx configuration may looks like:

    server {
        listen *:80;
        ...
        proxy_set_header    X-Real-REMOTE_ADDR      $remote_addr;
        proxy_set_header    X-Real-REMOTE_PORT      $remote_port;
        proxy_set_header    X-Real-HTTPS            "";
    }
    server {
        listen *:443;
        ...
        proxy_set_header    X-Real-REMOTE_ADDR      $remote_addr;
        proxy_set_header    X-Real-REMOTE_PORT      $remote_port;
        proxy_set_header    X-Real-HTTPS            on;
    }

If you can guarantee only frontend is able to connect to backend, then you can
safely trust these X-Real-* headers. In this case you can set
C<< frontend_prefix => 'X-Real-' >> and new() will parse headers with this
prefix instead of standard REMOTE_ADDR, REMOTE_PORT and HTTPS variables.

=item {max_post}

To protect against DoS attack, size of POST/PUT request is B<always> limited.
Default limit is 1 MB. You can change it using C<< {max_post} >> option
(value in bytes).

=item {post_with_get}

Sometimes POST/PUT request sent to url which also contain some parameters
(after '?'). By default these parameters will be ignored, and only
parameters sent in HTTP request body (STDIN) will be parsed (to C<< {POST} >>).
If you want to additionally parse parameters from url you should set
C<< post_with_get => 1 >> option (these parameters will be parsed to
C<< {GET} >> and not mixed with parameters in C<< {POST} >>).

=item {keep_all_values}

By default only parameters which names ending with '[]' are allowed to have
more than one value. These parameters stored in fields
C<< {GET}, {POST}, {filename} and {mimetype} >> as ARRAYREF, while all other
parameters stored as SCALAR (only first value for these parameters is stored).
If you want to allow more than one value in all parameters you should set
C<< keep_all_values => 1 >> option, and all parameters will be stored as ARRAYREF.

=item {raw}

By default we suppose request send either in UTF8 (or ASCII) encoding.
Request path, GET/POST/cookie names and values (except uploaded files content)
and uploaded file names will be decoded from UTF8 to Unicode.

If you need to handle requests in other encodings, you should disable
automatic decoding from UTF8 using C<< raw => 1 >> option and decode
all these things manually.

=back

Created object will contain these fields:

=over

=item {scheme}

'http' or 'https'.

You may need to use C<< frontend_prefix >> option if you've frontend and
backend web servers to reliably detect 'https' scheme.

=item {host}

=item {port}

Host name and port for requested url.

=item {path}

Path from url, always begin with '/'.

Will be decoded from UTF8 to Unicode unless new() called with option
C<< raw=>1 >>.

=item {GET}

=item {POST}

Will contain request parameters. For request methods POST and PUT
parameters will be stored in C<< {POST} >> (if option C<< post_with_get => 1 >>
used then parameters from url will be additionally stored in C<< {GET >>),
for all other methods (HEAD/GET/DELETE/etc.) parameters will be stored
in C<< {GET} >>.

These fields will contain HASHREF with parameter names, which value will depend
on C<< keep_all_values >> option. By default, value for parameters which
names ending with '[]' will be ARRAYREF, and for all other SCALAR (only first
value for these parameters will be stored if more than one available).

Example: request "GET http://example.com/some.cgi?a=5&a=6&b[]=7&b[]=8&c=9"
will be parsed to

    # by default:
    GET => {
        'a'     => 5,
        'b[]'   => [ 7, 8 ],
        'c'     => 9,
    },
    POST => {}

    # with option keep_all_values=>1:
    GET => {
        'a'     => [ 5, 6 ],
        'b[]'   => [ 7, 8 ],
        'c'     => [ 9 ],
    },
    POST => {}

Parameter names and values (except file content) be decoded from UTF8 to
Unicode unless new() called with option C<< raw=>1 >>.

=item {filename}

=item {mimetype}

When C<< <INPUT TYPE="FILE"> >> used to upload files, browser will send
uploaded file name and MIME type in addition to file contents.
These values will be available in fields C<< {filename} >> and C<< {mimetype} >>,
which have same format as C<< {POST} >> field.

Example: submitted form contain parameter "a" with value "5" and parameter
"image" with value of file "C:\Images\some.gif" will be parsed to:

    GET => {},
    POST => {
        a       => 5,
        image   => '...binary image data...',
    },
    filename => {
        a       => undef,
        image   => 'C:\Images\some.gif',
    }
    mimetype => {
        a       => undef,
        image   => 'image/gif',
    }

Parameter names and file names will be decoded from UTF8 to Unicode unless
new() called with option C<< raw=>1 >>.

=item {cookie}

Will contain hash with cookie names and values. Example:

    cookie => {
        some_cookie     => 'some value',
        other_cookie    => 'other value',
    }

Cookie names and values will be decoded from UTF8 to Unicode unless
new() called with option C<< raw=>1 >>.

=item {REMOTE_ADDR}

=item {REMOTE_PORT}

User's IP and port.

You may need to use C<< frontend_prefix >> option if you've frontend and
backend web servers.

=item {AUTH_TYPE}

=item {REMOTE_USER}

=item {REMOTE_PASS}

There two ways to use HTTP authentication:

1) Web server will check user login/pass, and will provide values for
C<< {AUTH_TYPE} >> and C<< {REMOTE_USER} >>. In this case C<< {REMOTE_PASS} >>
will contain undef().

2) Your CGI will manually check authentication. Only 'Basic' type of HTTP
authentication supported by this module. In this case C<< {AUTH_TYPE} >> will be
set to 'Basic', and C<< {REMOTE_USER} >> and C<< {REMOTE_PASS} >> will contain
login/pass sent by user, and your CGI should check is they correct.
To allow this type of manual authentication you may need to configure
C<.htaccess> to force Apache to send HTTP_AUTHORIZATION environment to your
CGI/FastCGI script:

    <Files "myscript.cgi">
        RewriteEngine On
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]
    </Files>

=item {ENV}

=item {STDIN}

These fields will contain copy of %ENV and STDIN contents as they was seen
by new(). This is useful to access values in %ENV which doesn't included in
other fields of this object, and to manually parse non-standard data in STDIN.

=item {error}

This field will contain empty string if HTTP request was formed correctly, or
error message if HTTP request was formed incorrectly. Possible errors are:

    failed to parse HTTP_AUTHORIZATION
    POST body too large
    POST body incomplete

=back

Return created CGI::Easy::Request object.


=item param( )

=item param( $name )

This method shouldn't be called if you modified format of C<< {GET} >> or
C<< {POST} >> fields.

When called without parameter will return ARRAY with all CGI parameter
names, both GET and POST parameter names will be joined.

When called with parameter name will return value of this parameter (from
POST parameter if it exists, or from GET if it doesn't exist in POST parameters).
All stored values (see C<< keep_all_values >> option) for this parameter
will be returned in ARRAY context, and only first value will be returned
in SCALAR context.


=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-CGI-Easy/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-CGI-Easy>

    git clone https://github.com/powerman/perl-CGI-Easy.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=CGI-Easy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/CGI-Easy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Easy>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=CGI-Easy>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/CGI-Easy>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009-2010 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
