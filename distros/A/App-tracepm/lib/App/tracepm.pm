package App::tracepm;

our $DATE = '2017-07-29'; # DATE
our $VERSION = '0.21'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use version;

our %SPEC;

our $tablespec = {
    fields => {
        module  => {schema=>'str*' , pos=>0},
        version => {schema=>'str*' , pos=>1},
        require => {schema=>'str*' , pos=>2},
        by      => {schema=>'str*' , pos=>3},
        seq     => {schema=>'int*' , pos=>4},
        is_xs   => {schema=>'bool' , pos=>5},
        is_core => {schema=>'bool*', pos=>6},
    },
    pk => 'module',
};

$SPEC{tracepm} = {
    v => 1.1,
    summary => 'Trace dependencies of your Perl script',
    args_rels => {
        req_one => [qw/script module eval/],
    },
    args => {
        script => {
            summary => 'Path to script file',
            schema => ['str*'],
            pos => 0,
            cmdline_aliases => {s=>{}},
            tags => ['category:input'],
        },
        eval => {
            summary => 'Specify script from command-line instead',
            schema  => 'str*',
            cmdline_aliases => {e=>{}},
            tags => ['category:input'],
        },
        module => {
            summary => "--module MOD is equivalent to --script 'use MOD'",
            schema  => 'str*',
            cmdline_aliases => {m=>{}},
            tags => ['category:input'],
        },

        method => {
            summary => 'Tracing method to use',
            schema => ['str*',
                       in=>[qw/
                                  fatpacker
                                  require
                                  prereqscanner
                                  prereqscanner_lite
                                  prereqscanner_recurse
                                  prereqscanner_lite_recurse
                              /]],
            default => 'fatpacker',
            description => <<'_',

There are several tracing methods that can be used:

* `fatpacker` (the default): This method uses the same method that `fatpacker
  trace` uses, which is running the script using `perl -c` then collect the
  populated `%INC`. Only modules loaded during compile time are detected.

* `require`: This method runs your script normally until it exits. At the start
  of program, it replaces `CORE::GLOBAL::require()` with a routine that logs the
  require() argument to the log file. Modules loaded during runtime is also
  logged by this method. But some modules might not work, specifically modules
  that also overrides require() (there should be only a handful of modules that
  do this though).

* `prereqscanner`: This method does not run your Perl program, but statically
  analyze it using `Perl::PrereqScanner`. Since it uses `PPI`, it can be rather
  slow.

* `prereqscanner_recurse`: Like `prereqscanner`, but will recurse into all
  non-core modules until they are exhausted. Modules that are not found will be
  skipped. It is recommended to use the various `recurse_exclude_*` options
  options to limit recursion.

* `prereqscanner_lite`: This method is like the `prereqscanner` method, but
  instead of `Perl::PrereqScanner` it uses `Perl::PrereqScanner::Lite`. The
  latter does not use `PPI` but use `Compiler::Lexer` which is significantly
  faster.

* `prereqscanner_lite_recurse`: Like `prereqscanner_lite`, but recurses.

_
        },
        cache_prereqscanner => {
            summary => "Whether cache Perl::PrereqScanner{,::Lite} result",
            schema => ['bool' => default=>0],
        },
        recurse_exclude => {
            summary => 'When recursing, exclude some modules',
            schema => ['array*' => of => 'str*'],
        },
        recurse_exclude_pattern => {
            summary => 'When recursing, exclude some module patterns',
            schema => ['array*' => of => 'str*'], # XXX array of re
        },
        recurse_exclude_xs => {
            summary => 'When recursing, exclude XS modules',
            schema => ['bool'],
        },
        recurse_exclude_core => {
            summary => 'When recursing, exclude core modules',
            schema => ['bool'],
        },
        trap_script_output => {
            # XXX relevant only when method=trace or method=require
            summary => 'Trap script output so it does not interfere '.
                'with trace result',
            schema => ['bool', is=>1],
        },
        args => {
            summary => 'Script arguments',
            schema => ['array*' => of => 'str*'],
            req => 0,
            pos => 1,
            greedy => 1,
        },
        multiple_runs => {
            # XXX add args_rels: conflict with args
            summary => 'Parameter to run script multiple times',
            schema => ['array*' => of => 'hash*'],
            description => <<'_',

A more general alternative to using `args`. Script will be run multiple times,
each with setting from element of this option.

Can be used to reach multiple run pathways and trace more modules.

Example:

    [{"args":["-h"]}, # help mode
     {"args":[""], "env":{"COMP_LINE":"cmd x", "COMP_POINT":5}},
    ],

_
        },
        perl_version => {
            summary => 'Perl version, defaults to current running version',
            description => <<'_',

This is for determining which module is core (the list differs from version to
version. See Module::CoreList for more details.

_
            schema => ['str*'],
            cmdline_aliases => { V=>{} },
        },
        use => {
            summary => 'Additional modules to "use"',
            schema => ['array*' => of => 'str*'],
            description => <<'_',

This is like running:

    perl -MModule1 -MModule2 script.pl

_
        },
        detail => {
            summary => 'Whether to return records instead of just module names',
            schema => ['bool' => default=>0],
            cmdline_aliases => {l=>{}},
            tags => ['category:field-selection'],
        },
        core => {
            summary => 'Filter only modules that are in core',
            schema  => 'bool',
            tags => ['category:filtering'],
        },
        xs => {
            summary => 'Filter only modules that are XS modules',
            schema  => 'bool',
            tags => ['category:filtering'],
        },
        # fields
    },
    result => {
        table => { spec=>$tablespec },
    },
};
sub tracepm {
    require File::Temp;

    my %args = @_;

    my $script;
    {
        if (defined $args{script}) {
            $script = $args{script};
            last;
        }
        my ($fh, $filename) = File::Temp::tempfile();
        if (defined $args{module}) {
            print $fh "use $args{module};\n";
        } elsif (defined $args{eval}) {
            print $fh $args{eval};
        } else {
            die "Please specify input via one of ".
                "--script (-s), --module (-m), or --eval (-e)\n";
        }
        $script = $filename;
    }

    my $method = $args{method};
    my $plver = version->parse($args{perl_version} // $^V);

    my $add_fields_and_filter_1 = sub {
        my $r = shift;
        if ($args{detail} || defined($args{core})) {
            require Module::CoreList::More;
            my $is_core = Module::CoreList::More->is_still_core(
                $r->{module}, undef, $plver);
            return 0 if defined($args{core}) && ($args{core} xor $is_core);
            $r->{is_core} = $is_core;
        }

        if ($args{detail} || defined($args{xs})) {
            require Module::XSOrPP;
            my $is_xs = Module::XSOrPP::is_xs($r->{module});
            return 0 if defined($args{xs}) && (
                !defined($is_xs) || ($args{xs} xor $is_xs));
            $r->{is_xs} = $is_xs;
        }
        1;
    };

    my @res;
    if ($method =~ /\A(fatpacker|require)\z/) {

        my ($outfh, $outf) = File::Temp::tempfile();

        my $routine;
        if ($method eq 'fatpacker') {
            $routine = sub {
                require App::FatPacker;
                my $fp = App::FatPacker->new;
                $fp->trace(
                    output => ">>$outf",
                    use    => $args{use},
                    args   => [$script, @{$args{args} // []}],
                );
            };
        } else {
            # 'require' method
            $routine = sub {
                if ($args{multiple_runs}) {
                    local $ENV{TRACEPM_TRACER_APPEND} = 1;
                    for my $run (@{ $args{multiple_runs} }) {
                        my $save_env;
                        if ($run->{env}) {
                            $save_env = {};
                            for (keys %{ $run->{env} }) {
                                $save_env->{$_} = $ENV{$_};
                                $ENV{$_} = $run->{env}{$_};
                            }
                        }
                        system($^X,
                               "-MApp::tracepm::Tracer=$outf",
                               (map {"-M$_"} @{$args{use} // []}),
                               $script, @{$run->{args} // []},
                           );
                        if ($save_env) {
                            for (keys %$save_env) {
                                $ENV{$_} = $save_env->{$_};
                            }
                        }
                    }
                } else {
                    system($^X,
                           "-MApp::tracepm::Tracer=$outf",
                           (map {"-M$_"} @{$args{use} // []}),
                           $script, @{$args{args} // []},
                       );
                }
            };
        }

        if ($args{trap_script_output}) {
            require Capture::Tiny;
            Capture::Tiny::capture_merged($routine);
        } else {
            $routine->();
        }

        open my($fh), "<", $outf
            or die "Can't open trace output: $!";

        my $i = 0;
        while (<$fh>) {
            chomp;
            log_trace "got line: $_";

            my $r = {};
            $i++;
            $r->{seq} = $i if $method eq 'require';

            if (/(.+)\t(.+)/) {
                $r->{require} = $1;
                $r->{by} = $2;
            } else {
                $r->{require} = $_;
            }

            unless ($r->{require} =~ /(.+)\.pm\z/) {
                warn "Skipped non-pm entry: $_\n";
                next;
            }
            my $mod = $1; $mod =~ s!/!::!g;
            $r->{module} = $mod;

            next unless $add_fields_and_filter_1->($r);
            push @res, $r;
        }

        unlink $outf;

    } elsif ($method =~ /\A(?:prereqscanner|prereqscanner_lite)(_recurse)?\z/) {

        require CHI;
        require Module::Path::More;

        my @recurse_blacklist = (
            'Module::List', # segfaults on my pc
        );

        my $chi = CHI->new(driver => $args{cache_prereqscanner} ? "File" : "Null");

        my $recurse = $1 ? 1:0;
        my %seen_mods; # for limiting recursion

        my $scanner;
        my $scan;
        $scan = sub {
            my $file = shift;
            log_info "Scanning %s ...", $file;
            my $cache_key = "tracepm-$method-$file";
            my $sres = $chi->compute(
                $cache_key, "24h", # XXX cache should check timestamp
                sub { $scanner->scan_file($file) },
            );
            my $reqs = $sres->{requirements};

            my @new; # new modules to check
          MOD:
            for my $mod (keys %$reqs) {
                next if $mod =~ /\A(perl)\z/;
                my $req = $reqs->{$mod};
                my $v = $req->{minimum}{original};
                my $r = {module=>$mod, version=>$v};

              CHECK_RECURSE:
                {
                    last unless $recurse;
                    last MOD if $seen_mods{$mod}++;
                    my $path = Module::Path::More::module_path(module=>$mod);
                    unless ($path) {
                        log_info "Skipped recursing to %s: path not found", $mod;
                        last;
                    }
                    if ($mod ~~ @recurse_blacklist) {
                        log_info "Skipped recursing to %s: excluded by hard-coded blacklist", $mod;
                        last;
                    }
                    if ($args{recurse_exclude}) {
                        if ($mod ~~ @{ $args{recurse_exclude} }) {
                            log_info "Skipped recursing to %s: excluded by list", $mod;
                            last;
                        }
                    }
                    if ($args{recurse_exclude_pattern}) {
                        for (@{ $args{recurse_exclude_pattern} }) {
                            if ($mod =~ /$_/) {
                                log_info "Skipped recursing to %s: excluded by pattern %s", $mod, $_;
                                last CHECK_RECURSE;
                            }
                        }
                    }
                    if ($args{recurse_exclude_core}) {
                        require Module::CoreList::More;
                        my $is_core = Module::CoreList::More->is_still_core(
                            $mod, undef, $plver); # XXX use $v?
                        if ($is_core) {
                            log_info "Skipped recursing to %s: core module", $mod;
                        }
                    }
                    if ($args{recurse_exclude_xs}) {
                        require Module::XSOrPP;
                        my $is_xs = Module::XSOrPP::is_xs($mod);
                        if ($is_xs) {
                            log_info "Skipped recursing to %s: XS module", $mod;
                            last;
                        }
                    }
                    push @new, $path;
                }

                next unless $add_fields_and_filter_1->($r);
                push @res, $r;
            }
            if (@new) {
                log_debug "Recursively scanning %s ...", join(", ", @new);
                $scan->($_) for @new;
            }
        };

        my $sres;
        if ($method eq 'prereqscanner') {
            require Perl::PrereqScanner;
            $scanner = Perl::PrereqScanner->new;
        } else {
            # 'prereqscanner_lite' method
            require Perl::PrereqScanner::Lite;
            $scanner = Perl::PrereqScanner::Lite->new;
        }
        $scan->($script);

    } else {

        return [400, "Unknown trace method '$method'"];

    } # if method

    if (defined $args{module}) {
        @res = grep { $_->{module} ne $args{module} } @res;
    }

    unless ($args{detail}) {
        @res = map {$_->{module}} @res;
    }

    my $ff = $tablespec->{fields};
    my @ff = sort {$ff->{$a}{pos} <=> $ff->{$b}{pos}} keys %$ff;
    [200, "OK", \@res, {"table.fields" => \@ff}];
}

1;
# ABSTRACT: Trace dependencies of your Perl script

__END__

=pod

=encoding UTF-8

=head1 NAME

App::tracepm - Trace dependencies of your Perl script

=head1 VERSION

This document describes version 0.21 of App::tracepm (from Perl distribution App-tracepm), released on 2017-07-29.

=head1 SYNOPSIS

This distribution provides command-line utility called L<tracepm>.

=for Pod::Coverage ^()$

=head1 FUNCTIONS


=head2 tracepm

Usage:

 tracepm(%args) -> [status, msg, result, meta]

Trace dependencies of your Perl script.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args> => I<array[str]>

Script arguments.

=item * B<cache_prereqscanner> => I<bool> (default: 0)

Whether cache Perl::PrereqScanner{,::Lite} result.

=item * B<core> => I<bool>

Filter only modules that are in core.

=item * B<detail> => I<bool> (default: 0)

Whether to return records instead of just module names.

=item * B<eval> => I<str>

Specify script from command-line instead.

=item * B<method> => I<str> (default: "fatpacker")

Tracing method to use.

There are several tracing methods that can be used:

=over

=item * C<fatpacker> (the default): This method uses the same method that C<fatpacker
trace> uses, which is running the script using C<perl -c> then collect the
populated C<%INC>. Only modules loaded during compile time are detected.

=item * C<require>: This method runs your script normally until it exits. At the start
of program, it replaces C<CORE::GLOBAL::require()> with a routine that logs the
require() argument to the log file. Modules loaded during runtime is also
logged by this method. But some modules might not work, specifically modules
that also overrides require() (there should be only a handful of modules that
do this though).

=item * C<prereqscanner>: This method does not run your Perl program, but statically
analyze it using C<Perl::PrereqScanner>. Since it uses C<PPI>, it can be rather
slow.

=item * C<prereqscanner_recurse>: Like C<prereqscanner>, but will recurse into all
non-core modules until they are exhausted. Modules that are not found will be
skipped. It is recommended to use the various C<recurse_exclude_*> options
options to limit recursion.

=item * C<prereqscanner_lite>: This method is like the C<prereqscanner> method, but
instead of C<Perl::PrereqScanner> it uses C<Perl::PrereqScanner::Lite>. The
latter does not use C<PPI> but use C<Compiler::Lexer> which is significantly
faster.

=item * C<prereqscanner_lite_recurse>: Like C<prereqscanner_lite>, but recurses.

=back

=item * B<module> => I<str>

--module MOD is equivalent to --script 'use MOD'.

=item * B<multiple_runs> => I<array[hash]>

Parameter to run script multiple times.

A more general alternative to using C<args>. Script will be run multiple times,
each with setting from element of this option.

Can be used to reach multiple run pathways and trace more modules.

Example:

 [{"args":["-h"]}, # help mode
  {"args":[""], "env":{"COMP_LINE":"cmd x", "COMP_POINT":5}},
 ],

=item * B<perl_version> => I<str>

Perl version, defaults to current running version.

This is for determining which module is core (the list differs from version to
version. See Module::CoreList for more details.

=item * B<recurse_exclude> => I<array[str]>

When recursing, exclude some modules.

=item * B<recurse_exclude_core> => I<bool>

When recursing, exclude core modules.

=item * B<recurse_exclude_pattern> => I<array[str]>

When recursing, exclude some module patterns.

=item * B<recurse_exclude_xs> => I<bool>

When recursing, exclude XS modules.

=item * B<script> => I<str>

Path to script file.

=item * B<trap_script_output> => I<bool>

Trap script output so it does not interfere with trace result.

=item * B<use> => I<array[str]>

Additional modules to "use".

This is like running:

 perl -MModule1 -MModule2 script.pl

=item * B<xs> => I<bool>

Filter only modules that are XS modules.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-tracepm>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-App-tracepm>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-tracepm>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
