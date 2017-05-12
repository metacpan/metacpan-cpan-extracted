package Complete::Zsh::Gen::FromGetoptLong;

our $DATE = '2016-10-27'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Getopt::Long::Util qw(parse_getopt_long_opt_spec);
use String::ShellQuote;

our %SPEC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       gen_zsh_complete_from_getopt_long_script
                       gen_zsh_complete_from_getopt_long_spec
               );

sub _quote {
    local $_ = shift;
    s/[^A-Za-z0-9]+/_/g;
    $_ = "_$_" if /\A[0-9]/;
    "_$_";
}

$SPEC{gen_zsh_complete_from_getopt_long_spec} = {
    v => 1.1,
    summary => 'From Getopt::Long spec, generate completion '.
        'script for the zsh shell',
    description => <<'_',

This routine generate zsh completion script for each short/long option, enabling
zsh to display the options in a different color and showing description (if
specified) for each option.

Getopt::Long::Complete scripts are also supported.

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
        summary => 'A script that can be put in $fpath/_$cmdname',
    },
};
sub gen_zsh_complete_from_getopt_long_spec {
    my %args = @_;

    my $gospec = $args{spec} or return [400, "Please specify 'spec'"];
    my $cmdname = $args{cmdname} or return [400, "Please specify cmdname"];
    my $compname = $args{compname};
    my $opt_desc = $args{opt_desc};

    my @res;
    push @res, "#compdef $cmdname\n";

    # define function to complete arg or option value
    my $val_func;
    if (defined $compname) {
        $val_func = _quote($cmdname . "_val");
        push @res, join(
            "",
            "$val_func() {\n",
            "  _values 'values' \${(uf)\"\$(COMP_SHELL=zsh COMP_LINE=\$BUFFER COMP_POINT=\$CURSOR ".shell_quote($compname).")\"}\n",
            "}\n",
        );
    } else {
        $val_func = "_files";
    }

    push @res, "_arguments \\\n";
    for my $ospec (sort {
        # make sure <> is the last
        my $a_is_diamond = $a eq '<>' ? 1:0;
        my $b_is_diamond = $b eq '<>' ? 1:0;
        $a_is_diamond <=> $b_is_diamond || $a cmp $b
    } keys %$gospec) {
        my $res = parse_getopt_long_opt_spec($ospec)
            or die "Can't parse option spec '$ospec'";
        if ($res->{is_arg} && $compname) {
            push @res, "  '*:value:$val_func'\n";
        } else {
            $res->{min_vals} //= $res->{type} ? 1 : 0;
            $res->{max_vals} //= $res->{type} || $res->{opttype} ? 1:0;
            for my $o0 (@{ $res->{opts} }) {
                my @o = $res->{is_neg} && length($o0) > 1 ?
                    ($o0, "no$o0", "no-$o0") : ($o0);
                for my $o (@o) {
                    my $opt = length($o) == 1 ? "-$o" : "--$o";
                    my $desc = ($opt_desc ? $opt_desc->{$o} : undef) // '';
                    $desc =~ s/\[|\]/_/g;
                    push @res, "  " . shell_quote(
                        "$opt\[$desc\]" .
                            ($res->{min_vals} > 0 ? ":value:$val_func" : "")) .
                            " \\\n";
                }
            }
        }
    }
    push @res, "\n";

    [200, "OK", join("", @res)];
}

$SPEC{gen_zsh_complete_from_getopt_long_script} = {
    v => 1.1,
    summary => 'Generate zsh completion script from Getopt::Long script',
    description => <<'_',

This routine generate zsh `compadd` command for each short/long option, enabling
zsh to display the options in a different color and showing description (if
specified) for each option.

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
        summary => 'A script that can be put in $fpath/_$cmdname',
    },
};
sub gen_zsh_complete_from_getopt_long_script {
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

    gen_zsh_complete_from_getopt_long_spec(
        spec => $dump_res->[2],
        cmdname => $cmdname,
        compname => $compname,
    );
}

1;
# ABSTRACT: Generate zsh completion script from Getopt::Long spec/script

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Zsh::Gen::FromGetoptLong - Generate zsh completion script from Getopt::Long spec/script

=head1 VERSION

This document describes version 0.001 of Complete::Zsh::Gen::FromGetoptLong (from Perl distribution Complete-Zsh-Gen-FromGetoptLong), released on 2016-10-27.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 gen_zsh_complete_from_getopt_long_script(%args) -> [status, msg, result, meta]

Generate zsh completion script from Getopt::Long script.

This routine generate zsh C<compadd> command for each short/long option, enabling
zsh to display the options in a different color and showing description (if
specified) for each option.

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

Return value: A script that can be put in $fpath/_$cmdname (str)


=head2 gen_zsh_complete_from_getopt_long_spec(%args) -> [status, msg, result, meta]

From Getopt::Long spec, generate completion script for the zsh shell.

This routine generate zsh completion script for each short/long option, enabling
zsh to display the options in a different color and showing description (if
specified) for each option.

Getopt::Long::Complete scripts are also supported.

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

Return value: A script that can be put in $fpath/_$cmdname (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Zsh-Gen-FromGetoptLong>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Zsh-Gen-FromGetoptLong>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Zsh-Gen-FromGetoptLong>

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
