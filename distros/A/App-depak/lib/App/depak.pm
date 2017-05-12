package App::depak;

our $DATE = '2016-08-02'; # DATE
our $VERSION = '0.53'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';
BEGIN { no warnings; $main::Log_Level = 'info' }

use App::lcpan::Call qw(call_lcpan_script);
use App::tracepm (); # we need list of trace methods too so we load early
use File::chdir;
use File::Slurper qw(write_binary read_binary);
use version;

my @ALLOW_XS = qw(List::MoreUtils version::vxs);

our %SPEC;

sub _trace {
    my $self = shift;

    return if $self->{trace_method} eq 'none';

    $log->debugf("  Tracing with method '%s' ...", $self->{trace_method});
    my %traceargs = (
        method => $self->{trace_method},
        script => $self->{input_file},
        args => $self->{args},
        (multiple_runs => $self->{multiple_runs}) x !!$self->{multiple_runs},
        use => $self->{use},
        recurse_exclude_core => $self->{exclude_core} ? 1:0,
        detail => 1,
        trap_script_output => 1,

        core => $self->{exclude_core} ? 0 : undef,
        ($self->{trace_extra_opts} ? %{$self->{trace_extra_opts}} : ()),
    );

    $log->debugf("  tracepm args: %s", \%traceargs);
    my $res = App::tracepm::tracepm(%traceargs);
    die "Can't trace: $res->[0] - $res->[1]\n" unless $res->[0] == 200;
    $self->{deps} = $res->[2];
}

