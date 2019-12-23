package App::EscapeUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-15'; # DATE
our $DIST = 'App-EscapeUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %arg_strings = (
    strings => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'string',
        schema => ['array*', of=>'str*'],
        req => 1,
        pos => 0,
        greedy => 1,
        cmdline_src => 'stdin_or_args',
        stream => 1,
    },
);

$SPEC{uri_escape} = {
    v => 1.1,
    summary => 'URI-escape lines of input (in standard input or arguments)',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub uri_escape {
    require URI::Escape;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return URI::Escape::uri_escape($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{uri_unescape} = {
    v => 1.1,
    summary => 'URI-unescape lines of input (in standard input or arguments)',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub uri_unescape {
    require URI::Escape;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return URI::Escape::uri_unescape($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{js_escape} = {
    v => 1.1,
    summary => 'Encode lines of input (in standard input or arguments) '.
        'as JSON strings',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub js_escape {
    require String::JS;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return String::JS::encode_js_string($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{js_unescape} = {
    v => 1.1,
    summary => 'Interpret lines of input (in standard input or arguments) as '.
        'JSON strings and return the decoded value',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub js_unescape {
    require String::JS;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return String::JS::decode_js_string($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{backslash_escape} = {
    v => 1.1,
    summary => 'Escape lines of input using backslash octal sequence '.
        '(or \\r, \\n, \\t)',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub backslash_escape {
    require String::Escape;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return String::Escape::backslash($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{backslash_unescape} = {
    v => 1.1,
    summary => 'Restore backslash octal sequence (or \\r, \\n, \\t) to '.
        'original characters in lines of input (in stdin or arguments)',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub backslash_unescape {
    require String::Escape;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return String::Escape::unbackslash($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{html_escape} = {
    v => 1.1,
    summary => 'HTML-escape lines of input (in stdin or arguments)',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub html_escape {
    require HTML::Entities;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return HTML::Entities::encode_entities($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{html_unescape} = {
    v => 1.1,
    summary => 'HTML-unescape lines of input (in stdin or arguments)',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub html_unescape {
    require HTML::Entities;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return HTML::Entities::decode_entities($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{shell_escape} = {
    v => 1.1,
    summary => 'Shell-escape lines of input (in stdin or arguments)',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub shell_escape {
    require ShellQuote::Any::Tiny;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return ShellQuote::Any::Tiny::shell_quote($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{pod_escape} = {
    v => 1.1,
    summary => 'Quote POD special characters in input (in stdin or arguments)',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub pod_escape {
    require String::PodQuote;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return String::PodQuote::pod_quote($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{perl_dquote_escape} = {
    v => 1.1,
    summary => 'Encode lines of input (in stdin or arguments) inside Perl double-quoted strings',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub perl_dquote_escape {
    require String::PerlQuote;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return String::PerlQuote::double_quote($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

$SPEC{perl_squote_escape} = {
    v => 1.1,
    summary => 'Encode lines of input (in stdin or arguments) inside Perl single-quoted strings',
    args => {
        %arg_strings,
    },
    result => {
        schema => 'str*',
        stream => 1,
    },
};
sub perl_squote_escape {
    require String::PerlQuote;

    my %args = @_;

    my $strings = $args{strings};
    my $cb = sub {
        my $str = $strings->();
        if (defined $str) {
            return String::PerlQuote::single_quote($str);
        } else {
            return undef;
        }
    };

    return [200, "OK", $cb];
}

1;
# ABSTRACT: Various string escaping/unescaping utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

App::EscapeUtils - Various string escaping/unescaping utilities

=head1 VERSION

This document describes version 0.002 of App::EscapeUtils (from Perl distribution App-EscapeUtils), released on 2019-12-15.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<backslash-escape>

=item * L<backslash-unescape>

=item * L<html-escape>

=item * L<html-unescape>

=item * L<js-escape>

=item * L<js-unescape>

=item * L<perl-dquote-escape>

=item * L<perl-squote-escape>

=item * L<pod-escape>

=item * L<shell-escape>

=item * L<uri-escape>

=item * L<uri-unescape>

=back

=head1 FUNCTIONS


=head2 backslash_escape

Usage:

 backslash_escape(%args) -> [status, msg, payload, meta]

Escape lines of input using backslash octal sequence (or \r, \n, \t).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 backslash_unescape

Usage:

 backslash_unescape(%args) -> [status, msg, payload, meta]

Restore backslash octal sequence (or \r, \n, \t) to original characters in lines of input (in stdin or arguments).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 html_escape

Usage:

 html_escape(%args) -> [status, msg, payload, meta]

HTML-escape lines of input (in stdin or arguments).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 html_unescape

Usage:

 html_unescape(%args) -> [status, msg, payload, meta]

HTML-unescape lines of input (in stdin or arguments).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 js_escape

Usage:

 js_escape(%args) -> [status, msg, payload, meta]

Encode lines of input (in standard input or arguments) as JSON strings.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 js_unescape

Usage:

 js_unescape(%args) -> [status, msg, payload, meta]

Interpret lines of input (in standard input or arguments) as JSON strings and return the decoded value.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 perl_dquote_escape

Usage:

 perl_dquote_escape(%args) -> [status, msg, payload, meta]

Encode lines of input (in stdin or arguments) inside Perl double-quoted strings.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 perl_squote_escape

Usage:

 perl_squote_escape(%args) -> [status, msg, payload, meta]

Encode lines of input (in stdin or arguments) inside Perl single-quoted strings.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 pod_escape

Usage:

 pod_escape(%args) -> [status, msg, payload, meta]

Quote POD special characters in input (in stdin or arguments).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 shell_escape

Usage:

 shell_escape(%args) -> [status, msg, payload, meta]

Shell-escape lines of input (in stdin or arguments).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 uri_escape

Usage:

 uri_escape(%args) -> [status, msg, payload, meta]

URI-escape lines of input (in standard input or arguments).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)



=head2 uri_unescape

Usage:

 uri_unescape(%args) -> [status, msg, payload, meta]

URI-unescape lines of input (in standard input or arguments).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-EscapeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-EscapeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-EscapeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<URI::Escape>

L<String::JS>

L<String::Escape>

L<HTML::Entities>

L<String::ShellQuote> and L<ShellQuote::Any::Tiny>

L<String::xcPodQuote>

L<String::PerlQuote>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
