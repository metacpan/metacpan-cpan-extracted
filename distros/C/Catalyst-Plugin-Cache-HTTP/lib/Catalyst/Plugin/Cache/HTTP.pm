package Catalyst::Plugin::Cache::HTTP;

use base qw(Class::Accessor::Fast);

use strict;
use warnings;

use 5.008_001;

use MRO::Compat;

BEGIN {
    require List::Util;
    require HTTP::Headers::ETag;
}

=head1 NAME

Catalyst::Plugin::Cache::HTTP - HTTP/1.1 cache validators for Catalyst

=head1 VERSION

Version 0.001000

=cut

our $VERSION = "0.001000";

__PACKAGE__->mk_accessors(qw(_http_mc_finalized_headers));

=head1 SYNOPSIS

=head2 Load Plugin Into Application

  package MyApp;

  use Catalyst qw(Cache::HTTP);

=head2 Create a Last-Modified Header
  
  package MyApp::Controller::Foo;

  sub bar : Local {
    my ($self, $c) = @_;
    my $data = $c->model('MyApp::Model')->fetch_data;
    my $mtime = $data->mod_time;

    ...
    $c->response->headers->last_modified($mtime);
    ...
  }

=head2 Automatic Creation of ETag

  package MyApp::View::TT;

  use base 'Catalyst::View::TT';
  use MRO::Compat;
  use Digest::MD5 'md5_hex';

  sub process {
    my $self = shift;
    my $c = $_[0];

    $self->next::method(@_)
	or return 0;

    my $method = $c->request->method;
    return 1
	if $method ne 'GET' and $method ne 'HEAD' or
	   $c->stash->{nocache};    # disable caching explicitely

    my $body = $c->response->body;
    if ($body) {
      utf8::encode($body)
        if utf8::is_utf8($body);
      $c->response->headers->etag(md5_hex($body));
    }

    return 1;
  }

=head1 DESCRIPTION

Ever since mankind develops web sites, it has to deal with the problems
that arise when a site becomes popular. This is especially true for dynamic
contents. Optimizations of the web application itself are usually followed
by tweaking the system setup, better hardware, improved connectivity,
clustering and load balancing. Good if the site yields enough profit to
fund all this (and the people that are required).

There are also numerous modules on the CPAN and helpful tips all over the
World Wide Web about how to crack the whip on Catalyst applications.

Noticeably often is overlooked, that more than a decade ago the "fathers"
of the WWW have created concepts in C<HTTP/1.1> to reduce traffic between
web server and web client (and proxy where applicable). All common web
browsers support these concepts for many years now.

These concepts can accelerate a web application and save resources at the
same time.

How this is possible? You can look up the concept in RFC 2616 section 13.3,
plus the implementation in sections 14.19, 14.24, 14.25, 14.26, 14.28 and
14.44. To cut a long story short: This plugin does not manage any cache on
the server and avoids transmitting data where possible.

To utilize this concept in your Catalyst based application some rather small
additions have to be made in the code:

=over

=item 1. Use the plugin

This is easy: In the application class (often referred as MyApp.pm) just
add C<Cache::HTTP> to the list of plugins after C<use Catalyst>.

=item 2. Add appropriate response headers

Those headers are C<Last-Modified> and C<ETag>. The
L<< headers method of Catalyst::Response|Catalyst::Response/$res->headers >>
which actually provides us with an instance of L<HTTP::Headers|HTTP::Headers>
gives us two handy accessors to those header lines: C<last_modified> and
C<etag>.

=over

=item 2.1 C<< $c->response->headers->last_modified($unix_timestamp) >>

If this exists in a response for a requested resource, then for the next
request to the same resource a modern web browser will add a line to the
request headers to check if the resource data has changed since the
C<Last-Modified> date, that was given with the last response. If the
server answers with a status code C<304> and an empty body, the browser
takes the data for this resource from its local cache.

=item 2.2 C<< $c->response->headers->etag($entity_tag) >>

The entity tag is a unique representation of data from a resource. Usually
a digest of the response body serves well for this purpose, so for that
case whenever you read "ETag" you might replace it with "checksum". If an
C<Etag> exists in a response for a requested resource, then for the next
request to the same resource the browser will add a line to the request
headers with that ETag, that tells the server to only transmit the body if
the ETag for the resource has changed. If it hasn't the server responds
with a status code C<304> and an empty body, and the browser takes the
data for this resource from its local cache.

=back

=back

=head1 CAVEATS

Using this concept involves the risk of breaking something!

Especially the C<Last-Modified> header has some flaws:

First of all the accuracy of it cannot be better than the HTTP time
interval: one second.

But what is really hazardous is trying to calculate a last_modified
timestamp for dynamic pages.

As a rough rule of thumb, never use C<last_modified> when

=over

=item *

