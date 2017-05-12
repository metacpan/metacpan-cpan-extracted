package Dancer2::Plugin::HTTP::ConditionalRequest;

=head1 NAME

Dancer2::Plugin::HTTP::ConditionalRequest - RFC 7232 compliant

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.05';

use warnings;
use strict;

use Carp;
use Dancer2::Plugin;

use DateTime::Format::HTTP;


=head1 SYNOPSIS

Conditionally handling HTTP request based on eTag or Modification-Date,
according to RFC 7232

HTTP Conditional Requests are used for telling servers that they only have to
perform the method if the preconditions are met. Such requests are either used
by caches to (re)validate the cached response with the origin server - or -
to prevent lost-updates with unsafe-methods in a stateless api (like REST).
 
    any '/my_resource/:id' => sub {
        ...
        # check stuff
        # - compute eTag from MD5
        # - use an external table
        # - find a last modification date
        ...
        
        http_conditional {
            etag            => '2d5730a4c92b1061',
            last_modified   => "Tue, 15 Nov 1994 12:45:26 GMT", # HTTP Date
            required        => false,
        }
        
        # do the real stuff, like updating or serializing
        
    };

=head1 RFC_7232 HTTP: Conditional Requests... explained

As mentioned in the previous section, Conditional Requests are for two purposes
mainly:

=head2 Caching

For GET and HEAD methods, the caching-server passes the validators to the origin
server to see if it can still use the cached version or not - and if not, get a
fresh version.

Keep in mind that the Dancer2 server is probably designed to be that originating
server and should provide either the 304 (Not Modified) status or a fresh
representation off the requested resource. At this stage (and in compliance with
the RFC) there is nothing to deal with the caching of the responses at all.

This plugin does not do any caching, it's only purpose is to respond correctly
to conditional requests. Neither does this plugin set any caching-directives
that are part of RFC_7234 (Caching), and for which there is a seperate plugin.

=head2 Lost-Updates

For REST api's it is important to understand that it is a Stateless interface.
This means that there is no such thing as record locking on the server. Would
one desire to edit a resource, the only way to check that one is not accidently
overwritin someone elses changes, is comparing it with weak or strong
validators, like date/time of a last modification - or a unique version
identifier, known as a eTag.

=head2 Strong and weak validators

ETags are stronger validators than the Date Last-Modified. In the above
described example, it has two validators provided that can be used to check the
conditional request. If the client did set an eTag conditional in 'If-Matched'
or 'If-None-Matched', it will try to match that. If not, it will try to match
against the Date Last-Modified with either the 'If-Modified-Since' or
'If-Unmodified-Since'.

=head2 Required or not

The optional 'required' turns the API into a strict mode. Running under 'strict'
ensures that the client will provided either the eTag or Date-Modified validator
for un-safe requests. If not provided when required, it will return a response
with status 428 (Precondition Required) (RFC 6585).

When set to false, it allows a client to sent of a request without the headers
for the conditional requests and as such have bypassed all the checks end up in
the last validation step and continue with the requested operation.

=head2 Safe and unsafe methods

Sending these validators with a GET request is used for caching and respond with
a status of 304 (Not Modified) when the client has a 'fresh' version. Remember
though to send of current caching-information too (according to the RFC 7232).

When used with 'unsafe' methods that will cause updates, these validators can
prevent 'lost updates' and will respond with 412 (Precondition Failed) when
there might have happened an intermediate update.

=head2 Generating eTags and Dates Last-Modified

Unfortunately, for a any method one might have to retrieve and process the
resource data before being capable of generating a eTag. Or one might have to go
through a few pieces of underlying data structures to find that
last-modification date.

For a GET method one can then skip the 'post-processing' like serialisation and
one does no longer have to send the data but only the status message 304
(Not Modified).

=head2 More reading

There is a lot of additional information in RFC-7232 about generating and
retrieving eTags or last-modification-dates. Please read-up in the RFC about
those topics.

=cut

=head1 Dancer2 Keywords

=head2 http_conditional

This keyword used will check with the passed in parameters to do a conditional
request. If these pre-conditions are not met execution will be halted with the
relevant status code. If the preconditions apply, execution will continue on the
following line.

A optional hashref takes the options

=over

=item etag

a string that 'uniquely' identifies the current version of the resource.

=item last_modified

a HTTP Date compliant string of the date/time this resource was last updated.

or

a DateTime object.

A suitable string can be created from a UNIX timestamp using
L<HTTP::Date::time2str|HTTP::Date/time2str>, or from a L<DateTime|DateTime>
object using C<format_datetime> from L<DateTime::Format::HTTP|DateTime::Format::HTTP/format_datetime>.

=item required

if set to true, it enforces clients that request a unsafe method to provide one
or both validators.

=back

If used with either a GET or a HEAD method, the validators mentioned in the
options are set and returned in the appropriate HTTP Header Fields.

=cut

