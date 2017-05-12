package CGI::Apache2::Wrapper;
use strict;
use warnings;
use File::Basename;
use APR::Const -compile => qw(URI_UNP_OMITSITEPART
			      URI_UNP_OMITPATHINFO
			      URI_UNP_OMITQUERY);
our $VERSION = '0.215';
our $MOD_PERL;

sub new {
  my ($class, $r) = @_;
  unless (defined $r and ref($r) and ref($r) eq 'Apache2::RequestRec') {
    die qq{Must pass in an Apache2::RequestRec object \$r};
  }

  if ($ENV{USE_CGI_PM}) {
    require CGI;
    return CGI->new($r);
  }

  if (exists $ENV{MOD_PERL}) {
    if (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
      require Apache2::Response;
      require Apache2::RequestRec;
      require Apache2::RequestUtil;
      require Apache2::Connection;
      require Apache2::Access;
      require Apache2::URI;
      require Apache2::Log;
      require APR::URI;
      require APR::Pool;
      require Apache2::Request;
      require CGI::Apache2::Wrapper::Cookie;
      require CGI::Apache2::Wrapper::Upload;
      $MOD_PERL = 2;
    }
    else {
      die qq{mod_perl 2 required};
    }
  }
  else {
    die qq{Must be running under mod_perl};
  }

  my $self = {};
  bless $self, ref $class || $class;

  $self->r($r) unless $self->r;
  $self->c($r->connection) unless $self->c;
  $self->req(Apache2::Request->new($self->r)) unless $self->req;
  return $self;
}

sub r {
  my $self = shift;
  my $r = $self->{'.r'};
  $self->{'.r'} = shift if @_;
  return $r;
}

sub c {
  my $self = shift;
  my $c = $self->{'.c'};
  $self->{'.c'} = shift if @_;
  return $c;
}

sub req {
  my $self = shift;
  my $req = $self->{'.req'};
  $self->{'.req'} = shift if @_;
  return $req;
}

sub cookies {
  my $self = shift;
  my $cookies = $self->{'.cookies'};
  return $cookies if (defined $cookies);
  my %cookies = Apache2::Cookie->fetch($self->r);
  $self->{'.cookies'} = %cookies ? \%cookies : undef;
  return $self->{'.cookies'};
}

sub uploads {
  my ($self, $name) = @_;
  my $tmpfhs = $self->{'.tmpfhs'}->{$name};
  return $tmpfhs if (defined $tmpfhs and ref($tmpfhs) eq 'ARRAY');
  my @u = $self->req->upload($name);
  return unless @u;
  my $uploads = {};
  foreach my $u (@u) {
    next unless defined $u;
    my $tempname = $u->tempname();
    open(my $fh, '<', $tempname) or next;
    my $info = { %{$u->info()},
		 name => $name,
		 filename => $u->filename(),
		 size => $u->size(),
		 type => $u->type(),
	       };
    $uploads->{"$fh"} = {filehandle => $fh,
			 tempname => $tempname,
			 info => $info,
			};
    push @$tmpfhs, $fh;
  }
  $self->{'.uploads'} = $uploads;
  $self->{'.tmpfhs'}->{$name} = $tmpfhs;
  return $tmpfhs;
}

# Apache2::Request

sub param {
  return shift->req->param(@_);
}

# Apache2::Connection

sub remote_addr {
  return shift->c->remote_ip;
}

sub remote_host {
  return shift->c->remote_host;
}

# Apache2::Access

sub auth_type {
  return shift->r->auth_type;
}

sub remote_ident {
  return shift->r->get_remote_logname;
}

# Apache2::RequestUtil

sub remote_user {
  return shift->r->user;
}

sub user_name {
  my $self = shift;
  return ($self->remote_ident || $self->remote_user);
}

sub server_name {
  return shift->r->get_server_name;
}

sub server_port {
  return shift->r->get_server_port;
}

# Apache2::RequestRec

