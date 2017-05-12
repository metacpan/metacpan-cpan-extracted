package CGI::Apache2::Wrapper::Cookie;
use strict;
use warnings;

our $VERSION = '0.215';
our $MOD_PERL;
use overload '""' => sub { shift->as_string() }, fallback => 1;

sub new {
  my ($class, $r, %args) = @_;
  unless (defined $r and ref($r) and ref($r) eq 'Apache2::RequestRec') {
    die qq{Must pass in an Apache2::RequestRec object \$r};
  }
  if ($ENV{USE_CGI_PM}) {
    require CGI::Cookie;
    return CGI::Cookie->new($r);
  }
  if (exists $ENV{MOD_PERL}) {
    if (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
      require Apache2::RequestRec;
      require Apache2::Request;
      require Apache2::Cookie;
      $MOD_PERL = 2;
    }
    else {
      die qq{mod_perl 2 required};
    }
  }
  else {
    die qq{Must be running under mod_perl};
  }
  unless ($args{path} || $args{'-path'}) {
    $args{path} = '/';
  }
  my $cookie = Apache2::Cookie->new($r, %args);
  die qq{Creation of Apache2::Cookie failed}
    unless ($cookie and ref($cookie) eq 'Apache2::Cookie');
  my $self = {};
  bless $self, ref $class || $class;

  $self->r($r) unless $self->r;
  $self->{cookie} = $cookie;
  return $self;
}

sub r {
  my $self = shift;
  my $r = $self->{'.r'};
  $self->{'.r'} = shift if @_;
  return $r;
}

sub fetch {
  my ($class, $r) = @_;
  unless (defined $r and ref($r) and ref($r) eq 'Apache2::RequestRec') {
    die qq{Must pass in an Apache2::RequestRec object \$r};
  }
  if ($ENV{USE_CGI_PM}) {
    require CGI::Cookie;
    return CGI::Cookie->fetch($r);
  }
  if (exists $ENV{MOD_PERL}) {
    if (exists $ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
      require Apache2::RequestRec;
      require Apache2::Request;
      require Apache2::Cookie;
      $MOD_PERL = 2;
    }
    else {
      die qq{mod_perl 2 required};
    }
  }
  else {
    die qq{Must be running under mod_perl};
  }
  my %cookies = Apache2::Cookie->fetch($r);
  return wantarray ? %cookies : \%cookies;
}

sub cookie {
  my $self = shift;
  return $self->{cookie};
}

