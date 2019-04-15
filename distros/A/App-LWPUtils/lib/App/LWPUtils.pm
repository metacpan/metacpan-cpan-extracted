package App::LWPUtils;

our $DATE = '2019-04-15'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Util qw(gen_modified_sub);

our %SPEC;

sub _lwputil_request {
    require HTTP::Request;

    my ($class, %args) = @_;

    (my $class_pm = "$class.pm") =~ s!::!/!g;
    require $class_pm;

    my $res;
    my $method = $args{method} // 'GET';
    for my $i (0 .. $#{ $args{urls} }) {
        my $url = $args{urls}[$i];
        my $is_last_url = $i == $#{ $args{urls} };

        my $req = HTTP::Request->new($method => $url);

        if (defined $args{headers}) {
            for (keys %{ $args{headers} }) {
                $req->header($_ => $args{headers}{$_});
            }
        }
        if (defined $args{content}) {
            $req->content($args{content});
        } elsif (!(-t STDIN)) {
            local $/;
            $req->content(scalar <STDIN>);
        }

        my $res0 = $class->new(%{ $args{attributes} // {} })
            ->request($req);
        my $success = $res0->is_success;

        if ($args{raw}) {
            $res = [200, "OK", $res0->as_string];
        } else {
            $res = [$res0->code, $res0->message, $res0->content];
            print $res0->content unless $is_last_url;
        }

        unless ($success) {
            last unless $args{ignore_errors};
        }
    }
    $res;
}

$SPEC{lwputil_request} = {
    v => 1.1,
    summary => 'Perform request(s) with LWP::UserAgent',
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
            summary => 'Pass attributes to LWP::UserAgent constructor',
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
sub lwputil_request {
    _lwputil_request('LWP::UserAgent', @_);
}

gen_modified_sub(
    output_name => 'lwputil_request_plugin',
    base_name   => 'lwputil_request',
    summary => 'Perform request(s) with LWP::UserAgent::Plugin',
    description => <<'_',

Like `lwputil_request`, but uses <pm:LWP::UserAgent::Plugin> instead of
<pm:LWP::UserAgent>. See the documentation of LWP::UserAgent::Plugin for more
details.

_
    output_code => sub { _lwputil_request('LWP::UserAgent::Plugin', @_) },
);

1;
# ABSTRACT: Command-line utilities related to LWP

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LWPUtils - Command-line utilities related to LWP

=head1 VERSION

This document describes version 0.002 of App::LWPUtils (from Perl distribution App-LWPUtils), released on 2019-04-15.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to L<LWP> and
L<LWP::UserAgent>:

=over

=item * L<lwputil-request>

=item * L<lwputil-request-plugin>

=back

=head1 FUNCTIONS


=head2 lwputil_request

Usage:

 lwputil_request(%args) -> [status, msg, payload, meta]

Perform request(s) with LWP::UserAgent.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to LWP::UserAgent constructor.

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



=head2 lwputil_request_plugin

Usage:

 lwputil_request_plugin(%args) -> [status, msg, payload, meta]

Perform request(s) with LWP::UserAgent::Plugin.

Like C<lwputil_request>, but uses L<LWP::UserAgent::Plugin> instead of
L<LWP::UserAgent>. See the documentation of LWP::UserAgent::Plugin for more
details.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<attributes> => I<hash>

Pass attributes to LWP::UserAgent constructor.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-LWPUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LWPUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LWPUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Standard utilities that come with L<LWP>: L<lwp-download>, L<lwp-request>,
L<lwp-dump>, L<lwp-mirror>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
