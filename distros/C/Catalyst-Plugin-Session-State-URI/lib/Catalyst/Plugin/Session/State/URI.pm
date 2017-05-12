package Catalyst::Plugin::Session::State::URI;

use Moose;
use HTML::TokeParser::Simple;
use MIME::Types;
use MRO::Compat;
use URI;
use URI::Find;
use URI::QueryParam;

use namespace::clean -except => 'meta';

our $VERSION = '0.15';

extends 'Catalyst::Plugin::Session::State';
with 'MooseX::Emulate::Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/_sessionid_from_uri _sessionid_to_rewrite/);

sub get_session_id {
    my ( $c, @args ) = @_;
    return $c->_sessionid_from_uri || $c->maybe::next::method(@args);
}

sub set_session_id {
    my ( $c, $sid, @args ) = @_;
    $c->_sessionid_to_rewrite($sid);
    $c->maybe::next::method($sid, @args);
}

sub delete_session_id {
    my ( $c, @args ) = @_;
    $c->_sessionid_from_uri(undef);
    $c->_sessionid_to_rewrite(undef);
    $c->maybe::next::method(@args);
}

sub setup_session {
    my $c = shift();

    $c->maybe::next::method(@_);

    my %defaults = (
        rewrite_redirect     => 1,
        rewrite_body         => 1,
        no_rewrite_if_cookie => 1,
    );

    my $config = $c->_session_plugin_config;


    if ( delete $config->{rewrite} ) {
        $config->{rewrite_redirect} = 1
            unless exists $config->{rewrite_redirect};
        $config->{rewrite_body} = 1
            unless exists $config->{rewrite_body};
    }

    foreach my $key ( keys %defaults ) {
        $config->{$key} = $defaults{$key}
            unless exists $config->{$key};
    }
}

sub finalize {
    my $c = shift;

    $c->session_rewrite_if_needed;

    return $c->maybe::next::method(@_);
}


sub session_rewrite_if_needed {
    my $c = shift;

    my $sid = $c->_sessionid_to_rewrite || $c->_sessionid_from_uri;

    if ( $sid and $c->session_should_rewrite ) {
        $c->log->debug("rewriting response elements to include session id")
            if $c->debug;

        if ( $c->session_should_rewrite_redirect ) {
            $c->rewrite_redirect_with_session_id($sid);
        }

        if ( $c->session_should_rewrite_body ) {
            $c->rewrite_body_with_session_id($sid);
        }
    }
}

sub rewrite_body_with_session_id {
    my ( $c, $sid ) = @_;

    if (
        ($c->response->content_type || '') =~ /html/ # XML too?
            or
        (!$c->response->content_type and $c->response->body =~ /^\s*\w*\s*<[?!]?\s*\w+/ ), # if it looks like html
    ) {
        $c->rewrite_html_with_session_id($sid);
    } else {
        $c->rewrite_text_with_session_id($sid);
    }

}

sub _session_rewriting_html_tag_map {
    return {
        a      => "href",
        form   => "action",
        link   => "href",
        img    => "src",
        script => "src",
    };
}

sub rewrite_html_with_session_id {
    my ( $c, $sid ) = @_;

    my $p = HTML::TokeParser::Simple->new( string => ($c->response->body || return) );

    $c->log->debug("Rewriting HTML body with the token parser")
        if $c->debug;

    my $tag_map = $c->_session_rewriting_html_tag_map;

    my $body = '';
    while ( my $token = $p->get_token ) {
        if ( my $tag = $token->get_tag ) {
            # rewrite tags according to the map
            if ( my $attr_name = $tag_map->{$tag} ) {
                if ( defined(my $attr_value = $token->get_attr($attr_name) ) ) {
                    $attr_value = $c->uri_with_sessionid($attr_value, $sid)
                        if $c->session_should_rewrite_uri($attr_value);

                    $token->set_attr( $attr_name, $attr_value );
                }
            }
        }

        $body .= $token->as_is;
    }

    $c->response->body($body);
}