sub header {
  my $self = shift;
  my $header_extra;
  if (@_) {
    if (scalar @_ == 1) {
      $header_extra = shift;
    }
    else {
      my %args = @_;
      $header_extra = \%args;
    }
  }
  my $r = $self->r;
  unless (defined $header_extra and ref($header_extra) eq 'HASH') {
    $r->content_type('text/html');
    return '';
  }
  my $content_type = delete $header_extra->{'Content-Type'} || 'text/html';
  $r->content_type($content_type);
  foreach my $key (keys %$header_extra) {
    if ($key =~ /Set-Cookie/i) {
      my $cookie = $header_extra->{$key};
      if ($cookie) {
	my(@cookie) = ref($cookie) && ref($cookie) eq 'ARRAY' ? 
	  @{$cookie} : $cookie;
	foreach my $c (@cookie) {
	  my $cs = (UNIVERSAL::isa($c,'CGI::Cookie') or
		    UNIVERSAL::isa($c, 'CGI::Apache2::Wrapper::Cookie') or
		    UNIVERSAL::isa($c, 'Apache2::Cookie')) ? 
			$c->as_string : $c;
	  $r->err_headers_out->add($key => $cs);
	}
      }
    }
    else {
      $r->err_headers_out->add($key => $header_extra->{$key});
    }
  }
  return '';
}

sub query_string {
  return shift->r->args;
}

sub server_protocol {
  return shift->r->protocol;
}

sub request_method {
  return shift->r->method;
}

sub content_type {
  return shift->r->content_type;
}

sub path_info {
  return shift->r->path_info;
}

sub redirect {
  return shift->r->headers_out->set(Location => @_);
}

sub status {
  return shift->r->status(@_);
}

# Apache2::URI

sub url {
  my ($self, %args) = @_;
  my $r = $self->r;
  my $url = $r->construct_url;
  if (my $args = $r->args) {
    $url .= '?' . $args;
  }
  my $path_info = $r->path_info;
  if ($path_info eq '/') {
    $path_info = undef;
  }
  if ($path_info) {
    $path_info = quotemeta($path_info);
  }

  my $parsed = APR::URI->parse($r->pool, $url);
  my %opts;
  foreach my $key(keys %args) {
    if ($key =~ m/^-/) {
      $key =~ s/^-//;
      $opts{$key} = $args{"-$key"};
    }
    else {
      $opts{$key} = $args{$key};
    }
  }

  $opts{query} = 1 if $opts{query_string};
  $opts{path} = 1 if $opts{path_info};

  my $rv = '';
 SWITCH: {
    ( (scalar keys %args < 1) or $opts{full} ) and do {
      $rv = $parsed->unparse(APR::Const::URI_UNP_OMITQUERY);
      if ($path_info) {
	$rv =~ s/$path_info//;
      }
      last SWITCH;
    };

    ($opts{base}) and do {
      $rv = $parsed->unparse(APR::Const::URI_UNP_OMITPATHINFO);
      last SWITCH;
    };

    ($opts{absolute}) and do {
      $rv = $parsed->unparse(APR::Const::URI_UNP_OMITSITEPART | 
			     APR::Const::URI_UNP_OMITQUERY);
      if ($path_info) {
	$rv =~ s/$path_info//;
      }
      last SWITCH;
    };

    ($opts{path}) and do {
      $rv = $parsed->unparse(APR::Const::URI_UNP_OMITQUERY);
      last SWITCH;
    };

    ($opts{relative}) and do {
      if (my $file = $r->filename) {
	$rv = basename($file);
      }
      else {
	$rv = $parsed->unparse(APR::Const::URI_UNP_OMITQUERY);
	if ($path_info) {
	  $rv =~ s/$path_info//;
	}
	$rv =~ s{^/}{};
      }
      last SWITCH;
    };
    $opts{query} and do {
      last SWITCH;
    };

    die qq{Unknown option passed to url};
  }

  unless ($rv) {
    $rv = $parsed->unparse(APR::Const::URI_UNP_OMITQUERY);
    if ($path_info) {
      $rv =~ s/$path_info//;
    }
  }
  if ($opts{query}) {
    $rv .= '?' . $self->query_string;
  }

  return $rv;
}

sub self_url {
  return shift->url('-path_info' => 1, '-query' => 1);
}

# Apache2::Cookie

