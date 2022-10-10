package App::UnixUIDUtils;

use 5.010001;
use strict;
use warnings;

our %SPEC;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-24'; # DATE
our $DIST = 'App-UnixUIDUtils'; # DIST
our $VERSION = '0.002'; # VERSION

$SPEC{gid_to_groupname} = {
    v => 1.1,
    args => {
        group => {
            schema => 'unix::groupname::exists*',
            req => 1,
            pos => 0,
        },
    },
};
sub gid_to_groupname {
    my %args = @_;

    # this function actually just utilizes the coercion rule
    [200, "OK", $args{group}];
}

$SPEC{uid_to_username} = {
    v => 1.1,
    args => {
        user => {
            schema => 'unix::username::exists*',
            req => 1,
            pos => 0,
        },
    },
};
sub uid_to_username {
    my %args = @_;

    # this function actually just utilizes the coercion rule
    [200, "OK", $args{user}];
}

$SPEC{groupname_to_gid} = {
    v => 1.1,
    args => {
        group => {
            schema => 'unix::gid::exists*',
            req => 1,
            pos => 0,
        },
    },
};
sub groupname_to_gid {
    my %args = @_;

    # this function actually just utilizes the coercion rule
    [200, "OK", $args{group}];
}

$SPEC{username_to_uid} = {
    v => 1.1,
    args => {
        user => {
            schema => 'unix::uid::exists*',
            req => 1,
            pos => 0,
        },
    },
};
sub username_to_uid {
    my %args = @_;

    # this function actually just utilizes the coercion rule
    [200, "OK", $args{user}];
}

1;
# ABSTRACT: Utilities related to Unix UID/GID

__END__

=pod

=encoding UTF-8

=head1 NAME

App::UnixUIDUtils - Utilities related to Unix UID/GID

=head1 VERSION

This document describes version 0.002 of App::UnixUIDUtils (from Perl distribution App-UnixUIDUtils), released on 2022-07-24.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<gid-to-groupname>

=item * L<groupname-to-gid>

=item * L<uid-to-username>

=item * L<username-to-uid>

=back

=head1 FUNCTIONS


=head2 gid_to_groupname

Usage:

 gid_to_groupname(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<group>* => I<unix::groupname::exists>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 groupname_to_gid

Usage:

 groupname_to_gid(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<group>* => I<unix::gid::exists>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 uid_to_username

Usage:

 uid_to_username(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<user>* => I<unix::username::exists>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 username_to_uid

Usage:

 username_to_uid(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<user>* => I<unix::uid::exists>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-UnixUIDUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-UnixUIDUtils>.

=head1 SEE ALSO

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-UnixUIDUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