sub rewrite_text_with_session_id {
    my ( $c, $sid ) = @_;

    my $body = $c->response->body || return;

    $c->log->debug("Rewriting plain body with URI::Find")
        if $c->debug;

    URI::Find->new(sub {
        my ( $uri, $orig_uri ) = @_;

        if ( $c->session_should_rewrite_uri($uri) ) {
            my $rewritten = $c->uri_with_sessionid($uri, $sid);
            if ( $orig_uri =~ s/\Q$uri/$rewritten/ ) {
                # try to keep formatting
                return $orig_uri;
            } elsif ( $orig_uri =~ /^(<(?:URI:)?).*(>)$/ ) {
                return "$1$rewritten$2";
            } else {
                return $rewritten;
            }
        } else {
            return $orig_uri;
        }
    })->find( \$body );

    $c->response->body( $body );
}

sub rewrite_redirect_with_session_id {
    my ( $c, $sid ) = @_;

    my $location = $c->response->location || return;

    $c->log->debug("Rewriting location header")
        if $c->debug;

    $c->response->location( $c->uri_with_sessionid($location, $sid) )
        if $c->session_should_rewrite_uri($location);
}

sub session_should_rewrite {
    my $c = shift;

    my $config = $c->_session_plugin_config;
    return unless $config->{rewrite_redirect}
        ||  $config->{rewrite_body};

    if ( $c->isa("Catalyst::Plugin::Session::State::Cookie")
        and $config->{no_rewrite_if_cookie}
    ) {
        return if defined($c->get_session_cookie);
    }

    return 1;
}

sub session_should_rewrite_type {
    my $c = shift;

    if ( my $types = $c->_session_plugin_config->{rewrite_types} ) {
        my @req_type = $c->response->content_type; # split
        foreach my $type ( @$types ) {
            if ( ref($type) ) {
                return 1 if $type->( $c, @req_type );
            } else {
                return 1 if lc($type) eq $req_type[0];
            }
        }

        return;
    } else {
        return 1;
    }
}

sub session_should_rewrite_body {
    my $c = shift;
    return unless $c->_session_plugin_config->{rewrite_body};
    return $c->session_should_rewrite_type;
}

sub session_should_rewrite_redirect {
    my $c = shift;
    return unless $c->_session_plugin_config->{rewrite_redirect};
    ($c->response->status || 0) =~ /^\s*3\d\d\s*$/;
}


sub uri_for {
    my ( $c, $path, @args ) = @_;

    return $c->_session_plugin_config->{overload_uri_for}
        ? $c->uri_with_sessionid($c->maybe::next::method($path, @args))
        : $c->maybe::next::method($path, @args);
}

sub uri_with_sessionid {
    my ( $c, $uri, $sid ) = @_;

    $sid ||= $c->sessionid;

    my $uri_obj = eval { URI->new($uri) } || return $uri;

    return $c->_session_plugin_config->{param}
      ? $c->uri_with_param_sessionid($uri_obj, $sid)
      : $c->uri_with_path_sessionid($uri_obj, $sid);
}

sub uri_with_param_sessionid {
    my ( $c, $uri_obj, $sid ) = @_;

    my $param_name = $c->_session_plugin_config->{param};

    $uri_obj->query_param( $param_name => $sid );

    return $uri_obj;
}

sub uri_with_path_sessionid {
    my ( $c, $uri_obj, $sid ) = @_;

    ( my $old_path = $uri_obj->path ) =~ s{/$}{};

    $uri_obj->path( join( "/-/", $old_path, $sid ) );

    return $uri_obj;
}

sub session_should_rewrite_uri {
    my ( $c, $uri_text ) = @_;

    my $uri_obj = eval { URI->new($uri_text) } || return;

    # ignore the url outside
    my $rel = $uri_obj->abs( $c->request->base );

    return unless index( $rel, $c->request->base ) == 0;

    return unless $c->session_should_rewrite_uri_mime_type($rel);

    if ( my $param = $c->_session_plugin_config->{param} )
    {    # use param style rewriting

        # if the URI query string doesn't contain $param
        return not defined $uri_obj->query_param($param);

    } else {    # use path style rewriting

        # if the URI isn't already rewritten
        return $uri_obj->path !~ m#/-/#;

    }
}

