package Complete::Cwalitee;

our $DATE = '2019-07-05'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_cwalitee_indicators
               );

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines for *::Cwalitee modules',
};

$SPEC{complete_cwalitee_indicator} = {
    v => 1.1,
    summary => 'Complete from list of available cwalitee indicators',
    args => {
        %arg_word,
        prefix => {
            schema => 'perl::modprefix',
            default => '',
        },
    },
    result_naked => 1,
};
sub complete_cwalitee_indicator {
    require Complete::Util;
    require Cwalitee::Common;

    my %args = @_;

    my $res = Cwalitee::Common::list_cwalitee_indicators(
        prefix => $args{prefix},
    );

    return {message=>"Cannot list cwalitee indicators: $res->[0] - $res->[1]"}
        unless $res->[0] == 200;

    Complete::Util::complete_array_elem(
        word => $args{word},
        array => $res->[2],
    );
}

1;
# ABSTRACT: Completion routines for *::Cwalitee modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Cwalitee - Completion routines for *::Cwalitee modules

=head1 VERSION

This document describes version 0.001 of Complete::Cwalitee (from Perl distribution Complete-Cwalitee), released on 2019-07-05.

=head1 FUNCTIONS


=head2 complete_cwalitee_indicator

Usage:

 complete_cwalitee_indicator(%args) -> any

Complete from list of available cwalitee indicators.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<prefix> => I<perl::modprefix> (default: "")

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Cwalitee>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Cwalitee>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Cwalitee>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
