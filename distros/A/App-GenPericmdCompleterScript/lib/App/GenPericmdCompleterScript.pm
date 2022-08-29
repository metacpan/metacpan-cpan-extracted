package App::GenPericmdCompleterScript;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Data::Dmp;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-28'; # DATE
our $DIST = 'App-GenPericmdCompleterScript'; # DIST
our $VERSION = '0.124'; # VERSION

our @EXPORT_OK = qw(gen_pericmd_completer_script);

our %SPEC;

sub _pa {
    state $pa = do {
        require Perinci::Access::Lite;
        my $pa = Perinci::Access::Lite->new;
        $pa;
    };
    $pa;
}

sub _riap_request {
    my ($action, $url, $extras, $main_args) = @_;

    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0
        unless $main_args->{ssl_verify_hostname};

    _pa()->request($action => $url, %{$extras // {}});
}

$SPEC{gen_pericmd_completer_script} = {
    v => 1.1,
    summary => 'Generate Perinci::CmdLine completer script',
    args => {
        program_name => {
            summary => 'Program name that is being completed',
            schema  => 'str*',
            req     => 1,
            pos     => 0,
        },
        url => {
            summary => 'URL to function (or package, if you have subcommands)',
            schema => 'riap::url*',
            req => 1,
            pos => 1,
            tags => ['category:pericmd-attribute'],
        },
        subcommands => {
            summary => 'Hash of subcommand names and function URLs',
            description => <<'_',

Optionally, it can be additionally followed by a summary, so:

    URL[:SUMMARY]

Example (on CLI):

    --subcommand "delete=/My/App/delete_item:Delete an item"

_
            schema => ['hash*', of=>['any*', of=>['hash*', 'str*']]],
            cmdline_aliases => { s=>{} },
            tags => ['category:pericmd-attribute'],
        },
        subcommands_from_package_functions => {
            summary => "Form subcommands from functions under package's URL",
            schema => ['bool', is=>1],
            description => <<'_',

This is an alternative to the `subcommand` option. Instead of specifying each
subcommand's name and URL, you can also specify that subcommand names are from
functions under the package URL in `url`. So for example if `url` is `/My/App/`,
hen all functions under `/My/App` are listed first. If the functions are:

    foo
    bar
    baz_qux

then the subcommands become:

    foo => /My/App/foo
    bar => /My/App/bar
    "baz-qux" => /My/App/baz_qux

_
        },
        include_package_functions_match => {
            schema => 're*',
            summary => 'Only include package functions matching this pattern',
            links => [
                'subcommands_from_package_functions',
                'exclude_package_functions_match',
            ],
        },
        exclude_package_functions_match => {
            schema => 're*',
            summary => 'Exclude package functions matching this pattern',
            links => [
                'subcommands_from_package_functions',
                'include_package_functions_match',
            ],
        },
        output_file => {
            summary => 'Path to output file',
            schema => ['filename*'],
            default => '-',
            cmdline_aliases => { o=>{} },
            tags => ['category:output'],
        },
        overwrite => {
            schema => [bool => default => 0],
            summary => 'Whether to overwrite output if previously exists',
            tags => ['category:output'],
        },
        interpreter_path => {
            summary => 'What to put on shebang line',
            schema => 'str',
        },
        load_module => {
            summary => 'Load extra modules',
            schema  => ['array*', of=>'str*'],
        },
        completion => {
            schema => 'code*',
            tags => ['category:pericmd-attribute'],
        },
        default_subcommand => {
            schema => 'str*',
            tags => ['category:pericmd-attribute'],
        },
        per_arg_json => {
            schema => 'bool*',
            tags => ['category:pericmd-attribute'],
        },
        per_arg_yaml => {
            schema => 'bool*',
            tags => ['category:pericmd-attribute'],
        },
        skip_format => {
            schema => 'bool*',
            tags => ['category:pericmd-attribute'],
        },
        read_config => {
            schema => 'bool*',
            tags => ['category:pericmd-attribute'],
        },
        read_env => {
            schema => 'bool*',
            tags => ['category:pericmd-attribute'],
        },
        get_subcommand_from_arg => {
            schema => ['int*', in=>[0,1,2]],
            default => 1,
            tags => ['category:pericmd-attribute'],
        },
        strip => {
            summary => 'Whether to strip source code using Perl::Stripper',
            schema => 'bool*',
            default => 0,
        },
    },
};
sub gen_pericmd_completer_script {
    require Perinci::CmdLine::Lite;

    my %args = @_;

    # XXX schema
    my $output_file = $args{output_file} // '-';

    my $subcommands;
    my $sc_metas = {};
    if ($args{subcommands}) {
        $subcommands = {};
        for my $sc_name (keys %{ $args{subcommands} }) {
            my $v = $args{subcommands}{$sc_name};
            my ($sc_url, $sc_summary);
            if (ref($v) eq 'HASH') {
                $sc_url = $v->{url};
                $sc_summary = $v->{summary};
            } else {
                ($sc_url, $sc_summary) = split /:/, $v, 2;
            }
            my $res = _riap_request(meta => $sc_url => {}, \%args);
            return [500, "Can't meta $sc_url: $res->[0] - $res->[1]"]
                unless $res->[0] == 200;
            my $meta = $res->[2];
            $sc_metas->{$sc_name} = $meta;
            $sc_summary //= $meta->{summary};
            $subcommands->{$sc_name} = {
                url => $sc_url,
                summary => $sc_summary,
            };
        }
    } elsif ($args{subcommands_from_package_functions}) {
        my $res = _riap_request(child_metas => $args{url} => {detail=>1}, \%args);
        return [500, "Can't child_metas $args{url}: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        $subcommands = {};
        for my $uri (keys %{ $res->[2] }) {
            next unless $uri =~ /\A\w+\z/; # functions only
            my $meta = $res->[2]{$uri};
            if ($args{include_package_functions_match}) {
                next unless $uri =~ /$args{include_package_functions_match}/;
            }
            if ($args{exclude_package_functions_match}) {
                next if $uri =~ /$args{exclude_package_functions_match}/;
            }
            (my $sc_name = $uri) =~ s/_/-/g;
            $sc_metas->{$sc_name} = $meta;
            $subcommands->{$sc_name} = {
                url     => "$args{url}$uri",
                summary => $meta->{summary},
            };
        }
    }

    # request metadata to get summary (etc)
    my $meta;
    {
        my $res = _riap_request(meta => $args{url} => {}, \%args);
        return [500, "Can't meta $args{url}: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        $meta = $res->[2];
    }

    my $cli;
    {
        use experimental 'smartmatch';
        my $spec = $SPEC{gen_pericmd_completer_script};
        my @attr_args = grep {
            'category:pericmd-attribute' ~~ @{ $spec->{args}{$_}{tags} } }
            keys %{ $spec->{args} };
        $cli = Perinci::CmdLine::Lite->new(
            map { $_ => $args{$_} } @attr_args
        );
    }

    # GENERATE CODE
    my $code;
    my %used_modules = map {$_=>1} (
        'Complete::Bash',
        'Complete::Tcsh',
        'Complete::Util',
        'Perinci::Sub::Complete',
    );
    {
        my @res;

        # header
        {
            # XXX hide long-ish arguments

            push @res, (
                "#!", ($args{interpreter_path} // $^X), "\n\n",

                "# Note: This completer script is generated by ", __PACKAGE__, " version ", ($App::GenPericmdCompleterScript::VERSION // '?'), "\n",
                "# on ", scalar(localtime), ". You probably should not manually edit this file.\n\n",

                "# NO_PERINCI_CMDLINE_SCRIPT\n",
                "# PERINCI_CMDLINE_COMPLETER_SCRIPT: ", dmp(\%args), "\n",
                "# FRAGMENT id=shcompgen-hint completer=1 for=$args{program_name}\n",
                "# PODNAME: _$args{program_name}\n",
                "# ABSTRACT: Completer script for $args{program_name}\n",
                "\n",
            );
        }

        # code
        push @res, (
            "use 5.010;\n",
            "use strict;\n",
            "use warnings;\n",
            "\n",

            "# AUTHORITY\n",
            "# DATE\n",
            "# DIST\n",
            "# VERSION\n",

            'die "Please run this script under shell completion\n" unless $ENV{COMP_LINE} || $ENV{COMMAND_LINE};', "\n\n",

            ($args{load_module} ? (
                "# require extra modules\n",
                (map {"use $_ ();\n"} @{$args{load_module}}),
                "\n") : ()),

            'my $args = ', dmp(\%args), ";\n\n",

            'my $meta = ', dmp($meta), ";\n\n",

            'my $sc_metas = ', dmp($sc_metas), ";\n\n",

            'my $copts = ', dmp($cli->common_opts), ";\n\n",

            'my $r = {};', "\n\n",

            "# get words\n",
            'my $shell;', "\n",
            'my ($words, $cword);', "\n",
            'if ($ENV{COMP_LINE}) { $shell = "bash"; require Complete::Bash; require Encode; ($words,$cword) = @{ Complete::Bash::parse_cmdline() }; ($words,$cword) = @{ Complete::Bash::join_wordbreak_words($words,$cword) }; $words = [map {Encode::decode("UTF-8", $_)} @$words]; }', "\n",
            'elsif ($ENV{COMMAND_LINE}) { $shell = "tcsh"; require Complete::Tcsh; ($words,$cword) = @{ Complete::Tcsh::parse_cmdline() }; }', "\n",
            '@ARGV = @$words;', "\n",
            "\n",

            "# strip program name\n",
            'shift @$words; $cword--;', "\n\n",

            "# parse common_opts which potentially sets subcommand\n",
            '{', "\n",
            "    require Getopt::Long;\n",
            q(    my $old_go_conf = Getopt::Long::Configure('pass_through', 'no_ignore_case', 'bundling', 'no_auto_abbrev', 'no_getopt_compat', 'gnu_compat');), "\n",
            q(    my @go_spec;), "\n",
            q(    for my $k (keys %$copts) { push @go_spec, $copts->{$k}{getopt} => sub { my ($go, $val) = @_; $copts->{$k}{handler}->($go, $val, $r); } }), "\n",
            q(    Getopt::Long::GetOptions(@go_spec);), "\n",
            q(    Getopt::Long::Configure($old_go_conf);), "\n",
            "}\n\n",

            "# select subcommand\n",
            'my $scn = $r->{subcommand_name};', "\n",
            'my $scn_from = $r->{subcommand_name_from};', "\n",
            'if (!defined($scn) && defined($args->{default_subcommand})) {', "\n",
            '    # get from default_subcommand', "\n",
            '    if ($args->{get_subcommand_from_arg} == 1) {', "\n",
            '        $scn = $args->{default_subcommand};', "\n",
            '        $scn_from = "default_subcommand";', "\n",
            '    } elsif ($args->{get_subcommand_from_arg} == 2 && !@ARGV) {', "\n",
            '        $scn = $args->{default_subcommand};', "\n",
            '        $scn_from = "default_subcommand";', "\n",
            '    }', "\n",
            '}', "\n",
            'if (!defined($scn) && $args->{subcommands} && @ARGV) {', "\n",
            '    # get from first command-line arg', "\n",
            '    $scn = shift @ARGV;', "\n",
            '    $scn_from = "arg";', "\n",
            '}', "\n\n",
            'if (defined($scn) && !$sc_metas->{$scn}) { undef $scn } # unknown subcommand name', "\n",

            "# XXX read_env\n\n",

            "# complete with periscomp\n",
            'my $compres;', "\n",
            "{\n",
            '    require Perinci::Sub::Complete;', "\n",
            '    $compres = Perinci::Sub::Complete::complete_cli_arg(', "\n",
            '        meta => defined($scn) ? $sc_metas->{$scn} : $meta,', "\n",
            '        words => $words,', "\n",
            '        cword => $cword,', "\n",
            '        common_opts => $copts,', "\n",
            '        riap_server_url => undef,', "\n",
            '        riap_uri => undef,', "\n",
            '        extras => {r=>$r, cmdline=>undef},', "\n", # no cmdline object
            '        func_arg_starts_at => (($scn_from//"") eq "arg" ? 1:0),', "\n",
            '        completion => sub {', "\n",
            '            my %args = @_;', "\n",
            '            my $type = $args{type};', "\n",
            '', "\n",
            '            # user specifies custom completion routine, so use that first', "\n",
            '            if ($args->{completion}) {', "\n",
            '                my $res = $args->{completion}->(%args);', "\n",
            '                return $res if $res;', "\n",
            '            }', "\n",
            q(            # if subcommand name has not been supplied and we're at arg#0,), "\n",
            '            # complete subcommand name', "\n",
            '            if ($args->{subcommands} &&', "\n",
            '                $scn_from ne "--cmd" &&', "\n",
            '                     $type eq "arg" && $args{argpos}==0) {', "\n",
            '                my @subc_names     = keys %{ $args->{subcommands} };', "\n",
            '                my @subc_summaries = map { $args->{subcommands}{$_}{summary} } @subc_names;', "\n",
            '                require Complete::Util;', "\n",
            '                return Complete::Util::complete_array_elem(', "\n",
            '                    array     => \\@subc_names,', "\n",
            '                    summaries => \\@subc_summaries,', "\n",
            '                    word  => $words->[$cword]);', "\n",
            '            }', "\n",
            '', "\n",
            '            # otherwise let periscomp do its thing', "\n",
            '            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef', "\n",
            '        },', "\n",
            '    );', "\n",
            "}\n\n",

            "# display result\n",
            'if    ($shell eq "bash") { print Complete::Bash::format_completion($compres, {word=>$words->[$cword]}) }', "\n",
            'elsif ($shell eq "tcsh") { print Complete::Tcsh::format_completion($compres) }', "\n",
        );

        $code = join "", @res;
    } # END GENERATE CODE

    # pack the modules
    my $packed_code;
    {
        require App::depak;
        require File::Slurper;
        require File::Temp;

        my (undef, $tmp_unpacked_path) = File::Temp::tempfile();
        my (undef, $tmp_packed_path)   = File::Temp::tempfile();

        File::Slurper::write_text($tmp_unpacked_path, $code);

        my %depakargs = (
            include_prereq => [sort keys %used_modules],
            input_file     => $tmp_unpacked_path,
            output_file    => $tmp_packed_path,
            overwrite      => 1,
            trace_method   => 'none',
            pack_method    => 'datapack',
            code_after_shebang => "## no critic: TestingAndDebugging::RequireUseStrict\n", # currently datapack code does not use strict
        );
        if ($args{strip}) {
            $depakargs{stripper} = 1;
            $depakargs{stripper_pod}     = 1;
            $depakargs{stripper_comment} = 1;
            $depakargs{stripper_ws}      = 1;
            $depakargs{stripper_maintain_linum} = 0;
            $depakargs{stripper_log}     = 0;
        } else {
            $depakargs{stripper} = 0;
        }
        my $res = App::depak::depak(%depakargs);
        return $res unless $res->[0] == 200;

        $packed_code = File::Slurper::read_text($tmp_packed_path);
    }

    if ($output_file ne '-') {
        log_trace("Outputing result to %s ...", $output_file);
        if ((-f $output_file) && !$args{overwrite}) {
            return [409, "Output file '$output_file' already exists (please use --overwrite if you want to override)"];
        }
        open my($fh), ">", $output_file
            or return [500, "Can't open '$output_file' for writing: $!"];

        print $fh $packed_code;
        close $fh
            or return [500, "Can't write '$output_file': $!"];

        chmod 0755, $output_file or do {
            log_warn("Can't 'chmod 0755, $output_file': $!");
        };

        my $output_name = $output_file;
        $output_name =~ s!.+[\\/]!!;

        $packed_code = "";
    }

    [200, "OK", $packed_code, {
    }];
}

1;
# ABSTRACT: Generate Perinci::CmdLine completer script

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GenPericmdCompleterScript - Generate Perinci::CmdLine completer script

=head1 VERSION

This document describes version 0.124 of App::GenPericmdCompleterScript (from Perl distribution App-GenPericmdCompleterScript), released on 2022-08-28.

=head1 FUNCTIONS


=head2 gen_pericmd_completer_script

Usage:

 gen_pericmd_completer_script(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate Perinci::CmdLine completer script.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<completion> => I<code>

=item * B<default_subcommand> => I<str>

=item * B<exclude_package_functions_match> => I<re>

Exclude package functions matching this pattern.

=item * B<get_subcommand_from_arg> => I<int> (default: 1)

=item * B<include_package_functions_match> => I<re>

Only include package functions matching this pattern.

=item * B<interpreter_path> => I<str>

What to put on shebang line.

=item * B<load_module> => I<array[str]>

Load extra modules.

=item * B<output_file> => I<filename> (default: "-")

Path to output file.

=item * B<overwrite> => I<bool> (default: 0)

Whether to overwrite output if previously exists.

=item * B<per_arg_json> => I<bool>

=item * B<per_arg_yaml> => I<bool>

=item * B<program_name>* => I<str>

Program name that is being completed.

=item * B<read_config> => I<bool>

=item * B<read_env> => I<bool>

=item * B<skip_format> => I<bool>

=item * B<strip> => I<bool> (default: 0)

Whether to strip source code using Perl::Stripper.

=item * B<subcommands> => I<hash>

Hash of subcommand names and function URLs.

Optionally, it can be additionally followed by a summary, so:

 URL[:SUMMARY]

Example (on CLI):

 --subcommand "delete=/My/App/delete_item:Delete an item"

=item * B<subcommands_from_package_functions> => I<bool>

Form subcommands from functions under package's URL.

This is an alternative to the C<subcommand> option. Instead of specifying each
subcommand's name and URL, you can also specify that subcommand names are from
functions under the package URL in C<url>. So for example if C<url> is C</My/App/>,
hen all functions under C</My/App> are listed first. If the functions are:

 foo
 bar
 baz_qux

then the subcommands become:

 foo => /My/App/foo
 bar => /My/App/bar
 "baz-qux" => /My/App/baz_qux

=item * B<url>* => I<riap::url>

URL to function (or package, if you have subcommands).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GenPericmdCompleterScript>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GenPericmdCompleterScript>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GenPericmdCompleterScript>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
