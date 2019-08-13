package App::BencherUtils;

our $DATE = '2019-08-08'; # DATE
our $VERSION = '0.242'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Data::Clean::ForJSON;
use Function::Fallback::CoreOrPP qw(clone);
use Perinci::Object;
use Perinci::Sub::Util qw(err);
use PerlX::Maybe;
use POSIX qw(strftime);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to bencher',
};

my %args_common = (
    result_dir => {
        summary => 'Directory to store results files in',
        schema => 'str*',
        req => 1,
    },
);

my %args_common_query = (
    query => {
        schema => ['array*', of=>'str*'],
        pos => 0,
        greedy => 1,
    },
    detail => {
        schema => 'bool',
        cmdline_aliases => {l=>{}},
    },
);

sub _clean {
    state $cleanser = Data::Clean::ForJSON->get_cleanser;
    $cleanser->clone_and_clean($_[0]);
}

sub _json {
    state $json = do {
        require JSON::MaybeXS;
        my $json = JSON::MaybeXS->new;
        $json->convert_blessed(1);
        $json->allow_nonref(1);
        $json->canonical(1);
    };
    $json;
}

sub _encode_json {
    no strict 'refs';
    no warnings 'once';
    local *version::TO_JSON = sub { "$_[0]" };
    _json->encode($_[0]);
}

sub _complete_scenario_module {
    require Complete::Module;
    my %args = @_;
    Complete::Module::complete_module(
        word=>$args{word}, ns_prefix=>'Bencher::Scenario');
}

my $re_filename = qr/\A
                     (\w+(?:-(?:\w+))*)
                     (\.module_startup)?
                     \.(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d)-(\d\d)-(\d\d)
                     \.json
                     \z/x;

sub _complete_scenario_in_result_dir {
    require Complete::Util;

    my %args = @_;
    my $word = $args{word};
    my $cmdline = $args{cmdline};
    my $r = $args{r};

    return undef unless $cmdline;

    $r->{read_config} = 1;

    my $res = $cmdline->parse_argv($r);
    return undef unless $res->[0] == 200;

    # combine from command-line and from config/env
    my $final_args = { %{$res->[2]}, %{$args{args}} };
    #log_trace("final args=%s", $final_args);

    return [] unless $final_args->{result_dir};

    my %scenarios;

    opendir my($dh), $final_args->{result_dir} or return undef;
    for my $filename (readdir $dh) {
        $filename =~ $re_filename or next;
        my $sc = $1; $sc =~ s/-/::/g;
        $scenarios{$sc}++;
    }

    Complete::Util::complete_hash_key(hash=>\%scenarios, word=>$word);
}

