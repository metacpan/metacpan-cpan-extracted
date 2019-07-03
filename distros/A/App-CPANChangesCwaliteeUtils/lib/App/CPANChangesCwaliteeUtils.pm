package App::CPANChangesCwaliteeUtils;

our $DATE = '2019-07-03'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{calc_cpan_changes_cwalitee} = {
    v => 1.1,
    summary => 'Calculate CPAN Changes cwalitee',
    args => {
        path => {
            schema => 'pathname*',
            pos => 0,
        },
    },
};
sub calc_cpan_changes_cwalitee {
    require CPAN::Changes::Cwalitee;

    my %args = @_;

    my $path;
    for my $f (
        "Changes",
        "CHANGES",
        "ChangeLog",
        "CHANGELOG",
        (grep {/change|chn?g/i} glob("*")),
    ) {
        if (-f $f) {
            $path = $f;
            last;
        }
    }
    unless ($path) {
        return [400, "Please specify path"];
    }
    CPAN::Changes::Cwalitee::calc_cpan_changes_cwalitee(
        path => $path,
    );
}

1;
# ABSTRACT: CLI Utilities related to CPAN Changes cwalitee

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CPANChangesCwaliteeUtils - CLI Utilities related to CPAN Changes cwalitee

=head1 VERSION

This document describes version 0.001 of App::CPANChangesCwaliteeUtils (from Perl distribution App-CPANChangesCwaliteeUtils), released on 2019-07-03.

=head1 DESCRIPTION

This distribution includes the following utilities:

=over

=item * L<calc-cpan-changes-cwalitee>

=item * L<list-cpan-changes-cwalitee-indicators>

=back

=head1 FUNCTIONS


=head2 calc_cpan_changes_cwalitee

Usage:

 calc_cpan_changes_cwalitee(%args) -> [status, msg, payload, meta]

Calculate CPAN Changes cwalitee.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<pathname>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CPANChangesCwaliteeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CPANChangesCwaliteeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CPANChangesCwaliteeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Changes::Cwalitee>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