sub cookie {
  my $self = shift;
  my ($name, $value, %args);
  if (@_) {
    if (scalar @_ == 1) {
      $name = shift;
    }
    else {
      %args = @_;
    }
  }

  if (%args and not $name) {
    ($name, $value) = ( ($args{'-name'} || $args{name} ),
			($args{'-value'} || $args{value} ));
  }
  unless (defined($value)) {
    my $cookies = $self->cookies;
    return () unless $cookies;
    return keys %{$cookies} unless $name;
    return () unless $cookies->{$name};
    return $cookies->{$name}->value 
      if defined($name) && $name ne '';
  }
  return undef unless defined($name) && $name ne '';	# this is an error
  my $cookie = CGI::Apache2::Wrapper::Cookie->new($self->r, %args);
  return $cookie;
}

# Apache2::Upload

sub upload {
  my ($self, $name) = @_;
  return unless $name;
  my $tmpfhs = $self->uploads($name);
  return unless (defined $tmpfhs and ref($tmpfhs) eq 'ARRAY');
  return wantarray ? @$tmpfhs : $tmpfhs->[0];
}

sub tmpFileName {
  my ($self, $fh) = @_;
  return unless (defined $fh and ref($fh) eq 'GLOB');
  my $uploads = $self->{'.uploads'};
  return unless (defined $uploads and ref($uploads) eq 'HASH');
  return (defined $uploads->{"$fh"} and 
	  defined $uploads->{"$fh"}->{tempname} ) ?
	    $uploads->{"$fh"}->{tempname} : undef;
}

sub uploadInfo {
  my ($self, $fh) = @_;
  return unless (defined $fh and ref($fh) eq 'GLOB');
  my $uploads = $self->{'.uploads'};
  return unless (defined $uploads and ref($uploads) eq 'HASH');
  return (defined $uploads->{"$fh"} and 
	  defined $uploads->{"$fh"}->{info} ) ?
	    $uploads->{"$fh"}->{info} : undef;
}

1;

__END__

=head1 NAME

CGI::Apache2::Wrapper - CGI.pm-compatible methods via mod_perl

=head1 SYNOPSIS

  sub handler {
    my $r = shift;
    my $cgi = CGI::Apache2::Wrapper->new($r);
    my $foo = $cgi->param("foo");
    my $header = {'Content-Type' => 'text/plain; charset=utf-8',
		  'X-err_header_out' => 'err_headers_out',
		 };
    $cgi->header($header);
    $r->print("You passed in $foo\n");
    return Apache2::Const::OK;
  }

=head1 DESCRIPTION

Certain modules, such as L<CGI::Ajax> and
L<JavaScript::Autocomplete::Backend>,
require a minimal L<CGI.pm>-compatible module to provide certain methods,
such as I<param()> to fetch parameters. The standard module to
do this is of course L<CGI.pm>; however, especially in a mod_perl
environment, there may be concerns with the resultant memory footprint.
This module provides various CGI.pm-compatible methods via
L<mod_perl2> and L<librapreq2>, and as such, it may be a viable
alternative in a mod_perl scenario.

Note that this module is I<not> a drop-in replacement for
L<CGI.pm>, as only a select few methods that naturally arise
in mod_perl2 and libapreq2 are provided. As well as providing
CGI.pm-compatible methods to other modules, one of the
main intents here is to assist development of porting 
CGI applications over to mod_perl2 and libapreq2 and/or
for use in writing applications
that are to be used in either a cgi or mod_perl environment. However,
for applications that are intended only for mod_perl, it is recommended
that the native interface to mod_perl2 and libapreq2 ultimately
be used, as this module will add some overhead.

=head1 Methods

Methods are called via the object created as

  my $cgi = CGI::Apache2::Wrapper->new($r);

The L<Apache2::RequestRec> object I<$r> must be
passed in as an argument.

Methods available can be grouped according to what
mod_perl2/libapreq2 modules provide them:

=head2 Apache2::RequestRec

=over

=item * $cgi-E<gt>header($header);

In a mod_perl environment, this sets the headers, whereas
in a CGI environment, this returns a string containing the
headers to be printed out. If no argument is given to
I<header()>, only the I<Content-Type> is set, which by
default is I<text/html>. If a hash reference I<$header> is
passed to I<header>, such as

  my $header = {'Content-Type' => 'text/plain; charset=utf-8',
	        'X-err_header_out' => 'err_headers_out',
	       };

these will be used as the headers.

=item * $qs = $cgi-E<gt>query_string();

This retrieves the unprocessed query string.

=item * $sp = $cgi-E<gt>server_protocol();

This returns the protocol of the client, such as I<HTTP/1.0>
or I<HTTP/1.1>.

