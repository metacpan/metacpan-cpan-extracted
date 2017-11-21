package App::Genpass::WordList;

our $DATE = '2017-11-12'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

require App::wordlist;

our %SPEC;

$SPEC{genpass} = {
    v => 1.1,
    summary => 'Generate password with words from WordList::*',
    args => {
        num => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
        },
        %App::wordlist::arg_wordlists,
    },
    examples => [
    ],
};
sub genpass {

    my %args = @_;

    my $num = $args{num} // 1;
    my $wordlists = $args{wordlists};
    my $min_len;
    if (!$wordlists || !@$wordlists) {
        $wordlists = ['EN::Enable'];
        $min_len = 6;
    }

    my $res = App::wordlist::wordlist(
        wordlists => $wordlists,
        random    => 1,
        num       => 2*$num,
        (min_len   => $min_len) x !!defined($min_len),
    );
    return $res unless $res->[0] == 200;

    my @pass;
    for my $i (1..$num) {
        my $w1 = shift @{$res->[2]};
        my $w2 = shift @{$res->[2]};
        my $num1 = 1000 + int(9000*rand());
        push @pass, $w1 . $num1 . $w2;
    }

    [200, "OK", \@pass];
}

1;
# ABSTRACT: Generate password with words from WordList::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Genpass::WordList - Generate password with words from WordList::*

=head1 VERSION

This document describes version 0.001 of App::Genpass::WordList (from Perl distribution App-Genpass-WordList), released on 2017-11-12.

=head1 SYNOPSIS

See the included script L<genpass-wordlist>.

=head1 FUNCTIONS


=head2 genpass

Usage:

 genpass(%args) -> [status, msg, result, meta]

Generate password with words from WordList::*.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<int> (default: 1)

=item * B<wordlists> => I<array[str]>

Select one or more wordlist modules.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-Genpass-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-Genpass-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Genpass-WordList>

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
