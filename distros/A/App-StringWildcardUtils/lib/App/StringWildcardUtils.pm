package App::StringWildcardUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-09'; # DATE
our $DIST = 'App-StringWildcardUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %arg0_string = (
    string => {
        schema => 'str*',
        req => 1,
        pos => 0,
    },
);

our %argopt_quiet = (
    quiet => {
        schema => 'true*',
        cmdline_aliases => {q=>{}},
    },
);

$SPEC{parse_bash_wildcard} = {
    v => 1.1,
    summary => 'Parse Unix-style wildcard using String::Wildcard::Bash and return the captures',
    args => {
        %arg0_string,
    },
};
sub parse_bash_wildcard {
    require String::Wildcard::Bash;

    my %args = @_;

    my $string = $args{string};
    my @matches; push @matches, {%+}
        while $string =~ /$String::Wildcard::Bash::RE_WILDCARD_BASH/g;

    [200, "OK", \@matches];
}

$SPEC{contains_bash_wildcard} = {
    v => 1.1,
    summary => 'Check whether string contains Unix-style wildcard',
    args => {
        %arg0_string,
        %argopt_quiet,
    },
};
sub contains_bash_wildcard {
    require String::Wildcard::Bash;

    my %args = @_;

    my $contains = String::Wildcard::Bash::contains_wildcard($args{string});
    [200, "OK",
     ($args{quiet} ? "" : $contains ? "String contains wildcard" : "String does NOT contain wildcard"),
     {"cmdline.exit_code" => $contains?0:1}];
}

$SPEC{parse_sql_wildcard} = {
    v => 1.1,
    summary => 'Parse SQL-style wildcard using String::Wildcard::SQL and return the captures',
    args => {
        %arg0_string,
    },
};
sub parse_sql_wildcard {
    require String::Wildcard::SQL;

    my %args = @_;

    my $string = $args{string};
    my @matches; push @matches, {%+}
        while $string =~ /$String::Wildcard::SQL::RE_WILDCARD_SQL/g;

    [200, "OK", \@matches];
}

$SPEC{contains_sql_wildcard} = {
    v => 1.1,
    summary => 'Check whether string contains SQL wildcard',
    args => {
        %arg0_string,
        %argopt_quiet,
    },
};
sub contains_sql_wildcard {
    require String::Wildcard::SQL;

    my %args = @_;

    my $contains = String::Wildcard::SQL::contains_wildcard($args{string});
    [200, "OK",
     ($args{quiet} ? "" : $contains ? "String contains wildcard" : "String does NOT contain wildcard"),
     {"cmdline.exit_code" => $contains?0:1}];
}

$SPEC{convert_bash_wildcard_to_re} = {
    v => 1.1,
    summary => 'Convert Unix-style wildcard to regex',
    args => {
        %arg0_string,
    },
};
sub convert_bash_wildcard_to_re {
    require String::Wildcard::Bash;

    my %args = @_;

    [200, "OK", String::Wildcard::Bash::convert_wildcard_to_re($args{string})];
}


$SPEC{convert_bash_wildcard_to_sql_wildcard} = {
    v => 1.1,
    summary => 'Convert Unix-style wildcard to SQL wildcard',
    args => {
        %arg0_string,
    },
};
sub convert_bash_wildcard_to_sql_wildcard {
    require String::Wildcard::Bash;

    my %args = @_;

    [200, "OK", String::Wildcard::Bash::convert_wildcard_to_sql($args{string})];
}

1;
# ABSTRACT: Utilities related to wildcard strings

__END__

=pod

=encoding UTF-8

=head1 NAME

App::StringWildcardUtils - Utilities related to wildcard strings

=head1 VERSION

This document describes version 0.001 of App::StringWildcardUtils (from Perl distribution App-StringWildcardUtils), released on 2020-02-09.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<contains-bash-wildcard>

=item * L<contains-sql-wildcard>

=item * L<convert-bash-wildcard-to-re>

=item * L<convert-bash-wildcard-to-sql-wildcard>

=item * L<parse-bash-wildcard>

=item * L<parse-sql-wildcard>

=back

=head1 FUNCTIONS


=head2 contains_bash_wildcard

Usage:

 contains_bash_wildcard(%args) -> [status, msg, payload, meta]

Check whether string contains Unix-style wildcard.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<true>

=item * B<string>* => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 contains_sql_wildcard

Usage:

 contains_sql_wildcard(%args) -> [status, msg, payload, meta]

Check whether string contains SQL wildcard.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<true>

=item * B<string>* => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 convert_bash_wildcard_to_re

Usage:

 convert_bash_wildcard_to_re(%args) -> [status, msg, payload, meta]

Convert Unix-style wildcard to regex.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<string>* => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 convert_bash_wildcard_to_sql_wildcard

Usage:

 convert_bash_wildcard_to_sql_wildcard(%args) -> [status, msg, payload, meta]

Convert Unix-style wildcard to SQL wildcard.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<string>* => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_bash_wildcard

Usage:

 parse_bash_wildcard(%args) -> [status, msg, payload, meta]

Parse Unix-style wildcard using String::Wildcard::Bash and return the captures.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<string>* => I<str>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_sql_wildcard

Usage:

 parse_sql_wildcard(%args) -> [status, msg, payload, meta]

Parse SQL-style wildcard using String::Wildcard::SQL and return the captures.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<string>* => I<str>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-StringWildcardUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-StringWildcardUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-StringWildcardUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<String::Wilcard::Bash>

L<String::Wilcard::SQL>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
