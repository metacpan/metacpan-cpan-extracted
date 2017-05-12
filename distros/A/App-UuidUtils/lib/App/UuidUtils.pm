package App::UuidUtils;

our $DATE = '2015-09-27'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{gen_uuids} = {
    v => 1.1,
    summary => 'Generate UUIDs, with several options',
    description => <<'_',

This utility is meant to generate one or several UUIDs with several options,
like algorithm

_
    args => {
        algorithm => {
            schema => ['str*', in=>[qw/random/]],
            default => 'random',
            cmdline_aliases => {a=>{}},
        },
        num => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
            pos => 0,
        },
    },
};
sub gen_uuids {
    my %args = @_;

    my $num  = $args{num} // 1;
    my $algo = $args{algorithm} // 'random';

    my $res = [200, "OK"];
    if ($num > 1) { $res->[2] = [] }

    # currently the only available algorithm
    require UUID::Random;

    for (1..$num) {
        my $uuid = UUID::Random::generate();
        if ($num > 1) {
            push @{ $res->[2] }, $uuid;
        } else {
            $res->[2] = $uuid;
        }
    }

    $res;
}

1;
# ABSTRACT: Command-line utilities related to UUIDs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::UuidUtils - Command-line utilities related to UUIDs

=head1 VERSION

This document describes version 0.02 of App::UuidUtils (from Perl distribution App-UuidUtils), released on 2015-09-27.

=head1 DESCRIPTION

This distribution contains command-line utilities related to UUIDs:

=over

=item * L<gen-uuids>

=back

=head1 FUNCTIONS


=head2 gen_uuids(%args) -> [status, msg, result, meta]

Generate UUIDs, with several options.

This utility is meant to generate one or several UUIDs with several options,
like algorithm

Arguments ('*' denotes required arguments):

=over 4

=item * B<algorithm> => I<str> (default: "random")

=item * B<num> => I<int> (default: 1)

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-UuidUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-UuidUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-UuidUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