=item * $rm = $cgi-E<gt>request_method();

This returns the method used to form the request, such as
I<POST>, I<GET> or I<HEAD>.

=item * $ct = $cgi-E<gt>content_type();

This returns the HTTP response Content-type header value.

=item * $pi = $cgi-E<gt>path_info();

Returns additional path information from the 
URL. For example, for a handler specified through a
E<lt>Location /some/location E<gt> directive,
fetching I</some/location/additional/stuff>
will result in I<path_info()> returning I</additional/stuff>.

=item * $cgi-E<gt>redirect($url);

This redirects the client to the specified URL. For a
L<ModPerl::Registry> script, I<$cgi->status(Apache2::Const::REDIRECT);>
should also be called.

=item * $cgi-E<gt>status(Apache2::Const::REDIRECT);

This can be used to set the status field, typically in the
context of a I<redirect> for a L<ModPerl::Registry> script.
Handlers should never manipulate the status field directly.

=back

=head2 Apache2::RequestUtil

=over 

=item * $ru = $cgi-E<gt>remote_user();

This returns the authorization name used for user verification.

=item * $un = $cgi-E<gt>user_name();

Attempts to return the remote user's name.

=item * $sn = $cgi-E<gt>server_name();

This returns the name of the server, 
which is usually the machine's host name.

=item * $sp = $cgi-E<gt>server_port();

This returns the port that the server is listening on.

=back

=head2 Apache2::Access

=over

=item * $at = $cgi-E<gt>auth_type();

This returns the authorization/verification
method in use, if any.

=item * $ri = $cgi-E<gt>remote_ident();

This returns the identity of the remote user
if the host is running identd.

=back

=head2 Apache2::Connection

=over

=item * $ra = $cgi-E<gt>remote_addr();

This returns the remote IP address.

=item * $rh = $cgi-E<gt>remote_host();

This returns either the remote host name 
or the IP address, if the former is unavailable.

=back

=head2 Apache2::Request

=over

=item * $value = $cgi-E<gt>param("foo");

This fetches the value of the named parameter. If no argument
is given to I<param()>, a list of all parameter names is returned.

=back

=head2 Apache2::URI

=over

=item * my $url = $cgi-E<gt>url(%opts);

This returns the url in a variety of formats compatible with L<CGI>.
For example, suppose that the handler is in a location

   <Location /TestCGI>
      SetHandler modperl
      PerlResponseHandler My::Handler
   </Location>

on port 8529 and the request 
I<http://localhost:8529/TestCGI/extra/path/info?opening=hello> is made.
The following options for %opts are recognized:

=over

=item * no options

Called without any arguments, this returns the full
form of the URL, including host name and port number:
I<http://localhost:8529/TestCGI>

=item * -absolute =E<gt> 1

This produces an absolute url: I</TestCGI>

=item * -relative =E<gt> 1

This produces an relative url: I<TestCGI>

=item * -full =E<gt> 1

This produces a full url: I<http://localhost:8529/TestCGI>

=item * -path =E<gt> 1 (or -path_info =E<gt> 1)

This appends the additional path information to the url:
I<http://localhost:8529/TestCGI/extra/path/info>

=item * -query =E<gt> 1 (or -query_string =E<gt> 1)

This appends the query string to the url:
I<http://localhost:8529/TestCGI?opening=hello;closing=goodbye>

=item * -base =E<gt> 1

This generates just the protocol and net location:
I<http://localhost:8529>

=back

Specifying the options I<-path =E<gt> 1> and I<-query =E<gt> 1>
will lead to the complete url:
I<http://localhost:8529/TestCGI/extra/path/info?opening=hello;closing=goodbye>.

=item * my $url = $cgi-E<gt>self_url;

This generates the complete url, and is a shortcut for
I<my $url = $cgi-E<gt>url(-query =E<gt> 1, -path =E<gt> 1);>. Using the
example described in the I<url> options, this would lead to
I<http://localhost:8529/TestCGI/extra/path/info?opening=hello;closing=goodbye>.

=back

=head2 Apache2::Cookie

A new cookie can be created as

 my $c = $cgi->cookie(-name    =>  'foo',
                      -value   =>  'bar',
                      -expires =>  '+3M',
                      -domain  =>  '.capricorn.com',
                      -path    =>  '/cgi-bin/database',
                      -secure  =>  1
                     );

