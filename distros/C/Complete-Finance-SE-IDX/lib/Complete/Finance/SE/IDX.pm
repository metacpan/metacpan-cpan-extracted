package Complete::Finance::SE::IDX;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-18'; # DATE
our $DIST = 'Complete-Finance-SE-IDX'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_idx_listed_stock_code
               );

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to Indonesian Stock Exchange',
};

$SPEC{complete_idx_listed_stock_code} = {
    v => 1.1,
    summary => 'Complete from list of currently listed stock codes',
    args => {
        %arg_word,
    },
    result_naked => 1,
};
sub complete_idx_listed_stock_code {
    require Complete::Util;
    require Finance::SE::IDX::Static;

    my %args = @_;

    Complete::Util::complete_array_elem(
        word => $args{word},
        array     => [map {$_->[0]} @{$Finance::SE::IDX::Static::data_stock}],
        summaries => [map {$_->[2]} @{$Finance::SE::IDX::Static::data_stock}],
    );
}

1;
# ABSTRACT: Completion routines related to Indonesian Stock Exchange

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Finance::SE::IDX - Completion routines related to Indonesian Stock Exchange

=head1 VERSION

This document describes version 0.001 of Complete::Finance::SE::IDX (from Perl distribution Complete-Finance-SE-IDX), released on 2021-01-18.

=head1 FUNCTIONS


=head2 complete_idx_listed_stock_code

Usage:

 complete_idx_listed_stock_code(%args) -> any

Complete from list of currently listed stock codes.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

Word to complete.


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Finance-SE-IDX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Finance-SE-IDX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Complete-Finance-SE-IDX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
