package App::SortSubUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-14'; # DATE
our $DIST = 'App-SortSubUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{list_sort_sub_modules} = {
    v => 1.1,
};
sub list_sort_sub_modules {
    require Module::List::Tiny;

    my %args = @_;

    my $res = Module::List::Tiny::list_modules(
        "Sort::Sub::", {list_modules=>1, recurse=>1});
    my @rows;
    for (sort keys %$res) {
        s/^Sort::Sub:://;
        push @rows, $_;
    }
    [200, "OK", \@rows];
}

1;
# ABSTRACT: CLIs related to Sort::Sub

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SortSubUtils - CLIs related to Sort::Sub

=head1 VERSION

This document describes version 0.002 of App::SortSubUtils (from Perl distribution App-SortSubUtils), released on 2019-12-14.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution contains the following CLIs related to L<Sort::Sub>:

=over

=item * L<list-sort-sub-modules>

=back

=head1 FUNCTIONS


=head2 list_sort_sub_modules

Usage:

 list_sort_sub_modules() -> [status, msg, payload, meta]

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SortSubUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SortSubUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SortSubUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Sub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
