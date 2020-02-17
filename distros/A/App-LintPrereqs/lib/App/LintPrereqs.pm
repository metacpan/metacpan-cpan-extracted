package App::LintPrereqs;

our $DATE = '2019-12-17'; # DATE
our $VERSION = '0.541'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Config::IOD;
use Fcntl qw(:DEFAULT);
use File::Find;
use File::Which;
use Filename::Backup qw(check_backup_filename);
use IPC::System::Options 'system', -log=>1;
use Module::CoreList::More;
use Proc::ChildError qw(explain_child_error);
use Scalar::Util 'looks_like_number';
use Sort::Sub qw(prereq_ala_perlancar);
use Version::Util qw(version_gt version_ne);

our %SPEC;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(lint_prereqs);

# create a merged list of prereqs from any phase
sub _create_prereqs_for_Any_phase {
    my $prereqs = shift;
    $prereqs->{Any}   = {};
    for my $phase (grep {$_ ne 'Any'} keys %$prereqs) {
        for my $mod (keys %{ $prereqs->{$phase} }) {
            my $v = $prereqs->{$phase}{$mod};
            if (exists $prereqs->{Any}{$mod}) {
                $prereqs->{Any}{$mod} = $v
                    if version_gt($v, $prereqs->{Any}{$mod});
            } else {
                $prereqs->{Any}{$mod} = $v;
            }
        }
    }
}

