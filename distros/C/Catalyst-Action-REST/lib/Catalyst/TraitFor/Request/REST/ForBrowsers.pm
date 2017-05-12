package Catalyst::TraitFor::Request::REST::ForBrowsers;
$Catalyst::TraitFor::Request::REST::ForBrowsers::VERSION = '1.20';
use Moose::Role;
use namespace::autoclean;

with 'Catalyst::TraitFor::Request::REST';

has _determined_real_method => (
    is  => 'rw',
    isa => 'Bool',
);

has looks_like_browser => (
    is       => 'rw',
    isa      => 'Bool',
    lazy     => 1,
    builder  => '_build_looks_like_browser',
    init_arg => undef,
);

# All this would be much less gross if Catalyst::Request used a builder to
# determine the method. Then we could just wrap the builder.
around method => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
        if @_ || $self->_determined_real_method;

    my $method = $self->$orig();

    my $tunneled;
    if ( defined $method && uc $method eq 'POST' ) {
        $tunneled = $self->param('x-tunneled-method')
            || $self->header('x-http-method-override');
    }

    $self->$orig( defined $tunneled ? uc $tunneled : $method );

    $self->_determined_real_method(1);

    return $self->$orig();
};

{
    my %HTMLTypes = map { $_ => 1 } qw(
        text/html
        application/xhtml+xml
    );

    sub _build_looks_like_browser {
        my $self = shift;

        my $with = $self->header('x-requested-with');
        return 0
            if $with && grep { $with eq $_ }
                qw( HTTP.Request XMLHttpRequest );

        if ( uc $self->method eq 'GET' ) {
            my $forced_type = $self->param('content-type');
            return 0
                if $forced_type && !$HTMLTypes{$forced_type};
        }

        # IE7 does not say it accepts any form of html, but _does_
        # accept */* (helpful ;)
        return 1
            if $self->accepts('*/*');

        return 1
            if grep { $self->accepts($_) } keys %HTMLTypes;

        return 0
            if @{ $self->accepted_content_types() };

        # If the client did not specify any content types at all,
        # assume they are a browser.
        return 1;
    }
}

1;

__END__

=pod

=head1 NAME

Catalyst::TraitFor::Request::REST::ForBrowsers - A request trait for REST and browsers

=head1 SYNOPSIS

    package MyApp;
    use Moose;
    use namespace::autoclean;

    use Catalyst;
    use CatalystX::RoleApplicator;

    extends 'Catalyst';

    __PACKAGE__->apply_request_class_roles(qw[
        Catalyst::TraitFor::Request::REST::ForBrowsers
    ]);

=head1 DESCRIPTION

Writing REST-y apps is a good thing, but if you're also trying to support web
browsers, you're probably going to need some hackish workarounds. This module
provides those workarounds for you.

Specifically, it lets you do two things. First, it lets you "tunnel" PUT and
DELETE requests across a POST, since most browsers do not support PUT or
DELETE actions (as of early 2009, at least).

Second, it provides a heuristic to check if the client is a web browser,
regardless of what content types it claims to accept. The reason for this is
that while a browser might claim to accept the "application/xml" content type,
it's really not going to do anything useful with it, and you're best off
giving it HTML.

=head1 METHODS

This class provides the following methods:

=head2 $request->method

This method works just like C<< Catalyst::Request->method() >> except it
allows for tunneling of PUT and DELETE requests via a POST.

Specifically, you can provide a form element named "x-tunneled-method" which
can override the request method for a POST. This I<only> works for a POST, not
a GET.

You can also use a header named "x-http-method-override" instead (Google uses
this header for its APIs).

=head2 $request->looks_like_browser

This attribute provides a heuristic to determine whether or not the request
I<appears> to come from a browser. You can use this however you want. I
usually use it to determine whether or not to give the client a full HTML page
or some sort of serialized data.

This is a heuristic, and like any heuristic, it is probably wrong
sometimes. Here is how it works:

=over 4

=item *

If the request includes a header "X-Request-With" set to either "HTTP.Request"
or "XMLHttpRequest", this returns false. The assumption is that if you're
doing XHR, you don't want the request treated as if it comes from a browser.

=item *

If the client makes a GET request with a query string parameter
"content-type", and that type is I<not> an HTML type, it is I<not> a browser.

=item *

If the client provides an Accept header which includes "*/*" as an accepted
content type, the client is a browser. Specifically, it is IE7, which submits
an Accept header of "*/*". IE7's Accept header does not include any html types
like "text/html".

=item *

If the client provides an Accept header and accepts either "text/html" or
"application/xhtml+xml" it is a browser.

=item *

If it provides an Accept header of any sort that doesn't match one of the
above criteria, it is I<not> a browser.

=item *

The default is that the client is a browser.

=back

This all works well for my apps, but read it carefully to make sure it meets
your expectations before using it.

=head1 AUTHOR

Dave Rolsky, C<< <autarch@urth.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-action-rest@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
