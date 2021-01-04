package App::OverlapUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-12-30'; # DATE
our $DIST = 'App-OverlapUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{combine_overlap} = {
    v => 1.1,
    summary => 'Given two or more files (ordered sequences of lines), combine overlapping items',
    description => <<'_',

See <pm:Array::OverlapFinder> for more details.

_
    args => {
        files => {
            schema => ['array*', of=>'filename*', min_len=>2],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
};
sub combine_overlap {
    require Array::OverlapFinder;
    require File::Slurper::Dash;

    my %args = @_;
    my @seqs;
    for my $file (@{ $args{files} }) {
        my $content = File::Slurper::Dash::read_text($file);
        chomp(my @lines = split /^/m, $content);
        push @seqs, \@lines;
    }
    my @combined_seq = Array::OverlapFinder::combine_overlap(@seqs);
    [200, "OK", \@combined_seq];
}

1;
# ABSTRACT: Command-line utilities related to overlapping lines

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverlapUtils - Command-line utilities related to overlapping lines

=head1 VERSION

This document describes version 0.001 of App::OverlapUtils (from Perl distribution App-OverlapUtils), released on 2020-12-30.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes the following command-line utilities related to
overlapping lines:

=over

=item * L<combine-overlap>

=back

=head1 FUNCTIONS


=head2 combine_overlap

Usage:

 combine_overlap(%args) -> [status, msg, payload, meta]

Given two or more files (ordered sequences of lines), combine overlapping items.

See L<Array::OverlapFinder> for more details.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-OverlapUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-OverlapUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-OverlapUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Array::OverlapFinder>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