register http_conditional => sub {
    my $self    = shift;
    my $coderef = pop if ref($_[-1]) eq "CODE";
    my $args    = shift;
    
#   unless ( $coderef && ref $coderef eq 'CODE' ) {
#       return sub {
#          warn "http_conditional: missing CODE-REF";
#       };
#   };
    
    # To understand the flow of the desicions the original text of the RFC has
    # been included so one can see that it does what the RFC says, not what the
    # evelopper thinks it should do.
    
    # Additional checks for argument validation have been added.
    
    goto STEP_1 if not $args->{required};
    
    # RFC-6585 - Status 428 (Precondition Required)
    # 
    # For a GET, it would be totaly safe to return a fresh response,
    # however, for unsafe methods it could be required that the client
    # does provide the eTag or DateModified validators.
    # 
    # setting the pluging config with something like: required => 1
    # might be a nice way to handle it for the entire app, turning it
    # into a strict modus. 
    
    if ($self->http_method_is_nonsafe) {
#       warn "http_conditional: http_method_is_nonsafe";
        $self->halt( $self->_http_status_precondition_required_etag )
            if ( $args->{etag}
                and not $self->app->request->header('If-Match') );
        $self->halt( $self->_http_status_precondition_required_last_modified)
            if ( $args->{last_modified}
                and not $self->app->request->header('If-Unmodified-Since') );
    } else {
#       warn "http_conditional: http_method_is_safe";
    };
    
    
    # RFC 7232 Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests
    #
    # Section 6. Precedence
    #
    # When more than one conditional request header field is present in a
    # request, the order in which the fields are evaluated becomes
    # important.  In practice, the fields defined in this document are
    # consistently implemented in a single, logical order, since "lost
    # update" preconditions have more strict requirements than cache
    # validation, a validated cache is more efficient than a partial
    # response, and entity tags are presumed to be more accurate than date
    # validators.
    
STEP_1:
    # When recipient is the origin server and If-Match is present,
    # evaluate the If-Match precondition:
    
    # if true, continue to step 3
    
    # if false, respond 412 (Precondition Failed) unless it can be
    # determined that the state-changing request has already
    # succeeded (see Section 3.1)
    
    if ( defined ($self->app->request->header('If-Match')) ) {
        
        # check arguments and http-headers
        $self->halt( $self->_http_status_precondition_failed_no_etag )
            if not exists $args->{etag};
        
        
        # RFC 7232
        if ( $self->app->request->header('If-Match') eq $args->{etag} ) {
            goto STEP_3;
        } else {
            $self->app->response->status(412); # Precondition Failed
            $self->halt( );
        }
    }
    
STEP_2:
    # When recipient is the origin server, If-Match is not present, and
    # If-Unmodified-Since is present, evaluate the If-Unmodified-Since
    # precondition:
    
    # if true, continue to step 3
    
    # if false, respond 412 (Precondition Failed) unless it can be
    # determined that the state-changing request has already
    # succeeded (see Section 3.4)
    
    if ( defined ($self->app->request->header('If-Unmodified-Since')) ) {
        
        # check arguments and http-headers
        $self->halt( $self->_http_status_precondition_failed_no_date )
            if not exists $args->{last_modified};
        
        my $rqst_date = DateTime::Format::HTTP->parse_datetime(
            $self->app->request->header('If-Unmodified-Since')
        );
        $self->halt( $self->_http_status_bad_request_if_unmodified_since )
            if not defined $rqst_date;
            
        my $last_date = $args->{last_modified}->isa('DateTime')
            ? $args->{last_modified}
            : DateTime::Format::HTTP->parse_datetime($args->{last_modified});
        $self->halt( $self->_http_status_server_error_bad_last_modified )
            if not defined $last_date;
        
        
        # RFC 7232
        if ( $rqst_date > $last_date ) {
            goto STEP_3;
        } else {
            $self->app->response->status(412); # Precondition Failed
            return;
        }
    }

STEP_3:
    # When If-None-Match is present, evaluate the If-None-Match
    # precondition:
    
    # if true, continue to step 5
    
    # if false for GET/HEAD, respond 304 (Not Modified)
    
    # if false for other methods, respond 412 (Precondition Failed)
    
    if ( defined ($self->app->request->header('If-None-Match')) ) {
        
        # check arguments and http-headers
        $self->halt( $self->_http_status_precondition_failed_no_etag )
            if not exists $args->{etag};
        
        
        # RFC 7232
        if ( $self->app->request->header('If-None-Match') ne $args->{etag} ) {
            goto STEP_5;
        } else {
            if (
                $self->app->request->method eq 'GET'
                or
                $self->app->request->method eq 'HEAD'
            ) {
                $self->app->response->status(304); # Not Modified
                $self->halt;
            } else {
                $self->app->response->status(412); # Precondition Failed
                $self->halt( );
            }
        }
    }

STEP_4:
    # When the method is GET or HEAD, If-None-Match is not present, and
    # If-Modified-Since is present, evaluate the If-Modified-Since
    # precondition:
    
    # if true, continue to step 5
    
    # if false, respond 304 (Not Modified)

    if (
        ($self->app->request->method eq 'GET' or $self->app->request->method eq 'HEAD')
        and
        not defined($self->app->request->header('If-None-Match'))
        and
        defined($self->app->request->header('If-Modified-Since'))
    ) {
        
        # check arguments and http-headers
        $self->halt( $self->_http_status_precondition_failed_no_date )
            if not exists $args->{last_modified};
        
        my $rqst_date = DateTime::Format::HTTP->parse_datetime(
            $self->app->request->header('If-Modified-Since')
        );
        $self->halt( $self->_http_status_bad_request_if_modified_since )
            if not defined $rqst_date;
        
        my $last_date = $args->{last_modified}->isa('DateTime')
            ? $args->{last_modified}
            : DateTime::Format::HTTP->parse_datetime($args->{last_modified});
        $self->halt( $self->_http_status_server_error_bad_last_modified )
            if not defined $last_date;
        
        
        # RFC 7232
        if ( $rqst_date < $last_date ) {
            goto STEP_5;
        } else {
            $self->app->response->status(304); # Not Modified
            $self->halt( );
        }
    }
    
STEP_5:
    # When the method is GET and both Range and If-Range are present,
    # evaluate the If-Range precondition:
    
    # if the validator matches and the Range specification is
    # applicable to the selected representation, respond 206
    # (Partial Content) [RFC7233]
    
    undef; # TODO (BTW, up till perl 5.13, this would break because of labels
    
STEP_6:
    # Otherwise,
    
    # all conditions are met, so perform the requested action and
    # respond according to its success or failure.
    
    # set HTTP Header-fields for GET / HEAD requests
    if (
        ($self->app->request->method eq 'GET' or $self->app->request->method eq 'HEAD')
    ) {
        if ( exists($args->{etag}) ) {
            $self->app->response->header('ETag' => $args->{etag})
        }
        if ( exists($args->{last_modified}) ) {
            my $last_date = $args->{last_modified}->isa('DateTime')
                ? $args->{last_modified}
                : DateTime::Format::HTTP->parse_datetime($args->{last_modified});
            $self->halt( $self->_http_status_server_error_bad_last_modified )
                if not defined $last_date;
            $self->app->response->header('Last-Modified' =>
                DateTime::Format::HTTP->format_datetime($last_date) )
        }
    }
    
    # RFC 7232
    
    return $coderef->($self) if $coderef;
    return
    
};

