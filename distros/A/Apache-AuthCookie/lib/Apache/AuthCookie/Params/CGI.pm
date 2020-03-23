package Apache::AuthCookie::Params::CGI;
$Apache::AuthCookie::Params::CGI::VERSION = '3.29';
# ABSTRACT: Internal CGI Params Subclass

use strict;
use warnings;
use Carp ();
use WWW::Form::UrlEncoded qw(parse_urlencoded);
use Hash::MultiValue;
use HTTP::Body;
use Encode ();


sub new {
    my ($class, $r) = @_;

    $class = ref $class || $class;

    return bless {
        _request => $r
    }, $class;
}


sub request {
    my $self = shift;

    return $self->{_request};
}


sub param {
    my ($self, $name, @vals) = @_;

    # no param name given, return list of all parameter names.
    unless (defined $name) {
        return $self->params->keys;
    }

    # set values
    if (@vals) {
        $self->params->remove($name);
        $self->params->add($name => @vals);
    }

    # return values
    return $self->params->get_all($name);
}


sub params {
    my $self = shift;

    $self->{_params} ||= Hash::MultiValue->new(
        map $_->flatten, $self->query_params, $self->body_params
    );
}


sub query_params {
    my $self = shift;

    $self->{_query_params} ||= $self->_compute_pnote('request.query-params', sub {
        my $query = $self->request->args || '';

        $self->_decode( Hash::MultiValue->new(parse_urlencoded($query)) );
    });
}


sub body_params {
    my $self = shift;

    $self->{_body_params} ||= $self->_compute_pnote('request.body-params', sub {
        $self->_decode( Hash::MultiValue->from_mixed($self->_http_body->param) );
    });
}


sub content_length {
    my $self = shift;

    $self->{_content_length} ||=
        $self->request->headers_in->get('Content-Length') || 0;
}


sub content_type {
    my $self = shift;

    $self->{_content_type} ||=
        $self->request->headers_in->get('Content-Type') || '';
}

sub _http_body {
    my $self = shift;

    $self->{_http_body} ||= $self->_compute_pnote('request.body', sub {
        $self->_read_body;
    });
}

sub _read_body {
    my $self = shift;

    my $length = $self->content_length;

    my $body = HTTP::Body->new($self->content_type, $length);

    # HTTP::Body creates temp files for uploads. we need to tell it to clean up
    # those files when the body goes out of scope.
    $body->cleanup(1);

    my $r = $self->request;

    my $spin = 0;

    while ($length) {
        $r->read(my $buffer, ($length < 8192) ? $length : 8192);

        my $bytes_read = length $buffer;

        $length -= $bytes_read;
        $body->add($buffer);

        # guard against a signal interrupting read()
        if ($bytes_read == 0 && $spin++ > 2000) {
            Carp::croak "Bad Content-Length: maybe client disconnect? ($length bytes remaining)";
        }
    }

    return $body;
}

# utility method to fetch a pnote, or set it to a computed value if it has not
# already been set.
sub _compute_pnote {
    my ($self, $key, $code) = @_;

    my $r = $self->request;

    unless (defined $r->pnotes($key)) {
        $r->pnotes($key, $code->());
    }

    return $r->pnotes($key);
}

sub _decode {
    my ($self, $hash) = @_;

    my $r = $self->request;
    my $auth_name = $r->auth_name;

    if (my $encoding = $r->dir_config("${auth_name}Encoding")) {
        my $decoded = Hash::MultiValue->new;

        $hash->each(sub {
            my @dec = map { Encode::decode($encoding, $_) } @_;

            $decoded->add(@dec);
        });

        return $decoded;
    }
    else {
        return $hash;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Apache::AuthCookie::Params::CGI - Internal CGI Params Subclass

=head1 VERSION

version 3.29

=head1 SYNOPSIS

 Internal Use Only!

=head1 DESCRIPTION

This is a pure perl implementation of HTTP/CGI parameter processing for Apache::AuthCookie.

=head1 METHODS

=head2 new($r)

Constructor

=head2 request(): scalar

Get the apache request object

=head2 param()

Get or set parameters. This manipulates the enderlying L<params()> object.  When called with no parameters returns the list of CGI parameter names.  Return value depends on the arguments passed:

=over 4

=item *

param()

Return the list of CGI parameter names

=item *

param($field)

Return the value of the given CGI field.  If the field has multiple values they will all be returned as a list.

=item *

param($field, @values)

Set the given CGI field value to the given values.  Existing values will be replaced.
=end

=back

=head2 params(): Hash::MultiValue

Get the underlying CGI parameters.  This is a merged version of
L<query_params()> and L<body_params()>.

=head2 query_params(): Hash::MultiValue

Get the request query parameters.

=head2 body_params(): Hash::MultiValue

Get the request body parameters.

=head2 content_length(): int

Get the values of the C<Content-Length> header.  Returns C<0> if the header is not present or empty.

=head2 content_type(): string

Get the value of the C<Content-Type> header.  Returns an empty string if the
header is not present.

=head1 SOURCE

The development version is on github at L<https://https://github.com/mschout/apache-authcookie>
and may be cloned from L<git://https://github.com/mschout/apache-authcookie.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/apache-authcookie/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Ken Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
