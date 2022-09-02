package App::SahUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-16'; # DATE
our $DIST = 'App-SahUtils'; # DIST
our $VERSION = '0.480'; # VERSION

our %SPEC;

$SPEC{get_sah_type} = {
    v => 1.1,
    summary => 'Extract type from a Sah string or array schema',
    description => <<'_',

Uses <pm:Data::Sah::Util::Type>'s `get_type()` to extract the type name part of
the schema.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub get_sah_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    [200, "OK", Data::Sah::Util::Type::get_type($args{schema})];
}

$SPEC{is_sah_builtin_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a Sah builtin type',
    description => <<'_',

Uses <pm:Data::Sah::Util::Type>'s `is_type()` to return the type of the schema
is the type is known builtin type, or undef if type is unknown.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_builtin_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    [200, "OK", Data::Sah::Util::Type::is_type($args{schema})];
}

$SPEC{is_sah_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a Sah type',
    description => <<'_',

The difference from this and `is_sah_builtin_type` is: if type is not a known
builtin type, this routine will try to resolve the schema using
<pm:Data::Sah::Resolve> then try again.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    my $res;
    unless ($res = Data::Sah::Util::Type::is_type($args{schema})) {
        require Data::Sah::Resolve;
        eval { $res = Data::Sah::Resolve::resolve_schema($args{schema}) };
        unless ($@) {
            $res = Data::Sah::Util::Type::is_type($res);
        }
    }

    [200, "OK", $res];
}

$SPEC{is_sah_simple_builtin_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a Sah simple builtin type',
    description => <<'_',

Uses <pm:Data::Sah::Util::Type>'s `is_simple()` to check whether the schema is a
simple Sah builtin type.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_simple_builtin_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    [200, "OK", Data::Sah::Util::Type::is_simple($args{schema})];
}

$SPEC{is_sah_simple_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a simple Sah type',
    description => <<'_',

The difference from this and `is_sah_simple_builtin_type` is: if type is not a
known builtin type, this routine will try to resolve the schema using
<pm:Data::Sah::Resolve> then try again.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_simple_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    my $res;
    if (Data::Sah::Util::Type::is_type($args{schema})) {
        $res = Data::Sah::Util::Type::is_simple($args{schema});
    } else {
        require Data::Sah::Resolve;
        eval { $res = Data::Sah::Resolve::resolve_schema($args{schema}) };
        unless ($@) {
            $res = Data::Sah::Util::Type::is_simple($res);
        }
    }

    [200, "OK", $res];
}

$SPEC{is_sah_collection_builtin_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a Sah collection builtin type',
    description => <<'_',

Uses <pm:Data::Sah::Util::Type>'s `is_collection()` to check whether the schema
is a collection Sah builtin type.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_collection_builtin_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    [200, "OK", Data::Sah::Util::Type::is_collection($args{schema})];
}

$SPEC{is_sah_collection_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a collection Sah type',
    description => <<'_',

The difference from this and `is_sah_collection_builtin_type` is: if type is not
a known builtin type, this routine will try to resolve the schema using
<pm:Data::Sah::Resolve> then try again.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_collection_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    my $res;
    if (Data::Sah::Util::Type::is_type($args{schema})) {
        $res = Data::Sah::Util::Type::is_collection($args{schema});
    } else {
        require Data::Sah::Resolve;
        eval { $res = Data::Sah::Resolve::resolve_schema($args{schema}) };
        unless ($@) {
            $res = Data::Sah::Util::Type::is_collection($res);
        }
    }

    [200, "OK", $res];
}

$SPEC{is_sah_ref_builtin_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a Sah ref builtin type',
    description => <<'_',

Uses <pm:Data::Sah::Util::Type>'s `is_ref()` to check whether the schema is a
ref Sah builtin type.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_ref_builtin_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    [200, "OK", Data::Sah::Util::Type::is_ref($args{schema})];
}

$SPEC{is_sah_ref_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a ref Sah type',
    description => <<'_',

The difference from this and `is_sah_ref_builtin_type` is: if type is not
a known builtin type, this routine will try to resolve the schema using
<pm:Data::Sah::Resolve> then try again.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_ref_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    my $res;
    if (Data::Sah::Util::Type::is_type($args{schema})) {
        $res = Data::Sah::Util::Type::is_ref($args{schema});
    } else {
        require Data::Sah::Resolve;
        eval { $res = Data::Sah::Resolve::resolve_schema($args{schema}) };
        unless ($@) {
            $res = Data::Sah::Util::Type::is_ref($res);
        }
    }

    [200, "OK", $res];
}

$SPEC{is_sah_numeric_builtin_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a Sah numeric builtin type',
    description => <<'_',

Uses <pm:Data::Sah::Util::Type>'s `is_ref()` to check whether the schema is a
numeric Sah builtin type.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_numeric_builtin_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    [200, "OK", Data::Sah::Util::Type::is_numeric($args{schema})];
}