sub _scan_prereqs {
    my %args = @_;

    my $scanner = do {
        if ($args{scanner} eq 'lite') {
            require Perl::PrereqScanner::Lite;
            my $scanner = Perl::PrereqScanner::Lite->new;
            $scanner->add_extra_scanner('Moose');
            $scanner->add_extra_scanner('Version');
            $scanner;
        } elsif ($args{scanner} eq 'nqlite') {
            require Perl::PrereqScanner::NotQuiteLite;
            my $scanner = Perl::PrereqScanner::NotQuiteLite->new(
                parsers  => [qw/:installed -UniversalVersion/],
                suggests => 1,
            );
            $scanner;
        } else {
            require Perl::PrereqScanner;
            Perl::PrereqScanner->new;
        }
    };
    require File::Find;
    my %files; # key=phase, val=[file, ...]

    {
        $files{Runtime} = [];
        my @dirs = (grep {-d} (
            "lib", "bin", "script", "scripts",
            #"sample", "samples", "example", "examples" # decidedly not included
            #"share", # decidedly not included
            @{ $args{extra_runtime_dirs} // [] },
        ));
        last unless @dirs;
        find(
            sub {
                return unless -f;
                return if check_backup_filename(filename=>$_);
                push @{$files{Runtime}}, "$File::Find::dir/$_";
            },
            @dirs
        );
    }

    {
        my @dirs = (grep {-d} (
            "t", "xt",
            @{ $args{extra_test_dirs} // [] },
        ));
        last unless @dirs;
        find(
            sub {
                return unless -f;
                return if check_backup_filename(filename=>$_);
                return unless /\.(t|pl|pm)$/;
                push @{$files{Test}}, "$File::Find::dir/$_";
            },
            @dirs
        );
    }

    my %res; # key=phase, value=hash of {mod=>version , ...}
    for my $phase (keys %files) {
        $res{$phase} = {};
        for my $file (@{$files{$phase}}) {
            my $scanres = $scanner->scan_file($file);
            unless ($scanres) {
                log_trace("Scanned %s, got nothing", $file);
            }

            # if we use PP::NotQuiteLite, it returns PPN::Context which supports
            # a 'requires' method to return a CM:Requirements like the other
            # scanners
            my $reqs = $scanres->can("requires") ?
                $scanres->requires->as_string_hash : $scanres->as_string_hash;

            if ($scanres->can("suggests") && (my $sugs = $scanres->suggests)) {
                # currently it's not clear what makes PP:NotQuiteLite determine
                # something as a suggests requirement, so we include suggests as
                # a normal requires requirement.
                $sugs = $sugs->as_string_hash;
                for (keys %$sugs) {
                    $reqs->{$_} ||= $sugs->{$_};
                }
            }

            log_trace("Scanned %s, got: %s", $file, $reqs);
            for my $req (keys %$reqs) {
                my $v = $reqs->{$req};
                if (exists $res{$phase}{$req}) {
                    $res{$phase}{$req} = $v
                        if version_gt($v, $res{$phase}{$req});
                } else {
                    $res{$phase}{$req} = $v;
                }
            }
        } # for file
    } # for phase

    _create_prereqs_for_Any_phase(\%res);

    %res;
}

$SPEC{lint_prereqs} = {
    v => 1.1,
    summary => 'Check extraneous/missing/incorrect prerequisites in dist.ini',
    description => <<'_',

lint-prereqs can improve your prereqs specification in `dist.ini` by reporting
prereqs that are extraneous (specified but unused), missing (used/required but
not specified), or incorrect (mismatching version between what's specified in
`dist.ini` vs in source code, incorrect phase like test prereqs specified in
runtime, etc).

Checking actual usage of prereqs is done using <pm:Perl::PrereqScanner> (or
<pm:Perl::PrereqScanner::Lite>).

Sections that will be checked for prereqs include `[Prereqs / *]`, as well as
`OSPrereqs`, `Extras/lint-prereqs/Assume-*`. Designed to work with prerequisites
that are manually written. Does not work if you use AutoPrereqs (using
AutoPrereqs basically means that you do not specify prereqs and just use
whatever modules are detected by the scanner.)

Sometimes there are prerequisites that you know are used but can't be detected
by the scanner, or you want to include anyway. If this is the case, you can
instruct lint_prereqs to assume that the prerequisite is used.

    ;!lint_prereqs assume-used "even though we know it is not currently used"
    Foo::Bar=0

    ;!lint_prereqs assume-used "we are forcing a certain version"
    Baz=0.12

Sometimes there are also prerequisites that are detected by scan_prereqs, but
are false positives (<pm:Perl::PrereqScanner::Lite> sometimes does this because
its parser is simpler) or you know are already provided by some other modules.
So to make lint-prereqs ignore them:

    [Extras / lint-prereqs / assume-provided]
    Qux::Quux=0

You can also add a `[versions]` section in your `lint-prereqs.conf`
configuration containing minimum versions that you want for certain modules,
e.g.:

    [versions]
    Bencher=0.30
    Log::ger=0.19
    ...

then if there is a prereq specified less than the minimum versions,
`lint-prereqs` will also complain.

_
    args => {
        perl_version => {
            schema => ['str*'],
            summary => 'Perl version to use (overrides scan_prereqs/dist.ini)',
        },
        extra_runtime_dirs => {
            'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*'],
            summary => 'Add extra directories to scan for runtime requirements',
        },
        extra_test_dirs => {
            'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*'],
            summary => 'Add extra directories to scan for test requirements',
        },
        scanner => {
            schema => ['str*', in=>['regular','lite','nqlite']],
            default => 'regular',
            summary => 'Which scanner to use',
            description => <<'_',

`regular` means <pm:Perl::PrereqScanner> which is PPI-based and is the slowest
but has the most complete support for Perl syntax.

`lite` means <pm:Perl::PrereqScanner::Lite> has uses an XS-based lexer and is
the fastest but might miss some Perl syntax (i.e. miss some prereqs) or crash if
given some weird code.

`nqlite` means <pm:Perl::PrereqScanner::NotQuiteLite> which is faster than
`regular` but not as fast as `lite`.

_
        },
        lite => {
            schema => ['bool*'],
            default => 0,
            summary => 'Use Perl::PrereqScanner::Lite instead of Perl::PrereqScanner',
            "summary.alt.bool.not" =>
                'Use Perl::PrereqScanner instead of Perl::PrereqScanner::Lite',
            description => <<'_',

This option is deprecated and has been replaced by `scanner`.

Lite is faster but it might still miss detecting some modules.

_
            tags => ['deprecated', 'hidden'],
        },
        core_prereqs => {
            schema => ['bool*'],
            default => 1,
            summary => 'Whether or not prereqs to core modules are allowed',
            description => <<'_',

If set to 0 (the default), will complain if there are prerequisites to core
modules. If set to 1, prerequisites to core modules are required just like other
modules.

_
        },
        fix => {
            schema => 'bool',
            summary => 'Attempt to automatically fix the errors',
            cmdline_aliases => {F=>{}},
            description => <<'_',

`lint-prereqs` can attempt to automatically fix the errors by
adding/removing/moving prereqs in `dist.ini`. Not all errors can be
automatically fixed. When modifying `dist.ini`, a backup in `dist.ini~` will be
created.

_
        },
    },
};
sub lint_prereqs {
    my %args = @_;

    (-f "dist.ini")
        or return [412, "No dist.ini found. ".
                       "Are you in the right dir (dist top-level)? ".
                           "Is your dist managed by Dist::Zilla?"];

    my $ct = do {
        open my($fh), "<", "dist.ini" or die "Can't open dist.ini: $!";
        local $/;
        binmode $fh, ":encoding(utf8)";
        scalar <$fh>;
    };
    return [200, "Not run (no-lint-prereqs)"] if $ct =~ /^;!no[_-]lint[_-]prereqs$/m;

    my $ciod = Config::IOD->new(
        ignore_unknown_directive => 1,
    );

    my $cfg = $ciod->read_string($ct);

    my %mods_from_ini;
    my %assume_used;
    my %assume_provided;
    for my $section ($cfg->list_sections) {
        $section =~ m!^(
                          osprereqs \s*/\s* .+ |
                          osprereqs(::\w+)+ |
                          prereqs (?: \s*/\s* (?<prereqs_phase_rel>\w+))? |
                          extras \s*/\s* lint[_-]prereqs \s*/\s* (assume-(?:provided|used))
                      )$!ix or next;
        #$log->errorf("TMP: section=%s, %%+=%s", $section, {%+});

        my ($phase, $rel);
        if (my $pr = $+{prereqs_phase_rel}) {
            if ($pr =~ /^(develop|configure|build|test|runtime|x_\w+)(requires|recommends|suggests|x_\w+)$/i) {
                $phase = ucfirst(lc($1));
                $rel = ucfirst(lc($2));
            } else {
                return [400, "Invalid section '$section' (invalid phase/rel $pr)"];
            }
        } else {
            $phase = "Runtime";
            $rel = "Requires";
        }

        my %params;
        for my $param ($cfg->list_keys($section)) {
            my $v = $cfg->get_value($section, $param);
            if ($param =~ /^-phase$/) {
                $phase = ucfirst(lc($v));
                next;
            } elsif ($param =~ /^-(relationship|type)$/) {
                $rel = ucfirst(lc($v));
                next;
            }
            $params{$param} = $v;
        }
        #$log->tracef("phase=%s, rel=%s", $phase, $rel);

        for my $param (sort keys %params) {
            my $v = $params{$param};
            if (ref($v) eq 'ARRAY') {
                return [412, "Multiple '$param' prereq lines specified in dist.ini"];
            }
            my $dir = $cfg->get_directive_before_key($section, $param);
            my $dir_s = $dir ? join(" ", @$dir) : "";
            log_trace("section=%s, v=%s, param=%s, directive=%s", $section, $param, $v, $dir_s);

            my $mod = $param;
            $mods_from_ini{$phase}{$mod}   = $v unless $section =~ /assume-provided/;
            $assume_provided{$phase}{$mod} = $v if     $section =~ /assume-provided/;
            $assume_used{$phase}{$mod}     = $v if     $section =~ /assume-used/ ||
                $dir_s =~ /^lint[_-]prereqs\s+assume-used\b/m ||
                $rel =~ /\A(X_spec|X_alt_for|X_copypaste)\z/;
        } # for param
    } # for section
    _create_prereqs_for_Any_phase(\%mods_from_ini);
    _create_prereqs_for_Any_phase(\%assume_provided);
    _create_prereqs_for_Any_phase(\%assume_used);
    log_trace("mods_from_ini: %s", \%mods_from_ini);
    log_trace("assume_used: %s", \%assume_used);
    log_trace("assume_provided: %s", \%assume_provided);

    # get packages from current dist. assume package names from filenames,
    # should be better and scan using PPI
    my %dist_pkgs;
    find({
        #no_chdir => 1,
        wanted => sub {
            return unless /\.pm$/;
            my $pkg = $File::Find::dir;
            #$log->errorf("TMP:pkg=%s",$pkg);
            $pkg =~ s!^lib/?!!;
            $pkg =~ s!/!::!g;
            $pkg .= (length($pkg) ? "::" : "") . $_;
            $pkg =~ s/\.pm$//;
            $dist_pkgs{$pkg}++;
        },
    }, "lib");
    log_trace("Dist packages: %s", \%dist_pkgs);
    my %test_dist_pkgs;
    find({
        #no_chdir => 1,
        wanted => sub {
            return unless /\.pm$/;
            my $pkg = $File::Find::dir;
            #$log->errorf("TMP:pkg=%s",$pkg);
            $pkg =~ s!^t/lib/?!!;
            $pkg =~ s!/!::!g;
            $pkg .= (length($pkg) ? "::" : "") . $_;
            $pkg =~ s/\.pm$//;
            $dist_pkgs{$pkg}++;
        },
    }, "t/lib") if -d "t/lib";
    log_trace("Dist packages (in tests): %s", \%test_dist_pkgs);

    my %mods_from_scanned = _scan_prereqs(
        scanner => $args{lite} ? 'lite' : $args{scanner},
        extra_runtime_dirs => $args{extra_runtime_dirs},
        extra_test_dirs    => $args{extra_test_dirs},
    );
    log_trace("mods_from_scanned: %s", \%mods_from_scanned);

    if ($mods_from_scanned{Any}{perl}) {
        return [500, "Perl version specified by source code ($mods_from_scanned{Any}{perl}) ".
                    "but not specified in dist.ini"] unless $mods_from_ini{Any}{perl};
        if (version_ne($mods_from_ini{Any}{perl}, $mods_from_scanned{Any}{perl})) {
            return [500, "Perl version from dist.ini ($mods_from_ini{Any}{perl}) ".
                        "and scan_prereqs ($mods_from_scanned{Any}{perl}) mismatch"];
        }
    } else {
        return [500, "Perl version not specified by source code but specified in dist.ini ".
                    "($mods_from_ini{Any}{perl})"] if $mods_from_ini{Any}{perl};
    }

    my $versions;
    {
        last unless $args{-cmdline_r};
        $versions = $args{-cmdline_r}{config}{versions};
    }

    my $perlv; # min perl v to use in x.yyyzzz (numified)format
    if ($args{perl_version}) {
        log_trace("Will assume perl %s (via perl_version argument)",
                     $args{perl_version});
        $perlv = $args{perl_version};
    } elsif ($mods_from_ini{Any}{perl}) {
        log_trace("Will assume perl %s (via dist.ini)",
                     $mods_from_ini{Any}{perl});
        $perlv = $mods_from_ini{Any}{perl};
    } elsif ($mods_from_scanned{Any}{perl}) {
        log_trace("Will assume perl %s (via scan_prereqs)",
                     $mods_from_scanned{Any}{perl});
        $perlv = $mods_from_scanned{Any}{perl};
    } else {
        log_trace("Will assume perl %s (from running interpreter's \$^V)",
                     $^V);
        if ($^V =~ /^v(\d+)\.(\d+)\.(\d+)/) {
            $perlv = sprintf("%d\.%03d%03d", $1, $2, $3)+0;
        } elsif (looks_like_number($^V)) {
            $perlv = $^V;
        } else {
            return [500, "Can't parse \$^V ($^V)"];
        }
    }

    my @errs;

    # check modules that are specified in dist.ini but extraneous (unused) or
    # have mismatched version or phase
    {
        for my $mod (keys %{$mods_from_ini{Any}}) {
            my $v = $mods_from_ini{Any}{$mod};
            next if $mod eq 'perl';
            log_trace("Checking mod from dist.ini: %s (%s)", $mod, $v);
            my $is_core = Module::CoreList::More->is_still_core($mod, $v, $perlv);
            if (!$args{core_prereqs} && $is_core) {
                push @errs, {
                    module  => $mod,
                    req_v   => $v,
                    is_core => 1,
                    error   => "Core in perl ($perlv to latest) but ".
                        "mentioned in dist.ini",
                    remedy  => "Remove from dist.ini",
                    remedy_cmds => [
                        ["pdrutil", "remove-prereq", $mod],
                    ],
                };
            }
            my $scanv = $mods_from_scanned{Any}{$mod};
            if (defined($scanv) && $scanv != 0 && version_ne($v, $scanv)) {
                push @errs, {
                    module  => $mod,
                    req_v   => $v,
                    is_core => $is_core,
                    error   => "Version mismatch between dist.ini ($v) ".
                        "and from scanned_prereqs ($scanv)",
                    remedy  => "Fix either the code or version in dist.ini",
                };
            }
            if (defined($mods_from_scanned{Test}{$mod}) &&
                    !defined($mods_from_scanned{Runtime}{$mod}) &&
                    !defined($mods_from_ini{Test}{$mod}) &&
                    defined($mods_from_ini{Runtime}{$mod})) {
                push @errs, {
                    module  => $mod,
                    req_v   => $v,
                    is_core => $is_core,
                    error   => "Only used in test phase but listed under runtime prereq in dist.ini",
                    remedy  => "Move prereq from runtime to test prereq in dist.ini",
                    remedy_cmds => [
                        ["pdrutil", "remove-prereq", $mod],
                        ["pdrutil", "add-prereq", $mod, $v, "--phase", "test"],
                    ],
                };
            }
            if (defined($mods_from_scanned{Runtime}{$mod}) &&
                    defined($mods_from_ini{Test}{$mod}) &&
                    !defined($mods_from_ini{Runtime}{$mod})) {
                push @errs, {
                    module  => $mod,
                    req_v   => $v,
                    is_core => $is_core,
                    error   => "Used in runtime phase but listed only under test prereq in dist.ini",
                    remedy  => "Move prereq from test to runtime prereq in dist.ini",
                    remedy_cmds => [
                        ["pdrutil", "remove-prereq", $mod],
                        ["pdrutil", "add-prereq", $mod, $v],
                    ],
                };
            }
            unless (defined($scanv) || exists($assume_used{Any}{$mod})) {
                push @errs, {
                    module  => $mod,
                    req_v   => $v,
                    is_core => $is_core,
                    error   => "Unused but listed in dist.ini",
                    remedy  => "Remove from dist.ini",
                    remedy_cmds => [
                        ["pdrutil", "remove-prereq", $mod],
                    ],
                };
            }
        }
    } # END check modules from dist.ini

    # check lumped modules
    {
        no strict 'refs';
        my %lumped_mods;
        for my $mod (keys %{$mods_from_ini{Any}}) {
            next unless $mod =~ /::Lumped$/;
            my $mod_pm = $mod;
            $mod_pm =~ s!::!/!g;
            $mod_pm .= ".pm";
            require $mod_pm;
            my $lm = \@{"$mod\::LUMPED_MODULES"};
            for (@$lm) { $lumped_mods{$_} = $mod }
        }
        last unless %lumped_mods;
        log_trace("Checking lumped modules");
        for my $mod (keys %lumped_mods) {
            my $v = $mods_from_ini{Any}{$mod};
            my $is_core = Module::CoreList::More->is_still_core($mod, $v, $perlv);
            if (exists $mods_from_ini{Any}{$mod}) {
                push @errs, {
                    module  => $mod,
                    req_v   => $v,
                    is_core => $is_core,
                    error   => "Listed in dist.ini but already lumped in $lumped_mods{$mod}",
                    remedy  => "Remove one of $mod or $lumped_mods{$mod} from dist.ini",
                };
            }
        }
    } # END check lumped modules

    # check modules from scanned: check for missing prereqs (scanned/used but
    # not listed in dist.ini).
    {
        for my $mod (keys %{$mods_from_scanned{Any}}) {
            next if $mod eq 'perl';
            my $v = $mods_from_scanned{Any}{$mod};
            log_trace("Checking mod from scanned: %s (%s)", $mod, $v);
            my $is_core = Module::CoreList::More->is_still_core($mod, $v, $perlv);
            next if exists $dist_pkgs{$mod}; # skip modules from same dist
            next if exists $test_dist_pkgs{$mod}; # skip test modules from same dist (XXX should check that $mod is only used in tests)
            unless (exists($mods_from_ini{Any}{$mod}) ||
                        exists($assume_provided{Any}{$mod}) ||
                        ($args{core_prereqs} ? 0 : $is_core)) {
                my $phase;
                for (qw/Runtime Test Build Configure Develop/) {
                    if (defined $mods_from_scanned{$_}{$mod}) {
                        $phase = $_;
                        last;
                    }
                }
                $v = $versions->{$mod}
                    if $versions->{$mod} && version_gt($versions->{$mod}, $v);
                push @errs, {
                    module  => $mod,
                    req_v   => $v,
                    is_core => $is_core,
                    error   => "Used but not listed in dist.ini",
                    remedy  => "Put '$mod=$v' in dist.ini (e.g. in [Prereqs/${phase}Requires])",
                    remedy_cmds => [
                        ["pdrutil", "add-prereq", $mod, $v, "--phase", lc($phase)],
                    ],
                };
            }
        }
    } # END check modules from scanned

    # check minimum versions specified in [versions] in our config
    {
        last unless $versions;
        log_trace("Checking minimum versions ...");
        for my $mod (keys %{$mods_from_ini{Any}}) {
            next if $mod eq 'perl';
            my $v = $mods_from_ini{Any}{$mod};
            my $is_core = Module::CoreList::More->is_still_core($mod, $v, $perlv);
            my $min_v = $versions->{$mod};
            if (defined($min_v) && version_gt($min_v, $v)) {
                push @errs, {
                    module  => $mod,
                    req_v   => $v,
                    is_core => $is_core,
                    error   => "Less than specified minimum version ($min_v) in lint-prereqs.conf",
                    remedy  => "Increase version to $min_v",
                    remedy_cmds => [
                        ["pdrutil", "inc-prereq-version-to", $mod, $min_v],
                    ],
                };
            }
        }
    } # END check minimum versions

    return [200, "OK", []] unless @errs;

    @errs = sort {prereq_ala_perlancar($a->{module}, $b->{module})} @errs;

    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/module req_v is_core error remedy/];

    if ($args{fix}) {
        # there is an unfixable error
        if (grep {!$_->{remedy_cmds}} @errs) {
            for my $e (@errs) {
                $e->{remedy} = " (CAN'T FIX AUTOMATICALLY) $e->{remedy}" unless $e->{remedy_cmds};
            }
            $resmeta->{'cmdline.exit_code'} = 112;
        } else {
            # create dist.ini~ first
            if (-f "dist.ini~") { unlink "dist.ini~" or return [500, "Can't unlink dist.ini~: $!"] }
            sysopen my($fh), "dist.ini~", O_WRONLY|O_CREAT|O_EXCL or return [500, "Can't create dist.ini~: $!"];
            binmode $fh, ":encoding(utf8)"; print $fh $ct; close $fh or return [500, "Can't write to dist.ini~: $!"];

            # run the commands
          FIX:
            {
                # add sort-prereqs at the end
                push @{ $errs[-1]{remedy_cmds} }, ["pdrutil", "sort-prereqs"];

              ERR:
                for my $e (@errs) {
                    for my $cmd (@{ $e->{remedy_cmds} }) {
                        system @$cmd;
                        if ($?) {
                            $e->{remedy} = "(FIX FAILED: ".explain_child_error().") $e->{remedy}";
                            $resmeta->{'cmdline.exit_code'} = 1;
                            # restore dist.ini from backup
                            rename "dist.ini~", "dist.ini";
                            last FIX;
                        }
                    }
                }
                for my $e (@errs) {
                    $e->{remedy} = "(DONE) $e->{remedy}";
                }
                $resmeta->{'cmdline.exit_code'} = 0;
                # remove dist.ini~
                #unlink "dist.ini~";
            }
        }
        for my $e (@errs) { delete $e->{$_} for qw/remedy_cmds/ }
        return [200, "OK", \@errs, $resmeta];
    } else {
        for my $e (@errs) { delete $e->{$_} for qw/remedy_cmds/ }
        $resmeta->{'cmdline.exit_code'} = 200;
        return [200, "OK", \@errs, $resmeta];
    }
}