serving results joined from multiple sources,

=item *

the output depends on input parameters.

=back

Hence C<Last-Modified> is ideal for serving data without changing it
(e.g. images) or for an RSS feed where C<Last-Modified> is the time of the
latest entry.

An C<ETag> header that is calculated as a checksum of the actual
response body is much more robust in general. The only real drawback is,
that calculating this checksum costs a few CPU cycles. The L</SYNOPSIS> at
the top shows an example how to create this C<ETag> header automatically.

=head1 INTERNAL METHODS

=head2 finalize_headers

This hooks into the chain of C<finalize_headers> methods and checks the
request headers C<If-Match>, C<If-Unmodified-Since>, C<If-None-Match> and
C<If-Modified-Since> as well as the response headers C<ETag> and
C<Last-Modified>. Sets the status response code to C<304 Not Modified>
if those fields indicate, that the data for the resource has not changed
since the last request from the same client, so the client will use a
locally cache copy of the resource data.

=cut

sub finalize_headers {
    my $c = shift;

    return if $c->_http_mc_finalized_headers;

    my $status = $c->_meets_conditions;
    if ($status) {
	$c->response->status($status);
	$c->response->body('');
    }

    $c->_http_mc_finalized_headers(1);	# Kilroy was here

    return $c->next::method(@_);
}

# code borrowed from apache 2.2.10 modules/http/http_protocol.c

sub _meets_conditions {
    my $c = $_[0];
    my $req = $c->request;
    my $headers_in = $req->headers;
    my $res = $c->response;
    my $headers_out = $res->headers;
    my $status = $res->status || 200;

    $status < 300 and $status >= 200 or return 0;

    my $etag = $headers_out->etag;
    my $now = time;
    my $mtime = $headers_out->last_modified || $now;
    my (@a, $t);

    if (@a = $headers_in->if_match) {
	# If an If-Match request-header field was given
	# AND the field value is not "*" (meaning match anything)
	# AND if our strong ETag does not match any entity tag in that
	# field, respond with a status of 412 (Precondition Failed).
	return 412
	    if $a[0] ne '"*"' and (
		not defined($etag) or
		substr($etag, 0, 1) eq 'W' or
		not (List::Util::first { $etag eq $_ } @a)
	    );
    }
    elsif ($t = $headers_in->if_unmodified_since and $mtime > $t) {
	# Else if a valid If-Unmodified-Since request-header field was
	# given AND the requested resource has been modified since the
	# time specified in this field, then the server MUST respond
	# with a status of 412 (Precondition Failed).
	# RFC 2616 14.28 does not tell what to do when no Last-Modified
	# header exists in the response. This implementation treats this
	# situation as if the resource has been modified now.
	return 412;
    }

    my $method = uc $req->method;
    my $not_modified;

    if (@a = $headers_in->if_none_match) {
	# If an If-None-Match request-header field was given
	# AND the field value is "*" (meaning match anything)
	#     OR our ETag matches any of the entity tags in that field, fail.
	#
	# If the request method was GET or HEAD, failure means the server
	#    SHOULD respond with a 304 (Not Modified) response.
	# For all other request methods, failure means the server MUST
	#    respond with a status of 412 (Precondition Failed).
	#
	# GET or HEAD allow weak etag comparison, all other methods require
	# strong comparison.  We can only use weak if it's not a range request.
	if ($method eq 'GET' or $method eq 'HEAD') {
	    if ($a[0] eq '"*"') {
		$not_modified = 1;
	    }
	    elsif (defined $etag) {
		if ($headers_in->header('Range')) {
		    $not_modified = 
			substr($etag, 0, 1) ne 'W' &&
			    !!(List::Util::first { $etag eq $_ } @a);
		}
		else {
		    $not_modified = !!(List::Util::first { $etag eq $_ } @a);
		}
	    }
	}
	else {
	    return 412
		if $a[0] eq '"*"' or
		    defined($etag) and List::Util::first { $etag eq $_ } @a;
	}
    }

    if (
	$method eq 'GET' and
	($not_modified or not @a) and
	$t = $headers_in->if_modified_since
    ) {
	# Else if a valid If-Modified-Since request-header field was given
	# AND it is a GET request
	# AND the requested resource has not been modified since the time
	# specified in this field, then the server MUST
	# respond with a status of 304 (Not Modified).
	# A date later than the server's current request time is invalid.
	$not_modified = $t >= $mtime && $t <= $now;
    }

    return $not_modified ? 304 : 0;
}


1;

__END__

=head1 CONFIGURATION

none.

=head1 SEE ALSO

L<Catalyst>, L<http://www.ietf.org/rfc/rfc2616.txt>

=head1 AUTHOR

Bernhard Graf C<< <graf(a)cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-cache-http at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Cache-HTTP>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Bernhard Graf.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