$SPEC{is_sah_numeric_type} = {
    v => 1.1,
    summary => 'Check that a string or array schema is a numeric Sah type',
    description => <<'_',

The difference from this and `is_sah_numeric_builtin_type` is: if type is not a
known builtin type, this routine will try to resolve the schema using
<pm:Data::Sah::Resolve> then try again.

_
    args => {
        schema => {
            schema => 'any*', # XXX 'sah::schema*' still causes deep recursion
            req => 1,
            pos => 0,
        },
    },
};
sub is_sah_numeric_type {
    require Data::Sah::Util::Type;

    my %args = @_;
    my $res;
    if (Data::Sah::Util::Type::is_type($args{schema})) {
        $res = Data::Sah::Util::Type::is_numeric($args{schema});
    } else {
        require Data::Sah::Resolve;
        eval { $res = Data::Sah::Resolve::resolve_schema($args{schema}) };
        unless ($@) {
            $res = Data::Sah::Util::Type::is_numeric($res);
        }
    }

    [200, "OK", $res];
}

1;
# ABSTRACT: Collection of CLI utilities for Sah and Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SahUtils - Collection of CLI utilities for Sah and Data::Sah

=head1 VERSION

This document describes version 0.480 of App::SahUtils (from Perl distribution App-SahUtils), released on 2022-07-16.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
L<Sah> and L<Data::Sah>:

=over

=item * L<coerce-with-sah>

=item * L<filter-with-sah>

=item * L<format-with-sah>

=item * L<get-sah-type>

=item * L<is-sah-builtin-type>

=item * L<is-sah-collection-builtin-type>

=item * L<is-sah-collection-type>

=item * L<is-sah-numeric-builtin-type>

=item * L<is-sah-numeric-type>

=item * L<is-sah-ref-builtin-type>

=item * L<is-sah-ref-type>

=item * L<is-sah-simple-builtin-type>

=item * L<is-sah-simple-type>

=item * L<is-sah-type>

=item * L<list-sah-clauses>

=item * L<list-sah-coerce-rule-modules>

=item * L<list-sah-filter-rule-modules>

=item * L<list-sah-pschema-modules>

=item * L<list-sah-pschemas-modules>

=item * L<list-sah-schema-modules>

=item * L<list-sah-schemas-modules>

=item * L<list-sah-type-modules>

=item * L<normalize-sah-schema>

=item * L<resolve-sah-schema>

=item * L<sah-to-human>

=item * L<show-sah-coerce-rule-module>

=item * L<show-sah-filter-rule-module>

=item * L<show-sah-schema-module>

=item * L<validate-with-sah>

=back

=head1 FUNCTIONS


=head2 get_sah_type

Usage:

 get_sah_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Extract type from a Sah string or array schema.

Uses L<Data::Sah::Util::Type>'s C<get_type()> to extract the type name part of
the schema.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_builtin_type

Usage:

 is_sah_builtin_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a Sah builtin type.

Uses L<Data::Sah::Util::Type>'s C<is_type()> to return the type of the schema
is the type is known builtin type, or undef if type is unknown.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_collection_builtin_type

Usage:

 is_sah_collection_builtin_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a Sah collection builtin type.

Uses L<Data::Sah::Util::Type>'s C<is_collection()> to check whether the schema
is a collection Sah builtin type.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_collection_type

Usage:

 is_sah_collection_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a collection Sah type.

The difference from this and C<is_sah_collection_builtin_type> is: if type is not
a known builtin type, this routine will try to resolve the schema using
L<Data::Sah::Resolve> then try again.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_numeric_builtin_type

Usage:

 is_sah_numeric_builtin_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a Sah numeric builtin type.

Uses L<Data::Sah::Util::Type>'s C<is_ref()> to check whether the schema is a
numeric Sah builtin type.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_numeric_type

Usage:

 is_sah_numeric_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a numeric Sah type.

The difference from this and C<is_sah_numeric_builtin_type> is: if type is not a
known builtin type, this routine will try to resolve the schema using
L<Data::Sah::Resolve> then try again.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_ref_builtin_type

Usage:

 is_sah_ref_builtin_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a Sah ref builtin type.

Uses L<Data::Sah::Util::Type>'s C<is_ref()> to check whether the schema is a
ref Sah builtin type.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_ref_type

Usage:

 is_sah_ref_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a ref Sah type.

The difference from this and C<is_sah_ref_builtin_type> is: if type is not
a known builtin type, this routine will try to resolve the schema using
L<Data::Sah::Resolve> then try again.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_simple_builtin_type

Usage:

 is_sah_simple_builtin_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a Sah simple builtin type.

Uses L<Data::Sah::Util::Type>'s C<is_simple()> to check whether the schema is a
simple Sah builtin type.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_simple_type

Usage:

 is_sah_simple_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a simple Sah type.

The difference from this and C<is_sah_simple_builtin_type> is: if type is not a
known builtin type, this routine will try to resolve the schema using
L<Data::Sah::Resolve> then try again.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_sah_type

Usage:

 is_sah_type(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that a string or array schema is a Sah type.

The difference from this and C<is_sah_builtin_type> is: if type is not a known
builtin type, this routine will try to resolve the schema using
L<Data::Sah::Resolve> then try again.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<schema>* => I<any>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SahUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SahUtils>.

=head1 SEE ALSO

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SahUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
