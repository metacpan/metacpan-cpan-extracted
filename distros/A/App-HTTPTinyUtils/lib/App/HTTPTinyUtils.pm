package App::HTTPTinyUtils;

our $DATE = '2019-04-14'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Util qw(gen_modified_sub);

our %SPEC;

sub _http_tiny {
    my ($class, %args) = @_;

    (my $class_pm = "$class.pm") =~ s!::!/!g;
    require $class_pm;

    my $url = $args{url};
    my $method = $args{method} // 'GET';

    my %opts;

    if (defined $args{content}) {
        $opts{content} = $args{content};
    } elsif (!(-t STDIN)) {
        local $/;
        $opts{content} = <STDIN>;
    }

    my $res = $class->new(%{ $args{attributes} // {} })
        ->request($method, $url, \%opts);

    if ($args{raw}) {
        [200, "OK", $res];
    } else {
        [$res->{status}, $res->{reason}, $res->{content}];
    }
}

$SPEC{http_tiny} = {
    v => 1.1,
    summary => 'Perform request with HTTP::Tiny',
    args => {
        url => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        method => {
            schema => ['str*', match=>qr/\A[A-Z]+\z/],
            default => 'GET',
            cmdline_aliases => {
                delete => {summary => 'Shortcut for --method DELETE', is_flag=>1, code=>sub { $_[0]{method} = 'DELETE' } },
                get    => {summary => 'Shortcut for --method GET'   , is_flag=>1, code=>sub { $_[0]{method} = 'GET'    } },
                head   => {summary => 'Shortcut for --method HEAD'  , is_flag=>1, code=>sub { $_[0]{method} = 'HEAD'   } },
                post   => {summary => 'Shortcut for --method POST'  , is_flag=>1, code=>sub { $_[0]{method} = 'POST'   } },
                put    => {summary => 'Shortcut for --method PUT'   , is_flag=>1, code=>sub { $_[0]{method} = 'PUT'    } },
            },
        },
        attributes => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'attribute',
            summary => 'Pass attributes to HTTP::Tiny constructor',
            schema => ['hash*', each_key => 'str*'],
        },
        headers => {
            schema => ['hash*', of=>'str*'],
            'x.name.is_plural' => 1,
            'x.name.singular' => 'header',
        },
        content => {
            schema => 'str*',
        },
        raw => {
            schema => 'bool*',
        },
        # XXX option: agent
        # XXX option: timeout
        # XXX option: post form
    },
};
sub http_tiny {
    _http_tiny('HTTP::Tiny', @_);
}

gen_modified_sub(
    output_name => 'http_tiny_cache',
    base_name   => 'http_tiny',
    summary => 'Perform request with HTTP::Tiny::Cache',
    description => <<'_',

Like `http_tiny`, but uses <pm:HTTP::Tiny::Cache> instead of <pm:HTTP::Tiny>.
See the documentation of HTTP::Tiny::Cache on how to set cache period.

_
    output_code => sub { _http_tiny('HTTP::Tiny::Cache', @_) },
);

gen_modified_sub(
    output_name => 'http_tiny_plugin',
    base_name   => 'http_tiny',
    summary => 'Perform request with HTTP::Tiny::Plugin',
    description => <<'_',

Like `http_tiny`, but uses <pm:HTTP::Tiny::Plugin> instead of <pm:HTTP::Tiny>.
See the documentation of HTTP::Tiny::Plugin for more details.

_
    output_code => sub { _http_tiny('HTTP::Tiny::Plugin', @_) },
);

gen_modified_sub(
    output_name => 'http_tiny_retry',
    base_name   => 'http_tiny',
    summary => 'Perform request with HTTP::Tiny::Retry',
    description => <<'_',

Like `http_tiny`, but uses <pm:HTTP::Tiny::Retry> instead of <pm:HTTP::Tiny>.
See the documentation of HTTP::Tiny::Retry for more details.

_
    modify_meta => sub {
        my $meta = shift;

        $meta->{args}{attributes}{cmdline_aliases} = {
            retries => {
                summary => 'Number of retries',
                code => sub { $_[0]{attributes}{retries} = $_[1] },
            },
            retry_delay => {
                summary => 'Retry delay',
                code => sub { $_[0]{attributes}{retry_delay} = $_[1] },
            },
        };
    },
    output_code => sub { _http_tiny('HTTP::Tiny::Retry', @_) },
);

gen_modified_sub(
    output_name => 'http_tiny_customretry',
    base_name   => 'http_tiny',
    summary => 'Perform request with HTTP::Tiny::CustomRetry',
    description => <<'_',

Like `http_tiny`, but uses <pm:HTTP::Tiny::CustomRetry> instead of
<pm:HTTP::Tiny>. See the documentation of HTTP::Tiny::CustomRetry for more
details.

_
    modify_meta => sub {
        my $meta = shift;

        $meta->{args}{attributes}{cmdline_aliases} = {
            retry_strategy => {
                summary => 'Choose backoff strategy',
                code => sub { $_[0]{attributes}{retry_strategy} = $_[1] },
                # disabled, unrecognized for now
                _completion => sub {
                    require Complete::Module;

                    my %args = @_;

                    Complete::Module::complete_module(
                        word => $args{word},
                        ns_prefix => 'Algorithm::Backoff',
                    );
                },
            },
        };
    },
    output_code => sub { _http_tiny('HTTP::Tiny::CustomRetry', @_) },
);

1;
# ABSTRACT: Command-line utilities related to HTTP::Tiny

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HTTPTinyUtils - Command-line utilities related to HTTP::Tiny

=head1 VERSION

This document describes version 0.005 of App::HTTPTinyUtils (from Perl distribution App-HTTPTinyUtils), released on 2019-04-14.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to L<HTTP::Tiny>:

=over

=item * L<http-tiny>

=item * L<http-tiny-cache>

=item * L<http-tiny-customretry>

=item * L<http-tiny-plugin>

=item * L<http-tiny-retry>

=back

=head1 FUNCTIONS


=head2 http_tiny

Usage:

 http_tiny(%args) -> [status, msg, payload, meta]

Perform request with HTTP::Tiny.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<url>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 http_tiny_cache

Usage:

 http_tiny_cache(%args) -> [status, msg, payload, meta]

Perform request with HTTP::Tiny::Cache.

Like C<http_tiny>, but uses L<HTTP::Tiny::Cache> instead of L<HTTP::Tiny>.
See the documentation of HTTP::Tiny::Cache on how to set cache period.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<url>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 http_tiny_customretry

Usage:

 http_tiny_customretry(%args) -> [status, msg, payload, meta]

Perform request with HTTP::Tiny::CustomRetry.

Like C<http_tiny>, but uses L<HTTP::Tiny::CustomRetry> instead of
L<HTTP::Tiny>. See the documentation of HTTP::Tiny::CustomRetry for more
details.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<url>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 http_tiny_plugin

Usage:

 http_tiny_plugin(%args) -> [status, msg, payload, meta]

Perform request with HTTP::Tiny::Plugin.

Like C<http_tiny>, but uses L<HTTP::Tiny::Plugin> instead of L<HTTP::Tiny>.
See the documentation of HTTP::Tiny::Plugin for more details.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<url>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 http_tiny_retry

Usage:

 http_tiny_retry(%args) -> [status, msg, payload, meta]

Perform request with HTTP::Tiny::Retry.

Like C<http_tiny>, but uses L<HTTP::Tiny::Retry> instead of L<HTTP::Tiny>.
See the documentation of HTTP::Tiny::Retry for more details.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<url>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-HTTPTinyUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-HTTPTinyUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-HTTPTinyUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
