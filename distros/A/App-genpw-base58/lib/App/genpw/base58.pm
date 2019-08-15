package App::genpw::base58;

our $DATE = '2018-01-16'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::genpw ();

our %SPEC;

my %args = %{$App::genpw::SPEC{genpw}{args}};
delete $args{patterns};
delete $args{case};

$SPEC{genpw} = {
    v => 1.1,
    summary => 'Generate random password using base58 characters',
    description => <<'_',

_
    args => {
        %args,
    },
    examples => [
    ],
};
sub genpw {
    my %args = @_;

    my $min_len = $args{len} // $args{min_len} // 8;
    my $max_len = $args{len} // $args{max_len} // 20;

    App::genpw::genpw(
        %args,
        patterns => ["%${min_len}\$${max_len}b"],
    );
}

1;
# ABSTRACT: Generate random password using base58 characters

__END__

=pod

=encoding UTF-8

=head1 NAME

App::genpw::base58 - Generate random password using base58 characters

=head1 VERSION

This document describes version 0.002 of App::genpw::base58 (from Perl distribution App-genpw-base58), released on 2018-01-16.

=head1 SYNOPSIS

See the included script L<genpw-base58>.

=head1 FUNCTIONS


=head2 genpw

Usage:

 genpw(%args) -> [status, msg, result, meta]

Generate random password using base58 characters.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<len> => I<posint>

If no pattern is supplied, will generate random alphanum characters with this exact length.

=item * B<max_len> => I<posint>

If no pattern is supplied, will generate random alphanum characters with this maximum length.

=item * B<min_len> => I<posint>

If no pattern is supplied, will generate random alphanum characters with this minimum length.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-genpw-base58>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-genpw-base58>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-genpw-base58>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Base58>

L<genpw> (from L<App::genpw>)

L<genpw-base56> (from L<App::genpw::base56>)

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