sub name {
  my $self = shift;
  die qq{Apache2::Cookie doesn't support setting "name"} if @_;
  return $self->cookie->name;
}

sub value {
  my $self = shift;
  die qq{Apache2::Cookie doesn't support setting "value"} if @_;
  return $self->cookie->value;
}

sub path {
  my ($self, $x) = @_;
  if (defined $x) {
    $self->cookie->path($x);
    return $x;
  }
  else {
    return $self->cookie->path;
  }
}

sub domain {
  my ($self, $x) = @_;
  if (defined $x) {
    $self->cookie->domain($x);
    return $x;
  }
  else {
    return $self->cookie->domain;
  }
}

sub secure {
  my ($self, $x) = @_;
  if (defined $x) {
    $self->cookie->secure($x);
    return $x;
  }
  else {
    return $self->cookie->secure;
  }
}

sub expires {
  my ($self, $x) = @_;
  die qq{Apache2::Cookie currently demands an argument to "expires"}
    unless (defined $x);
  $self->cookie->expires($x);
}

sub httponly {
  die qq{Apache2::Cookie currently doesn't support "httponly"};
}

sub as_string {
  return shift->cookie->as_string;
}

sub bake {
  my $self = shift;
  return $self->cookie->bake($self->r);
}

1;

__END__

=head1 NAME

CGI::Apache2::Wrapper::Cookie - cookies via libapreq2

=head1 SYNOPSIS

 use CGI::Apache2::Wrapper::Cookie;
 
 sub handler {
    my $r = shift;
    # create a new Cookie and add it to the headers
    my $cookie = CGI::Apache2::Wrapper::Cookie->new($r,
                                                    -name=>'ID',
                                                    -value=>123456);
    $cookie->bake();
    # fetch existing cookies
    my %cookies = CGI::Apache2::Wrapper::Cookie->fetch($r);
    my $id = $cookies{'ID'}->value;
    return Apache2::Const::OK;
 }

=head1 DESCRIPTION

This module provides a wrapper around L<Apache2::Cookie>. Some
methods are overridden in order to provide a L<CGI::Cookie>-compatible
interface.

Cookies are created with the I<new> method:

 my $c = CGI::Apache2::Wrapper::Cookie->new($r,
                             -name    =>  'foo',
                             -value   =>  'bar',
                             -expires =>  '+3M',
                             -domain  =>  '.capricorn.com',
                             -path    =>  '/cgi-bin/database',
                             -secure  =>  1
                            );


with a mandatory first argument of the L<Apache2::RequestRec> object I<$r>.
The remaining arguments are

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

After creation, cookies can be sent to the browser in the appropriate
header by I<$c-E<gt>bake();>.

Existing cookies can be fetched with
I<%cookies = CGI::Apache2::Wrapper::Cookie-E<gt>fetch($r);>,
which requires a mandatory argument of the L<Apache2::RequestRec>
object I<$r>. In a scalar context, this returns a hash reference.
The keys of the hash are the values of the I<name> of the Cookie,
while the values are the corresponding I<CGI::Apache2::Wrapper::Cookie>
object.

=head1 Methods

Available methods are

=over

=item * I<new>

 my $c = CGI::Apache2::Wrapper::Cookie->new($r, %args);

This creates a new cookie. Mandatory arguments are the
L<Apache2::RequestRec> object I<$r>, as well as the I<name>
and I<value> specified in I<%args>.

=item * I<name>

 my $name = $c->name();

This gets the cookie name.

=item * I<value>

 my $value = $c->value();

This gets the cookie value.

=item * I<domain>

 my $domain = $c->domain();
 my $new_domain = $c->domain('.pie-shop.com');

This gets or sets the domain of the cookie.

=item * I<path>

 my $path = $c->path();
 my $new_path = $c->path('/basket/');

This gets or sets the path of the cookie.

=item * I<secure>

 my $secure = $c->secure();
 my $new_secure_setting = $c->secure(1);

This gets or sets the security setting of the cookie.

=item * I<expires>

  $c->expires('+3M');

This sets the expires setting of the cookie. In the current
behaviour of L<Apache2::Cookie>, this requires a mandatory
setting, and doesn't return anything.

=item * I<bake>

 $c->bake();

This will send the cookie to the browser by adding the stringified
version of the cookie to the I<Set-Cookie> field of the HTTP
header.

=item * I<fetch>

 %cookies = CGI::Apache2::Wrapper::Cookie->fetch($r);

This fetches existing cookies, and
requires a mandatory argument of the L<Apache2::RequestRec>
object I<$r>. In a scalar context, this returns a hash reference.
The keys of the hash are the values of the I<name> of the Cookie,
while the values are the corresponding I<CGI::Apache2::Wrapper::Cookie>
object.

=back

=head1 SEE ALSO

L<CGI>, L<CGI::Cookie>,
L<Apache2::Cookie>, and L<CGI::Apache2::Wrapper>.

Development of this package takes place at
L<http://cpan-search.svn.sourceforge.net/viewvc/cpan-search/CGI-Apache2-Wrapper/>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc CGI::Apache2::Wrapper::Cookie

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
I<new> method will return a L<CGI::Cookie> object,
while I<fetch> will return the corresponding
cookies using L<CGI::Cookie>.

=head1 COPYRIGHT

This software is copyright 2007 by Randy Kobes
E<lt>r.kobes@uwinnipeg.caE<gt>. Use and
redistribution are under the same terms as Perl itself;
see L<http://www.perl.com/pub/a/language/misc/Artistic.html>.

=cut