sub session_should_rewrite_uri_mime_type {
    my ( $c, $uri ) = @_;

    # ignore media type such as gif, pdf and etc
    if ( my ($ext) = $uri->path =~ m#\.(\w+)(?:\?|$)# ) {
        my $mt = MIME::Types->new->mimeTypeOf($ext);
        return if ref $mt && $mt->isBinary;
    }

    return 1;
}

sub prepare_path {
    my $c = shift;

    $c->maybe::next::method(@_);

    if ( my $param = $c->_session_plugin_config->{param} )
    {           # use param style rewriting

        if ( my $sid = $c->request->query_parameters->{$param} ) {
            $c->_sessionid_from_uri($sid);
            $c->_tried_loading_session_id(0);
            $c->log->debug(qq/Found sessionid "$sid" in query parameters/)
              if $c->debug;
        }

    } else {    # use path style rewriting

        if ( my ( $path, $sid ) = ( $c->request->path =~ m{^ (?: (.*) / )? -/ (.+) $}x )  ) {
            $c->request->path( defined($path) ? $path : "" );
            $c->log->debug(qq/Found sessionid "$sid" in uri path/)
              if $c->debug;
            $c->_sessionid_from_uri($sid);
            $c->_tried_loading_session_id(0);
        }

    }
}

__PACKAGE__

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::State::URI - Use URIs to pass the session id between requests

=head1 SYNOPSIS

    use Catalyst qw/Session Session::State::URI Session::Store::Foo/;

    # If you want the param style rewriting, set the parameter
    MyApp->config('Plugin::Session' => {
        param   => 'sessionid', # or whatever you like
    });

=head1 DESCRIPTION

In order for L<Catalyst::Plugin::Session> to work the session ID needs
to be available on each request, and the session data needs to be
stored on the server.

This plugin puts the session id into URIs instead of something like a
cookie.

By default, it rewrites all outgoing URIs, both redirects and in
outgoing HTML, but you can exercise control over exactly which URIs
are rewritten.

=head1 METHODS

=over 4

=item session_should_rewrite

This method is consulted by C<finalize>, and URIs will be rewritten
only if it returns a true value.

Rewriting is controlled by the C<< $c->config('Plugin::Session' => { rewrite_body => $val })
>> and C<< $c->config('Plugin::Session' => { rewrite_redirect => $val }) >> config settings,
both of which default to true.

To globally disable rewriting simply set these parameters to false.

If C<< $c->config('Plugin::Session' => { no_rewrite_if_cookie => 1 }) >>,
L<Catalyst::Plugin::Session::State::Cookie> is also in use, and the
user agent sent a cookie for the sesion then this method will return
false. This parameter also defaults to true.

=item session_should_rewrite_body

This method checks C<< $c->config('Plugin::Session' => {rewrite_body => $val}) >>
first. If this is true, it then calls C<session_should_rewrite_type>.

=item session_should_rewrite_type

This method determines whether or not the body should be rewritten,
based on its content type.

For compatibility this method will B<not> test the response's content type
without configuration. If you want to do that you must provide a list of valid
content types in C<< $c->config->{'Plugin::Session'}{rewrite_types} >>, or subclass this
method.

=item session_should_rewrite_redirect

This method determines whether or not to rewrite the C<Location>
header of the response.

This method checks C<< $c->config->{session}{rewrite_redirect} >>
first. If this is true, it then checks if the status code is a number
in the 3xx range.

=item session_should_rewrite_uri $uri_text

This method is to determine whether a URI should be rewritten.

It will return true for URIs under C<$c-E<gt>req-E<gt>base>, and it will also
use L<MIME::Types> to filter the links which point to png, pdf and etc with the
file extension.

You are encouraged to override this method if it's logic doesn't suit your
setup.

