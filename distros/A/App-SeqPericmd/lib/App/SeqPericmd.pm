package App::SeqPericmd;

our $DATE = '2016-09-28'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use List::Util qw(max);

our %SPEC;

$SPEC{seq} = {
    v => 1.1,
    summary => 'Rinci-/Perinci::CmdLine-based "seq"-like CLI utility',
    description => <<'_',

This utility is similar to Unix `seq` command, with a few differences: some
differences in option names, JSON output, allow infinite stream (when `to` is
not specified).

_
    args_rels => {
        dep_any => ['equal_width', ['to']], # can't specify equal_width without to
    },
    args => {
        from => {
            schema => 'float*',
            req => 1,
            pos => 0,
        },
        to => {
            schema => 'float*',
            pos => 1,
        },
        increment => {
            schema => 'float*',
            default => 1,
            cmdline_aliases => {i=>{}},
            pos => 2,
        },
        header => {
            summary => 'Add a header row',
            schema => 'str*',
        },
        equal_width => {
            summary => 'Equalize width by padding with leading zeros',
            schema => ['bool*', is=>1],
            cmdline_aliases => {w=>{}},
        },
        limit => {
            summary => 'Only generate a certain amount of numbers',
            schema => ['int*', min=>1],
            cmdline_aliases => {n=>{}},
        },
        number_format => {
            summary => 'sprintf() format for each number',
            schema => ['str*'],
            cmdline_aliases => {f=>{}},
        },
    },
    examples => [
        {
            summary => 'Generate whole numbers from 1 to 10 (1, 2, ..., 10)',
            src => '[[prog]] 1 10',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate odd numbers from 1 to 10 (1, 3, 5, 7, 9)',
            src => '[[prog]] 1 10 2',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate 1, 1.5, 2, 2.5, ..., 10',
            src => '[[prog]] 1 10 -i 0.5',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate stream 1, 1.5, 2, 2.5, ...',
            src => '[[prog]] 1 -i 0.5',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate 01, 02, ..., 10',
            src => '[[prog]] 1 10 -w',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate 0001, 0002, ..., 0010',
            src => '[[prog]] 1 10 -f "%04s"',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Generate -10, -9, -8, -7, -6 (limit 5 numbers)',
            src => '[[prog]] --from -10 --to 0 -n 5',
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Use with fsql',
            src => q{[[prog]] 1 100 --header num | fsql --add-tsv - --add-csv data.csv 'SELECT num, data1 FROM stdin LEFT JOIN data ON stdin.num=data.num'},
            src_plang => 'bash',
            'x.doc.show_result' => 0,
        },
    ],
};
sub seq {
    my %args = @_;

    my $fmt = $args{number_format};
    if (!defined($fmt)) {
        if ($args{equal_width}) {
            my $neg = $args{from}<0 || $args{to}<0 || $args{increment}<0 ? 1:0;
            my $width_whole = max(
                length(int($args{from}     )),
                length(int($args{to}       )),
                length(int($args{increment})),
            );
            my $width_frac  = max(
                length($args{from}      - int($args{from}     )),
                length($args{to}        - int($args{to}       )),
                length($args{increment} - int($args{increment})),
            ) - 2;
            $width_frac = 0 if $width_frac < 0;
            $fmt = sprintf("%%0%d.%df",
                           $width_whole+$width_frac+($width_frac ? 1:0) + $neg,
                           $width_frac,
                       );
            #say "D:fmt=$fmt";
        } elsif ($args{from} != int($args{from}) ||
                     defined($args{to}) && $args{to} != int($args{to}) ||
                     $args{increment} || int($args{increment})) {
            # use fixed floating point to avoid showing round-off errors
            my $width_frac  = max(
                length($args{from}      - int($args{from}     )),
                length($args{increment} - int($args{increment})),
                (defined($args{to}) ?
                     (length($args{to}-int($args{to}))) : ()),
            ) - 2;
            $width_frac = 0 if $width_frac < 0;
            $fmt = sprintf("%%.%df", $width_frac);
        }
    }

    if (defined $args{to}) {
        my @res;
        push @res, $args{header} if $args{header};
        my $i = $args{from}+0;
        while ($i <= $args{to}) {
            push @res, defined($fmt) ? sprintf($fmt, $i) : $i;
            last if defined($args{limit}) && @res >= $args{limit};
            $i += $args{increment};
        }
        return [200, "OK", \@res];
    } else {
        # stream
        my $i = $args{from}+0;
        my $j = $args{header} ? -1 : 0;
        my $next_i;
        #my $finish;
        my $func = sub {
            #return undef if $finish;
            $i = $next_i if $j++ > 0;
            return $args{header} if $j == 0 && $args{header};
            $next_i = $i + $args{increment};
            #$finish = 1 if ...
            return defined($fmt) ? sprintf($fmt, $i) : $i;
        };
        return [200, "OK", $func, {stream=>1}];
    }
}

1;
# ABSTRACT: Rinci-/Perinci::CmdLine-based "seq"-like CLI utility

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SeqPericmd - Rinci-/Perinci::CmdLine-based "seq"-like CLI utility

=head1 VERSION

This document describes version 0.04 of App::SeqPericmd (from Perl distribution App-SeqPericmd), released on 2016-09-28.

=head1 FUNCTIONS


=head2 seq(%args) -> [status, msg, result, meta]

Rinci-/Perinci::CmdLine-based "seq"-like CLI utility.

This utility is similar to Unix C<seq> command, with a few differences: some
differences in option names, JSON output, allow infinite stream (when C<to> is
not specified).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<equal_width> => I<bool>

Equalize width by padding with leading zeros.

=item * B<from>* => I<float>

=item * B<header> => I<str>

Add a header row.

=item * B<increment> => I<float> (default: 1)

=item * B<limit> => I<int>

Only generate a certain amount of numbers.

=item * B<number_format> => I<str>

sprintf() format for each number.

=item * B<to> => I<float>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-SeqPericmd>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SeqPericmd>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SeqPericmd>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