# RFC 7231 HTTP/1.1 Semantics and Content
# section 4.2.1 Common Method Properties - Safe Methods#
# http://tools.ietf.org/html/rfc7231#section-4.2.1
# there is a patch for Dancer2 it self
register http_method_is_safe => sub {
    return (
        $_[0]->app->request->method eq 'GET'       ||
        $_[0]->app->request->method eq 'HEAD'      ||
        $_[0]->app->request->method eq 'OPTIONS'   ||
        $_[0]->app->request->method eq 'TRACE'
    );
};

register http_method_is_nonsafe => sub {
    return not $_[0]->http_method_is_safe();
};

sub _http_status_bad_request_if_modified_since {
    warn "http_conditional: bad formatted date 'If-Modified-Since'";
    $_[0]->status(400); # Bad Request
    return;
}

sub _http_status_bad_request_if_unmodified_since {
    warn "http_conditional: bad formatted date 'If-Unmodified-Since'";
    $_[0]->status(400); # Bad Request
    return;
}

sub _http_status_precondition_failed_no_date {
    warn "http_conditional: not provided 'last_modified'";
    $_[0]->status(412); # Precondition Failed
    return;
}

sub _http_status_precondition_failed_no_etag {
    warn "http_conditional: not provided 'eTag'";
    $_[0]->status(412); # Precondition Failed
    return;
}

sub _http_status_precondition_required_etag {
    warn "http_conditional: Precondition Required 'ETag'";
    $_[0]->status(428); # Precondition Required
    return;
}

sub _http_status_precondition_required_last_modified {
    warn "http_conditional: Precondition Required 'Date Last-Modified'";
    $_[0]->status(428); # Precondition Required
    return;
}

sub _http_status_server_error_bad_last_modified {
    $_[0]->status(500); # Precondition Failed
    return "http_conditional: bad formatted date 'last_modified'";
}

register_plugin;

=head1 AUTHOR

Theo van Hoesel, C<< <Th.J.v.Hoesel at THEMA-MEDIA.nl> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dancer2-plugin-http-conditionalrequest at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-HTTP-ConditionalRequest>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::HTTP::ConditionalRequest


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-HTTP-ConditionalRequest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-HTTP-ConditionalRequest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-HTTP-ConditionalRequest>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-HTTP-ConditionalRequest/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Theo van Hoesel.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
