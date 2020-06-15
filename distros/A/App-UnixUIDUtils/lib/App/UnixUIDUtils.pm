package App::UnixUIDUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'App-UnixUIDUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{gid_to_groupname} = {
    v => 1.1,
    args => {
        group => {
            schema => 'unix::local_groupname*',
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
            schema => 'unix::local_username*',
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
            schema => 'unix::local_gid*',
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
            schema => 'unix::local_uid*',
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

This document describes version 0.001 of App::UnixUIDUtils (from Perl distribution App-UnixUIDUtils), released on 2020-06-13.

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

 gid_to_groupname(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<group>* => I<unix::local_groupname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 groupname_to_gid

Usage:

 groupname_to_gid(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<group>* => I<unix::local_gid>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 uid_to_username

Usage:

 uid_to_username(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<user>* => I<unix::local_username>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 username_to_uid

Usage:

 username_to_uid(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<user>* => I<unix::local_uid>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-UnixUIDUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-UnixUIDUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-UnixUIDUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