1;
# ABSTRACT: Check extraneous/missing/incorrect prerequisites in dist.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LintPrereqs - Check extraneous/missing/incorrect prerequisites in dist.ini

=head1 VERSION

This document describes version 0.541 of App::LintPrereqs (from Perl distribution App-LintPrereqs), released on 2019-12-17.

=head1 SYNOPSIS

 # Use via lint-prereqs CLI script

=head1 FUNCTIONS


=head2 lint_prereqs

Usage:

 lint_prereqs(%args) -> [status, msg, payload, meta]

Check extraneous/missing/incorrect prerequisites in dist.ini.

lint-prereqs can improve your prereqs specification in C<dist.ini> by reporting
prereqs that are extraneous (specified but unused), missing (used/required but
not specified), or incorrect (mismatching version between what's specified in
C<dist.ini> vs in source code, incorrect phase like test prereqs specified in
runtime, etc).

Checking actual usage of prereqs is done using L<Perl::PrereqScanner> (or
L<Perl::PrereqScanner::Lite>).

Sections that will be checked for prereqs include C<[Prereqs / *]>, as well as
C<OSPrereqs>, C<Extras/lint-prereqs/Assume-*>. Designed to work with prerequisites
that are manually written. Does not work if you use AutoPrereqs (using
AutoPrereqs basically means that you do not specify prereqs and just use
whatever modules are detected by the scanner.)