sub _build_lib {
    use experimental 'smartmatch';

    require Dist::Util;
    require File::Copy;
    require File::Find;
    require File::Path;
    require List::MoreUtils;
    require Module::Path::More;

    my $self = shift;

    my $tempdir = $self->{tempdir};

    my $totsize = 0;
    my $totfiles = 0;

    my %mod_paths; # modules to add, key=name, val=path

    my $deps = $self->{deps};
    for (@{$deps // []}) {
        next if $_->{is_core} && $self->{exclude_core};
        $log->debugf("  Adding module: %s (traced)", $_->{module});
        $mod_paths{$_->{module}} = undef;
    }

    if ($self->{include_prereq} && @{ $self->{include_prereq} }) {
        $log->infof("Searching recursive prereqs to add into the pack: %s", $self->{include_prereq});
        for my $prereq (@{ $self->{include_prereq} }) {
            my @mods = ($prereq);
            # find prereq's dependencies
            my $res = call_lcpan_script(argv=>["deps", "--no-include-core", "-R", "--perl-version", $self->{perl_version}->numify, $prereq]);
            die "Can't lcpan deps: $res->[0] - $res->[1]" unless $res->[0] == 200;
            for my $entry (@{ $res->[2] }) {
                $entry->{module} =~ s/^\s+//;
                push @mods, $entry->{module};
            }
            # pull all the other modules from the same dists
            $res = call_lcpan_script(argv=>["mods-from-same-dist", "--latest", "--detail", @mods]);
            die "Can't lcpan mods-from-same-dist: $res->[0] - $res->[1]" unless $res->[0] == 200;
            for my $entry (@{ $res->[2] }) {
                $log->debugf("  Adding module: %s (include_prereq %s, dist %s)", $entry->{name}, $prereq, $entry->{dist});
                $mod_paths{$entry->{name}} = undef;
            }
        }
    }

    for (@{ $self->{include_module} // [] }) {
        $log->debugf("  Adding module: %s (included)", $_);
        $mod_paths{$_} = undef;
    }

    for (@{ $self->{include_dist} // [] }) {
        my @distmods = Dist::Util::list_dist_modules($_);
        if (@distmods) {
            $log->debugf("  Adding modules: %s (included dist)", join(", ", @distmods));
            $mod_paths{$_} = undef for @distmods;
        } else {
            $log->infof("  Adding module: %s (included dist, but can't find other modules)", $_);
            $mod_paths{$_} = undef;
        }
    }

    if (defined(my $file = $self->{include_list})) {
        $log->debugf("  Adding modules listed in: %s", $file);
        open my($fh), "<", $file
            or die "Can't open modules list file '$file': $!\n";
        my $linenum = 0;
        while (my $line = <$fh>) {
            $linenum++;
            next unless $line =~ /\S/;
            $line =~ s/^\s+//;
            $line =~ s/^(\w+(?:::\w+)*)\s*// or do {
                warn "Invalid syntax in $file:$linenum: can't find valid module name, skipped\n";
                next;
            };
            my $mod = $1;

            # special handling for scan_prereqs or dist.ini
            next if $mod eq 'perl';

            $log->debugf("    Adding module: %s", $mod);
            $mod_paths{$mod} = undef;
        }
    }

    for (@{ $self->{include_dir} // [] }) {
        $log->debugf("  Adding modules found in: %s", $_);
        local $CWD = $_;
        File::Find::find(
            sub {
                return unless -f;
                return unless /\.pm$/i;
                my $mod = $File::Find::dir eq '.' ? $_ : "$File::Find::dir/$_";
                $mod =~ s!^\.[/\\]!!;
                $mod =~ s![/\\]!::!g; $mod =~ s/\.pm$//i;
                $log->debugf("    Adding module: %s", $mod);
                $mod_paths{$mod} = "$CWD/$_";
            }, ".",
        );
    }

    # filter excluded
    my $excluded_distmods;
    my $excluded_list;
    my $excluded_prereqs;
    my %fmod_paths; # filtered mods

  MOD_TO_FILTER:
    for my $mod (sort keys %mod_paths) {
        if ($self->{exclude_prereq} && @{ $self->{exclude_prereq} }) {
            if (!$excluded_prereqs) {
                $excluded_prereqs = {};
                $log->infof("Searching recursive prereqs to exclude from the pack: %s", $self->{exclude_prereq});
                for my $prereq (@{ $self->{exclude_prereq} }) {
                    my @mods = ($prereq);
                    # find prereq's dependencies
                    my $res = call_lcpan_script(argv=>["deps", "--no-include-core", "-R", "--perl-version", $self->{perl_version}->numify, $prereq]);
                    die "Can't lcpan deps: $res->[0] - $res->[1]" unless $res->[0] == 200;
                    for my $entry (@{ $res->[2] }) {
                        $entry->{module} =~ s/^\s+//;
                        push @mods, $entry->{module};
                    }
                    # pull all the other modules from the same dists
                    $res = call_lcpan_script(argv=>["mods-from-same-dist", "--latest", "--detail", @mods]);
                    die "Can't lcpan mods-from-same-dist: $res->[0] - $res->[1]" unless $res->[0] == 200;
                    for my $entry (@{ $res->[2] }) {
                        $excluded_prereqs->{$entry->{name}} = $prereq;
                    }
                }
            }
            if ($excluded_prereqs->{$mod}) {
                $log->infof("Excluding %s: skipped by exclude_prereq %s", $mod, $excluded_prereqs->{$mod});
                next MOD_TO_FILTER;
            }
        }

        if ($self->{exclude_module} && $mod ~~ @{ $self->{exclude_module} }) {
            $log->infof("Excluding %s: skipped", $mod);
            next MOD_TO_FILTER;
        }
        for (@{ $self->{exclude_pattern} // [] }) {
            if ($mod ~~ /$_/) {
                $log->infof("Excluding %s: skipped by pattern %s", $mod, $_);
                next MOD_TO_FILTER;
            }
        }
        if ($self->{exclude_dist}) {
            if (!$excluded_distmods) {
                $excluded_distmods = [];
                for (@{ $self->{exclude_dist} }) {
                    push @$excluded_distmods, Dist::Util::list_dist_modules($_);
                }
            }
            if ($mod ~~ @$excluded_distmods) {
                $log->infof("Excluding %s (by dist): skipped", $mod);
                next MOD_TO_FILTER;
            }
        }
        if (defined(my $file = $self->{exclude_list})) {
            if (!$excluded_list) {
                $excluded_list = [];
                $log->debugf("  Reading excludes listed in: %s", $file);
                open my($fh), "<", $file
                    or die "Can't open modules list file '$file': $!\n";
                my $linenum = 0;
                while (my $line = <$fh>) {
                    $linenum++;
                    next unless $line =~ /\S/;
                    $line =~ s/^\s+//;
                    $line =~ s/(\w+(?:::\w+)*)\s*// or do {
                        warn "Invalid syntax in $file:$linenum: can't find valid module name, skipped\n";
                        next;
                    };
                    my $emod = $1;
                    $log->debugf("    Adding excluded module: %s", $emod);
                    push @$excluded_list, $emod;
                }
            }
            if ($mod ~~ @$excluded_list) {
                $log->infof("Excluding %s (by list): skipped", $mod);
            }
        }

        $fmod_paths{$mod} = $mod_paths{$mod};
    }
    %mod_paths = %fmod_paths;

    require Module::XSOrPP;

  MOD_TO_ADD:
    for my $mod (sort keys %mod_paths) {
        my $mpath = $mod_paths{$mod};

        unless ($mpath) {
            if (Module::XSOrPP::is_xs($mod)) {
                unless (!$self->{allow_xs} || $mod ~~ @{ $self->{allow_xs} } ||
                            $mod ~~ @ALLOW_XS) {
                    die "Can't add XS module: $mod\n";
                }
            }
        }

        $mpath //= Module::Path::More::module_path(module=>$mod);
        unless (defined $mpath) {
            if ($self->{skip_not_found}) {
                $log->infof("Path for module '%s' not found, skipped", $mod);
                next MOD_TO_ADD;
            } else {
                die "Can't find path for $mod\n";
            }
        }

        my $modp = $mod; $modp =~ s!::!/!g; $modp .= ".pm";
        my ($dir) = $modp =~ m!(.+)/(.+)!;
        if ($dir) {
            my $dir_to_make = "$tempdir/lib/$dir";
            unless (-d $dir_to_make) {
                File::Path::make_path($dir_to_make) or die "Can't make_path: $dir_to_make\n";
            }
        }

        if ($self->{stripper}) {
            my $stripper = do {
                require Perl::Stripper;
                Perl::Stripper->new(
                    maintain_linum => $self->{stripper_maintain_linum},
                    strip_ws       => $self->{stripper_ws},
                    strip_comment  => $self->{stripper_comment},
                    strip_pod      => $self->{stripper_pod},
                    strip_log      => $self->{stripper_log},
                );
            };
            $log->debug("  Stripping $mpath --> $modp ...");
            my $src = read_binary($mpath);
            my $stripped = $stripper->strip($src);
            write_binary("$tempdir/lib/$modp", $stripped);
        } elsif ($self->{strip}) {
            require Perl::Strip;
            my $strip = Perl::Strip->new;
            $log->debug("  Stripping $mpath --> $modp ...");
            my $src = read_binary($mpath);
            my $stripped = $strip->strip($src);
            write_binary("$tempdir/lib/$modp", $stripped);
        } elsif ($self->{squish}) {
            $log->debug("  Squishing $mpath --> $modp ...");
            require Perl::Squish;
            my $squish = Perl::Squish->new;
            $squish->file($mpath, "$tempdir/lib/$modp");
        } else {
            $log->debug("  Copying $mpath --> $tempdir/lib/$modp ...");
            File::Copy::copy($mpath, "$tempdir/lib/$modp");
        }

        $totfiles++;
        $totsize += (-s $mpath);
    }
    $log->infof("  Added %d files (%.1f KB)", $totfiles, $totsize/1024);
}

sub _pack {
    require ExtUtils::MakeMaker;
    require File::Find;

    my $self = shift;

    my $tempdir = $self->{tempdir};

    $self->{_included_modules} = {};
    my %pack_args;
    {
        local $CWD = "$tempdir/lib";
        File::Find::find(
            sub {
                return unless -f;
                return unless /\.pm$/i;
                my $mod_pm = $File::Find::dir eq '.' ? $_ : "$File::Find::dir/$_";
                $mod_pm =~ s!^\.[/\\]!!;
                $mod_pm =~ s!\\!/!g; # convert windows-style path

                my $mod = $mod_pm;
                $mod =~ s/\.pm$//;
                $mod =~ s!/!::!g;

                my $mod_ver = MM->parse_version($_);
                $mod_ver = undef if defined($mod_ver) && $mod_ver eq 'undef';

                $pack_args{module_srcs}{$mod_pm} = read_binary($_);
                $self->{_included_modules}{$mod} = $mod_ver;
            }, ".",
        );
    }

    my $script = read_binary($self->{abs_input_file});

    my $shebang = $self->{shebang} // '#!/usr/bin/perl';
    $shebang = "#!$shebang" unless $shebang =~ /^#!/;
    $shebang =~ s/\R+//g;

    # strip shebang from script
    $script =~ s/\A#![^\n]*\R?//;

    my $res;
    $pack_args{preamble}  = "$shebang\n\n";
    $pack_args{postamble} = "\n$script";
    if ($self->{pack_method} eq 'datapack') {
        require Module::DataPack;
        $res = Module::DataPack::datapack_modules(
            %pack_args,
        );
        return $res unless $res->[0] == 200;
    } else {
        require Module::FatPack;
        $res = Module::FatPack::fatpack_modules(
            %pack_args,
        );
        return $res unless $res->[0] == 200;
    }

    write_binary($self->{abs_output_file}, $res->[2]);
    chmod 0755, $self->{abs_output_file};

    $log->infof("  Produced %s (%.1f KB)",
                $self->{abs_output_file}, (-s $self->{abs_output_file})/1024);
}

sub _test {
    use experimental 'smartmatch';
    require Capture::Tiny;
    require IPC::System::Options;

    my $self = shift;
    die "Can't test: at least one test case ('--test-case-json') must be specified\n"
        unless $self->{test_cases} && @{ $self->{test_cases} };

    my $cases = $self->{test_cases};
    my $i = 0;
    for my $case (@$cases) {
        $i++;
        $log->debugf("  Test case %d/%d: %s ...", $i, ~~@$cases, $case->{args});
        my @cmd = ($^X);
        push @cmd, @{ $case->{perl_args} } if $case->{perl_args} && @{ $case->{perl_args} };
        push @cmd, $self->{abs_output_file}, @{ $case->{args} };
        my $exit;
        # log statement by IPC::System::Options' log=1 will be eaten by
        # Capture::Tiny, so we log here
        $log->tracef("cmd: %s", \@cmd);
        my $output = Capture::Tiny::capture_merged(
            sub {
                IPC::System::Options::system({log=>0, shell=>0}, @cmd);
                $exit = $?;
            }
        );
        my $expected_exit = $case->{exit_code} // 0;
        if ($exit != $expected_exit) {
            die "  Test case $i failed: exit code is not $expected_exit ($exit),output: <<$output>>\n";
        }
        if (defined $case->{output_like}) {
            $output =~ /$case->{output_like}/
                or die "  Test case $i failed: output does not match $case->{output_like}, output: <<$output>>\n";
        }
    }
}

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

my $trace_methods;
{
    my $sch = $App::tracepm::SPEC{tracepm}{args}{method}{schema};
    # XXX should've normalized schema
    if (ref($sch->[1]) eq 'HASH') {
        $trace_methods = $sch->[1]{in};
    } else {
        $trace_methods = $sch->[2];
    }
}

$SPEC{depak} = {
    v => 1.1,
    summary => 'Pack your dependencies onto your script file',
    args => {
        input_file => {
            summary => 'Path to input file (script to be packed)',
            description => <<'_',

`-` (or if unspecified) means to take from standard input (internally, a
temporary file will be created to handle this).

_
            schema => ['str*'],
            default => '-',
            pos => 0,
            cmdline_aliases => { i=>{} },
            tags => ['category:input'],
            'x.schema.entity' => 'filename',
        },
        output_file => {
            summary => 'Path to output file',
            description => <<'_',

`-` (or if unspecified) means to output to stdout.

_
            schema => ['str*'],
            default => '-',
            cmdline_aliases => { o=>{} },
            pos => 1,
            tags => ['category:output'],
            'x.schema.entity' => 'filename',
        },
        include_module => {
            summary => 'Include extra modules',
            'summary.alt.plurality.singular' => 'Include an extra module',
            description => <<'_',

When the tracing process fails to include a required module, you can add it
here.

_
            schema => ['array*' => of => 'str*'],
            cmdline_aliases => { I=>{}, include=>{} },
            tags => ['category:module-selection'],
            'x.schema.element_entity' => 'modulename',
        },
        include_list => {
            summary => 'Include extra modules from a list in a file',
            schema => 'str*', # XXX filename
            tags => ['category:module-selection'],
            'x.schema.entity' => 'filename',
        },
        include_dir => {
            summary => 'Include extra modules under directories',
            'summary.alt.plurality.singular' => 'Include extra modules under a directory',
            schema => ['array*' => of => 'str*'],
            tags => ['category:module-selection'],
            'x.schema.element_entity' => 'dirname',
        },
        include_dist => {
            summary => 'Include all modules of dist',
            description => <<'_',

Just like the `include` option, but will include module as well as other modules
from the same distribution. Module name must be the main module of the
distribution. Will determine other modules from the `.packlist` file.

_
            schema => ['array*' => of => 'str*'],
            cmdline_aliases => {},
            tags => ['category:module-selection'],
            'x.schema.element_entity' => 'distname',
        },
        exclude_module => {
            summary => 'Modules to exclude',
            'summary.alt.plurality.singular' => 'Exclude a module',
            description => <<'_',

When you don't want to include a module, specify it here.

_
            schema => ['array*' => of => 'str*'],
            cmdline_aliases => { E => {}, exclude => {} },
            tags => ['category:module-selection'],
            'x.schema.element_entity' => 'modulename',
        },
        exclude_pattern => {
            summary => 'Regex patterns of modules to exclude',
            'summary.alt.plurality.singular' => 'Regex pattern of modules to exclude',
            description => <<'_',

When you don't want to include a pattern of modules, specify it here.

_
            schema => ['array*' => of => 'str*'],
            cmdline_aliases => { p => {} },
            tags => ['category:module-selection'],
            #'x.schema.element_entity' => 'regex',
        },
        exclude_dist => {
            summary => 'Exclude all modules of dist',
            description => <<'_',

Just like the `exclude` option, but will exclude module as well as other modules
from the same distribution. Module name must be the main module of the
distribution. Will determine other modules from the `.packlist` file.

_
            schema => ['array*' => of => 'str*'],
            cmdline_aliases => {},
            tags => ['category:module-selection'],
            'x.schema.element_entity' => 'distname',
        },
        exclude_core => {
            summary => 'Whether to exclude core modules',
            'summary.alt.bool.not' => 'Do not exclude core modules',
            schema => ['bool' => default => 1],
            tags => ['category:module-selection'],
        },
        exclude_list => {
            summary => 'Exclude modules from a list in a file',
            schema => 'str*', # XXX filename
            tags => ['category:module-selection'],
            'x.schema.entity' => 'filename',
        },
        perl_version => {
            summary => 'Perl version to target, defaults to current running version',
            description => <<'_',

This is for determining which modules are considered core and should be skipped
by default (when `exclude_core` option is enabled). Different perl versions have
different sets of core modules as well as different versions of the modules.

_
            schema => ['str*'],
            cmdline_aliases => { V=>{} },
            # XXX completion: list of known perl versions by Module::CoreList?
            tags => ['category:module-selection'],
        },

        overwrite => {
            schema => [bool => default => 0],
            summary => 'Whether to overwrite output if previously exists',
            'summary.alt.bool.yes' => 'Overwrite output if previously exists',
            tags => ['category:output'],
        },
        pack_method => {
            summary => 'Packing method to use',
            schema => ['str*', in=>['fatpack', 'datapack']],
            default => 'fatpack',
            cmdline_aliases => {},
            description => <<'_',

Either `fatpack` (the default) or `datapack`. Fatpack puts packed modules inside
Perl variables and load them via require hook. Datapack puts packed modules in
__DATA__ section. For more details about each method, please consult
`Module::FatPack` and `Module::DataPack`.

One thing to remember is, with datapack, your script cannot load modules during
compile-time (`use`): all modules must be loaded during run-time (`require`)
when data section is already available. Also, your script currently cannot
contain data section of its own.

_
            tags => ['category:packing'],
        },
        trace_method => {
            summary => "Which method to use to trace dependencies",
            schema => ['str*', {
                default => 'fatpacker',
                in=>[@$trace_methods, 'none'],
            }],
            description => <<'_',

The default is `fatpacker`, which is the same as what `fatpack trace` does.
Different tracing methods have different pro's and con's, one method might
detect required modules that another method does not, and vice versa. There are
several methods available, please see `App::tracepm` for more details.

A special value of `none` is also provided. If this is selected, then depak will
not perform any tracing. Usually used in conjunction with `--include-from`.

_
            cmdline_aliases => { t=>{} },
            tags => ['category:module-selection', 'category:tracing'],
        },
        trace_extra_opts => {
            schema => ['hash*'],
            summary => 'Pass more options to `App::tracepm`',
            tags => ['category:module-selection'],
        },
        include_prereq => {
            'summary.alt.plurality.singular' => 'Include module and its recursive dependencies for packing',
            schema => ['array*', of=>'str*'],
            description => <<'_',

This option can be used to include a module, as well as other modules in the
same distribution as that module, as well as the distribution's recursive
dependencies, for packing. Dependencies will be searched using a local CPAN
index. This is a convenient alternative to tracing a module. So you might want
to use this option together with setting `trace_method` to `none`.

This option requires that `lcpan` is installed and a fairly recent lcpan index
is available.

_
            tags => ['category:module-selection'],
        },
        exclude_prereq => {
            'summary.alt.plurality.singular' => 'Allow script to depend on a module instead of packing it',
            schema => ['array*', of=>'str*'],
            description => <<'_',

This option can be used to express that script will depend on a specified
module, instead of including it packed. The prereq-ed module, as well as other
modules in the same distribution, as well as its prereqs and so on recursively,
will be excluded from packing as well.

This option can be used to express dependency to an XS module, since XS modules
cannot be packed.

To query dependencies, a local CPAN index is used for querying speed. Thus, this
option requires that `lcpan` is installed and a fairly recent lcpan index is
available.

_
            tags => ['category:module-selection'],
        },
        skip_not_found => {
            summary => 'Instead of dying, skip when module to add is not found',
            'summary.alt.bool.not' => 'Instead of skipping, die when module to add is not found',
            schema => ['bool'],
            description => <<'_',

This option is useful when you use `include_prereq`, because modules without its
own .pm files will also be included (CPAN indexes packages, including those that
do not have their own .pm files).

By default, this option is turned off unless when you use `include_prereq` where
this option is by default turned on. You can of course override the default by
explicitly specify this option.

_
            tags => ['category:module-selection'],
        },
        allow_xs => {
            'summary.alt.plurality.singular' => 'Allow adding a specified XS module',
            schema => ['array*', of=>'str*'],
            tags => ['category:module-selection'],
        },
        use => {
            summary => 'Additional modules to "use"',
            'summary.alt.plurality.singular' => 'Additional module to "use"',
            schema => ['array*' => of => 'str*'],
            description => <<'_',

Will be passed to the tracer. Will currently only affect the `fatpacker` and
`require` methods (because those methods actually run your script).

_
            tags => ['category:module-selection'],
            'x.schema.element_entity' => 'modulename',
        },
        args => {
            summary => 'Script arguments',
            'x.name.is_plural' => 1,
            'summary.alt.plurality.singular' => 'Script argument',
            description => <<'_',

Will be used when running your script, e.g. when `trace_method` is `fatpacker`
or `require`. For example, if your script requires three arguments: `--foo`,
`2`, `"bar baz"` then you can either use:

    % depak script output --args --foo --args 2 --args "bar baz"

or:

    % depak script output --args-json '["--foo",2,"bar baz"]'

_
            schema => ['array*' => of => 'str*'],
            tags => ['category:tracing'],
        },
        multiple_runs => {
            summary => 'Pass to tracepm',
            schema => ['array*' => of => ['hash*']],
            tags => ['category:tracing'],
        },

        shebang => {
            summary => 'Set shebang line/path',
            schema => 'str*',
            default => '/usr/bin/perl',
            tags => ['category:output'],
        },

        squish => {
            summary => 'Whether to squish included modules using Perl::Squish',
            'summary.alt.bool.yes' => 'Squish included modules using Perl::Squish',
            schema => ['bool' => default=>0],
            tags => ['category:stripping'],
        },

        strip => {
            summary => 'Whether to strip included modules using Perl::Strip',
            'summary.alt.bool.yes' => 'Strip included modules using Perl::Strip',
            schema => ['bool' => default=>0],
            tags => ['category:stripping'],
        },

        debug_keep_tempdir => {
            summary => 'Keep temporary directory for debugging',
            schema => ['bool'],
            tags => ['category:debugging'],
        },

        test => {
            schema => ['bool', is=>1],
            summary => 'Test the resulting output',
            cmdline_aliases => {T=>{}},
            description => <<'_',

Testing is done by running the resulting packed script with perl. To test, at
least one test case is required (see `--test-case-json`). Test cases specify
what arguments to give to program, what exit code we expect, and what the output
should contain.

_
            tags => ['category:testing'],
        },
        test_cases => {
            schema => ['array*', of=>'hash*'],
            'x.name.is_plural' => 1,
            description => <<'_',

Example case:

    {"args":["--help"], "exit_code":0, "perl_args":["-Mlib::core::only"], "output_like":"Usage:"}

_
            tags => ['category:testing'],
        },
    },
};
sub depak {
    require Cwd;
    require File::MoreUtil;
    require File::Spec;
    require File::Temp;

    my %args = @_;
    my $self = __PACKAGE__->new(%args);

    $self->{debug_keep_tempdir} //= $ENV{DEBUG_KEEP_TEMPDIR} // 0;

    $self->{skip_not_found} //= $self->{include_prereq} ? 1:0;

    my $tempdir = File::Temp::tempdir(CLEANUP => 0);
    $log->debugf("Created tempdir %s", $tempdir);
    $self->{tempdir} = $tempdir;

    # for convenience of completion in bash, we allow / to separate namespace.
    # we convert it back to :: here.
    for (@{ $self->{exclude_module} // [] },
         @{ $self->{exclude_dist} // [] },
         @{ $self->{include_module} // [] },
         @{ $self->{include_dist} // [] },
         @{ $self->{use} // [] },
     ) {
        s!/!::!g;
        s/\.pm\z//;
    }

    mkdir "$tempdir/lib";

    $self->{perl_version} //= $^V;
    $self->{perl_version} = version->parse($self->{perl_version});
    $log->debugf("Will be targetting perl %s", $self->{perl_version});

    if ($self->{input_file} eq '-') {
        $self->{input_file_is_stdin} = 1;
        $self->{input_file} = $self->{abs_input_file} = (File::Temp::tempfile())[1];
        open my($fh), ">", $self->{abs_input_file}
            or return [500, "Can't write temporary input file '$self->{abs_input_file}': $!"];
        local $_; while (<STDIN>) { print $fh $_ }
        $self->{output_file} //= '-';
    } else {
        (-f $self->{input_file})
            or return [500, "No such input file: $self->{input_file}"];
        $self->{abs_input_file} = Cwd::abs_path($self->{input_file}) or return
            [500, "Can't find absolute path of input file $self->{input_file}"];
    }

    if ($self->{output_file} eq '-') {
        $self->{output_file_is_stdout} = 1;
        $self->{output_file} = $self->{abs_output_file} = (File::Temp::tempfile())[1];
    } else {
        return [412, "Output file '$self->{output_file}' exists, won't overwrite (see --overwrite)"]
            if File::MoreUtil::file_exists($self->{output_file}) && !$self->{overwrite};
        return [500, "Can't write to output file '$self->{output_file}': $!"]
            unless open my($fh), ">", $self->{output_file};
    }

    $self->{abs_output_file} //= Cwd::abs_path($self->{output_file}) or return
        [500, "Can't find absolute path of output file '$self->{output_file}'"];

    unless ($self->{trace_method} eq 'none') {
        $log->infof("Tracing dependencies ...");
        $self->_trace;
    }

    $log->infof("Building lib/ ...");
    $self->_build_lib;

    $log->infof("Packing ...");
    $self->_pack;

    if ($self->{debug_keep_tempdir}) {
        $log->infof("Keeping tempdir %s for debugging", $tempdir);
    } else {
        $log->debugf("Deleting tempdir %s ...", $tempdir);
        File::Path::remove_tree($tempdir);
    }

    if ($self->{input_file_is_stdin}) {
        unlink $self->{abs_input_file};
    }
    if ($self->{output_file_is_stdout}) {
        open my($fh), "<", $self->{abs_output_file}
            or return [500, "Can't open temporary output file '$self->{abs_output_file}': $!"];
        local $_; print while <$fh>; close $fh;
        unlink $self->{abs_output_file};
    }

    if ($self->{test}) {
        $log->infof("Testing ...");
        $self->_test;
    }

    [200, "OK", undef, {
        'func.included_modules' => $self->{_included_modules},
    }];
}

# IFBUILT
sub _add_stripper_args_to_meta {
    my $meta = shift;

    # already added
    $meta->{args}{stripper} and return [304];

    $meta->{args}{stripper} = {
        summary => 'Whether to strip included modules using Perl::Stripper',
        'summary.alt.bool.yes' => 'Strip included modules using Perl::Stripper',
        schema => ['bool' => default=>0],
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_maintain_linum} = {
        summary => "Set maintain_linum=1 in Perl::Stripper",
        schema => ['bool'],
        default => 0,
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_ws} = {
        summary => "Set strip_ws=1 (strip whitespace) in Perl::Stripper",
        'summary.alt.bool.not' => "Set strip_ws=0 (don't strip whitespace) in Perl::Stripper",
        schema => ['bool'],
        default => 1,
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_comment} = {
        summary => "Set strip_comment=1 (strip comments) in Perl::Stripper",
        'summary.alt.bool.not' => "Set strip_comment=0 (don't strip comments) in Perl::Stripper",
        schema => ['bool'],
        default => 1,
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_pod} = {
        summary => "Set strip_pod=1 (strip POD) in Perl::Stripper",
        'summary.alt.bool.not' => "Set strip_pod=0 (don't strip POD) in Perl::Stripper",
        schema => ['bool'],
        default => 1,
        tags => ['category:stripping'],
    };

    $meta->{args}{stripper_log} = {
        summary => "Set strip_log=1 (strip log statements) in Perl::Stripper",
        'summary.alt.bool.not' => "Set strip_log=0 (don't strip log statements) in Perl::Stripper",
        schema => ['bool'],
        default => 0,
        tags => ['category:stripping'],
    };

    # XXX strip_log_levels

    $meta->{args_rels} //= {};
    my $ar = $meta->{args_rels};
    my $prop;
    if ($ar->{'dep_any&'}) {
        $prop = $ar->{'dep_any&'};
    } elsif (ref($ar->{'dep_any'}) eq 'ARRAY' && ($ar->{'dep_any.op'} // '') eq 'and') {
        $prop = $ar->{'dep_any'};
    } elsif (!$ar->{'dep_any'}) {
        $ar->{'dep_any'} = [];
        $ar->{'dep_any.op'} = 'and';
        $prop = $ar->{'dep_any'};
    }
    if ($prop) {
        push @$prop, [stripper_maintain_linum => [qw/stripper/]];
        push @$prop, [stripper_ws             => [qw/stripper/]];
        push @$prop, [stripper_log            => [qw/stripper/]];
        push @$prop, [stripper_pod            => [qw/stripper/]];
        push @$prop, [stripper_comment        => [qw/stripper/]];
    }

    [200];
}

_add_stripper_args_to_meta($SPEC{depak});
# END IFBUILT
# IFUNBUILT
# require PERLANCAR::AppUtil::PerlStripper; PERLANCAR::AppUtil::PerlStripper::_add_stripper_args_to_meta($SPEC{depak});
# END IFUNBUILT

1;
# ABSTRACT: Pack your dependencies onto your script file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::depak - Pack your dependencies onto your script file

=head1 VERSION

This document describes version 0.53 of App::depak (from Perl distribution App-depak), released on 2016-08-02.

=head1 SYNOPSIS

See L<depak>.

=for Pod::Coverage ^(new)$

=head1 FUNCTIONS


=head2 depak(%args) -> [status, msg, result, meta]

Pack your dependencies onto your script file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_xs> => I<array[str]>

=item * B<args> => I<array[str]>

Script arguments.

Will be used when running your script, e.g. when C<trace_method> is C<fatpacker>
or C<require>. For example, if your script requires three arguments: C<--foo>,
C<2>, C<"bar baz"> then you can either use:

 % depak script output --args --foo --args 2 --args "bar baz"

or:

 % depak script output --args-json '["--foo",2,"bar baz"]'

=item * B<debug_keep_tempdir> => I<bool>

Keep temporary directory for debugging.

=item * B<exclude_core> => I<bool> (default: 1)

Whether to exclude core modules.

=item * B<exclude_dist> => I<array[str]>

Exclude all modules of dist.

Just like the C<exclude> option, but will exclude module as well as other modules
from the same distribution. Module name must be the main module of the
distribution. Will determine other modules from the C<.packlist> file.

=item * B<exclude_list> => I<str>

Exclude modules from a list in a file.

=item * B<exclude_module> => I<array[str]>

Modules to exclude.

When you don't want to include a module, specify it here.

=item * B<exclude_pattern> => I<array[str]>

Regex patterns of modules to exclude.

When you don't want to include a pattern of modules, specify it here.

=item * B<exclude_prereq> => I<array[str]>

This option can be used to express that script will depend on a specified
module, instead of including it packed. The prereq-ed module, as well as other
modules in the same distribution, as well as its prereqs and so on recursively,
will be excluded from packing as well.

This option can be used to express dependency to an XS module, since XS modules
cannot be packed.

To query dependencies, a local CPAN index is used for querying speed. Thus, this
option requires that C<lcpan> is installed and a fairly recent lcpan index is
available.

=item * B<include_dir> => I<array[str]>

Include extra modules under directories.

=item * B<include_dist> => I<array[str]>

Include all modules of dist.

Just like the C<include> option, but will include module as well as other modules
from the same distribution. Module name must be the main module of the
distribution. Will determine other modules from the C<.packlist> file.

=item * B<include_list> => I<str>

Include extra modules from a list in a file.

=item * B<include_module> => I<array[str]>

Include extra modules.

When the tracing process fails to include a required module, you can add it
here.

=item * B<include_prereq> => I<array[str]>

This option can be used to include a module, as well as other modules in the
same distribution as that module, as well as the distribution's recursive
dependencies, for packing. Dependencies will be searched using a local CPAN
index. This is a convenient alternative to tracing a module. So you might want
to use this option together with setting C<trace_method> to C<none>.

This option requires that C<lcpan> is installed and a fairly recent lcpan index
is available.

=item * B<input_file> => I<str> (default: "-")

Path to input file (script to be packed).

C<-> (or if unspecified) means to take from standard input (internally, a
temporary file will be created to handle this).

=item * B<multiple_runs> => I<array[hash]>

Pass to tracepm.

=item * B<output_file> => I<str> (default: "-")

Path to output file.

C<-> (or if unspecified) means to output to stdout.

=item * B<overwrite> => I<bool> (default: 0)

Whether to overwrite output if previously exists.

=item * B<pack_method> => I<str> (default: "fatpack")

Packing method to use.

Either C<fatpack> (the default) or C<datapack>. Fatpack puts packed modules inside
Perl variables and load them via require hook. Datapack puts packed modules in
B<DATA> section. For more details about each method, please consult
C<Module::FatPack> and C<Module::DataPack>.

One thing to remember is, with datapack, your script cannot load modules during
compile-time (C<use>): all modules must be loaded during run-time (C<require>)
when data section is already available. Also, your script currently cannot
contain data section of its own.

=item * B<perl_version> => I<str>

Perl version to target, defaults to current running version.

This is for determining which modules are considered core and should be skipped
by default (when C<exclude_core> option is enabled). Different perl versions have
different sets of core modules as well as different versions of the modules.

=item * B<shebang> => I<str> (default: "/usr/bin/perl")

Set shebang line/path.

=item * B<skip_not_found> => I<bool>

Instead of dying, skip when module to add is not found.

This option is useful when you use C<include_prereq>, because modules without its
own .pm files will also be included (CPAN indexes packages, including those that
do not have their own .pm files).

By default, this option is turned off unless when you use C<include_prereq> where
this option is by default turned on. You can of course override the default by
explicitly specify this option.

=item * B<squish> => I<bool> (default: 0)

Whether to squish included modules using Perl::Squish.

=item * B<strip> => I<bool> (default: 0)

Whether to strip included modules using Perl::Strip.

=item * B<stripper> => I<bool> (default: 0)

Whether to strip included modules using Perl::Stripper.

=item * B<stripper_comment> => I<bool> (default: 1)

Set strip_comment=1 (strip comments) in Perl::Stripper.

=item * B<stripper_log> => I<bool> (default: 0)

Set strip_log=1 (strip log statements) in Perl::Stripper.

=item * B<stripper_maintain_linum> => I<bool> (default: 0)

Set maintain_linum=1 in Perl::Stripper.

=item * B<stripper_pod> => I<bool> (default: 1)

Set strip_pod=1 (strip POD) in Perl::Stripper.

=item * B<stripper_ws> => I<bool> (default: 1)

Set strip_ws=1 (strip whitespace) in Perl::Stripper.

=item * B<test> => I<bool>

Test the resulting output.

Testing is done by running the resulting packed script with perl. To test, at
least one test case is required (see C<--test-case-json>). Test cases specify
what arguments to give to program, what exit code we expect, and what the output
should contain.

=item * B<test_cases> => I<array[hash]>

Example case:

 {"args":["--help"], "exit_code":0, "perl_args":["-Mlib::core::only"], "output_like":"Usage:"}

=item * B<trace_extra_opts> => I<hash>

Pass more options to `App::tracepm`.

=item * B<trace_method> => I<str> (default: "fatpacker")

Which method to use to trace dependencies.

The default is C<fatpacker>, which is the same as what C<fatpack trace> does.
Different tracing methods have different pro's and con's, one method might
detect required modules that another method does not, and vice versa. There are
several methods available, please see C<App::tracepm> for more details.

A special value of C<none> is also provided. If this is selected, then depak will
not perform any tracing. Usually used in conjunction with C<--include-from>.

=item * B<use> => I<array[str]>

Additional modules to "use".

Will be passed to the tracer. Will currently only affect the C<fatpacker> and
C<require> methods (because those methods actually run your script).

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

Please visit the project's homepage at L<https://metacpan.org/release/App-depak>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-depak>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-depak>

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
