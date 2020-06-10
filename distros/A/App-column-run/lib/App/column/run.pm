package App::column::run;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-06'; # DATE
our $DIST = 'App-column-run'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Text::Column::Util;

our %SPEC;

# TODO: color theme

$SPEC{column_run} = {
    v => 1.1,
    summary => 'Run several commands and show their output in multiple columns',
    description => <<'_',

This utility is similar to using the Unix utility <prog:pr> to columnate output,
something like (in bash):

    % pr -t -m -w $COLUMNS -l 99999 <(command1 args...) <(command2 args...)

except with the following features:

* ANSI color and wide character handling

* passing adjusted COLUMNS environment to commands so they can adjust output

* Passing common arguments to all commands

* Multiplexing STDIN to all commands

_
    args => {
        %Text::Column::Util::args_common,
        commands => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'command',
            schema => ['array*', of=>'str*'], # XXX actually array of str is allowed as command
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        args => {
            summary => 'Common arguments to pass to each program',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'arg',
            schema => ['array*', of=>'str*'],
        },
    },
    'cmdline.skip_format' => 1,
    links => [
        {url=>'prog:pr', summary=>'Unix utility to format and columnate text'},
        {url=>'prog:column', summary=>'Unix utility to fill columns with list'},
        {url=>'prog:diff', summary=>'The --side-by-side (-y) option display files in two columns'},
    ],
};
sub column_run {
    require IPC::Run;
    require ShellQuote::Any::PERLANCAR;

    my %args = @_;
    my $commands = delete $args{commands};
    my $command_args = delete $args{args};

    Text::Column::Util::show_texts_in_columns(
        %args,
        num_columns => scalar @$commands,
        gen_texts => sub {
            my %gargs = @_;
            # start the programs and capture the output. for now we do this in a
            # simple way: one by one and grab the whole output. in the future we
            # might do this parallel and line-by-line.

            my $stdin = "";
            unless (-t STDIN) {
                local $/;
                $stdin = <STDIN>;
            }

            local $ENV{COLUMNS} = $gargs{column_width};

            my @texts; # ([line1-from-cmd1, ...], [line1-from-cmd2, ...], ...)
            for my $i (0..$#{$commands}) {
                my $cmd = $commands->[$i];
                if ($command_args) {
                    $cmd .= " " . ShellQuote::Any::PERLANCAR::shell_quote(@{ $command_args });
                }
                my ($out, $err);
                IPC::Run::run(
                    sub {
                        system $cmd;
                        if ($?) { die "Can't system($cmd):, exit code=".($? < 0 ? $? : $? >> 8) }
                    },
                    \$stdin,
                    \$out,
                    \$err,
                );
                $texts[$i] = $out;
            }
            \@texts;
        }, # _gen_texts
    );
}

1;
# ABSTRACT: Run several commands and show their output in multiple columns

__END__

=pod

=encoding UTF-8

=head1 NAME

App::column::run - Run several commands and show their output in multiple columns

=head1 VERSION

This document describes version 0.002 of App::column::run (from Perl distribution App-column-run), released on 2020-06-06.

=head1 FUNCTIONS


=head2 column_run

Usage:

 column_run(%args) -> [status, msg, payload, meta]

Run several commands and show their output in multiple columns.

This utility is similar to using the Unix utility L<pr> to columnate output,
something like (in bash):

 % pr -t -m -w $COLUMNS -l 99999 <(command1 args...) <(command2 args...)

except with the following features:

=over

=item * ANSI color and wide character handling

=item * passing adjusted COLUMNS environment to commands so they can adjust output

=item * Passing common arguments to all commands

=item * Multiplexing STDIN to all commands

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args> => I<array[str]>

Common arguments to pass to each program.

=item * B<commands>* => I<array[str]>

=item * B<linum_width> => I<posint>

Line number width.

=item * B<on_long_line> => I<str> (default: "clip")

What to do to long lines.

=item * B<separator> => I<str> (default: "|")

Separator character between columns.

=item * B<show_linum> => I<bool>

Show line number.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-column-run>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-column-run>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-column-run>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<pr>. Perinci::To::POD=HASH(0x55c267e37168).

L<column>. Perinci::To::POD=HASH(0x55c267e37168).

L<diff>. Perinci::To::POD=HASH(0x55c267e37168).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