=item session_should_rewrite_uri_mime_type $uri_obj

A sub test of session_should_rewrite_uri, that checks if the file name's
guessed mime type is of a kind we should rewrite URIs to.

Files which are typically static (images, etc) will thus not be rewritten in
order to not get 404s or pass bogus parameters to the server.

If C<$uri_obj>'s path causes L<MIME::Types> to return true for the C<isBinary>
test then then the URI will not be rewritten.

=item uri_with_sessionid $uri_text, [ $sid ]

When using path style rewriting (the default), it will append
C</-/$sessionid> to the uri path.

http://myapp/link -> http://myapp/link/-/$sessionid

When using param style rewriting, it will add a parameter key/value
pair after the uri path.

http://myapp/link -> http://myapp/link?$param=$sessionid

If $sid is not provided it will default to C<< $c->sessionid >>.

=item session_rewrite_if_needed

Rewrite the response if necessary.

=item rewrite_body_with_session_id $sid

Calls either C<rewrite_html_with_session_id> or C<rewrite_text_with_session_id>
depending on the content type.

=item rewrite_html_with_session_id $sid

Rewrites the body using L<HTML::TokePaser::Simple>.

This method of rewriting also matches relative URIs, and is thus more robust.

=item rewrite_text_with_session_id $sid

Rewrites the body using L<URI::Find>.

This method is used when the content does not appear to be HTML.

=item rewrite_redirect_with_session_id $sid

Rewrites the C<Location> header.

=item uri_with_param_sessionid

=item uri_with_path_sessionid

=back

=head1 EXTENDED METHODS

=over 4

=item prepare_path

Will restore the session if the request URI is formatted accordingly, and
rewrite the URI to remove the additional part.

=item finalize

Rewrite a redirect or the body HTML as appropriate.

=item delete_session_id

=item get_session_id

=item set_session_id

=item setup_session

=item uri_for

=back

=head1 CAVEATS

=head2 Session Hijacking

URI sessions are very prone to session hijacking problems.

Make sure your users know not to copy and paste URIs to prevent these problems,
and always provide a way to safely link to public resources.

Also make sure to never link to external sites without going through a gateway
page that does not have session data in it's URI, so that the external site
doesn't get any session IDs in the http referrer header.

Due to these issues this plugin should be used as a last resort, as
L<Catalyst::Plugin::Session::State::Cookie> is more appropriate 99% of the
time.

Take a look at the IP address limiting features in L<Catalyst::Plugin::Session>
to see make some of these problems less dangerous.

=head3 Goodbye page recipe

To exclude some sections of your application, like a goodbye page (see
L</CAVEATS>) you should make extend the C<session_should_rewrite_uri> method to
return true if the URI does not point to the goodbye page, extend
C<prepare_path> to not rewrite URIs that match C</-/> (so that external URIs
with that in their path as a parameter to the goodbye page will not be
destroyed) and finally extend C<uri_with_sessionid> to rewrite URIs with the
following logic:

=over 4

=item *

URIs that match C</^$base/> are appended with session data (
C<< $c->maybe::next::method >>).

=item *

External URIs (everything else) should be prepended by the goodbye page. (e.g.
C<http://myapp/link/http://the_url_of_whatever/foo.html>).

=back

But note that this behavior will be problematic when you are e.g. submitting
POSTs to forms on external sites.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>,L<Catalyst::Plugin::Session::FastMmap>
C<HTML::TokeParser::Simple>, C<MIME::Types>.

=head1 AUTHORS

This module is derived from L<Catalyst::Plugin::Session::FastMmap> code, and
has been heavily modified since.

=over 4

=item Andrew Ford

=item Andy Grundman

=item Christian Hansen

=item Dave Rolsky

=item Yuval Kogman, C<nothingmuch@woobling.org>

=item Marcus Ramberg

=item Sebastian Riedel

=item Hu Hailin

=item Tomas Doran, C<bobtfish@bobtfish.net> (Current maintainer)

=item Florian Ragwitz C<rafl@debian.org>

=back

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
