# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Apache::Wombat::Response;

=pod

=head1 NAME

Apache::Wombat::Response - Apache connector response class

=head1 SYNOPSIS

=head1 DESCRIPTION

Apache connector response class. Extends
B<Wombat::Connector::HttpResponseBase>. Overrides many superclass
methods to delegate to an underlying B<Apache::Request> instance.

=cut

use base qw(Wombat::Connector::HttpResponseBase);
use fields qw(apr);
use strict;
use warnings;

use Apache::Util ();

=pod

=head1 CONSTRUCTOR

=over

=item new($apr)

Create and return an instance, initializing fields to default values.

B<Parameters:>

=over

=item $apr

a B<Apache::Request> instance representing the Apache request record

=back

=back

=cut

sub new {
    my $self = shift;
    my $apr = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(@_);

    return $self;
}

=pod

=head1 METHODS

=over

=item addDateHeader($name, $date)

Add a date value for the named response header to the B<Apache>
headers_out table.

B<Parameters:>

=over

=item $name

the name of the response header

=item $date

the additional header value, as the number of seconds since the epoch

=back

=cut

sub addDateHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    my $str = Apache::Util::ht_time($value);
    $self->addHeader($name, $str || $value);

    return 1;
}

=pod

=item setDateHeader($name, $date)

Set the date value for the named response header in the B<Apache>
headers_out table.

B<Parameters:>

=over

=item $name

the name of the header

=item $date

the header value, as the number of seconds since the epoch

=back

=cut

sub setDateHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    my $str = Apache::Util::ht_time($value);
    $self->setHeader($name, $str || $value);

    return 1;
}

=pod

=item addHeader($name, $value)

Add a value for the named response header to the B<Apache> headers_out
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

    $self->{apr}->header_out($name => $value);

    return 1;
  }

=pod

=item getHeader($name)

Return the first value for the named response header from the Apache
headers_out table.

=cut

sub getHeader {
    my $self = shift;
    my $name = shift;

    return $self->getHeaders($name)->[0];
}

=pod

=item getHeaderNames()

Return the names of all the response headers from the B<Apache>
headers_out table.

=cut

sub getHeaderNames {
    my $self = shift;

    my @names = keys %{ $self->{apr}->headers_out() };

    return wantarray ? @names : \@names;
}

=pod

=item getHeaders($name)

Return the list of values for the named response header from the
Apache headers_out table.

B<Parameters:>

=over

=item $name

the header name

=back

=cut

sub getHeaders {
    my $self = shift;
    my $name = shift;

    my @vals = $self->{apr}->header_out($name);

    return wantarray ? @vals : \@vals;
}

=item setHeader($name, $value)

Set the value for the named response header in the B<Apache>
headers_out table.

B<Parameters:>

=over

=item $name

the name of the response header

=item $value

the header value

=back

=cut

sub setHeader {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    return 1 if $self->isCommitted();
    return 1 if $self->isIncluded();

    my $match = lc $name;
    if ($match eq 'content-type') {
        $self->setContentLength($value);
    } elsif ($match eq 'content-length') {
        $self->setContentType($value);
    } else {
        $self->{apr}->header_out($name => $value);
    }

    return 1;
}

=pod

=item clearHeaders()

Unset all response headers from the B<Apache> headers_out table.

=cut

sub clearHeaders {
    my $self = shift;

    $self->{apr}->headers_out()->clear();

    return 1;
}

=pod

=item getStatus()

Return the HTTP status code for this Response.

=cut

sub getStatus {
    my $self = shift;

    return $self->{apr}->status();
}

=pod

=item setStatus($code)

Set the status code for this response.

B<Parameters:>

=over

=item $code

the HTTP status code

=back

=cut

sub setStatus {
    my $self = shift;
    my $status = shift;

    return 1 if $self->isIncluded();

    $self->{apr}->status($status);
    $self->{message} = $self->getStatusMessage($status);

    return 1;
}

=pod

=back

=head1 PACKAGE METHODS

=over

=item sendHeaders()

Direct Apache API to send a response header, committing the
response. Usually doesn't need to be called by other classes, but will
be called the first time the buffer is flushed.

=cut

sub sendHeaders {
    my $self = shift;
    my $request = $self->getRequest();

    # set up status line
    if ($self->{message}) {
        $self->{apr}->status_line(join(' ', $self->getStatus(),
                                       $self->{message}));
    }

    # set up headers
    if ($self->{contentType}) {
        $self->{apr}->content_type($self->{contentType});
    }
    if ($self->{contentLength} >= 0) {
        $self->{apr}->header_out('Content-Length' => $self->{contentLength});
    }

    # add session id cookie if necessary
    my $sessionCookie = Wombat::Util::RequestUtil->makeSessionCookie($request);
    $self->addCookie($sessionCookie) if $sessionCookie;

    # set up cookies
    for my $cookie ($self->getCookies()) {
        my $name = Wombat::Util::CookieTools->getCookieHeaderName($cookie);
        my $value = Wombat::Util::CookieTools->getCookieHeaderValue($cookie);
        $self->addHeader($name, $value);
    }

    $self->{apr}->send_http_header();

#    Wombat::Globals::DEBUG &&
#        $self->debug("sent headers");

    unless ($self->{committed}) {
        $self->{committed} = 1;
#        Wombat::Globals::DEBUG &&
#            $self->debug("committed response");
    }

    return 1;
}

# have to totally override flushBuffer cos the superclass calls
# write() on $self->{handle}, which doesn't exist on Apache::Request;
# use print() instead.

sub flushBuffer {
    my $self = shift;

    $self->sendHeaders() unless $self->isCommitted();

    if ($self->{bufferCount}) {
        eval {
            $self->{handle}->print($self->{buffer});
        };
        if ($@) {
            my $msg = "flushBuffer: problem writing to output handle";
            Servlet::Util::IOException->new($msg);
        }

        undef $self->{buffer};
        $self->{bufferCount} = 0;

        unless ($self->{committed}) {
            $self->{committed} = 1;

#            Wombat::Globals::DEBUG &&
#                $self->debug("committed response");
        }
    }

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
L<Wombat::Connector::HttpResponseBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
