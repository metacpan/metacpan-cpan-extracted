# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Apache::Wombat::Request;

=pod

=head1 NAME

Apache::Wombat::Request - Apache connector request class

=head1 SYNOPSIS

=head1 DESCRIPTION

Apache connector request class. Extends
B<Wombat::Connector::HttpRequestBase>. Overrides many superclass
methods to delegate to an underlying B<Apache::Request> instance.

=cut

use base qw(Wombat::Connector::HttpRequestBase);
use fields qw(apr);
use strict;
use warnings;

use Apache::Request ();
use Apache::Util ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Create and return an instance, initializing fields to default values.

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    return $self;
}

=pod

=head1 METHODS

=over

=item getAttribute($name)

Return the value of the named attribute from the B<Apache> pnotes table.

B<Parameters:>

=over

=item $name

the name of the attribute

=back

=cut

sub getAttribute {
    my $self = shift;
    my $name = shift;

    return $self->{apr}->pnotes($name);
}

=item getAttributeNames()

Return an array containing the names of the attributes available in
the B<Apache> pnotes table.

=cut

sub getAttributeNames {
    my $self = shift;

    my $pnotes = $self->{apr}->pnotes();
    my @names = grep { /::/ } keys %$pnotes;

    return wantarray ? @names : \@names;
}

=pod

=item removeAttribute($name)

Remove the named attribute from the B<Apache> pnotes table.

B<Parameters:>

=over

=item $name

the name of the attribute

=back

=cut

sub removeAttribute {
    my $self = shift;
    my $name = shift;

    $self->{apr}->unset($name);

    return 1;
}

=pod

=item setAttribute($name, $value)

Set the named attribute in the B<Apache> pnotes table.

B<Parameters:>

=over

=item $name

the name of the attribute

=item $value

the value to be set, a scalar or a reference

=back

=cut

sub setAttribute {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{apr}->pnotes($name, $value);

    return 1;
}

=item getAuthType()

Return the authentication type used for this Request.

=cut

sub getAuthType {
    my $self = shift;

    return $self->{apr}->connection()->auth_type();
}

=pod

=item setAuthType($type)

Set the authentication type used for this request.

B<Parameters:>

=over

=item $type

the authentication type, as defined in
C<Servlet::Http::HttpServletRequest>

=back

=cut

sub setAuthType {
    my $self = shift;
    my $type = shift;

    $self->{apr}->connection()->auth_type($type);

    return 1;
}

=pod

=item getDateHeader($name)

Return the value of the named header from the B<Apache> headers_in table
as the number of seconds since the epoch, or -1.

B<Parameters:>

=over

=item $name

the header name

=back

=cut

sub getDateHeader {
    my $self = shift;
    my $name = shift;

    my $secs;
    if (my $val = $self->getHeader($name)) {
        $secs = Apache::Util::parsedate($val);
    }

    return $secs || -1;
}

=pod

=item addHeader($name, $value)

Add a value for the named request header to the B<Apache> headers_in
table.

B<Parameters:>

=over

=item $name

the parameter name

=item $value

the parameter value, scalar

=back

=cut

sub addHeader
  {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{apr}->header_in($name => $value);

    return 1;
  }

=pod

=item getHeader($name)

Return the first value for the named request header from the Apache
headers_in table.

=cut

sub getHeader {
    my $self = shift;
    my $name = shift;

    return $self->getHeaders($name)->[0];
}

=pod

=item getHeaderNames()

Return the names of all the request headers from the B<Apache>
headers_in table.

=cut

sub getHeaderNames {
    my $self = shift;

    my @names = keys %{ $self->{apr}->headers_in() };

    return wantarray ? @names : \@names;
}

=pod

=item getHeaders($name)

Return the list of values for the named request header from the Apache
headers_in table.

B<Parameters:>

=over

=item $name

the header name

=back

=cut

sub getHeaders {
    my $self = shift;
    my $name = shift;

    my @vals = $self->{apr}->header_in($name);

    return wantarray ? @vals : \@vals;
}

=pod

=item clearHeaders()

Unset all request headers from the B<Apache> headers_in table.

=cut

sub clearHeaders {
    my $self = shift;

    $self->{apr}->headers_in()->clear();

    return 1;
}

=pod

=item getMethod()

Return the HTTP request method used for this Request.

=cut

sub getMethod {
    my $self = shift;

    return $self->{apr}->method();
}

=pod

=item setMethod($method)

Set the HTTP request method used for this Request.

B<Parameters:>

=over

=item $method

the request method

=back

=cut

sub setMethod {
    my $self = shift;
    my $method = shift;

    $self->{apr}->method();
}

=pod

=item getParameter($name)

Return the value of the named request parameter from the
B<Apache::Request> params structure. If more than one value is
defined, return only the first one.

B<Parameters:>

=over

=item $name

the name of the parameter

=back

=cut