Sometimes there are prerequisites that you know are used but can't be detected
by the scanner, or you want to include anyway. If this is the case, you can
instruct lint_prereqs to assume that the prerequisite is used.

 ;!lint_prereqs assume-used "even though we know it is not currently used"
 Foo::Bar=0
 
 ;!lint_prereqs assume-used "we are forcing a certain version"
 Baz=0.12

Sometimes there are also prerequisites that are detected by scan_prereqs, but
are false positives (L<Perl::PrereqScanner::Lite> sometimes does this because
its parser is simpler) or you know are already provided by some other modules.
So to make lint-prereqs ignore them:

 [Extras / lint-prereqs / assume-provided]
 Qux::Quux=0

You can also add a C<[versions]> section in your C<lint-prereqs.conf>
configuration containing minimum versions that you want for certain modules,
e.g.:

 [versions]
 Bencher=0.30
 Log::ger=0.19
 ...

then if there is a prereq specified less than the minimum versions,
C<lint-prereqs> will also complain.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<core_prereqs> => I<bool> (default: 1)

Whether or not prereqs to core modules are allowed.

If set to 0 (the default), will complain if there are prerequisites to core
modules. If set to 1, prerequisites to core modules are required just like other
modules.

=item * B<extra_runtime_dirs> => I<array[str]>

Add extra directories to scan for runtime requirements.

=item * B<extra_test_dirs> => I<array[str]>

Add extra directories to scan for test requirements.

=item * B<fix> => I<bool>

Attempt to automatically fix the errors.

C<lint-prereqs> can attempt to automatically fix the errors by
adding/removing/moving prereqs in C<dist.ini>. Not all errors can be
automatically fixed. When modifying C<dist.ini>, a backup in C<dist.ini~> will be
created.

=item * B<perl_version> => I<str>

Perl version to use (overrides scan_prereqs/dist.ini).

=item * B<scanner> => I<str> (default: "regular")

Which scanner to use.

C<regular> means L<Perl::PrereqScanner> which is PPI-based and is the slowest
but has the most complete support for Perl syntax.

C<lite> means L<Perl::PrereqScanner::Lite> has uses an XS-based lexer and is
the fastest but might miss some Perl syntax (i.e. miss some prereqs) or crash if
given some weird code.

C<nqlite> means L<Perl::PrereqScanner::NotQuiteLite> which is faster than
C<regular> but not as fast as C<lite>.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-LintPrereqs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LintPrereqs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LintPrereqs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
