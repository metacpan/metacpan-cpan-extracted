package Complete::Fish::Gen::FromGetoptLong;

our $DATE = '2016-10-27'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;

use Getopt::Long::Util qw(parse_getopt_long_opt_spec);
use String::ShellQuote;

our %SPEC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       gen_fish_complete_from_getopt_long_script
                       gen_fish_complete_from_getopt_long_spec
               );

$SPEC{gen_fish_complete_from_getopt_long_spec} = {
    v => 1.1,
    summary => 'From Getopt::Long spec, generate tab completion '.
        'commands for the fish shell',
    description => <<'_',


_
    args => {
        spec => {
            summary => 'Getopt::Long options specification',
            schema => 'hash*',
            req => 1,
            pos => 0,
        },
        opt_desc => {
            summary => 'Description for each option',
            description => <<'_',

This is optional and allows adding description for the complete command. Each
key of the hash should correspond to the option name without the dashes, e.g.
`s`, `long`.

_
            schema => 'hash*',
        },
        cmdname => {
            summary => 'Command name to be completed',
            schema => 'str*',
            req => 1,
        },
        compname => {
            summary => 'Completer name, if there is a completer for option values',
            schema => 'str*',
        },
    },
    result => {
        schema => 'str*',
        summary => 'A script that can be fed to the fish shell',
    },
};
sub gen_fish_complete_from_getopt_long_spec {
    my %args = @_;

    my $gospec = $args{spec} or return [400, "Please specify 'spec'"];
    my $cmdname = $args{cmdname} or return [400, "Please specify cmdname"];
    my $compname = $args{compname};
    my $opt_desc = $args{opt_desc};

    my @cmds;
    my $prefix = "complete -c ".shell_quote($cmdname);
    my $a_val  = shell_quote("(begin; set -lx COMP_SHELL fish; set -lx COMP_LINE (commandline); set -lx COMP_POINT (commandline -C); ".shell_quote($compname)."; end)")
        if $compname;
    push @cmds, "$prefix -e"; # currently does not work (fish bug?)
    for my $ospec (sort {
        # make sure <> is the last
        my $a_is_diamond = $a eq '<>' ? 1:0;
        my $b_is_diamond = $b eq '<>' ? 1:0;
        $a_is_diamond <=> $b_is_diamond || $a cmp $b
    } keys %$gospec) {
        my $res = parse_getopt_long_opt_spec($ospec)
            or die "Can't parse option spec '$ospec'";
        if ($res->{is_arg} && $compname) {
            push @cmds, "$prefix -a $a_val";
        } else {
            $res->{min_vals} //= $res->{type} ? 1 : 0;
            $res->{max_vals} //= $res->{type} || $res->{opttype} ? 1:0;
            for my $o0 (@{ $res->{opts} }) {
                my @o = $res->{is_neg} && length($o0) > 1 ?
                    ($o0, "no$o0", "no-$o0") : ($o0);
                for my $o (@o) {
                    my $cmd = $prefix;
                    $cmd .= length($o) > 1 ? " -l '$o'" : " -s '$o'";
                    if ($opt_desc && $opt_desc->{$o}) {
                        $cmd .= " -d ".shell_quote($opt_desc->{$o});
                    }
                    if ($res->{min_vals} > 0) {
                        if ($compname) {
                            $cmd .= " -r -f -a $a_val";
                        } else {
                            $cmd .= " -r";
                        }
                    }
                    push @cmds, $cmd;
                }
            }
        }
    }
    [200, "OK", join("", map {"$_\n"} @cmds)];
}

$SPEC{gen_fish_complete_from_getopt_long_script} = {
    v => 1.1,
    summary => 'Generate fish completion script from Getopt::Long script',
    description => <<'_',

This routine generate fish `complete` command for each short/long option,
enabling fish to display the options in a different color.

Getopt::Long::Complete scripts are also supported.

_
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
            cmdline_aliases => {f=>{}},
        },
        cmdname => {
            summary => 'Command name to be completed, defaults to filename',
            schema => 'str*',
        },
        compname => {
            summary => 'Completer name',
            schema => 'str*',
        },
        skip_detect => {
            schema => ['bool', is=>1],
            cmdline_aliases => {D=>{}},
        },
    },
    result => {
        schema => 'str*',
        summary => 'A script that can be fed to the fish shell',
    },
};
sub gen_fish_complete_from_getopt_long_script {
    my %args = @_;

    my $filename = $args{filename};
    return [404, "No such file or not a file: $filename"] unless -f $filename;

    require Getopt::Long::Dump;
    my $dump_res = Getopt::Long::Dump::dump_getopt_long_script(
        filename => $filename,
        skip_detect => $args{skip_detect},
    );
    return $dump_res unless $dump_res->[0] == 200;

    my $cmdname = $args{cmdname};
    if (!$cmdname) {
        ($cmdname = $filename) =~ s!.+/!!;
    }
    my $compname = $args{compname};

    my $glspec = $dump_res->[2];

    # GL:Complete scripts can also complete arguments
    my $mod = $dump_res->[3]{'func.detect_res'}[3]{'func.module'} // '';
    if ($mod eq 'Getopt::Long::Complete') {
        $compname //= $cmdname;
        $glspec->{'<>'} = sub {};
    }

    gen_fish_complete_from_getopt_long_spec(
        spec => $dump_res->[2],
        cmdname => $cmdname,
        compname => $compname,
    );
}

1;
# ABSTRACT: Generate fish completion script from Getopt::Long spec/script

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Fish::Gen::FromGetoptLong - Generate fish completion script from Getopt::Long spec/script

=head1 VERSION

This document describes version 0.09 of Complete::Fish::Gen::FromGetoptLong (from Perl distribution Complete-Fish-Gen-FromGetoptLong), released on 2016-10-27.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 gen_fish_complete_from_getopt_long_script(%args) -> [status, msg, result, meta]

Generate fish completion script from Getopt::Long script.

This routine generate fish C<complete> command for each short/long option,
enabling fish to display the options in a different color.

Getopt::Long::Complete scripts are also supported.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmdname> => I<str>

Command name to be completed, defaults to filename.

=item * B<compname> => I<str>

Completer name.

=item * B<filename>* => I<filename>

=item * B<skip_detect> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: A script that can be fed to the fish shell (str)


=head2 gen_fish_complete_from_getopt_long_spec(%args) -> [status, msg, result, meta]

From Getopt::Long spec, generate tab completion commands for the fish shell.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmdname>* => I<str>

Command name to be completed.

=item * B<compname> => I<str>

Completer name, if there is a completer for option values.

=item * B<opt_desc> => I<hash>

Description for each option.

This is optional and allows adding description for the complete command. Each
key of the hash should correspond to the option name without the dashes, e.g.
C<s>, C<long>.

=item * B<spec>* => I<hash>

Getopt::Long options specification.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value: A script that can be fed to the fish shell (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Fish-Gen-FromGetoptLong>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Fish-Gen-FromGetoptLong>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Fish-Gen-FromGetoptLong>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