sub getParameter {
    my $self = shift;
    my $name = shift;

    my @params = $self->{apr}->param($name);

    return $params[0];
}

=pod

=item getParameterNames()

Return an array containing the names of the parameters contained in
the B<Apache::Request> params structure.

=cut

sub getParameterNames {
    my $self = shift;

    my @names = $self->{apr}->param();

    return wantarray ? @names : \@names;
}

=pod

=item getParameterValues($name)

Return an array containing all of the values of the named request
parameter from the B<Apache::Request> params structure.

B<Parameters:>

=over

=item $name

the name of the parameter

=back

=cut

sub getParameterValues {
    my $self = shift;
    my $name = shift;

    my @vals = $self->{apr}->param($name);

    return wantarray ? @vals : \@vals;
}

=pod

=item addParameter($name, @values)

Add a named parameter with one or more values to the
B<Apache::Request> params table.

B<Parameters:>

=over

=item $name

the name of the parameter to add

=item @values

a list of one or more parameter values, scalar or C<undef>

=back

=cut

sub addParameter {
    my $self = shift;
    my $name = shift;

    $self->{apr}->param($name => \@_);

    return 1;
  }

=pod

=item clearParameters()

Clear the set of parameters from the B<Apache::Request> params table.

=cut

sub clearParameters {
    my $self = shift;

    for my $name ($self->getParameterNames()) {
        $self->{apr}->param($name => undef);
    }

    return 1;
}

=pod

=item getProtocol()

Return the name and version of the protocol used for the request.

=cut

sub getProtocol {
    my $self = shift;

    return $self->{apr}->protocol();
}

=pod

=item setProtocol($protocol)

Set the name and version of the protocol used for the request in the
form I<protocol/majorVersion.minorVersion>.

B<Parameters:>

=over

=item $protocol

the name and version of the protocol

=back

=cut

sub setProtocol {
    my $self = shift;
    my $protocol = shift;

    $self->{apr}->protocol($protocol);

    return 1;
}

=pod

=item getQueryString()

Return the query string for this Request.

=cut

sub getQueryString {
    my $self = shift;

    return $self->{apr}->args();
}

=pod

=item setQueryString($query)

Set the query string for this Request. This is normally called by the
Connector when it parses the request headers.

B<Parameters:>

=over

=item $query

the query string

=back

=cut

sub setQueryString {
    my $self = shift;
    my $query = shift;

    $self->{apr}->args();

    return 1;
}

=pod

=item getRemoteAddr()

Return the remote IP address of the client making this request.

=cut

sub getRemoteAddr {
    my $self = shift;

    return $self->{apr}->connection()->remote_ip();
}

=pod

=item setRemoteAddr($addr)

Set the remote IP address of the client making this request. This
value will be used to resolve the name of the remote host if necessary
(see C<getRemoteHost()>).

B<Parameters:>

=over

=item $addr

the remote IP address

=back

=cut

sub setRemoteAddr {
    my $self = shift;
    my $remote = shift;

    $self->{apr}->connection()->remote_ip($remote);

    return 1;
}

=pod

=item getRemoteHost()

Return the remote host name of the client making this request.

=cut

sub getRemoteHost {
    my $self = shift;

    return $self->{apr}->get_remote_host();
}

=pod

=item setRemoteHost($host)

Set the remote host name of the client making this request.

B<Parameters:>

=over

=item $host

the remote host name

=back

=cut

sub setRemoteHost {
    my $self = shift;
    my $host = shift;

    $self->{apr}->connection()->remote_host($host);

    return 1;
}

=pod

=item getRequestRec()

Return the Apache request record for this Request.

=cut

sub getRequestRec {
    my $self = shift;

    return $self->{apr};
}

=pod

=item setRequestRec($apr)

Set the Apache request record for this Request.

B<Parameters:>

=over

=item $apr

the B<Apache::Request> instance

=back

=cut

sub setRequestRec {
    my $self = shift;
    my $apr = shift;

    $self->{apr} = $apr;

    return 1;
}

=pod

=item getRequestURI()

Return the request URI for this Request.

=cut

sub getRequestURI {
    my $self = shift;

    return $self->{apr}->uri();
}

=pod

=item setRequestURI($uri)

Set the unparsed request URI for this Request. This is normally called
by the Connector when it parses the request headers.

B<Parameters:>

=over

=item $uri

the request URI

=back

=cut

sub setRequestURI {
    my $self = shift;
    my $uri = shift;

    $self->{apr}->uri($uri);

    return 1;
}

=pod

=item recycle()

Release all object references and initialize instances variables in
preparation for use or reuse of this object.

=cut

sub recycle {
    my $self = shift;

    $self->SUPER::recycle();

    $self->{apr} = undef;

    return 1;
}

1;
__END__

=pod

=back

=head1 SEE ALSO

L<Apache>,
L<Apache::Request>,
L<Apache::Table>,
L<Apache::Util>,
L<Wombat::Connector::HttpRequestBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