which is an object of the L<CGI::Apache2::Wrapper::Cookie>
class. The arguments accepted are

=over

=item * I<-name>

This is the name of the cookie (required)

=item * I<-value>

This is the value associated with the cookie (required)

=item * I<-expires>

This accepts any of the relative or absolute date formats 
recognized by CGI.pm, for example "+3M" for three months in the future.
See L<CGI.pm> for details.

=item * I<-domain>

This points to a domain name or to a fully qualified
host name. If not specified, the cookie will be returned only
to the Web server that created it.

=item * I<-path>

This points to a partial URL on the current server.
The cookie will be returned to all URLs beginning with 
the specified path. If not specified, it defaults to '/',
which returns the cookie to all pages at your site.

=item * I<-secure>

If set to a true value, this instructs the 
browser to return the cookie only when a cryptographic protocol is in use.

=back

A value of an existing cookie can be retrieved by
calling I<cookie> without the I<value> parameter:

   my $value = $cgi->cookie(-name => 'fred');

A list of all cookie names can be obtained by calling
I<cookie> without any arguments:

  my @names = $cgi->cookie();

See also L<CGI::Apache2::Wrapper::Cookie> for a
L<CGI::Cookie>-compatible interface to cookies.

=head2 Apache2::Upload

Uploads can be handled with the I<upload> method:

   my $fh = $cgi->upload('filename');

which returns a file handle that can be used to access the
uploaded file. If there are multiple upload fields, calling
I<upload> in a list context:

  my @fhs = $cgi->upload('filename');

will return an array of filehandles. There are two
helper methods available for uploads:

=over

=item * my $tmpfile = $cgi-E<gt>tmpFileName($fh);

This returns the name of the temporary file associated with
the I<$fh> fielhandle returned from I<upload>.

=item * my $info = $cgi-E<gt>uploadInfo($fh);

This returns a hash reference containing some information about
the uploaded file associated with the I<$fh> filehandle
returned from I<upload>. The keys of this hash typically include:

=over

=item * Content-Type

The content type, such as I<text/plain>, associated with this upload.

=item * Content-Disposition

This typically is a string such as
I<form-data; name="HTTPUPLOAD"; filename="data.txt">.

=item * size

This is the size of the uploaded file.

=item * name

This is the name of the HTML form element which generated the upload.

=item * filename

The (client-side) filename as submitted in the HTML form.
Note that some agents will submit the file's full pathname,
while others may submit just the basename.

=item * type

This is the MIME type of the upload.

=back

=back

=head2 Helpers

=over

=item * my $r = $cgi-E<gt>r;

This returns the I<Apache2::RequestRec> object I<$r>
passed into the I<new()> method.

=item * my $req = $cgi-E<gt>req;

This returns the I<Apache2::Request> object I<$req>, which
provides the I<param()> method to fetch form parameters.

=back

=head1 SEE ALSO

L<CGI>, L<Apache2::RequestRec>, and L<Apache2::Request>.

Development of this package takes place at
L<http://cpan-search.svn.sourceforge.net/viewvc/cpan-search/CGI-Apache2-Wrapper/>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc CGI::Apache2::Wrapper

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Apache2-Wrapper>

=item * CPAN::Forum: Discussion forum

L<http:///www.cpanforum.com/dist/CGI-Apache2-Wrapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Apache2-Wrapper>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Apache2-Wrapper>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Apache2-Wrapper>

=item * UWinnipeg CPAN Search

L<http://cpan.uwinnipeg.ca/dist/CGI-Apache2-Wrapper>

=back

=head1 ENVIRONMENT VARIABLES

If the I<USE_CGI_PM> environment variable is set, the
I<new> method will return a L<CGI.pm> object.

=head1 BUGS

Although the methods provided here have a natural correspondence
with the associated methods of CGI.pm, there may be subtle
differences present.

Please report any bugs and feature requests to the author or
through CPAN's request tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Apache2-Wrapper>.

=head1 COPYRIGHT

This software is copyright 2007 by Randy Kobes
E<lt>r.kobes@uwinnipeg.caE<gt>. Use and
redistribution are under the same terms as Perl itself;
see L<http://www.perl.com/pub/a/language/misc/Artistic.html>.

=cut
