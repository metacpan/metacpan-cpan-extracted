package App::PickRandomLines;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-29'; # DATE
our $DIST = 'App-PickRandomLines'; # DIST
our $VERSION = '0.020'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{pick_random_lines} = {
    v => 1.1,
    summary => 'Pick one or more random lines from input',
    description => <<'_',

TODO:
* option to allow or disallow duplicates

_
    args => {
        files => {
            schema => ['array*', of=>'filename*'],
            'x.name.is_plural' => 1,
            pos => 0,
            greedy => 1,
            description => <<'_',

If none is specified, will get input from stdin.

_
        },
        algorithm => {
            schema => ['str*', in=>[qw/scan seek/]],
            default => 'scan',
            description => <<'_',

`scan` is the algorithm described in the `perlfaq` manual (`perldoc -q "random
line"). This algorithm scans the whole input once and picks one or more lines
randomly from it.

`seek` is the algorithm employed by the Perl module `File::RandomLine`. It works
by seeking a file randomly and finding the next line (repeated `n` number of
times). This algorithm is faster when the input is very large as it avoids
having to scan the whole input. But it requires that the input is seekable (a
single file, stdin is not supported and currently multiple files are not
supported as well). *Might produce duplicate lines*.

_
        },
        num_lines => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
            description => <<'_',

If input contains less lines than the requested number of lines, then will only
return as many lines as the input contains.

_
        },
    },
    links => [
        {url=>'pm:Data::Unixish::pick'},
    ],
};
sub pick_random_lines {
    my %args = @_;

    # XXX schema
    my $n = $args{num_lines} // 1;
    $n > 0 or return [400, "Please specify a positive number of lines"];
    my $files = $args{files} // [];
    my $algo = $args{algorithm} // 'scan';
    $algo = 'scan' if !@$files || @$files > 1;

    my @lines;
    if ($algo eq 'scan') {
        require File::Random::Pick;
        my $path;
        if (!@$files) {
            $path = \*STDIN;
        } elsif (@$files > 1) {
            $path = \*ARGV;
        } else {
            $path = $files->[0];
        }
        @lines = File::Random::Pick::random_line($path, $n);
    } else {
        require File::RandomLine;
        my $rl = File::RandomLine->new($files->[0]);
        for (1..$n) { push @lines, $rl->next }
    }
    chomp @lines;
    [200, "OK", \@lines];
}

1;
# ABSTRACT: Pick one or more random lines from input

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PickRandomLines - Pick one or more random lines from input

=head1 VERSION

This document describes version 0.020 of App::PickRandomLines (from Perl distribution App-PickRandomLines), released on 2020-04-29.

=head1 SYNOPSIS

See L<pick-random-lines>.

=head1 FUNCTIONS


=head2 pick_random_lines

Usage:

 pick_random_lines(%args) -> [status, msg, payload, meta]

Pick one or more random lines from input.

TODO:
* option to allow or disallow duplicates

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<algorithm> => I<str> (default: "scan")

C<scan> is the algorithm described in the C<perlfaq> manual (`perldoc -q "random
line"). This algorithm scans the whole input once and picks one or more lines
randomly from it.

C<seek> is the algorithm employed by the Perl module C<File::RandomLine>. It works
by seeking a file randomly and finding the next line (repeated C<n> number of
times). This algorithm is faster when the input is very large as it avoids
having to scan the whole input. But it requires that the input is seekable (a
single file, stdin is not supported and currently multiple files are not
supported as well). I<Might produce duplicate lines>.

=item * B<files> => I<array[filename]>

If none is specified, will get input from stdin.

=item * B<num_lines> => I<int> (default: 1)

If input contains less lines than the requested number of lines, then will only
return as many lines as the input contains.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-PickRandomLines>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PickRandomLines>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PickRandomLines>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<Data::Unixish::pick>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
