package App::AlgorithmDiffUtils;

our $DATE = '2017-07-29'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities based on Algorithm::Diff',
};

sub _read_files {
    my $args = shift;

    my $fh;
    open $fh, "<", $args->{file1} or die "Can't open file '$args->{file1}': $!";
    chomp(my @seq1 = <$fh>);
    open $fh, "<", $args->{file2} or die "Can't open file '$args->{file2}': $!";
    chomp(my @seq2 = <$fh>);

    return (\@seq1, \@seq2);
}

my %args_common = (
    file1 => {
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
    file2 => {
        schema => 'filename*',
        req => 1,
        pos => 1,
    },
);

$SPEC{algodiff_lcs} = {
    v => 1.1,
    summary => "Perform LCS() on two files",
    args => {
        %args_common,
    },
};
sub algodiff_lcs {
    require Algorithm::Diff;
    my %args = @_;

    my ($seq1, $seq2) = _read_files(\%args);
    my $lcs = Algorithm::Diff::LCS($seq1, $seq2);
    [200, "OK", $lcs];
}

$SPEC{algodiff_diff} = {
    v => 1.1,
    summary => "Perform diff() on two files",
    args => {
        %args_common,
    },
};
sub algodiff_diff {
    require Algorithm::Diff;
    my %args = @_;

    my ($seq1, $seq2) = _read_files(\%args);
    my $diff = Algorithm::Diff::diff($seq1, $seq2);
    [200, "OK", $diff];
}

$SPEC{algodiff_sdiff} = {
    v => 1.1,
    summary => "Perform sdiff() on two files",
    args => {
        %args_common,
    },
};
sub algodiff_sdiff {
    require Algorithm::Diff;
    my %args = @_;

    my ($seq1, $seq2) = _read_files(\%args);
    my $sdiff = Algorithm::Diff::sdiff($seq1, $seq2);
    [200, "OK", $sdiff];
}

$SPEC{algodiff_compact_diff} = {
    v => 1.1,
    summary => "Perform compact_diff() on two files",
    args => {
        %args_common,
    },
};
sub algodiff_compact_diff {
    require Algorithm::Diff;
    my %args = @_;

    my ($seq1, $seq2) = _read_files(\%args);
    my $cdiff = Algorithm::Diff::compact_diff($seq1, $seq2);
    [200, "OK", $cdiff];
}

1;
# ABSTRACT: CLI utilities based on Algorithm::Diff

__END__

=pod

=encoding UTF-8

=head1 NAME

App::AlgorithmDiffUtils - CLI utilities based on Algorithm::Diff

=head1 VERSION

This document describes version 0.001 of App::AlgorithmDiffUtils (from Perl distribution App-AlgorithmDiffUtils), released on 2017-07-29.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities:

=over

=item * L<algodiff-compact-diff>

=item * L<algodiff-diff>

=item * L<algodiff-lcs>

=item * L<algodiff-sdiff>

=back

=head1 FUNCTIONS


=head2 algodiff_compact_diff

Usage:

 algodiff_compact_diff(%args) -> [status, msg, result, meta]

Perform compact_diff() on two files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file1>* => I<filename>

=item * B<file2>* => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 algodiff_diff

Usage:

 algodiff_diff(%args) -> [status, msg, result, meta]

Perform diff() on two files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file1>* => I<filename>

=item * B<file2>* => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 algodiff_lcs

Usage:

 algodiff_lcs(%args) -> [status, msg, result, meta]

Perform LCS() on two files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file1>* => I<filename>

=item * B<file2>* => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 algodiff_sdiff

Usage:

 algodiff_sdiff(%args) -> [status, msg, result, meta]

Perform sdiff() on two files.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file1>* => I<filename>

=item * B<file2>* => I<filename>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-AlgorithmDiffUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-AlgorithmDiffUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AlgorithmDiffUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
