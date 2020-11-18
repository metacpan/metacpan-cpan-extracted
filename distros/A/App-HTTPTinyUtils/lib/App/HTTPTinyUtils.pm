package App::HTTPTinyUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-17'; # DATE
our $DIST = 'App-HTTPTinyUtils'; # DIST
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Sub::Util qw(gen_modified_sub);

our %SPEC;

sub _http_tiny {
    my ($class, %args) = @_;

    (my $class_pm = "$class.pm") =~ s!::!/!g;
    require $class_pm;

    my $res;
    my $method = $args{method} // 'GET';
    for my $i (0 .. $#{ $args{urls} }) {
        my $url = $args{urls}[$i];
        my $is_last_url = $i == $#{ $args{urls} };

        my %opts;
        if (defined $args{content}) {
            $opts{content} = $args{content};
        } elsif (!(-t STDIN)) {
            local $/;
            $opts{content} = <STDIN>;
        }

        log_trace "Request: $method $url ...";
        my $res0 = $class->new(%{ $args{attributes} // {} })
            ->request($method, $url, \%opts);
        my $success = $res0->{success};

        if ($args{raw}) {
            $res = [200, "OK", $res0];
        } else {
            $res = [$res0->{status}, $res0->{reason}, $res0->{content}];
            print $res0->{content} unless $is_last_url;
        }

        unless ($success) {
            last unless $args{ignore_errors};
        }
    }
    $res;
}

$SPEC{http_tiny} = {
    v => 1.1,
    summary => 'Perform request(s) with HTTP::Tiny',
    args => {
        urls => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'url',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
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
        ignore_errors => {
            summary => 'Ignore errors',
            description => <<'_',

Normally, when given multiple URLs, the utility will exit after the first
non-success response. With `ignore_errors` set to true, will just log the error
and continue. Will return with the last error response.

_
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
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
    summary => 'Perform request(s) with HTTP::Tiny::Cache',
    description => <<'_',

Like `http_tiny`, but uses <pm:HTTP::Tiny::Cache> instead of <pm:HTTP::Tiny>.
See the documentation of HTTP::Tiny::Cache on how to set cache period.

_
    output_code => sub { _http_tiny('HTTP::Tiny::Cache', @_) },
);

gen_modified_sub(
    output_name => 'http_tiny_plugin',
    base_name   => 'http_tiny',
    summary => 'Perform request(s) with HTTP::Tiny::Plugin',
    description => <<'_',

Like `http_tiny`, but uses <pm:HTTP::Tiny::Plugin> instead of <pm:HTTP::Tiny>.
See the documentation of HTTP::Tiny::Plugin for more details.

_
    output_code => sub { _http_tiny('HTTP::Tiny::Plugin', @_) },
);

gen_modified_sub(
    output_name => 'http_tiny_retry',
    base_name   => 'http_tiny',
    summary => 'Perform request(s) with HTTP::Tiny::Retry',
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
    summary => 'Perform request(s) with HTTP::Tiny::CustomRetry',
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

gen_modified_sub(
    output_name => 'http_tiny_plugin_every',
    base_name   => 'http_tiny',
    summary => 'Perform request(s) with HTTP::Tiny::Plugin every N seconds, log result in a directory',
    description => <<'_',

Like `http_tiny_plugin`, but perform the request every N seconds and log the
result in a directory.

_
    modify_meta => sub {
        my $meta = shift;
        $meta->{args}{every} = {
            schema => 'duration*',
            req => 1,
        };
        $meta->{args}{dir} = {
            schema => 'dirname*',
            req => 1,
        };
    },
    output_code => sub {
        require Log::ger::App;

        my %args = @_;

        my $log_dump = Log::ger->get_logger(category => 'Dump');

        no warnings 'once';
        shift @Log::ger::App::IMPORT_ARGS;
        #log_trace("Existing Log::ger::App import: %s", \@Log::ger::App::IMPORT_ARGS);
        Log::ger::App->import(
            @Log::ger::App::IMPORT_ARGS,
            outputs => {
                DirWriteRotate => {
                    conf => {
                        path => $args{dir},
                        max_files => 10_000,
                    },
                    level => 'off',
                    category_level => {
                        Dump => 'info',
                    },
                },
            },
            extra_conf => {
                category_level => {
                    Dump => 'off',
                },
            },
        );

        while (1) {
            my $res = _http_tiny('HTTP::Tiny::Plugin', %args);
            if ($res->[0] !~ /^(200|304)/) {
                log_warn "Failed: $res->[1], skipped saving to directory";
            } else {
                $log_dump->info($res->[2]);
            }
            log_trace "Sleeping %s second(s) ...", $args{every};
            sleep $args{every};
        }
        [200];
    },
);

1;
# ABSTRACT: Command-line utilities related to HTTP::Tiny

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HTTPTinyUtils - Command-line utilities related to HTTP::Tiny

=head1 VERSION

This document describes version 0.009 of App::HTTPTinyUtils (from Perl distribution App-HTTPTinyUtils), released on 2020-11-17.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to L<HTTP::Tiny>:

=over

=item * L<http-tiny>

=item * L<http-tiny-cache>

=item * L<http-tiny-customretry>

=item * L<http-tiny-plugin>

=item * L<http-tiny-plugin-every>

=item * L<http-tiny-retry>

=back

=head1 FUNCTIONS


=head2 http_tiny

Usage:

 http_tiny(%args) -> [status, msg, payload, meta]

Perform request(s) with HTTP::Tiny.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<ignore_errors> => I<bool>

Ignore errors.

Normally, when given multiple URLs, the utility will exit after the first
non-success response. With C<ignore_errors> set to true, will just log the error
and continue. Will return with the last error response.

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<urls>* => I<array[str]>


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

Perform request(s) with HTTP::Tiny::Cache.

Like C<http_tiny>, but uses L<HTTP::Tiny::Cache> instead of L<HTTP::Tiny>.
See the documentation of HTTP::Tiny::Cache on how to set cache period.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<ignore_errors> => I<bool>

Ignore errors.

Normally, when given multiple URLs, the utility will exit after the first
non-success response. With C<ignore_errors> set to true, will just log the error
and continue. Will return with the last error response.

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<urls>* => I<array[str]>


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

Perform request(s) with HTTP::Tiny::CustomRetry.

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

=item * B<ignore_errors> => I<bool>

Ignore errors.

Normally, when given multiple URLs, the utility will exit after the first
non-success response. With C<ignore_errors> set to true, will just log the error
and continue. Will return with the last error response.

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<urls>* => I<array[str]>


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

Perform request(s) with HTTP::Tiny::Plugin.

Like C<http_tiny>, but uses L<HTTP::Tiny::Plugin> instead of L<HTTP::Tiny>.
See the documentation of HTTP::Tiny::Plugin for more details.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<ignore_errors> => I<bool>

Ignore errors.

Normally, when given multiple URLs, the utility will exit after the first
non-success response. With C<ignore_errors> set to true, will just log the error
and continue. Will return with the last error response.

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<urls>* => I<array[str]>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 http_tiny_plugin_every

Usage:

 http_tiny_plugin_every(%args) -> [status, msg, payload, meta]

Perform request(s) with HTTP::Tiny::Plugin every N seconds, log result in a directory.

Like C<http_tiny_plugin>, but perform the request every N seconds and log the
result in a directory.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<dir>* => I<dirname>

=item * B<every>* => I<duration>

=item * B<headers> => I<hash>

=item * B<ignore_errors> => I<bool>

Ignore errors.

Normally, when given multiple URLs, the utility will exit after the first
non-success response. With C<ignore_errors> set to true, will just log the error
and continue. Will return with the last error response.

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<urls>* => I<array[str]>


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

Perform request(s) with HTTP::Tiny::Retry.

Like C<http_tiny>, but uses L<HTTP::Tiny::Retry> instead of L<HTTP::Tiny>.
See the documentation of HTTP::Tiny::Retry for more details.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to HTTP::Tiny constructor.

=item * B<content> => I<str>

=item * B<headers> => I<hash>

=item * B<ignore_errors> => I<bool>

Ignore errors.

Normally, when given multiple URLs, the utility will exit after the first
non-success response. With C<ignore_errors> set to true, will just log the error
and continue. Will return with the last error response.

=item * B<method> => I<str> (default: "GET")

=item * B<raw> => I<bool>

=item * B<urls>* => I<array[str]>


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

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