$SPEC{list_bencher_results} = {
    v => 1.1,
    summary => "List results in results directory",
    args => {
        %args_common,
        %args_common_query,

        include_scenarios => {
            'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
            element_completion => \&_complete_scenario_in_result_dir,
        },
        exclude_scenarios => {
            'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
            element_completion => \&_complete_scenario_in_result_dir,
        },
        module_startup => {
            schema => 'bool*',
            tags => ['category:filtering'],
        },
        latest => {
            'summary.alt.bool.yes' => 'Only list the latest result for every scenario+CPU',
            'summary.alt.bool.no'  => 'Do not list the latest result for every scenario+CPU',
            schema => ['bool*'],
            tags => ['category:filtering'],
        },

        fmt => {
            summary => 'Display each result with bencher-fmt',
            schema => 'bool*',
            tags => ['category:display'],
        },
    },
    examples => [
        {
            summary => 'List all results',
            src => 'list-bencher-results',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List all results, show detail information',
            src => 'list-bencher-results -l',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List matching results only',
            src => 'list-bencher-results --exclude-scenario Perl::Startup Startup',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List matching results, format all using bencher-fmt',
            src => 'list-bencher-results --exclude-scenario Perl::Startup Startup --fmt',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List latest result for each scenario+CPU',
            src => 'list-bencher-results QUERY --latest',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Delete old results',
            src => 'cd $RESULT_DIR; list-bencher-results --no-latest | xargs rm',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_bencher_results {
    require File::Slurper;

    my %args = @_;

    my $dir = $args{result_dir};

    opendir my($dh), $dir or return [500, "Can't read result_dir `$dir`: $!"];

    # normalize
    ## no critic (ControlStructures::ProhibitMutatingListFunctions)
    my $include_scenarios = [
        map {s!/!::!g; $_} @{ $args{include_scenarios} // [] }
    ];
    my $exclude_scenarios = [
        map {s!/!::!g; $_} @{ $args{exclude_scenarios} // [] }
    ];
    ## use critic

    my %latest; # key = module+(module_startup)+cpu, value = latest row
    my @rows;
  FILE:
    for my $filename (sort readdir $dh) {
        next unless $filename =~ $re_filename;
        my $row = {
            filename => $filename,
            scenario => $1,
            module_startup => $2 ? 1:0,
            time => "$3-$4-$5T$6:$7:$8",
        };
        $row->{scenario} =~ s/-/::/g;
        if (@$include_scenarios) {
            next FILE unless grep {$row->{scenario} eq $_} @$include_scenarios;
        }
        if (@$exclude_scenarios) {
            next FILE if grep {$row->{scenario} eq $_} @$exclude_scenarios;
        }

        my $benchres = _json->decode(File::Slurper::read_text("$dir/$filename"));
        $row->{res} = $benchres;
        $row->{cpu} = $benchres->[3]{'func.cpu_info'}[0]{name};

        $row->{module_startup} = 1 if $benchres->[3]{'func.module_startup'};

        if (defined $args{module_startup}) {
            next FILE if $row->{module_startup} xor $args{module_startup};
        }

        my $key = sprintf(
            "%s.%s.%s",
            $row->{scenario},
            $row->{module_startup} ? 0:1,
            $row->{cpu} // '', # when bencher is run --no-return-meta, there's no cpu information
        );

        if ($args{query} && @{ $args{query} }) {
            my $matches = 1;
          QUERY_WORD:
            for my $q (@{ $args{query} }) {
                my $lq = lc($q);
                if (index(lc($row->{cpu} // ''), $lq) == -1 &&
                        index(lc($row->{filename}), $lq) == -1 &&
                        index(lc($row->{scenario}), $lq) == -1
                ) {
                    $matches = 0;
                    last;
                }
            }
            next unless $matches;
        }

        if (!$latest{$key} || $latest{$key}{time} lt $row->{time}) {
            $latest{$key} = $row;
        }
        $row->{_key} = $key;

        push @rows, $row;
    }

    # we do the 'latest' filter here after we get all the rows
    if (defined $args{latest}) {
        my @rows0 = @rows;
        @rows = grep {
            my $latest_time = $latest{ $_->{_key} }{time};
            $args{latest} ?
                $_->{time} eq $latest_time :
                $_->{time} ne $latest_time;
        } @rows;
    }

    for (@rows) { delete $_->{_key} }

    my $resmeta = {};
    if ($args{fmt}) {
        require Bencher::Backend;

        $resmeta->{'cmdline.skip_format'} = 1;
        my @content;
        for my $row (@rows) {
            push @content, "$row->{filename} (cpu: ", ($row->{cpu}//''), "):\n";
            push @content, Bencher::Backend::format_result($row->{res});
            push @content, "\n";
        }
        return [200, "OK", join("", @content), $resmeta];
    } else {
        delete($_->{res}) for @rows;
        if ($args{detail}) {
            $resmeta->{'table.fields'} = [qw(scenario module_startup time cpu filename)];
        } else {
            @rows = map {$_->{filename}} @rows;
        }
        return [200, "OK", \@rows, $resmeta];
    }
}

$SPEC{cleanup_old_bencher_results} = {
    v => 1.1,
    summary => 'Delete old results',
    description => <<'_',

By default it will only keep 1 latest result for each scenario for the same CPU
and the same module versions.

You can use `--dry-run` first to see which files would be deleted without
actually deleting them.

_
    args => {
        %args_common,
        %args_common_query,
        num_keep => {
            summary => 'Number of old results to keep',
            schema  => ['int*', min=>0],
            default => 0,
        },
    },
    features => {
        dry_run => 1,
    },
};
sub cleanup_old_bencher_results {
    require File::Slurper;

    my %args = @_;
    my $num_keep = $args{num_keep} // 0;

    my $res = list_bencher_results(
        detail           => 1,
        maybe result_dir => $args{result_dir},
        maybe query      => $args{query},
    );
    return $res if $res->[0] != 200;

    my @scenarios;
    for my $scenario (@{ $res->[2] }) {
        $scenario->{result} = _json->decode(File::Slurper::read_text(
            "$args{result_dir}/$scenario->{filename}"));
        push @scenarios, $scenario;
    }

    my %filenames; # key = scenario|cpu|module_startup(0|1)|json(module_versions), value = [filename, ...]
    for my $scenario (@scenarios) {
        my $key = join(
            "|",
            $scenario->{scenario},
            $scenario->{cpu} // '',
            $scenario->{module_startup} ? 1:0,
            _encode_json($scenario->{result}[3]{'func.module_versions'}),
        );
        #log_trace("key = %s", $key);
        push @{$filenames{$key}}, $scenario->{filename};
    }

    $res = envresmulti();
    for my $key (sort keys %filenames) {
        my $val = $filenames{$key};
        next unless @$val > $num_keep+1;
        $val = [sort @$val];
        for my $f (@{$val}[0..$#{$val}-$num_keep-1]) {
            if ($args{-dry_run}) {
                log_warn("[DRY-RUN] Deleting %s ...", $f);
                $res->add_result(200, "OK (dry-run)", {item_id=>$f});
            } else {
                log_warn("Deleting %s ...", $f);
                if (unlink "$args{result_dir}/$f") {
                    $res->add_result(200, "OK", {item_id=>$f});
                } else {
                    log_warn("Can't unlink '%s': %s", $f, $!);
                    $res->add_result(500, "Can't unlink: $!", {item_id=>$f});
                }
            }
        }
    }
    return $res->as_struct;
}

$SPEC{list_bencher_scenario_modules} = {
    v => 1.1,
    summary => 'List Bencher scenario modules',
    args => {
        query => {
            #schema => ['array*', of=>'str*'],
            schema => 'str*',
            pos => 0,
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_bencher_scenario_modules {
    require PERLANCAR::Module::List;

    my %args = @_;
    my $q = lc($args{query} // '');
    my $detail = $args{detail};

    my $res = PERLANCAR::Module::List::list_modules(
        "Bencher::Scenario::", {list_modules=>1, recurse=>1});
    my @res0 = sort keys %$res;

    my @res;
    my $resmeta = {};
    for my $mod (@res0) {
        (my $scenario_name = $mod) =~ s/^Bencher::Scenario:://;
        next if length($q) && index(lc($scenario_name), $q) < 0;
        if ($detail) {
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            my $scenario = ${"$mod\::scenario"};
            my %participant_types;
            for my $p (@{ $scenario->{participants} }) {
                for my $t (qw/code code_template fcall_template
                              cmdline cmdline_template
                              perl_cmdline perl_cmdline_template
                             /) {
                    if ($p->{$t}) {
                        $participant_types{$t}++;
                        last;
                    }
                }
            }
            push @res, {
                name => $scenario_name,
                summary => $scenario->{summary},
                num_participants => scalar(@{$scenario->{participants}}),
                num_datasets => $scenario->{datasets} ?
                    scalar(@{$scenario->{datasets}}) : '-',
                participant_types => join(", ", sort keys %participant_types),
            };
        } else {
            push @res, $scenario_name;
        }
    }
    $resmeta = {'table.fields' => [qw/name summary num_participants num_datasets
                                      participant_types
                                     /]}
        if $detail;

    [200, "OK", \@res, $resmeta];
}

$SPEC{format_bencher_result} = {
    v => 1.1,
    summary => 'Format bencher raw/JSON result',
    args => {
        json => {
            summary => 'JSON data',
            schema => 'str*', # XXX filename
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_file',
        },
        # XXX allow customizing formatters
    },
};
sub format_bencher_result {
    require Bencher::Backend;

    my %args = @_;
    my $res = _json->decode($args{json});
    [200, "OK", Bencher::Backend::format_result($res),
     {'cmdline.skip_format'=>1}];
}

$SPEC{chart_bencher_result} = {
    v => 1.1,
    summary => 'Generate chart of bencher result and display it',
    args => {
        json => {
            summary => 'JSON data',
            schema => 'str*', # XXX filename
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_file',
        },
    },
};
sub chart_bencher_result {
    require Bencher::Backend;
    require Browser::Open;
    require File::Temp;

    my %args = @_;

    my $envres = _json->decode($args{json});

    my ($temp_fh, $temp_fname) = File::Temp::tempfile();

    $temp_fname .= ".png";

    my $chart_res = Bencher::Backend::chart_result(
        envres => $envres, output_file => $temp_fname, overwrite=>1);

    return $chart_res if $chart_res->[0] != 200;

    my $view_res = Browser::Open::open_browser("file:$temp_fname");

    $view_res ? [500, "Failed"] : [200, "OK"];
}

$SPEC{bencher_module_startup_overhead} = {
    v => 1.1,
    summary => 'Accept a list of module names and '.
        'perform startup overhead benchmark',
    description => <<'_',

    % bencher-module-startup-overhead Mod1 Mod2 Mod3

is basically a shortcut for creating a scenario like this:

    {
        module_startup => 1,
        participants => [
            {module=>"Mod1"},
            {module=>"Mod2"},
            {module=>"Mod3"},
        ],
    }

and running that scenario with `bencher`.

To specify import arguments, you can use:

    % bencher-module-startup-overhead Mod1 Mod2=arg1,arg2

which will translate to this Bencher scenario:

    {
        module_startup => 1,
        participants => [
            {module=>"Mod1"},
            {module=>"Mod2", import_args=>'arg1,arg2'},
        ],
    }


_
    args => {
        modules => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module',
            schema => ['array*', of=>'perl::modargs*'],
            req => 1,
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
        with_process_size => {
            schema => 'bool*',
        },
    },

};
sub bencher_module_startup_overhead {
    my %args = @_;

    my $mods = $args{modules};

    my $with_process_size = $args{with_process_size} //
        $^O =~ /linux/ ? 1:0;

    my $scenario = {
        module_startup => 1,
        participants => [],
        with_process_size => $with_process_size,
    };
    for my $mod (@$mods) {
        my $import_args;
        if ($mod =~ s/=(.*)//) {
            $import_args = $1;
        }
        push @{$scenario->{participants}}, {
            module => $mod,
            (import_args => $import_args) x !!defined($import_args),
        };
    }

    require Bencher::Backend;
    my $res = Bencher::Backend::bencher(
        action => 'bench',
        scenario => $scenario,
    );
    return $res unless $res->[0] == 200;

    my $r = $args{-cmdline_r};
    return $res if !$r || $r->{format} && $r->{format} !~ /text/;

    [200, "OK", Bencher::Backend::format_result($res),
     {'cmdline.skip_format'=>1}];
}

$SPEC{bencher_code} = {
    v => 1.1,
    summary => 'Accept a list of codes and '.
        'perform benchmark',
    description => <<'_',

    % bencher-code 'code1' 'code2'

is basically a shortcut for creating a scenario like this:

    {
        participants => [
            {code_template=>'code1'},
            {code_template=>'code2'},
        ],
    }

and running that scenario with `bencher`.

_
    args => {
        startup => {
            summary => 'Use code_startup mode instead of normal benchmark',
            schema => 'bool*',
            default => 0,
        },
        codes => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'code',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
        with_process_size => {
            schema => 'bool*',
        },
        precision => {
            schema => 'float*',
        },
    },

};
sub bencher_code {
    my %args = @_;

    my $codes = $args{codes};

    my $scenario = {
        participants => [],
    };
    for my $code (@$codes) {
        push @{$scenario->{participants}}, {
            code_template => $code,
        };
    }

    require Bencher::Backend;
    my $res = Bencher::Backend::bencher(
        action => 'bench',
        scenario => $scenario,
        code_startup => $args{startup},
        with_process_size => $args{with_process_size},
        (precision => $args{precision}) x !!(defined $args{precision}),
    );
    return $res unless $res->[0] == 200;

    my $r = $args{-cmdline_r};
    return $res if !$r || $r->{format} && $r->{format} !~ /text/;

    [200, "OK", Bencher::Backend::format_result($res),
     {'cmdline.skip_format'=>1}];
}

$SPEC{bencher_for} = {
    v => 1.1,
    summary => 'List distributions that benchmarks specified modules',
    description => <<'_',

This utility consults <prog:lcpan> (local indexed CPAN mirror) to check if there
are distributions that benchmarks a specified module. This is done by checking
the presence of a dependency with the relationship `x_benchmarks`.

_
    args => {
        modules => {
            schema => ['array*', of=>'perl::modname*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },

};
sub bencher_for {
    require App::lcpan::Call;

    my %args = @_;

    my $res = App::lcpan::Call::call_lcpan_script(
        argv => ["rdeps", "--phase", "x_benchmarks", @{ $args{modules} }],
    );

    return $res unless $res->[0] == 200;

    return [200, "OK", [map {$_->{dist}} @{ $res->[2] }]];
}

1;
# ABSTRACT: Utilities related to bencher

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BencherUtils - Utilities related to bencher

=head1 VERSION

This document describes version 0.242 of App::BencherUtils (from Perl distribution App-BencherUtils), released on 2019-08-08.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities:

=over

=item * L<bencher-code>

=item * L<bencher-for>

=item * L<bencher-module-startup-overhead>

=item * L<chart-bencher-result>

=item * L<cleanup-old-bencher-results>

=item * L<format-bencher-result>

=item * L<list-bencher-results>

=item * L<list-bencher-scenario-modules>

=back

=head1 FUNCTIONS


=head2 bencher_code

Usage:

 bencher_code(%args) -> [status, msg, payload, meta]

Accept a list of codes and perform benchmark.

% bencher-code 'code1' 'code2'

is basically a shortcut for creating a scenario like this:

 {
     participants => [
         {code_template=>'code1'},
         {code_template=>'code2'},
     ],
 }

and running that scenario with C<bencher>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<codes>* => I<array[str]>

=item * B<precision> => I<float>

=item * B<startup> => I<bool> (default: 0)

Use code_startup mode instead of normal benchmark.

=item * B<with_process_size> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 bencher_for

Usage:

 bencher_for(%args) -> [status, msg, payload, meta]

List distributions that benchmarks specified modules.

This utility consults L<lcpan> (local indexed CPAN mirror) to check if there
are distributions that benchmarks a specified module. This is done by checking
the presence of a dependency with the relationship C<x_benchmarks>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<modules>* => I<array[perl::modname]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 bencher_module_startup_overhead

Usage:

 bencher_module_startup_overhead(%args) -> [status, msg, payload, meta]

Accept a list of module names and perform startup overhead benchmark.

% bencher-module-startup-overhead Mod1 Mod2 Mod3

is basically a shortcut for creating a scenario like this:

 {
     module_startup => 1,
     participants => [
         {module=>"Mod1"},
         {module=>"Mod2"},
         {module=>"Mod3"},
     ],
 }

and running that scenario with C<bencher>.

To specify import arguments, you can use:

 % bencher-module-startup-overhead Mod1 Mod2=arg1,arg2

which will translate to this Bencher scenario:

 {
     module_startup => 1,
     participants => [
         {module=>"Mod1"},
         {module=>"Mod2", import_args=>'arg1,arg2'},
     ],
 }

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<modules>* => I<array[perl::modargs]>

=item * B<with_process_size> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 chart_bencher_result

Usage:

 chart_bencher_result(%args) -> [status, msg, payload, meta]

Generate chart of bencher result and display it.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<json>* => I<str>

JSON data.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 cleanup_old_bencher_results

Usage:

 cleanup_old_bencher_results(%args) -> [status, msg, payload, meta]

Delete old results.

By default it will only keep 1 latest result for each scenario for the same CPU
and the same module versions.

You can use C<--dry-run> first to see which files would be deleted without
actually deleting them.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<num_keep> => I<int> (default: 0)

Number of old results to keep.

=item * B<query> => I<array[str]>

=item * B<result_dir>* => I<str>

Directory to store results files in.

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 format_bencher_result

Usage:

 format_bencher_result(%args) -> [status, msg, payload, meta]

Format bencher raw/JSON result.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<json>* => I<str>

JSON data.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_bencher_results

Usage:

 list_bencher_results(%args) -> [status, msg, payload, meta]

List results in results directory.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<exclude_scenarios> => I<array[str]>

=item * B<fmt> => I<bool>

Display each result with bencher-fmt.

=item * B<include_scenarios> => I<array[str]>

=item * B<latest> => I<bool>

=item * B<module_startup> => I<bool>

=item * B<query> => I<array[str]>

=item * B<result_dir>* => I<str>

Directory to store results files in.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_bencher_scenario_modules

Usage:

 list_bencher_scenario_modules(%args) -> [status, msg, payload, meta]

List Bencher scenario modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<query> => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-BencherUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BencherUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BencherUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
