package App::wordstat;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-11'; # DATE
our $DIST = 'App-wordstat'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{wordstat} = {
    v => 1.1,
    summary => 'Return word statistics of a text',
    args => {
        text => {
            schema => ['str*'],
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_files',
        },
        # XXX ci
    },
    examples => [
        {
            args => {text=><<'_'},
An optimistic person sees good things everywhere, is generally confident and
hopeful of what the future holds. From the optimist's point-of-view the world is
full of potential opportunities. The pessimist, on the other hand, observes
mainly the negative aspects of everything around.

_
            naked_result => {
                'avg_line_len' => '56',
                'avg_line_with_words_len' => '70',
                'avg_nonempty_line_len' => '70',
                'avg_word_len' => '5.17777777777778',
                'avg_words_per_line' => '9',
                'avg_words_per_line_with_words' => '11.25',
                'avg_words_per_nonempty_line' => '11.25',
                'longest_word_len' => 13,
                'num_chars' => 285,
                'num_lines' => 5,
                'num_lines_with_words' => 4,
                'num_nonempty_lines' => 4,
                'num_unique_words' => 36,
                'num_words' => 45,
                'shortest_word_len' => 1
            },
        },
        {
            summary => 'Supply text from file or stdin',
            argv => ['file.txt'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub wordstat {
    my %args = @_;
    my $text = $args{text};

    my %stats = (
        # line stats
        num_lines => 0,
        num_nonempty_lines => 0,
        num_lines_with_words => 0,
        avg_line_len => 0,
        avg_nonempty_line_len => 0,
        avg_line_with_words_len => 0,

        # word stats
        num_words => 0,
        num_unique_words => 0,
        longest_word_len => 0,
        shortest_word_len => undef,
        avg_word_len => 0,
        avg_words_per_line => 0,
        avg_words_per_nonempty_line => 0,
        avg_words_per_line_with_words => 0,

        # char stats
        num_chars => 0,
    );

    $stats{num_chars} = length($text);

  LINE_STATS: {
        my @lines = split /^/m, $text;
        chomp for @lines;

        my $tot_line_len = 0;
        for my $line (@lines) {
            my $line_len = length($line);

            $stats{num_lines}++;
            $stats{num_nonempty_lines}++ if $line =~ /\S/;
            $stats{num_lines_with_words}++ if $line =~ /\w+/;
            $tot_line_len += $line_len;
        }
        $stats{avg_line_len}            = $tot_line_len / $stats{num_lines} if $stats{num_lines};
        $stats{avg_nonempty_line_len}   = $tot_line_len / $stats{num_nonempty_lines} if $stats{num_nonempty_lines};
        $stats{avg_line_with_words_len} = $tot_line_len / $stats{num_lines_with_words} if $stats{num_lines_with_words};
    }

  WORD_STATS: {
        my %words;
        my $tot_word_len = 0;
        while ($text =~ /(\w+)/g) {
            my $word = $1;
            my $word_len = length($word);

            $stats{num_words}++;
            $stats{num_unique_words}++ unless $words{ lc $word }++;
            $stats{longest_word_len}  = $word_len if $word_len > $stats{longest_word_len};
            $stats{shortest_word_len} = $word_len if !defined($stats{shortest_word_len}) || $stats{shortest_word_len} > $word_len;
            $tot_word_len += $word_len;
        }

        $stats{avg_word_len} = $tot_word_len / $stats{num_words} if $stats{num_words};
        $stats{avg_words_per_line}            = $stats{num_words} / $stats{num_lines} if $stats{num_lines};
        $stats{avg_words_per_nonempty_line}   = $stats{num_words} / $stats{num_nonempty_lines} if $stats{num_nonempty_lines};
        $stats{avg_words_per_line_with_words} = $stats{num_words} / $stats{num_lines_with_words} if $stats{num_lines_with_words};
    }

    [200, "OK", \%stats];
}

1;
# ABSTRACT: Return word statistics of a text

__END__

=pod

=encoding UTF-8

=head1 NAME

App::wordstat - Return word statistics of a text

=head1 VERSION

This document describes version 0.003 of App::wordstat (from Perl distribution App-wordstat), released on 2020-10-11.

=head1 DESCRIPTION

See included script L<wordstat>.

=head1 FUNCTIONS


=head2 wordstat

Usage:

 wordstat(%args) -> [status, msg, payload, meta]

Return word statistics of a text.

Examples:

=over

=item * Example #1:

 wordstat(text => "An optimistic person sees good things everywhere, is generally confident and\nhopeful of what the future holds. From the optimist's point-of-view the world is\nfull of potential opportunities. The pessimist, on the other hand, observes\nmainly the negative aspects of everything around.\n\n");

Result:

 [
   200,
   "OK (envelope generated)",
   {
     avg_line_len                  => 56,
     avg_line_with_words_len       => 70,
     avg_nonempty_line_len         => 70,
     avg_word_len                  => 5.17777777777778,
     avg_words_per_line            => 9,
     avg_words_per_line_with_words => 11.25,
     avg_words_per_nonempty_line   => 11.25,
     longest_word_len              => 13,
     num_chars                     => 285,
     num_lines                     => 5,
     num_lines_with_words          => 4,
     num_nonempty_lines            => 4,
     num_unique_words              => 36,
     num_words                     => 45,
     shortest_word_len             => 1,
   },
 ]

=item * Supply text from file or stdin:

 wordstat( text => "file.txt");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<text>* => I<str>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-wordstat>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-wordstat>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-wordstat>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<freqtable> from L<App::freqtable>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
