package Complete::Zsh::Gen::FromPerinciCmdLine;

our $DATE = '2016-10-28'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use String::ShellQuote;

our %SPEC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gen_zsh_complete_from_perinci_cmdline_script);

$SPEC{gen_zsh_complete_from_perinci_cmdline_script} = {
    v => 1.1,
    summary => 'Dump Perinci::CmdLine script '.
        'and generate zsh completion script from it',
    description => <<'_',

This routine generate zsh completion script which uses _arguments to list each
option, allowing zsh to be aware of each option.

_
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
            cmdline_aliases => {f=>{}},
        },
        cmdname => {
            summary => 'Command name (by default will be extracted from filename)',
            schema => 'str*',
        },
        compname => {
            summary => 'Completer name (in case different from cmdname)',
            schema => 'str*',
        },
        skip_detect => {
            schema => ['bool', is=>1],
            cmdline_aliases => {D=>{}},
        },
    },
    result => {
        schema => 'str*',
        summary => 'A script that can be put in $fpath/_$progname',
    },
};
sub gen_zsh_complete_from_perinci_cmdline_script {
    my %args = @_;
    my $filename = $args{filename};

    require Perinci::CmdLine::Dump;
    my $dump_res = Perinci::CmdLine::Dump::dump_perinci_cmdline_script(
        filename => $filename,
        skip_detect => $args{skip_detect},
    );
    return [500, "Can't dump script: $dump_res->[0] - $dump_res->[1]"]
        unless $dump_res->[0] == 200;

    my $cli = $dump_res->[2];

    if ($cli->{subcommands}) {
        return [412, "Sorry, script with subcommands not yet supported"];
    }

    state $pa = do {
        require Perinci::Access;
        Perinci::Access->new;
    };
    my $riap_res = $pa->request(meta => $cli->{url});
    return [500, "Can't Riap request: meta => $cli->{url}: ".
                "$riap_res->[0] - $riap_res->[1]"]
        unless $riap_res->[0] == 200;

    my $meta = $riap_res->[2];

    require Perinci::Sub::GetArgs::Argv;
    my $gengls_res = Perinci::Sub::GetArgs::Argv::gen_getopt_long_spec_from_meta(
        meta => $meta,
        meta_is_normalized => 1,
        common_opts => $cli->{common_opts},
        per_arg_json => $cli->{per_arg_json},
        per_arg_yaml => $cli->{per_arg_yaml},
    );
    return [500, "Can't generate Getopt::Long spec: ".
                "$gengls_res->[0] - $gengls_res->[1]"]
        unless $gengls_res->[0] == 200;
    my $glspec = $gengls_res->[2];
    $glspec->{'<>'} = sub{};

    require Perinci::Sub::To::CLIDocData;
    my $genclidocdata_res = Perinci::Sub::To::CLIDocData::gen_cli_doc_data_from_meta(
        common_opts => $cli->{common_opts},
        ggls_res => $gengls_res,
        meta => $meta,
        meta_is_normalized => 1,
        per_arg_json => $cli->{per_arg_json},
        per_arg_yaml => $cli->{per_arg_yaml},
    );
    return [500, "Can't generate CLI doc data: ".
                "$genclidocdata_res->[0] - $genclidocdata_res->[1]"]
        unless $genclidocdata_res->[0] == 200;
    my $clidocdata = $genclidocdata_res->[2];

    my $opt_desc = {};
    for my $k (sort keys %{$clidocdata->{opts}}) {
        my $v = $clidocdata->{opts}{$k};
        next unless $v->{summary};
        my @o = $k =~ /--?(\S+)/g;
        for my $o (@o) {
            $opt_desc->{$o} = $v->{summary};
        }
    }

    my $cmdname = $args{cmdname};
    if (!$cmdname) {
        ($cmdname = $filename) =~ s!.+/!!;
    }
    my $compname = $args{compname} // $cmdname;

    require Complete::Zsh::Gen::FromGetoptLong;
    Complete::Zsh::Gen::FromGetoptLong::gen_zsh_complete_from_getopt_long_spec(
        spec => $glspec,
        opt_desc => $opt_desc,
        cmdname => $cmdname,
        compname => $compname,
    );
}

1;
# ABSTRACT: Dump Perinci::CmdLine script and generate zsh completion script from it

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Zsh::Gen::FromPerinciCmdLine - Dump Perinci::CmdLine script and generate zsh completion script from it

=head1 VERSION

This document describes version 0.002 of Complete::Zsh::Gen::FromPerinciCmdLine (from Perl distribution Complete-Zsh-Gen-FromPerinciCmdLine), released on 2016-10-28.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 gen_zsh_complete_from_perinci_cmdline_script(%args) -> [status, msg, result, meta]

Dump Perinci::CmdLine script and generate zsh completion script from it.

This routine generate zsh completion script which uses _arguments to list each
option, allowing zsh to be aware of each option.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmdname> => I<str>

Command name (by default will be extracted from filename).

=item * B<compname> => I<str>

Completer name (in case different from cmdname).

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

Return value: A script that can be put in $fpath/_$progname (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Zsh-Gen-FromPerinciCmdLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Zsh-Gen-FromPerinciCmdLine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Zsh-Gen-FromPerinciCmdLine>

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
