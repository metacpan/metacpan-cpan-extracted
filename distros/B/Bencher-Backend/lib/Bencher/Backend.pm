package Bencher::Backend;

our $DATE = '2017-02-20'; # DATE
our $VERSION = '1.036'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Data::Dmp;
use List::MoreUtils qw(all);
use List::Util qw(first);

our %SPEC;

sub _ver_or_vers {
    my $v = shift;
    if (ref($v) eq 'ARRAY') {
        return join(", ", @$v);
    } else {
        return $v;
    }
}

sub _get_tempfile_path {
    my ($filename) = @_;
    state $tempdir = do {
        require File::Temp;
        File::Temp::tempdir(CLEANUP => $log->is_debug ? 0:1);
    };
    "$tempdir/$filename";
}

sub _fill_template {
    no warnings 'uninitialized';
    my ($template, $vars, $escape_method) = @_;

    if ($escape_method eq 'shell') {
        require String::ShellQuote;
    }

    $template =~ s/\<(\w+)(:raw)?\>/
        $2 eq ':raw' ? $vars->{$1} :
        $escape_method eq 'shell' ? String::ShellQuote::shell_quote($vars->{$1}) :
        $escape_method eq 'dmp' ? dmp($vars->{$1}) :
        $vars->{$1}
        /eg;

    $template;
}

sub _get_process_size {
    my ($parsed, $it) = @_;

    my $script_path = _get_tempfile_path("get_process_size-$it->{seq}");

    $log->debugf("Creating script to measure get process size at %s ...", $script_path);
    {
        open my($fh), ">", $script_path or die "Can't open file $script_path: $!";

        print $fh "# load modules\n";
        my $participants = $parsed->{participants};
        my $participant = _find_record_by_seq($participants, $it->{_permute}{participant});
        if ($participant->{module}) {
            print $fh "require $participant->{module};\n";
        } elsif ($participant->{modules}) {
            print $fh "require $_;\n" for @{ $participant->{modules} };
        }
        if ($participant->{helper_modules}) {
            print $fh "require $_;\n" for @{ $participant->{helper_modules} };
        }
        # XXX should we load extra_modules? i think we should
        print $fh "\n";

        print $fh "# run code\n";
        print $fh 'my $code = ', dmp($it->{_code}), '; $code->(); ', "\n";
        print $fh "\n";

        # we don't want to load extra modules like Linux::Smaps etc because they
        # will increase the process size themselves. instead, we do it very
        # minimally by reading /proc/PID/smaps directly. this means it will only
        # work for linux. support for other OS should be added here.
        print $fh "# get process size\n";
        print $fh 'print "### OUTPUT-TO-PARSE-BY-BENCHER ###\n";', "\n"; # keep sync with reading code
        print $fh 'my %stats;', "\n";
        print $fh 'open my($fh), "<", "/proc/$$/smaps" or die "Cannot open /proc/$$smaps: $!";', "\n";
        print $fh 'while (<$fh>) { /^(\w+):\s*(\d+)/ or next; $stat{lc $1} += $2 }', "\n";
        print $fh 'for (sort keys %stat) { print "$_: $stat{$_}\n" }', "\n";
        print $fh "\n";

        close $fh or die "Can't write to $script_path: $!";
    }

    # run the script
    {
        require Capture::Tiny;
        my @cmd = ($^X, $script_path);
        $log->debugf("Running %s ...", \@cmd);
        my ($stdout, @res) = &Capture::Tiny::capture_stdout(sub {
            system @cmd;
            die "Failed running script '$script_path' to get process size" if $?;
        });
        $stdout =~ /^### OUTPUT-TO-PARSE-BY-BENCHER ###(.+)/ms
            or die "Can't find marker in output of '$script_path' to get process size";
        my $info0 = $1;
        my %info; while ($info0 =~ /^(\w+): (\d+)/gm) { $info{$1} = $2 }
        $it->{"proc_size"} = $info{size}*1024;
        for (qw/rss private_dirty/) {
            $it->{"proc_${_}_size"} = $info{$_}*1024 if defined $info{$_};
        }
    }
}

sub _find_record_by_seq {
    my ($recs, $seq) = @_;

    for my $rec (@$recs) {
        return $rec if $rec->{seq} == $seq;
    }
    undef;
}

sub _filter_records {
    my %args = @_;

    my $recs = $args{records};
    my $entity = $args{entity};
    my $include = $args{include};
    my $exclude = $args{exclude};
    my $include_name = $args{include_name};
    my $exclude_name = $args{exclude_name};
    my $include_seq = $args{include_seq};
    my $exclude_seq = $args{exclude_seq};
    my $include_pattern = $args{include_pattern};
    my $exclude_pattern = $args{exclude_pattern};
    my $include_tags = $args{include_tags};
    my $exclude_tags = $args{exclude_tags};
    my $aibdf = $args{apply_include_by_default_filter} // 1;

    my $frecs = [];

    # check that there is a name that is also a sequence number which could be
    # confusing
    {
        last unless $include || $exclude ||
            $include_pattern || $exclude_pattern;
        my @seq_names;
        for my $rec (@$recs) {
            my $name = $rec->{name} // $rec->{_name};
            next unless $name =~ /\A\d+\z/ && $name < @$recs;
            push @seq_names, $name;
        }
        if (@seq_names) {
            warn "There is at least one $entity which has names that are also ".
                "sequence numbers and this can be confusing when ".
                "including/excluding: " . join(", ", @seq_names) .
                ". Either rename the $entity or use ".
                "--{include,exclude}-$entity-{name,seq}.\n";
        }
    }

    # check that what's mentioned in {in,ex}clude{,_name,_seq} are actually in
    # the records
    {
        for my $incexc (@{$include // []}) {
            my $found;
            for my $rec (@$recs) {
                if ($incexc =~ /\A\d+\z/ && $rec->{seq} == $incexc) {
                    $found++;
                    last;
                } elsif (($rec->{name} // $rec->{_name} // '') eq $incexc) {
                    $found++;
                    last;
                }
            }
            die "Unknown $entity '$incexc' specified in include, try ".
                "one of: " .
                    join(", ",
                         grep { length($_) }
                             map { ($_->{seq},
                                    $_->{name} // $_->{_name} // '') }
                                 @$recs)
                unless $found;
        }
        for my $incexc (@{$exclude // []}) {
            my $found;
            for my $rec (@$recs) {
                if ($incexc =~ /\A\d+\z/ && $rec->{seq} == $incexc) {
                    $found++;
                    last;
                } elsif (($rec->{name} // $rec->{_name} // '') eq $incexc) {
                    $found++;
                    last;
                }
            }
            die "Unknown $entity '$incexc' specified in exclude, try ".
                "one of: " .
                    join(", ",
                         grep { length($_) }
                             map { ($_->{seq},
                                    $_->{name} // $_->{_name} // '') }
                                 @$recs)
                unless $found;
        }
        for my $incexc (@{$include_name // []}) {
            my $found;
            for my $rec (@$recs) {
                if (($rec->{name} // $rec->{_name} // '') eq $incexc) {
                    $found++;
                    last;
                }
            }
            die "Unknown $entity name '$incexc' specified in include_name, try ".
                "one of: " .
                    join(", ",
                         grep { length($_) }
                             map { $_->{name} // $_->{_name} // '' }
                                 @$recs)
                unless $found;
        }
        for my $incexc (@{$exclude_name // []}) {
            my $found;
            for my $rec (@$recs) {
                if (($rec->{name} // $rec->{_name} // '') eq $incexc) {
                    $found++;
                    last;
                }
            }
            die "Unknown $entity name '$incexc' specified in exclude_name, try ".
                "one of: " .
                    join(", ",
                         grep { length($_) }
                             map { $_->{name} // $_->{_name} // '' }
                                 @$recs)
                unless $found;
        }
        for my $incexc (@{$include_seq // []}) {
            my $found;
            for my $rec (@$recs) {
                if ($rec->{seq} == $incexc) {
                    $found++;
                    last;
                }
            }
            die "Unknown $entity sequence '$incexc' specified in include_seq, try ".
                "one of: " . join(", ", map { $_->{seq} } @$recs) unless $found;
        }
        for my $incexc (@{$exclude_seq // []}) {
            my $found;
            for my $rec (@$recs) {
                if ($rec->{seq} == $incexc) {
                    $found++;
                    last;
                }
            }
            die "Unknown $entity sequence '$incexc' specified in exclude_seq, try ".
                "one of: " . join(", ", map { $_->{seq} } @$recs) unless $found;
        }
    }

  REC:
    for my $rec (@$recs) {
        my $explicitly_included;
        if ($include && @$include) {
            my $included;
          INC:
            for my $inc (@$include) {
                if ($inc =~ /\A\d+\z/) {
                    if ($rec->{seq} == $inc) {
                        $included++;
                        last INC;
                    }
                }
                if (($rec->{name} // $rec->{_name} // '') eq $inc) {
                    $included++;
                    last INC;
                }
            }
            next REC unless $included;
            $explicitly_included++;
        }
        if ($include_name && @$include_name) {
            my $included;
          INC:
            for my $inc (@$include_name) {
                if (($rec->{name} // $rec->{_name} // '') eq $inc) {
                    $included++;
                    last INC;
                }
            }
            next REC unless $included;
            $explicitly_included++;
        }
        if ($include_seq && @$include_seq) {
            my $included;
          INC:
            for my $inc (@$include_seq) {
                if ($rec->{seq} == $inc) {
                    $included++;
                    last INC;
                }
            }
            next REC unless $included;
            $explicitly_included++;
        }
        if ($exclude && @$exclude) {
            for my $exc (@$exclude) {
                if ($exc =~ /\A\d+\z/) {
                    next REC if $rec->{seq} == $exc;
                } else {
                    next REC if (($rec->{name} // $rec->{_name} // '') eq $exc);
                }
            }
        }
        if ($exclude_name && @$exclude_name) {
            for my $exc (@$exclude_name) {
                next REC if (($rec->{name} // $rec->{_name} // '') eq $exc);
            }
        }
        if ($exclude_seq && @$exclude_seq) {
            for my $exc (@$exclude_seq) {
                next REC if $rec->{seq} == $exc;
            }
        }
        if ($include_pattern) {
            next REC unless $rec->{seq} =~ /$include_pattern/i ||
                (($rec->{name} // $rec->{_name} // '') =~ /$include_pattern/i);
            $explicitly_included++;
        }
        if ($exclude_pattern) {
            next REC if $rec->{seq} =~ /$exclude_pattern/i ||
                (($rec->{name} // $rec->{_name} // '') =~ /$exclude_pattern/i);
        }
        if ($include_tags && @$include_tags) {
            my $included;
          INCTAG:
            for my $tag (@$include_tags) {
                if ($tag =~ /&/) {
                    $included = 1;
                    for my $simpletag (split /\s*&\s*/, $tag) {
                        unless (grep {$_ eq $simpletag} @{ $rec->{tags} // [] }) {
                            $included = 0;
                            next REC;
                        }
                    }
                    last INCTAG;
                } else {
                    if (grep {$_ eq $tag} @{ $rec->{tags} // [] }) {
                        $included++;
                        last INCTAG;
                    }
                }
            }
            next REC unless $included;
            $explicitly_included++;
        }
        if ($exclude_tags && @$exclude_tags) {
          EXCTAG:
            for my $tag (@$exclude_tags) {
                if ($tag =~ /&/) {
                    for my $simpletag (split /\s*&\s*/, $tag) {
                        unless (grep {$_ eq $simpletag} @{ $rec->{tags} // [] }) {
                            next EXCTAG;
                        }
                    }
                    next REC;
                } else {
                    next REC if grep {$_ eq $tag} @{ $rec->{tags} // [] };
                }
            }
        }

        unless ($explicitly_included || !$aibdf) {
            next REC if defined($rec->{include_by_default}) &&
                !$rec->{include_by_default};
        }

        push @$frecs, $rec;
    }

    $frecs;
}

sub _get_scenario {
    my %args = @_;

    my $pargs = $args{parent_args};

    my $scenario;
    if (defined $pargs->{scenario_file}) {
        $scenario = do $pargs->{scenario_file};
        die "Can't load scenario file '$pargs->{scenario_file}': $@" if $@;
    } elsif (defined $pargs->{scenario_module}) {
        my $m = "Bencher::Scenario::$pargs->{scenario_module}"; $m =~ s!/!::!g;
        my $mp = $m; $mp =~ s!::!/!g; $mp .= ".pm";
        {
            local @INC = @INC;
            unshift @INC, $_ for @{ $pargs->{include_path} // [] };
            require $mp;
        }
        no strict 'refs';
        $scenario = ${"$m\::scenario"};
    } elsif (defined $pargs->{scenario}) {
        $scenario = $pargs->{scenario};
    } else {
        $scenario = {
            participants => [],
        };
    }

    if ($pargs->{participants}) {
        for (@{ $pargs->{participants} }) {
            push @{ $scenario->{participants} }, $_;
        }
    }
    if ($pargs->{datasets}) {
        $scenario->{datasets} //= [];
        for (@{ $pargs->{datasets} }) {
            push @{ $scenario->{datasets} }, $_;
        }
    }
    if ($pargs->{env_hashes}) {
        for (@{ $pargs->{env_hashes} }) {
            push @{ $scenario->{env_hashes} }, $_;
        }
    }
    $scenario;
}

sub _parse_scenario {
    use experimental 'smartmatch';

    my %args = @_;

    my $unparsed = $args{scenario};
    my $pargs = $args{parent_args};
    my $apply_filters = $args{apply_filters} // 1;
    my $aibdf = $args{apply_include_by_default_filter} // 1; # skip items that have include_by_default=0

    my $parsed = {%$unparsed}; # shallow copy

    if ($parsed->{before_parse_participants}) {
        $log->infof("Executing before_parse_participants hook ...");
        $parsed->{before_parse_participants}->(
            hook_name => 'before_parse_participants',
            scenario  => $unparsed,
            stash     => $args{stash},
        );
    }
    # normalize participants
    {
        $parsed->{participants} = [];
        my $i = -1;
        for my $p0 (@{ $unparsed->{participants} }) {
            $i++;
            my $p = { %$p0, seq=>$i };
            $p->{include_by_default} //= 1;
            $p->{type} //= do {
                if ($p->{cmdline} || $p->{cmdline_template} ||
                        $p->{perl_cmdline} || $p->{perl_cmdline_template}) {
                    'command';
                } else {
                    'perl_code';
                }
            };
            if ($p->{fcall_template}) {
                if ($p->{fcall_template} =~ /\A
                                             (\w+(?:::\w+)*)
                                             (::|->)
                                             (\w+)/x) {
                    $p->{module}   = $1;
                    $p->{function} = $3;
                }
            }

            # try to come up with a nicer name for the participant (not
            # necessarily unique)
            unless (defined($p->{name})) {
                if ($p->{type} eq 'command') {
                    my $c = $p->{cmdline} // $p->{cmdline_template} //
                        $p->{perl_cmdline} // $p->{perl_cmdline_template};
                    if (ref($c) eq 'ARRAY') {
                        $p->{_name} = substr($c->[0], 0, 20);
                    } else {
                        $c =~ /(\S+)/;
                        $p->{_name} = substr($1, 0, 20);
                    }
                } elsif ($p->{type} eq 'perl_code') {
                    if ($p->{function}) {
                        $p->{_name} =
                            ($p->{module} ? "$p->{module}::" : "").
                            $p->{function};
                    } elsif ($p->{module}) {
                        $p->{_name} = $p->{module};
                    } elsif ($p->{modules}) {
                        $p->{_name} = join("+", @{$p->{modules}});
                    }
                }
            }

            push @{ $parsed->{participants} }, $p;
        } # for each participant

        # filter participants by include/exclude module/function
        if ($apply_filters) {
            if ($pargs->{include_modules} && @{ $pargs->{include_modules} }) {
                $parsed->{participants} = [grep {
                    (defined($_->{module}) && $_->{module} ~~ @{ $pargs->{include_modules} }) ||
                        (defined($_->{modules}) && (first { $_ ~~ @{ $pargs->{include_modules} } } @{ $_->{modules} }))
                    } @{ $parsed->{participants} }];
            }
            if ($pargs->{exclude_modules} && @{ $pargs->{exclude_modules} }) {
                $parsed->{participants} = [grep {
                    !(defined($_->{module}) && $_->{module} ~~ @{ $pargs->{exclude_modules} }) &&
                    !(defined($_->{modules}) && (first { $_ ~~ @{ $pargs->{exclude_modules} } } @{ $_->{modules} }))
                } @{ $parsed->{participants} }];
            }
            if ($pargs->{include_module_pattern}) {
                $parsed->{participants} = [grep {
                    (defined($_->{module}) && $_->{module} =~ qr/$pargs->{include_module_pattern}/i) ||
                    (defined($_->{modules}) && (first { /$pargs->{include_module_pattern}/i } @{ $_->{modules} }))
                } @{ $parsed->{participants} }];
            }
            if ($pargs->{exclude_module_pattern}) {
                $parsed->{participants} = [grep {
                    !(defined($_->{module}) && $_->{module} =~ qr/$pargs->{exclude_module_pattern}/i) &&
                    !(defined($_->{modules}) && (first { /$pargs->{exclude_module_pattern}/i } @{ $_->{modules} }))
                } @{ $parsed->{participants} }];
            }

            if ($pargs->{include_functions} && @{ $pargs->{include_functions} }) {
                $parsed->{participants} = [grep {
                    defined($_->{function}) && $_->{function} ~~ @{ $pargs->{include_functions} }
                } @{ $parsed->{participants} }];
            }
            if ($pargs->{exclude_functions} && @{ $pargs->{exclude_functions} }) {
                $parsed->{participants} = [grep {
                    !defined($_->{function}) || !($_->{function} ~~ @{ $pargs->{exclude_functions} })
                } @{ $parsed->{participants} }];
            }
            if ($pargs->{include_function_pattern}) {
                $parsed->{participants} = [grep {
                    defined($_->{function}) && $_->{function} =~ qr/$pargs->{include_function_pattern}/i
                } @{ $parsed->{participants} }];
            }
            if ($pargs->{exclude_function_pattern}) {
                $parsed->{participants} = [grep {
                    !defined($_->{function}) || $_->{function} !~ qr/$pargs->{exclude_function_pattern}/i
                } @{ $parsed->{participants} }];
            }

            if ($pargs->{exclude_pp_modules} || $pargs->{exclude_xs_modules}) {
                require Module::XSOrPP;
                $parsed->{participants} = [grep {
                    if (!defined($_->{module})) {
                        1;
                    } else {
                        my $xs_or_pp = Module::XSOrPP::xs_or_pp($_->{module});
                        if (!$xs_or_pp) {
                            warn "Can't determine if module '$_->{module}' is XS or PP";
                            1;
                        } elsif ($xs_or_pp =~ /xs/ && $pargs->{exclude_xs_modules}) {
                            $log->info("Excluding XS module '$_->{module}'");
                            0;
                        } elsif ($xs_or_pp =~ /pp/ && $pargs->{exclude_pp_modules}) {
                            $log->info("Excluding PP module '$_->{module}'");
                            0;
                        } else {
                            1;
                        }
                    }
                } @{ $parsed->{participants} }];
            }
        }

        $parsed->{participants} = _filter_records(
            entity => 'participant',
            records => $parsed->{participants},
            include => $pargs->{include_participants},
            exclude => $pargs->{exclude_participants},
            include_name => $pargs->{include_participant_names},
            exclude_name => $pargs->{exclude_participant_names},
            include_seq => $pargs->{include_participant_seqs},
            exclude_seq => $pargs->{exclude_participant_seqs},
            include_pattern => $pargs->{include_participant_pattern},
            exclude_pattern => $pargs->{exclude_participant_pattern},
            include_tags => $pargs->{include_participant_tags},
            exclude_tags => $pargs->{exclude_participant_tags},
            apply_include_by_default_filter => $aibdf,
        ) if $apply_filters;
    } # normalize participants

    if ($parsed->{before_parse_datasets}) {
        $log->infof("Executing before_parse_datasets hook ...");
        $parsed->{before_parse_datasets}->(
            hook_name => 'before_parse_datasets',
            scenario  => $unparsed,
            stash     => $args{stash},
        );
    }

    # normalize datasets
    if ($unparsed->{datasets}) {
        $parsed->{datasets} = [];
        my $i = -1;
        my $dss0 = $unparsed->{datasets};

        my $td_args;
        my @uniq_args;

        for my $ds0 (@$dss0) {
            $i++;
            my $ds = { %$ds0, seq=>$i };
            $ds->{include_by_default} //= 1;

            # try to come up with a nicer name for the dataset (not necessarily
            # unique): extract from argument values
            unless (defined($ds->{name})) {
                unless ($td_args) {
                    if (all {$_->{args}} @$dss0) {
                        require TableData::Object::aohos;
                        $td_args = TableData::Object::aohos->new(
                            [map {$_->{args}} @$dss0]);
                        @uniq_args = $td_args->uniq_col_names;
                    } else {
                        $td_args = -1;
                    }
                }
                if (@uniq_args > 1) {
                    $ds->{name} = dmp(
                        { map {$_ => $ds->{args}{$_}} @uniq_args });
                } elsif (@uniq_args) {
                    $ds->{name} = $ds->{args}{$uniq_args[0]};
                    $ds->{name} = dmp($ds->{name}) if ref($ds->{name});
                }
            }


            push @{ $parsed->{datasets} }, $ds;
        } # for each dataset

        $parsed->{datasets} = _filter_records(
            entity => 'dataset',
            records => $parsed->{datasets},
            include => $pargs->{include_datasets},
            exclude => $pargs->{exclude_datasets},
            include_name => $pargs->{include_dataset_names},
            exclude_name => $pargs->{exclude_dataset_names},
            include_seq => $pargs->{include_dataset_seqs},
            exclude_seq => $pargs->{exclude_dataset_seqs},
            include_pattern => $pargs->{include_dataset_pattern},
            exclude_pattern => $pargs->{exclude_dataset_pattern},
            include_tags => $pargs->{include_dataset_tags},
            exclude_tags => $pargs->{exclude_dataset_tags},
            apply_include_by_default_filter => $aibdf,
        ) if $apply_filters;
    } # normalize datasets

    $parsed;
}

sub _get_participant_modules {
    use experimental 'smartmatch';

    my $parsed = shift;

    my @modules;
    for my $p (@{ $parsed->{participants} }) {
        if (defined $p->{module}) {
            push @modules, $p->{module} unless $p->{module} ~~ @modules;
        } elsif (defined $p->{modules}) {
            for (@{ $p->{modules} }) {
                push @modules, $_ unless $_ ~~ @modules;
            }
        }
    }

    @modules;
}

sub _get_participant_helper_modules {
    use experimental 'smartmatch';

    my $parsed = shift;

    my @modules;
    for my $p (@{ $parsed->{participants} }) {
        if (defined $p->{helper_modules}) {
            for (@{ $p->{helper_modules} }) {
                push @modules, $_ unless $_ ~~ @modules;
            }
        }
    }

    @modules;
}

sub _get_participant_functions {
    use experimental 'smartmatch';

    my $parsed = shift;

    my @functions;
    for my $p (@{ $parsed->{participants} }) {
        next unless defined $p->{function};
        push @functions, $p->{function} unless $p->{function} ~~ @functions;
    }

    @functions;
}

sub _gen_items {
    require Permute::Named::Iter;

    my %args = @_;

    my $parsed = $args{scenario};
    my $pargs  = $args{parent_args};
    my $apply_filters = $args{apply_filters} // 1;

    $parsed->{items} = [];
    my @permute;

    my $participants;
    my $datasets;
    my $env_hashes;
    my $module_startup = $pargs->{module_startup} // $parsed->{module_startup};

    my @modules = _get_participant_modules($parsed);

    if ($module_startup) {
        my %mem;
        # push perl as base-line
        push @$participants, {
            seq  => 0,
            name => "perl -e1 (baseline)",
            type => 'command',
            perl_cmdline => ["-e1"],
        };

        my $i = 0;
        for my $p0 (@{ $parsed->{participants} }) {
            my $key;
            if (defined $p0->{module}) {
                $key = $p0->{module};
                next if $mem{$key}++;
                push @$participants, {
                    seq  => ++$i,
                    name => $key,
                    type => 'command',
                    module => $p0->{module},
                    perl_cmdline => ["-M$p0->{module}", "-e1"],
                };
            } elsif (defined $p0->{modules}) {
                $key = join("+", @{ $p0->{modules} });
                next if $mem{$key}++;
                push @$participants, {
                    seq  => ++$i,
                    name => $key,
                    type => 'command',
                    modules => $p0->{modules},
                    perl_cmdline => [(map {"-M$_"} @{ $p0->{modules} }), "-e1"],
                };
            }
        }
        return [412, "There are no modules to benchmark ".
                    "the startup overhead of"] unless %mem;
    } else {
        return [412, "Please load a scenario (-m, -f) or ".
                    "include at least one participant (-p)"]
            unless @{$parsed->{participants}};
        $participants = $parsed->{participants};
        $datasets = $parsed->{datasets} if $parsed->{datasets};
    }

    my %perl_exes; # key=name, val=path
    {
        my @perls;
        if ($pargs->{multiperl}) {
            require App::perlbrew;
            @perls = grep {$_->{has_bencher}} _list_perls();
            return [412, "Can't multiperl because no perl has Bencher installed"]
                unless @perls;

            if ($pargs->{include_perls} && @{ $pargs->{include_perls} }) {
                @perls = grep {
                    my $p = $_;
                    (grep { $p->{name} eq $_ } @{ $pargs->{include_perls} }) ? 1:0;
                } @perls;
            }
            if ($pargs->{exclude_perls} && @{ $pargs->{exclude_perls} }) {
                @perls = grep {
                    my $p = $_;
                    (grep { $p->{name} eq $_ } @{ $pargs->{exclude_perls} }) ? 0:1;
                } @perls;
            }
            die "You have to include at least one perl\n" unless @perls;
            for (@perls) {
                $perl_exes{$_->{name}} = $_->{executable};
            }
            @perls = map {$_->{name}} @perls;
        } else {
            $perl_exes{perl} = $^X;
            @perls = ("perl");
        }
        push @permute, "perl", \@perls;
    }

    my %perl_opts; # key=name, val=[opt, ...]
    if ($pargs->{multimodver}) {
        require ExtUtils::MakeMaker;
        require Module::Path::More;

        return [412, "There are no modules to search multiple versions of"]
            unless @modules;

        return [412, "Module '$pargs->{multimodver}' is not among modules to benchmark"]
            unless grep {$pargs->{multimodver} eq $_} @modules;

        local @INC = @INC;
        if ($pargs->{include_path} && @{ $pargs->{include_path} }) {
            unshift @INC, $_ for reverse @{ $pargs->{include_path} };
        }

        my %versions; # key=module name
        my $paths = Module::Path::More::module_path(module=>$pargs->{multimodver}, all=>1);

        if (@$paths < 1) {
            return [412, "Can't find module '$pargs->{multimodver}', try adding some --include-path"];
        } elsif (@$paths == 1) {
            return [412, "Only found one path for module '$pargs->{multimodver}', try adding some --include-path"];
        }
        for my $path (@$paths) {
            my $v = MM->parse_version($path);
            $v = undef if defined($v) && $v eq 'undef';
            if (!defined($v)) {
                $log->warnf("Can't parse version from %s", $path);
                next;
            }
            $versions{$v}++;
            my $incdir = $path;
            my $mod_pm = $pargs->{multimodver}; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
            $incdir =~ s!/\Q$mod_pm\E$!!;
            $perl_opts{$v} //= ["-I$incdir"];
        }
        return [412, "Can't find version number for module '$pargs->{multimodver}'"]
            unless keys(%versions);
        return [412, "Only found one version of module '$pargs->{multimodver}', try adding some --include-path"]
            unless keys(%versions) > 1;
        push @permute, "modver", [keys %versions];
    }

    push @permute, "participant", [map {$_->{seq}} @$participants];

    if ($datasets) {
        if (@$datasets) {
            push @permute, "dataset", [map {$_->{seq}} @$datasets];
        } else {
            return [412, "Please include at least one dataset"];
        }
    }

    $env_hashes = $parsed->{env_hashes};
    if ($env_hashes && @$env_hashes) {
        push @permute, "env_hash", [0..$#{$env_hashes}];
    }

    $log->debugf("permute: %s", \@permute);

    # to store multiple argument values that are hash, e.g.
    # {args=>{sizes=>{"1M"=>1024**2, "1G"=>1024**3, "1T"=>1024**4}}} instead of
    # array: {args=>{sizes=>[1024**2, 1024**3, 1024**4]}}
    my %ds_arg_values; # key=ds seq, val=hash(key=arg name, val=arg values)

    my $iter = Permute::Named::Iter::permute_named_iter(@permute);
    my $item_seq = 0;
    my $items = [];
    my %item_mems; # key=item key, value=1
  ITER:
    while (my $h = $iter->()) {
        $log->tracef("iter returns: %s", $h);

        my $p = _find_record_by_seq($participants, $h->{participant});
        my $ds;

        if (exists $h->{dataset}) {
            $ds = _find_record_by_seq($datasets, $h->{dataset});
            # filter first
            if ($ds->{include_participant_tags}) {
                my $included = 0;
              INCTAG:
                for my $tag (@{ $ds->{include_participant_tags} }) {
                    if ($tag =~ /\&/) {
                        for my $simpletag (split /\s*&\s*/, $tag) {
                            unless (grep {$simpletag eq $_} @{ $p->{tags} // [] }) {
                                next INCTAG;
                            }
                        }
                        $included++;
                        last INCTAG;
                    } else {
                        if (grep {$tag eq $_} @{ $p->{tags} // [] }) {
                            $included++;
                            last INCTAG;
                        }
                    }
                }
                unless ($included) {
                    $log->tracef(
                        "skipped dataset by include_participant_tags ".
                            "(%s vs participant:%s)",
                        $ds->{include_participant_tags}, $p->{tags});
                    next ITER;
                }
            }
            if ($ds->{exclude_participant_tags}) {
                my $excluded = 0;
              EXCTAG:
                for my $tag (@{ $ds->{exclude_participant_tags} }) {
                    if ($tag =~ /\&/) {
                        for my $simpletag (split /\s*&\s*/, $tag) {
                            unless (grep {$simpletag eq $_} @{ $p->{tags} // [] }) {
                                next EXCTAG;
                            }
                        }
                        $excluded++;
                        last EXCTAG;
                    } else {
                        if (grep {$tag eq $_} @{ $p->{tags} // [] }) {
                            $excluded++;
                            last EXCTAG;
                        }
                    }
                }
                if ($excluded) {
                    $log->tracef(
                        "skipped dataset by exclude_participant_tags ".
                            "(%s vs participant:%s)",
                        $ds->{exclude_participant_tags}, $p->{tags});
                    next ITER;
                }
            }
        }

        my $iter_args;
        if ($ds && $ds->{args} &&
                (my @multi_keys = grep {/\@\z/} keys %{$ds->{args}})) {
            # we need to permute arguments also
            my @permute_args;
            for my $mk0 (@multi_keys) {
                my $vals = $ds->{args}{$mk0};
                my $mk = $mk0; $mk =~ s/\@\z//;
                if (ref($vals) eq 'HASH') {
                    push @permute_args, $mk => [sort keys %$vals];
                    $ds_arg_values{$h->{dataset}}{$mk} = $vals;
                } elsif(ref($vals) eq 'ARRAY') {
                    push @permute_args, $mk => $vals;
                } else {
                    return [400, "Error in dataset #$h->{dataset} arg '$mk0': value must be hash or array"];
                }
            }
            $iter_args = Permute::Named::Iter::permute_named_iter(
                @permute_args);
            $log->debugf("permute args: %s", \@permute_args);
        } else {
            # create an iterator that returns just a single item: {}
            # require Array::Iter; $iter_args = Array::Iter::list_iter({});
            $iter_args = do {
                my $ary = [{}];
                my $i = 0;
                sub {
                    if ($i < @$ary) {
                        return $ary->[$i++];
                    } else {
                        return undef;
                    }
                };
            };
        }

        # don't permute module versions if participant doesn't involve said
        # module
        if ($pargs->{multimodver} && defined($h->{modver}) &&
                $pargs->{multimodver} ne ($p->{module} // '')) {
            $h->{modver} = '';
        }

      ITER_ARGS:
        while (my $h_args = $iter_args->()) {
            my $args;
            if ($ds && $ds->{args}) {
                $args = { %{$ds->{args}} };
                delete $args->{$_} for (grep {/\@\z/} keys %$args);
                for my $arg (keys %$h_args) {
                    if ($ds_arg_values{$h->{dataset}}{$arg}) {
                        $args->{$arg} = $ds_arg_values{$h->{dataset}}{$arg}{ $h_args->{$arg} };
                    } else {
                        $args->{$arg} = $h_args->{$arg};
                    }
                }
            }

            my $code;
            my $code_str;
            my $template_vars;
            if ($p->{type} eq 'command') {
                require String::ShellQuote;
                my @cmd;
                my $shell;
                if (defined $p->{cmdline}) {
                    if (ref($p->{cmdline}) eq 'ARRAY') {
                        @cmd = @{ $p->{cmdline} };
                        $shell = 0;
                    } else {
                        @cmd = ($p->{cmdline});
                        $shell = 1;
                    }
                } elsif (defined $p->{perl_cmdline}) {
                    if (ref($p->{perl_cmdline}) eq 'ARRAY') {
                        @cmd = ($perl_exes{$h->{perl}},
                                ($h->{modver} ? @{$perl_opts{$h->{modver}} // []} : ()),
                                @{ $p->{perl_cmdline} });
                        $shell = 0;
                    } else {
                        @cmd = (
                            join(
                                " ",
                                $perl_exes{$h->{perl}},
                                ($h->{modver} ? map {String::ShellQuote::shell_quote($_)} @{$perl_opts{$h->{modver}} // []} : ()),
                                $p->{perl_cmdline},
                            )
                        );
                        $shell = 1;
                    }
                } elsif (defined $p->{cmdline_template}) {
                    if ($ds->{args}) {
                        $template_vars = { %$args };
                    } elsif ($ds->{argv}) {
                        $template_vars = { map {$_=>$ds->{argv}[$_]}
                                               0..$#{ $ds->{argv} } };
                    }
                    if (ref($p->{cmdline_template}) eq 'ARRAY') {
                        @cmd = map { _fill_template($_, $template_vars) }
                            @{ $p->{cmdline_template} };
                        $shell = 0;
                    } else {
                        my $cmd = _fill_template(
                            $p->{cmdline_template}, $template_vars, 'shell');
                        @cmd = ($cmd);
                        $shell = 1;
                    }
                } elsif (defined $p->{perl_cmdline_template}) {
                    if ($ds->{args}) {
                        $template_vars = { %$args };
                    } elsif ($ds->{argv}) {
                        $template_vars = { map {$_=>$ds->{argv}[$_]}
                                               0..$#{ $ds->{argv} } };
                    }
                    if (ref($p->{perl_cmdline_template}) eq 'ARRAY') {
                        @cmd = (
                            $perl_exes{$h->{perl}},
                            ($h->{modver} ? @{$perl_opts{$h->{modver}} // []} : ()),
                            map { _fill_template($_, $template_vars) }
                                @{ $p->{perl_cmdline_template} }
                        );
                        $shell = 0;
                    } else {
                        my $cmd = _fill_template(
                            join(
                                " ",
                                $perl_exes{$h->{perl}},
                                ($h->{modver} ? map {String::ShellQuote::shell_quote($_)} @{$perl_opts{$h->{modver}} // []} : ()),
                                $p->{perl_cmdline_template},
                            ),
                            $template_vars,
                            'shell',
                        );
                        @cmd = ($cmd);
                        $shell = 1;
                    }
                } else {
                    die "BUG: Unknown command type";
                }

                $log->debugf("Item #%d: cmdline=%s", $item_seq, \@cmd);

                {
                    $code_str = "package main; sub { ";
                    if (defined $h->{env_hash}) {
                        my $env_hash = $env_hashes->[$h->{env_hash}];
                        for (sort keys %$env_hash) {
                            $code_str .= "local \$ENV{".dmp($_)."} = ".dmp($env_hash->{$_})."; ";
                        }
                    }
                    if ($shell) {
                        $code_str .= "system ".dmp($cmd[0])."; ";
                    } else {
                        $code_str .= "system {".dmp($cmd[0])."} \@{".dmp(\@cmd)."}; ";
                    }
                    $code_str .= q[die "Command failed (child error=$?, os error=$!)\\n" if $?];
                    $code_str .= "}";
                    $code = eval $code_str;
                    die "BUG: Can't produce code for cmdline: $@ (code string is: $code_str)" if $@;
                };
            } elsif ($p->{type} eq 'perl_code') {
                if ($p->{code}) {
                    my $save_env;
                    my $code_set_env = sub {
                        my $env_hash = $env_hashes->[shift];
                        $save_env = {};
                        for (keys %$env_hash) {
                            $save_env->{$_} = $ENV{$_};
                            $ENV{$_} = $env_hash->{$_};
                        }
                    };
                    my $code_restore_env = sub {
                        for (keys %$save_env) {
                            $ENV{$_} = $save_env->{$_};
                        }
                    };
                    if ($ds) {
                        if ($ds->{argv}) {
                            if (defined $h->{env_hash}) {
                                $code = sub {
                                    $code_set_env->($h->{env_hash});
                                    $p->{code}->(@{$ds->{argv}});
                                    $code_restore_env->();
                                };
                            } else {
                                $code = sub { $p->{code}->(@{$ds->{argv}}) };
                            }
                        } elsif ($ds->{args}) {
                            if (defined $h->{env_hash}) {
                                $code = sub {
                                    $code_set_env->($h->{env_hash});
                                    $p->{code}->(%$args);
                                    $code_restore_env->();
                                };
                            } else {
                                $code = sub { $p->{code}->(%$args) };
                            }
                        } else {
                            return [400, "Participant #$p->{seq}, dataset #$h->{dataset}: No argv/args supplied for code"];
                        }
                    } else {
                        if (defined $h->{env_hash}) {
                            $code = sub {
                                $code_set_env->($h->{env_hash});
                                $p->{code}->();
                                $code_restore_env->();
                            };
                        } else {
                            $code = $p->{code};
                        }
                    }
                } elsif (my $template = $p->{code_template} || $p->{fcall_template}) {
                    if ($ds->{args}) {
                        $template_vars = { %$args };
                    } elsif ($ds->{argv}) {
                        $template_vars = { map {$_=>$ds->{argv}[$_]}
                                               0..$#{ $ds->{argv} } };
                    } else {
                        #warn "Item #$item_seq: participant specifies code_template/fcall_template but there is no args/argv in the dataset #$h->{dataset}\n";
                    }

                    $code_str = "package main; sub { ";
                    if (defined $h->{env_hash}) {
                        my $env_hash = $env_hashes->[$h->{env_hash}];
                        for (sort keys %$env_hash) {
                            $code_str .= "local \$ENV{".dmp($_)."} = ".dmp($env_hash->{$_})."; ";
                        }
                    }
                    $code_str .= _fill_template($template, $template_vars, 'dmp') . " }";
                    $log->debugf("Item #%d: code=%s", $item_seq, $code_str);
                    $code = eval $code_str;
                    return [400, "Item #$item_seq: code compile error: $@ (code: $code_str)"] if $@;
                }
            } else {
                return [400, "Unknown participant type '$p->{type}'"];
            }

            my $item = {
                (_code_str => $code_str ) x !!defined($code_str),
                _code => $code,
                _permute => $h,
                _template_vars => $template_vars,
                ((_permute_args => $h_args) x !!$ds->{args}),
            };
            $item->{p_tags} = join(", ", @{ $p->{tags} // [] });
            $item->{ds_tags} = join(", ", @{ $ds->{tags} // [] }) if $ds;
            for my $k (keys %$h) {
                if ($k eq 'perl') {
                    $item->{perl} = $h->{$k};
                    $item->{_perl_exe} = $perl_exes{ $h->{$k} };
                } elsif ($k eq 'modver') {
                    $item->{modver} = $h->{$k};
                    $item->{_perl_opts} = $perl_opts{ $h->{$k} };
                } elsif ($k eq 'dataset') {
                    $item->{"dataset"} = $ds->{name} // "#$ds->{seq}";
                } elsif ($k eq 'participant') {
                    $item->{"participant"} = $p->{name} // $p->{_name} // "#$p->{seq}";
                } elsif ($k eq 'env_hash') {
                    $item->{env_hash} = $h->{$k};
                    $item->{_env} = $env_hashes->[$h->{$k}];
                } else {
                    $item->{"item_$k"} = $h->{$k};
                }
            }
            if ($ds->{args}) {
                for my $k (keys %$h_args) {
                    $item->{"arg_$k"} = $h_args->{$k};
                }
            }

            # skip duplicate items
            my $key = dmp [map { $item->{$_} }
                               grep { !/^_/ }
                               sort keys %$item];
            $log->tracef("item key=%s", $key);
            if ($item_mems{$key}++) {
                $log->tracef("Duplicate key, skipped item, recycling seq number %d", $item_seq);
                next ITER;
            }

            $item->{seq} = $item_seq++;

            push @$items, $item;

            last ITER_ARGS unless $ds->{args};
        } # ITER_ARGS

    } # ITER

    # give each item a convenient name, which is a short combination of its
    # permutation (unnecessarily unique, just as a human-readable name)
    {
        last unless @$items;
        require TableData::Object::aohos;
        my $td = TableData::Object::aohos->new($items);
        my @const_cols = $td->const_col_names;

        my @name_keys;
        for my $k (sort keys %{$items->[0]}) {
            next unless $k =~ /^(participant|p_.+|dataset|ds_.+|item_.+|arg_.+)$/;
            next if grep {$k eq $_} @const_cols;
            push @name_keys, $k;
        }

        for my $it (@$items) {
            $it->{_name} = join(" ", map {"$_=".($it->{$_} // "(undef)")}
                                    @name_keys);
        }
    }

    $items = _filter_records(
        entity => 'item',
        records => $items,
        include => $pargs->{include_items},
        exclude => $pargs->{exclude_items},
        include_name => $pargs->{include_item_names},
        exclude_name => $pargs->{exclude_item_names},
        include_seq => $pargs->{include_item_seqs},
        exclude_seq => $pargs->{exclude_item_seqs},
        include_pattern => $pargs->{include_item_pattern},
        exclude_pattern => $pargs->{exclude_item_pattern},
    ) if $apply_filters;

    [200, "OK", $items, {'func.permute'=>\@permute}];
}

sub _item_label {
    my %args = @_;

    my $item = $args{item};
    my $bencher_args = $args{bencher_args};

    join(
        "",
        "$item->{seq} ($item->{_name}",
        ($bencher_args->{multiperl} ? ", perl=$item->{perl}" : ""),
        ($bencher_args->{multimodver} ? ", modver=$item->{modver}" : ""),
        ($item->{_env} ?
             ", env={".join(" ", map {"$_=$item->{_env}{$_}"}
                                sort keys %{$item->{_env}})."}" : ""),
        ")",
    );
}

sub _complete_scenario_module {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);
    my $args = $res->[2];

    require Complete::Module;
    {
        local @INC = @INC;
        unshift @INC, $_ for @{ $args->{include_path} // [] };
        Complete::Module::complete_module(
            word=>$args{word}, ns_prefix=>'Bencher::Scenario');
    }
}

sub _complete_participant_module {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    my $unparsed = _get_scenario(parent_args=>$args);
    my $parsed = _parse_scenario(
        scenario=>$unparsed,
        parent_args=>$args,
        apply_filters => $args{apply_filters},
    );

    my @modules = _get_participant_modules($parsed);

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => \@modules,
    );
}

sub _complete_participant_modules_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_pmods = _complete_participant_module(%args, word=>'', apply_filters=>0);

    # at this point Complete::Util is already loaded by _complete_participant_module
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_pmods,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_function {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    my $unparsed = _get_scenario(parent_args=>$args);
    my $parsed = _parse_scenario(
        scenario=>$unparsed,
        parent_args=>$args,
        apply_filters => $args{apply_filters},
    );

    my @functions = _get_participant_functions($parsed);

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => \@functions,
    );
}

sub _complete_functions_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_functions = _complete_function(%args, word=>'', apply_filters=>0);

    # at this point Complete::Util is already loaded by _complete_functions
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_functions,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_participant {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    my $unparsed = _get_scenario(parent_args=>$args);
    my $parsed = _parse_scenario(
        scenario=>$unparsed,
        parent_args=>$args,
        apply_filters => $args{apply_filters},
    );

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => [grep {defined} map {(
            ($_->{seq} ) x !!($args{seq} || !defined($args{seq})),
            ($_->{name}, $_->{_name}) x !!($args{name} || !defined($args{name}))
        )} @{$parsed->{participants}}],
    );
}

sub _complete_participants_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_participants = _complete_participant(%args, word=>'', apply_filters=>0);

    # at this point Complete::Util is already loaded by _complete_participant
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_participants,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_participant_names_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_pnames = _complete_participant(%args, word=>'', apply_filters=>0, seq=>0);

    # at this point Complete::Util is already loaded by _complete_participant
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_pnames,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_participant_seqs_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_pseqs = _complete_participant(%args, word=>'', apply_filters=>0, name=>0);

    # at this point Complete::Util is already loaded by _complete_participant
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_pseqs,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_participant_tag {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    my $unparsed = _get_scenario(parent_args=>$args);
    my $parsed = _parse_scenario(
        scenario=>$unparsed,
        parent_args=>$args,
        apply_filters => $args{apply_filters},
    );

    my %tags;
    for my $p (@{ $parsed->{participants} }) {
        if ($p->{tags}) {
            $tags{$_}++ for @{ $p->{tags} };
        }
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => [keys %tags],
    );
}

sub _complete_participant_tags_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_tags = _complete_participant_tag(%args, word=>'', apply_filters=>0);

    # at this point Complete::Util is already loaded by _complete_participant
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_tags,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_dataset {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    my $unparsed = _get_scenario(parent_args=>$args);
    my $parsed = _parse_scenario(
        scenario=>$unparsed,
        parent_args=>$args,
        apply_filters => $args{apply_filters},
    );

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => [grep {defined} map {(
            ($_->{seq} ) x !!($args{seq} || !defined($args{seq})),
            ($_->{name}, $_->{_name}) x !!($args{name} || !defined($args{name})),
        )} @{$parsed->{datasets}}],
    );
}

sub _complete_datasets_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_datasets = _complete_dataset(%args, word=>'', apply_filters=>0);

    # at this point Complete::Util is already loaded by _complete_dataset
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_datasets,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_dataset_names_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_dsnames = _complete_dataset(%args, word=>'', apply_filters=>0, seq=>0);

    # at this point Complete::Util is already loaded by _complete_dataset
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_dsnames,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_dataset_seqs_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_dsseqs = _complete_dataset(%args, word=>'', apply_filters=>0, name=>0);

    # at this point Complete::Util is already loaded by _complete_dataset
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_dsseqs,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_dataset_tag {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    my $unparsed = _get_scenario(parent_args=>$args);
    my $parsed = _parse_scenario(
        scenario=>$unparsed,
        parent_args=>$args,
        apply_filters => $args{apply_filters},
    );

    my %tags;
    for my $p (@{ $parsed->{datasets} }) {
        if ($p->{tags}) {
            $tags{$_}++ for @{ $p->{tags} };
        }
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => [keys %tags],
    );
}

sub _complete_dataset_tags_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_tags = _complete_dataset_tag(%args, word=>'', apply_filters=>0);

    # at this point Complete::Util is already loaded by _complete_participant
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_tags,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_item {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    my $unparsed = _get_scenario(parent_args=>$args);
    my $parsed = _parse_scenario(
        scenario=>$unparsed,
        parent_args=>$args,
        apply_filters => $args{apply_filters},
    );
    $res = _gen_items(
        scenario=>$parsed,
        parent_args=>$args,
        apply_filters => $args{apply_filters},
    );
    return undef unless $res->[0] == 200;
    my $items = $res->[2];

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => [grep {defined} map {(
            ($_->{seq} ) x !!($args{seq} || !defined($args{seq})),
            ($_->{name}, $_->{_name}) x !!($args{name} || !defined($args{name}))
        )} @$items],
    );
}

sub _complete_items_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_items = _complete_items(%args, word=>'', apply_filters=>0);

    # at this point Complete::Util is already loaded by _complete_dataset
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_items,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_item_names_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_inames = _complete_item(%args, word=>'', apply_filters=>0, seq=>0);

    # at this point Complete::Util is already loaded by _complete_item
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_inames,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

sub _complete_item_seqs_comma_sep {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    my $all_iseqs = _complete_item(%args, word=>'', apply_filters=>0, name=>0);

    # at this point Complete::Util is already loaded by _complete_item
    Complete::Util::hashify_answer(
        Complete::Util::complete_comma_sep(
            word => $word,
            elems => $all_iseqs,
            uniq  => 1,
        ),
        {path_sep => ','},
    );
}

# list installed perls, and check each perl if Bencher::Backend is installed
sub _list_perls {
    require Capture::Tiny;

    eval { require App::perlbrew; 1 };
    return undef if $@;

    my $pb = App::perlbrew->new;
    my @perls = $pb->installed_perls;
    for my $perl (@perls) {
        my @cmd = (
            $perl->{executable},
            "-MBencher::Backend",
            "-e'print \$Bencher::Backend::VERSION'",
        );
        my ($stdout, $stderr, @res) =
            &Capture::Tiny::capture(sub { system @cmd });
        if ($stderr || $?) {
            $perl->{has_bencher} = 0;
            $perl->{bencher_version} = undef;
        } else {
            $perl->{has_bencher} = 1;
            $perl->{bencher_version} = $stdout;
        }
    }

    @perls;
}

sub _complete_perl {
    no warnings 'once';
    require Complete::Util;

    my %args = @_;
    my $word    = $args{word} // '';

    my @perls = _list_perls();

    local $Complete::Common::OPT_FUZZY = 0;
    Complete::Util::complete_array_elem(
        word => $word,
        array => [map {$_->{name}} grep {$_->{has_bencher}} @perls],
    );
}

sub _digest {
    require File::Digest;
    my $path = shift;
    my $digests = {};
    for my $algo (qw/md5 sha1 sha256/) {
        my $res = File::Digest::digest_file(file => $path, algorithm=>$algo);
        next unless $res->[0] == 200;
        $digests->{$algo} = $res->[2];
    }
    $digests;
}

my $_alias_spec_add_participant = {
    summary => 'Add a participant',
    code => sub {
        require JSON::MaybeXS;

        my $args = shift;
        push @{ $args->{participants} },
            JSON::MaybeXS::decode_json($_[0]);
    },
};

my $_alias_spec_add_dataset = {
    summary => 'Add a dataset',
    code => sub {
        require JSON::MaybeXS;

        my $args = shift;
        push @{ $args->{datasets} },
            JSON::MaybeXS::decode_json($_[0]);
    },
};

my $_alias_spec_add_env_hash = {
    summary => 'Add an environment hash',
    code => sub {
        require JSON::MaybeXS;

        my $args = shift;
        push @{ $args->{env_hashes} },
            JSON::MaybeXS::decode_json($_[0]);
    },
};

$SPEC{format_result} = {
    v => 1.1,
    summary => 'Format bencher result',
    args => {
        envres => {
            summary => 'Enveloped result from bencher',
            schema => 'array*', # XXX envres
            req => 1,
            pos => 0,
        },
        formatters => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'formatter',
            summary => 'Formatters specification',
            schema => ['array*', of=>[
                'any*', of=>[
                    'str*',
                    ['array*', len=>2, elems=>['str*', 'hash*']],
                ]
            ]],
            req => 1,
            pos => 1,
        },
        options => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'option',
            schema => 'hash*',
            pos => 2,
        },
    },
    args_as => 'array',
};
sub format_result {
    require POSIX;

    my ($envres, $formatters, $opts) = @_;

    $opts //= {};
    $opts->{render_as_text_table} //= 1;

    $formatters //= [
        'AddVsSlowestField',
        'ShowEnv',
        ['Sort', {by=>$opts->{sort}}],
        'ScaleTime',
        'ScaleRate',
        'ScaleSize',
        ['RoundNumbers', {scientific_notation => $opts->{scientific_notation}}],
        ($envres->[3]{'func.module_startup'} ? ('ModuleStartup') : ()),
        'DeleteConstantFields',
        'DeleteNotesFieldIfEmpty',
        'DeleteSeqField',

        ('RenderAsTextTable') x !!$opts->{render_as_text_table},
    ];

    # load all formatter modules
    my @fmtobjs;
    for my $fmt (@$formatters) {
        my ($fmtname, $fmtargs);
        if (ref($fmt)) {
            $fmtname = $fmt->[0];
            $fmtargs = $fmt->[1];
        } else {
            $fmtname = $fmt;
            $fmtargs = {};
        }
        my $fmtmod = "Bencher::Formatter::$fmtname";
        my $fmtmod_pm = $fmtmod; $fmtmod_pm =~ s!::!/!g; $fmtmod_pm .= ".pm";
        require $fmtmod_pm;
        push @fmtobjs, $fmtmod->new(%$fmtargs);
    }

    # run all munge_result()
    for my $fmtobj (@fmtobjs) {
        next unless $fmtobj->can("munge_result");
        $fmtobj->munge_result($envres);
    }

    # return the first render_result()
    for my $fmtobj (@fmtobjs) {
        next unless $fmtobj->can("render_result");
        return $fmtobj->render_result($envres);
    }

    # no render_result() has been called, we return the envres
    $envres;
}

# in enhanced mode, foo_bar becomes subscript etc. we don't want this. chart
# title can be non-enhanced with title => { text=>..., enhanced=>0 }, but
# dataset title can't. so we use escape stuffs.
sub _esc_gnuplot_title {
    my $val = shift;
    $val =~ s/_/-/g; # XXX superscript, greek?
    $val;
}

$SPEC{chart_result} = {
    v => 1.1,
    summary => 'Generate chart from the result',
    description => <<'_',

Will use gnuplot (via <pm:Chart::Gnuplot>) to generate the chart. Will produce
`.png` files in the specified directory.

Currently only results with one or two permutations of different items will be
chartable.

Options to customize the look/style of the chart will be added in the future.

_
    args => {
        envres => {
            summary => 'Enveloped result from bencher',
            schema => 'array*', # XXX envres
            req => 1,
            pos => 0,
        },
        output_file => {
            summary => '',
            schema => 'str*', # XXX filename
            req => 1,
            pos => 1,
            cmdline_aliases => {o=>{}},
            tags => ['category:output'],
        },
        overwrite => {
            schema => 'bool',
            tags => ['category:output'],
        },
        title => {
            schema => 'str*',
        },
    },
};
sub chart_result {
    require Chart::Gnuplot;
    require Package::Abbreviate;

    my %args = @_;

    return [412, "Output file already exists, use overwrite=1 if you want to ".
                "overwrite the file"]
        if (-f $args{output_file}) && !$args{overwrite};

    my $envres = format_result($args{envres}, undef, {render_as_text_table=>0});
    return [412, "No permute information in the result"]
        unless $envres->[3]{'func.permute'};
    my %permute = @{ $envres->[3]{'func.permute'} };
    my $num_different = 0;
    for (sort keys %permute) {
        if (@{ $permute{$_} } > 1) {
            $num_different++;
        } else {
            delete $permute{$_};
        }
    }
    return [412, "Result needs to have 1-2 permutations of different items ".
                "to be charted"]
        unless $num_different >= 1 && $num_different <= 2;
    my @permute = sort keys %permute;

    my $data = $envres->[3]{'func.module_startup'} ? "time" : "rate";

    my $chart = Chart::Gnuplot->new(
        #imagesize => "0.5, 0.5",
        output => $args{output_file},
        title  => $args{title} // 'Benchmark result',
        ylabel => $data,
        xlabel => "",
    );

    my @chart_datasets;

    if (@permute == 1) {
        my (@ydata, @xdata);
        for my $it (@{ $envres->[2] }) {
            push @ydata, $it->{$data};
            my $xdata = $it->{$permute[0]};
            if ($permute[0] eq 'participant' && $xdata =~ /\A\w+(::\w+)+\z/) {
                $xdata = Package::Abbreviate->new(10, {eager=>1})->abbr($xdata);
            }
            push @xdata, $xdata;
        }
        my $ds = Chart::Gnuplot::DataSet->new(
            ydata  => \@ydata,
            xdata  => \@xdata,
            title  => _esc_gnuplot_title($permute[0]),
            border => undef,
            fill   => {}, # XXX color doesn't affect, on my PC?
            style  => "histograms",
        );
        push @chart_datasets, $ds;
    } elsif (@permute == 2) {
        my %p1_values;
        for my $it (@{ $envres->[2] }) {
            $p1_values{ $it->{$permute[1]} }++;
        }
        for my $p1 (sort keys %p1_values) {
            my (@ydata, @xdata);
            for my $it (@{ $envres->[2] }) {
                next unless $it->{ $permute[1] } eq $p1;
                push @ydata, $it->{$data};
                push @xdata, $it->{$permute[0]};
            }
            my $title;
            if ($permute[1] eq 'participant' && $p1 =~ /\A\w+(::\w+)+\z/) {
                $title = Package::Abbreviate->new(10, {eager=>1})->abbr($p1);
            } else {
                $title = $p1;
            }

            my $ds = Chart::Gnuplot::DataSet->new(
                ydata  => \@ydata,
                xdata  => \@xdata,
                title  => _esc_gnuplot_title($title),
                border => undef,
                fill   => {}, # XXX color doesn't affect, on my PC?
                style  => "histograms",
            );
            push @chart_datasets, $ds;
        }
    }

    $chart->plot2d(@chart_datasets);
    [200, "OK"];
}

$SPEC{split_result} = {
    v => 1.1,
    summary => 'Split results based on one or more fields',
    description => <<'_',

This routine splits a table into multiple table based on one or more fields. If
you want to split a result, you should do it before `format_result()` and then
format the split results individually.

A common use-case is to produce separate tables for each participant or dataset,
to make the benchmark results more readable (this is an alternative to having to
perform separate benchmark run per participant or dataset).

Each split result clones all the result metadata (like `func.module_version`,
`func.platform_info`, `table.fields`, and so on). But the result items are only
a subset of the original result.

Return an array where each element is `[\%field_values, $split_result]`.

_
    args => {
        envres => {
            summary => 'Enveloped result from bencher',
            schema => 'array*', # XXX envres
            req => 1,
            pos => 0,
        },
        fields => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'field',
            summary => 'Fields to split the results on',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 1,
        },
        options => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'option',
            schema => 'hash*',
            pos => 2,
        },
    },
    args_as => 'array',
    result_naked => 1,
};
sub split_result {
    no warnings 'uninitialized';

    require Data::Clone;

    my ($envres, $fields, $opts) = @_;

    $opts //= {};

    my %idxs_by_key; # key= "field1-value\0field2-value\0...", val=[index of item in envres->[2], ...]

    for my $i (0..$#{ $envres->[2] }) {
        my $item = $envres->[2][$i];
        my $key = join("\0", map { $item->{$_} } @$fields);
        push @{ $idxs_by_key{$key} }, $i;
    }

    my $res = [];
    for my $key (sort keys %idxs_by_key) {
        my $split_res = Data::Clone::clone($envres);
        $split_res->[2] = [map { $split_res->[2][$_] } @{ $idxs_by_key{$key} }];
        my $split_fields = { map { $_ => $split_res->[2][0]{$_} } @$fields };

        if ($split_res->[3]{'func.permute'}) {
            my %permute = @{ $split_res->[3]{'func.permute'} };
            delete $permute{$_} for keys %$split_fields;
            $split_res->[3]{'func.permute'} =
                [map { $_=>$permute{$_} } sort keys %permute];
        }

        push @$res, [$split_fields, $split_res];
    }

    $res;
}

my $_code_remaining = sub {
    my ($seen_elems, $elems) = @_;
    my %seen;
    for (@$seen_elems) {
        (my $nodash = $_) =~ s/^-//;
        $seen{$nodash}++;
    }
    my @remaining;
    for (@$elems) {
        (my $nodash = $_) =~ s/^-//;
        push @remaining, $_ unless $seen{$nodash};
    }
    \@remaining;
};

$SPEC{bencher} = {
    v => 1.1,
    summary => 'A benchmark framework',
    description => <<'_',

Bencher is a benchmark framework. You specify a *scenario* (either in a
`Bencher::Scenario::*` Perl module, or a Perl script, or over the command-line)
containing list of *participants* and *datasets*. Participants are codes or
commands to run, and datasets are arguments for the codes/commands. Bencher will
permute the participants and datasets into benchmark items, ready to run.

You can choose to include only some participants, datasets, or items. And there
are options to view your scenario's participants/datasets/items/mentioned
modules, run benchmark against multiple perls and module versions, and so on.
Bencher comes as a CLI script as well as Perl module. See the
<pm:Bencher::Backend> documentation for more information.

_
    args_rels => {
        # XXX precision & precision_limit is only relevant when action =~ /^bench(-with-.+)?$/
        # XXX note is only relevant when action=bench
        # XXX sort is only relevant when action=bench and format=text
        # XXX include_perls & exclude_perls are only relevant when multiperl=1
        'choose_one&' => [
            ['scenario_file', 'scenario_module', 'scenario'],
        ],
    },
    args => {
        scenario_file => {
            summary => 'Load a scenario from a Perl file',
            description => <<'_',

Perl file will be do()'ed and the last expression should be a hash containing
the scenario specification.

_
            schema => ['str*'],
            cmdline_aliases => {f=>{}},
        },
        scenario_module => {
            summary => 'Load a scenario from a Bencher::Scenario:: Perl module',
            description => <<'_',

Will try to load module `Bencher::Scenario::<NAME>` and expect to find a package
variable in the module called `$scenario` which should be a hashref containing
the scenario specification.

_
            schema => ['str*', match=>qr!\A\w+((?:::|/)\w+)*\z!],
            cmdline_aliases => {m=>{}},
            completion => sub { _complete_scenario_module(@_) },
        },
        scenario => {
            summary => 'Load a scenario from data structure',
            schema => ['hash*'], # XXX bencher::scenario
            tags => ['hidden-cli'],
        },
        participants => {
            'summary' => 'Add participants',
            schema => ['array*', of=>['hash*']],
            cmdline_aliases => {
                participant => $_alias_spec_add_participant,
                p => $_alias_spec_add_participant,
            },
        },
        datasets => {
            summary => 'Add datasets',
            schema => ['array*', of=>['hash*']],
            cmdline_aliases => {
                dataset => $_alias_spec_add_dataset,
                d => $_alias_spec_add_dataset,
            },
        },
        env_hashes => {
            summary => 'Add environment hashes',
            schema => ['array*', of=>['hash*']],
            cmdline_aliases => {
                env_hash => $_alias_spec_add_env_hash,
            },
        },
        precision => {
            summary => 'Precision',
            description => <<'_',

When benchmarking with the default <pm:Benchmark::Dumb> runner, will pass the
precision to it. The value is a fraction, e.g. 0.5 (for 5% precision), 0.01 (for
1% precision), and so on. Or, it can also be a positive integer to speciify
minimum number of iterations, usually need to be at least 6 to avoid the "Number
of initial runs is very small (<6)" warning. The default precision is 0, which
is to let Benchmark::Dumb determine the precision, which is good enough for most
cases.

When benchmarking with <pm:Benchmark> runner, will pass this value as the
C<$count> argument. Which can be a positive integer to mean the number of
iterations to do (e.g. 10, or 100). Or, can also be set to a negative number
(e.g. -0.5 or -2) to mean minimum number of CPU seconds. The default is -0.5.

When benchmarking with <pm:Benchmark::Dumb::SimpleTime>, this value is a
positive integer which means the number of iterations to perform.

This setting overrides `default_precision` property in the scenario.

_
            schema => ['float*'],
        },
        precision_limit => {
            summary => 'Set precision limit',
            description => <<'_',

Instead of setting `precision` which forces a single value, you can also set
this `precision_limit` setting. If the precision in the scenario is higher
(=number is smaller) than this limit, then this limit is used. For example, if
the scenario specifies `default_precision` 0.001 and `precision_limit` is set to
0.005 then 0.005 is used.

This setting is useful on slower computers which might not be able to reach the
required precision before hitting maximum number of iterations.

_
            schema => ['float*', between=>[0,1]],
        },
        action => {
            schema => ['str*', {
                in=>[qw/
                           list-perls
                           list-scenario-modules
                           show-scenario
                           list-participants
                           list-participant-modules
                           list-datasets
                           list-items
                           show-items-codes
                           show-items-results
                           show-items-results-sizes
                           show-items-outputs
                           bench
                       /]
                    # list-functions
            }],
            default => 'bench',
            cmdline_aliases => {
                a => {},
                list_perls => {
                    is_flag => 1,
                    summary => 'Shortcut for -a list-perls',
                    code => sub { $_[0]{action} = 'list-perls' },
                },
                list_scenario_modules => {
                    is_flag => 1,
                    summary => 'Shortcut for -a list-scenario-modules',
                    code => sub { $_[0]{action} = 'list-scenario-modules' },
                },
                L => {
                    is_flag => 1,
                    summary => 'Shortcut for -a list-scenario-modules',
                    code => sub { $_[0]{action} = 'list-scenario-modules' },
                },
                show_scenario => {
                    is_flag => 1,
                    summary => 'Shortcut for -a show-scenario',
                    code => sub { $_[0]{action} = 'show-scenario' },
                },
                list_participants => {
                    is_flag => 1,
                    summary => 'Shortcut for -a list-participants',
                    code => sub { $_[0]{action} = 'list-participants' },
                },
                list_participant_modules => {
                    is_flag => 1,
                    summary => 'Shortcut for -a list-participant-modules',
                    code => sub { $_[0]{action} = 'list-participant-modules' },
                },
                list_datasets => {
                    is_flag => 1,
                    summary => 'Shortcut for -a list-datasets',
                    code => sub { $_[0]{action} = 'list-datasets' },
                },
                list_permutes => {
                    is_flag => 1,
                    summary => 'Shortcut for -a list-permutes',
                    code => sub { $_[0]{action} = 'list-permutes' },
                },
                list_items => {
                    is_flag => 1,
                    summary => 'Shortcut for -a list-items',
                    code => sub { $_[0]{action} = 'list-items' },
                },
                show_items_codes => {
                    is_flag => 1,
                    summary => 'Shortcut for -a show-items-codes',
                    code => sub { $_[0]{action} = 'show-items-codes' },
                },
                show_items_results => {
                    is_flag => 1,
                    summary => 'Shortcut for -a show-items-results',
                    code => sub { $_[0]{action} = 'show-items-results' },
                },
                show_items_results_sizes => {
                    is_flag => 1,
                    summary => 'Shortcut for -a show-items-results-sizes',
                    code => sub { $_[0]{action} = 'show-items-results-sizes' },
                },
                show_items_outputs => {
                    is_flag => 1,
                    summary => 'Shortcut for -a show-items-outputs',
                    code => sub { $_[0]{action} = 'show-items-outputs' },
                },
            },
            tags => ['category:action'],
        },
        raw => {
            summary => 'Show "raw" data',
            schema => ['bool'],
            description => <<'_',

When action=show-items-result, will print result as-is instead of dumping as
Perl.

_
        },
        test => {
            summary => 'Whether to test participant code once first before benchmarking',
            schema => ['bool*'],
            description => <<'_',

By default, participant code is run once first for testing (e.g. whether it dies
or return the correct result) before benchmarking. If your code runs for many
seconds, you might want to skip this test and set this to 0.

_
        },
        module_startup => {
            schema => ['bool*', is=>1],
            summary => 'Benchmark module startup overhead instead of normal benchmark',
            tags => ['category:action'],
        },
        detail => {
            schema => ['bool*'],
            cmdline_aliases => {l=>{}},
        },

        runner => {
            summary => 'Runner module to use',
            schema => ['str*', {
                in=>[
                    'Benchmark::Dumb',
                    'Benchmark',
                    'Benchmark::Dumb::SimpleTime',
                ],
            }],
            description => <<'_',

The default is `Benchmark::Dumb` which should be good enough for most cases.

You can use `Benchmark` runner (`Benchmark.pm`) if you are accustomed to it and
want to see its output format.

You can use `Benchmark::Dumb::SimpleTime` if your participant code runs for at
least a few to many seconds and you want to use very few iterations (like 1 or
2) because you don't want to wait for too long.

_
        },

        include_modules => {
            'x.name.is_plural' => 1,
            summary => 'Only include modules specified in this list',
            'summary.alt.plurality.singular' => 'Add module to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant_module(@_, apply_filters=>0) },
            completion => sub { _complete_participant_modules_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_module_pattern => {
            summary => 'Only include modules matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },
        exclude_modules => {
            'x.name.is_plural' => 1,
            summary => 'Exclude modules specified in this list',
            'summary.alt.plurality.singular' => 'Add module to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant_module(@_, apply_filters=>0) },
            completion => sub { _complete_participant_modules_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_module_pattern => {
            summary => 'Exclude module(s) matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },

        exclude_xs_modules => {
            summary => 'Exclude XS modules',
            schema => ['bool*', is=>1],
            cmdline_aliases => { noxs => {is_flag=>1} },
            tags => ['category:filtering'],
        },
        exclude_pp_modules => {
            summary => 'Exclude PP (pure-Perl) modules',
            schema => ['bool*', is=>1],
            cmdline_aliases => { nopp => {is_flag=>1} },
            tags => ['category:filtering'],
        },

        include_functions => {
            'x.name.is_plural' => 1,
            summary => 'Only include functions specified in this list',
            'summary.alt.plurality.singular' => 'Add function to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_function(@_, apply_filters=>0) },
            completion => sub { _complete_functions_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_function_pattern => {
            summary => 'Only include functions matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },
        exclude_functions => {
            'x.name.is_plural' => 1,
            summary => 'Exclude functions specified in this list',
            'summary.alt.plurality.singular' => 'Add function to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_function(@_, apply_filters=>0) },
            completion => sub { _complete_functions_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_function_pattern => {
            summary => 'Exclude function(s) matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },

        include_participants => {
            'x.name.is_plural' => 1,
            summary => 'Only include participants whose seq/name matches this',
            'summary.alt.plurality.singular' => 'Add participant (by name/seq) to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant(@_, apply_filters=>0) },
            completion => sub { _complete_participants_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_participant_names => {
            'x.name.is_plural' => 1,
            summary => 'Only include participants whose name matches this',
            'summary.alt.plurality.singular' => 'Add participant (by name) to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant(@_, apply_filters=>0, seq=>0) },
            completion => sub { _complete_participant_names_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_participant_seqs => {
            'x.name.is_plural' => 1,
            summary => 'Only include participants whose sequence number matches this',
            'summary.alt.plurality.singular' => 'Add participant (by sequence number) to include list',
            schema => ['array*', of=>['int*', min=>0], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant(@_, apply_filters=>0, name=>0) },
            completion => sub { _complete_participant_seqs_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_participant_pattern => {
            summary => 'Only include participants matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },
        include_participant_tags => {
            'x.name.is_plural' => 1,
            summary => 'Only include participants whose tag matches this',
            'summary.alt.plurality.singular' => 'Add a tag to participants include tag list',
            description => <<'_',

You can specify `A & B` to include participants that have _both_ tags A and B.

_
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant_tag(@_, apply_filters=>0) },
            completion => sub { _complete_participant_tags_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_participants => {
            'x.name.is_plural' => 1,
            summary => 'Exclude participants whose seq/name matches this',
            'summary.alt.plurality.singular' => 'Add participant (by name/seq) to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant(@_, apply_filters=>0) },
            completion => sub { _complete_participants_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_participant_names => {
            'x.name.is_plural' => 1,
            summary => 'Exclude participants whose name matches this',
            'summary.alt.plurality.singular' => 'Add participant (by name) to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant(@_, apply_filters=>0, seq=>0) },
            completion => sub { _complete_participant_names_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_participant_seqs => {
            'x.name.is_plural' => 1,
            summary => 'Exclude participants whose sequence number matches this',
            'summary.alt.plurality.singular' => 'Add participant (by sequence number) to exclude list',
            schema => ['array*', of=>['int*', min=>0], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant(@_, apply_filters=>0, name=>0) },
            completion => sub { _complete_participant_seqs_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_participant_pattern => {
            summary => 'Exclude participants matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },
        exclude_participant_tags => {
            'x.name.is_plural' => 1,
            summary => 'Exclude participants whose tag matches this',
            'summary.alt.plurality.singular' => 'Add a tag to participants exclude tag list',
            description => <<'_',

You can specify `A & B` to exclude participants that have _both_ tags A and B.

_
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_participant_tag(@_, apply_filters=>0) },
            completion => sub { _complete_participant_tags_comma_sep(@_) },
            tags => ['category:filtering'],
        },

        include_items => {
            'x.name.is_plural' => 1,
            summary => 'Only include items whose seq/name matches this',
            'summary.alt.plurality.singular' => 'Add item (by name/seq) to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_item(@_, apply_filters=>0) },
            completion => sub { _complete_items_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_item_names => {
            'x.name.is_plural' => 1,
            summary => 'Only include items whose name matches this',
            'summary.alt.plurality.singular' => 'Add item (by name) to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_item(@_, apply_filters=>0, seq=>0) },
            completion => sub { _complete_item_names_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_item_seqs => {
            'x.name.is_plural' => 1,
            summary => 'Only include items whose sequence number matches this',
            'summary.alt.plurality.singular' => 'Add item (by sequence number) to include list',
            schema => ['array*', of=>['int*', min=>0], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_item(@_, apply_filters=>0, name=>0) },
            completion => sub { _complete_item_seqs_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_item_pattern => {
            summary => 'Only include items matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },
        exclude_items => {
            'x.name.is_plural' => 1,
            summary => 'Exclude items whose seq/name matches this',
            'summary.alt.plurality.singular' => 'Add item (by name/seq) to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_item(@_, apply_filters=>0) },
            completion => sub { _complete_items_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_item_names => {
            'x.name.is_plural' => 1,
            summary => 'Exclude items whose name matches this',
            'summary.alt.plurality.singular' => 'Add item (by name) to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_item(@_, apply_filters=>0, seq=>0) },
            completion => sub { _complete_item_names_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_item_seqs => {
            'x.name.is_plural' => 1,
            summary => 'Exclude items whose sequence number matches this',
            'summary.alt.plurality.singular' => 'Add item (by sequence number) to exclude list',
            schema => ['array*', of=>['int*', min=>0], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_item(@_, apply_filters=>0, name=>0) },
            completion => sub { _complete_item_seqs_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_item_pattern => {
            summary => 'Exclude items matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },

        include_datasets => {
            'x.name.is_plural' => 1,
            summary => 'Only include datasets whose seq/name matches this',
            'summary.alt.plurality.singular' => 'Add dataset (by name/seq) to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_dataset(@_, apply_filters=>0) },
            completion => sub { _complete_datasets_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_dataset_names => {
            'x.name.is_plural' => 1,
            summary => 'Only include datasets whose name matches this',
            'summary.alt.plurality.singular' => 'Add dataset (by name) to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_dataset(@_, apply_filters=>0) },
            completion => sub { _complete_dataset_names_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_dataset_seqs => {
            'x.name.is_plural' => 1,
            summary => 'Only include datasets whose sequence number matches this',
            'summary.alt.plurality.singular' => 'Add dataset (by sequence number) to include list',
            schema => ['array*', of=>['int*', min=>0], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_dataset(@_, apply_filters=>0, name=>0) },
            completion => sub { _complete_dataset_seqs_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        include_dataset_pattern => {
            summary => 'Only include datasets matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },
        exclude_datasets => {
            'x.name.is_plural' => 1,
            summary => 'Exclude datasets whose seq/name matches this',
            'summary.alt.plurality.singular' => 'Add dataset (by name/seq) to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_dataset(@_, apply_filters=>0) },
            completion => sub { _complete_datasets_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_dataset_names => {
            'x.name.is_plural' => 1,
            summary => 'Exclude datasets whose name matches this',
            'summary.alt.plurality.singular' => 'Add dataset (by name) to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_dataset(@_, apply_filters=>0) },
            completion => sub { _complete_dataset_names_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_dataset_seqs => {
            'x.name.is_plural' => 1,
            summary => 'Exclude datasets whose sequence number matches this',
            'summary.alt.plurality.singular' => 'Add dataset (by sequence number) to exclude list',
            schema => ['array*', of=>['int*', min=>0], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_dataset(@_, apply_filters=>0, name=>0) },
            completion => sub { _complete_dataset_seqs_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_dataset_pattern => {
            summary => 'Exclude datasets matching this regex pattern',
            schema => ['re*'],
            tags => ['category:filtering'],
        },
        include_dataset_tags => {
            'x.name.is_plural' => 1,
            summary => 'Only include datasets whose tag matches this',
            'summary.alt.plurality.singular' => 'Add a tag to dataset include tag list',
            description => <<'_',

You can specify `A & B` to include datasets that have _both_ tags A and B.

_
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_dataset_tag(@_, apply_filters=>0) },
            completion => sub { _complete_dataset_tags_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        exclude_dataset_tags => {
            'x.name.is_plural' => 1,
            summary => 'Exclude datasets whose tag matches this',
            'summary.alt.plurality.singular' => 'Add a tag to dataset exclude tag list',
            description => <<'_',

You can specify `A & B` to exclude datasets that have _both_ tags A and B.

_
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_dataset_tag(@_, apply_filters=>0) },
            completion => sub { _complete_dataset_tags_comma_sep(@_) },
            tags => ['category:filtering'],
        },
        multiperl => {
            summary => 'Benchmark against multiple perls',
            schema => ['bool'],
            default => 0,
            description => <<'_',

Requires <pm:App::perlbrew> to be installed. Will use installed perls from the
perlbrew installation. Each installed perl must have <pm:Bencher::Backend>
module installed (in addition to having all modules that you want to benchmark,
obviously).

By default, only perls having Bencher::Backend will be included. Use
`--include-perl` and `--exclude-perl` to include and exclude which perls you
want.

Also note that due to the way this is currently implemented, benchmark code that
contains closures (references to variables outside the code) won't work.

_
        },
        include_perls => {
            'x.name.is_plural' => 1,
            summary => 'Only include some perls',
            'summary.alt.plurality.singular' => 'Add specified perl to include list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_perl(@_) },
            tags => ['category:filtering'],
        },
        exclude_perls => {
            'x.name.is_plural' => 1,
            summary => 'Exclude some perls',
            'summary.alt.plurality.singular' => 'Add specified perl to exclude list',
            schema => ['array*', of=>['str*'], 'x.perl.coerce_rules' => ['str_comma_sep']],
            element_completion => sub { _complete_perl(@_) },
            tags => ['category:filtering'],
        },

        multimodver => {
            summary => 'Benchmark multiple module versions',
            schema => ['str*'],
            description => <<'_',

If set to a module name, will search for all (instead of the first occurrence)
of the module in `@INC`. Then will generate items for each version.

Currently only one module can be multi version.

_
            completion => sub { _complete_participant_module(@_, apply_filters=>0) },
        },
        include_path => {
            summary => 'Additional module search paths',
            'summary.alt.plurality.singular' => 'Add path to module search path',
            schema => ['array*', of=>['str*'],

                       # for now we disable this because: when doing completion
                       # we are not using validation/coercion from Data::Sah, so
                       # include_path will still be a string instead of array,
                       # and this breaks routines that expect this argument to
                       # be an array

                       #'x.perl.coerce_rules' => ['str_comma_sep'],
                   ],
            description => <<'_',

Used when searching for scenario module, or when in multimodver mode.

_
            cmdline_aliases => {I=>{}},
        },
        # XXX include-mod-version
        # XXX exclude-mod-version

        on_failure => {
            summary => "What to do when there is a failure",
            schema => ['str*', in=>[qw/die skip/]],
            description => <<'_',

For a command participant, failure means non-zero exit code. For a Perl-code
participant, failure means Perl code dies or (if expected result is specified)
the result is not equal to the expected result.

The default is "die". When set to "skip", will first run the code of each item
before benchmarking and trap command failure/Perl exception and if that happens,
will "skip" the item.

_
        },
        on_result_failure => {
            summary => "What to do when there is a result failure",
            schema => ['str*', in=>[qw/die skip warn/]],
            description => <<'_',

This is like `on_failure` except that it specifically refer to the failure of
item's result not being equal to expected result.

There is an extra choice of `warn` for this type of failure, which is to print a
warning to STDERR and continue.

_
        },

        sorts => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'sort',
            schema => ['array*', {
                of => ['str*'],
                min_len => 1,
                'x.perl.coerce_rules' => ['str_comma_sep'],
            }],
            default => ['-time'],
            element_completion => sub {
                require Complete::Util;

                my %args = @_;

                # XXX all result fields are okay
                my $elems = [map {($_,"-$_")}
                                 qw/participant rate time errors samples/];

                my $remaining = $_code_remaining->(
                    $args{parsed_opts}{'--sort'} // [],
                    $elems,
                );
                Complete::Util::complete_array_elem(
                    word => $args{word},
                    array => $remaining,
                );
            },
            completion => sub {
                require Complete::Util;
                my %args = @_;
                Complete::Util::complete_comma_sep(
                    word => $args{word},
                    # XXX all result fields are okay
                    elems => [map {($_,"-$_")}
                                  qw/participant rate time errors samples/],
                    remaining => $_code_remaining,
                );
            },
            tags => ['category:format'],
        },
        scientific_notation => {
            schema => ['bool', is=>1],
            tags => ['category:format'],
        },

        with_result_size => {
            summary => "Also return memory usage of each item code's result (return value)",
            schema => 'bool',
            description => <<'_',

Memory size is measured using <pm:Devel::Size>.

_
        },

        with_args_size => {
            summary => "Also return memory usage of item's arguments",
            schema => 'bool',
            description => <<'_',

Memory size is measured using <pm:Devel::Size>.

_
        },

        capture_stdout => {
            summary => 'Trap output to stdout',
            schema => 'bool',
        },
        capture_stderr => {
            summary => 'Trap output to stderr',
            schema => 'bool',
        },

        with_process_size => {
            summary => "Also return process size information for each item",
            schema => 'bool',
            description => <<'_',

This is done by dumping each item's code into a temporary file and running the
file with a new perl interpreter process and measuring the process size at the
end (so it does not need to load Bencher itself or the other items). Currently
only works on Linux because process size information is retrieved from
`/proc/PID/smaps`. Not all code can work, e.g. if the code tries to access a
closure or outside data or extra modules (modules not specified in the
participant or loaded by the code itself). Usually does not make sense to use
this on external command participants.

_
        },

        return_meta => {
            summary => 'Whether to return extra metadata',
            description => <<'_',

When set to true, will return extra metadata such as platform information, CPU
information, system load before & after the benchmark, system time, and so on.
This is put in result metadata under `func.*` keys.

The default is to true (return extra metadata) unless when run as CLI and format
is text (where the extra metadata is not shown).

_
            schema => ['bool'],
            tags => ['category:result'],
        },

        save_result => {
            summary => 'Whether to save benchmark result to file',
            schema => 'bool*',
            description => <<'_',

Will also be turned on automatically if `BENCHER_RESULT_DIR` environment
variabl is defined.

When this is turned on, will save a JSON file after benchmark, containing the
result along with metadata. The directory of the JSON file will be determined
from the `results_dir` option, while the filename from the `results_filename`
option.

_
        },

        result_dir => {
            summary => 'Directory to use when saving benchmark result',
            schema => 'str*',
            'x.schema.entity' => 'dirname',
            tags => ['category:result'],
            description => <<'_',

Default is from `BENCHER_RESULT_DIR` environment variable, or the home
directory.

_
        },
        result_filename => {
            summary => 'Filename to use when saving benchmark result',
            schema => 'str*',
            'x.schema.entity' => 'filename',
            tags => ['category:result'],
            description => <<'_',

Default is:

    <NAME>.<yyyy-dd-dd-"T"HH-MM-SS>.json

or, when running in module startup mode:

    <NAME>.module_startup.<yyyy-dd-dd-"T"HH-MM-SS>.json

where <NAME> is scenario module name, or `NO_MODULE` if scenario is not from a
module. The `::` (double colon in the module name will be replaced with `-`
(dash).

_
        },

        note => {
            summary => 'Put additional note in the result',
            schema => ['str*'],
            tags => ['category:result'],
        },
    },
};
sub bencher {
    my %args = @_;

    my $action = $args{action};
    my $envres;

    my $is_cli_and_can_format_as_table;
    my $is_cli_and_text_format;
    {
        my $r = $args{-cmdline_r};
        $is_cli_and_can_format_as_table = $r &&
            ($r->{format} // 'text') =~ m!text|html!;
        $is_cli_and_text_format = $r &&
            ($r->{format} // 'text') =~ m!text!;
    }

    if ($action eq 'list-perls') {
        my @perls = _list_perls();
        my @res;
        for my $perl (@perls) {
            if ($args{detail}) {
                push @res, {
                    name            => $perl->{name},
                    version         => $perl->{version},
                    has_bencher     => $perl->{has_bencher},
                    bencher_version => $perl->{bencher_version},
                };
            } else {
                push @res, $perl->{name};
            }
        }
        my %resmeta;
        $resmeta{'table.fields'} = [
            'name',
            'version',
            'has_bencher',
            'bencher_version',
        ] if $args{detail};
        $envres =
            [200, "OK", \@res, \%resmeta];
        goto L_END;
    }

    if ($action eq 'list-scenario-modules') {
        require PERLANCAR::Module::List;
        local @INC = @INC;
        unshift @INC, $_ for @{ $args{include_path} // [] };
        my $mods = PERLANCAR::Module::List::list_modules(
            'Bencher::Scenario::', {list_modules=>1, recurse=>1});
        $envres =
            [200, "OK",
             [map {s/^Bencher::Scenario:://; $_} sort keys %$mods]];
        goto L_END;
    }

    my $unparsed = _get_scenario(parent_args=>\%args);

    if ($action eq 'show-scenario') {
        $envres = [200, "OK", $unparsed];
        goto L_END;
    }

    my $stash = {};

    my $aibdf;
    $aibdf = 0 if $action =~ /\A(list-(datasets|participants))\z/;

    if ($unparsed->{before_parse_scenario}) {
        $log->infof("Executing before_parse_scenario hook ...");
        $unparsed->{before_parse_scenario}->(
            hook_name => 'before_parse_scenario',
            scenario  => $unparsed,
            stash     => $stash,
        );
    }

    my $parsed = _parse_scenario(
        scenario=>$unparsed,
        parent_args=>\%args,
        apply_include_by_default_filter => $aibdf,
        stash => $stash,
    );

    if ($parsed->{after_parse_scenario}) {
        $log->infof("Executing after_parse_scenario hook ...");
        $parsed->{after_parse_scenario}->(
            hook_name => 'after_parse_scenario',
            scenario  => $parsed,
            stash     => $stash,
        );
    }

    my $module_startup = $args{module_startup} // $parsed->{module_startup};

    # DEPRECATED/now undocumented, see before_parse_datasets for more
    # appropriate hook
    if ($parsed->{before_list_datasets}) {
        $log->infof("Executing before_list_datasets hook ...");
        $parsed->{before_list_datasets}->(
            hook_name => 'before_list_datasets',
            scenario  => $parsed,
            stash     => $stash,
        );
    }

    if ($action eq 'list-datasets') {
        unless ($parsed->{datasets}) {
            $envres = [200, "OK", undef];
            goto L_END;
        }
        my @res;
        my $has_summary = 0;
        for my $ds (@{ $parsed->{datasets} }) {
            if ($args{detail}) {
                my $rec = {
                    seq      => $ds->{seq},
                    include_by_default => $ds->{include_by_default},
                    name     => $ds->{name},
                    tags     => join(", ", @{ $ds->{tags} // []}),
                };
                if (defined $ds->{summary}) {
                    $has_summary = 1;
                    $rec->{summary} = $ds->{summary};
                }
                push @res, $rec;
            } else {
                push @res, $ds->{name};
            }
        }
        my %resmeta;
        $resmeta{'table.fields'} = [
            'seq',
            'include_by_default',
            'name',
            ('summary') x $has_summary,
            'tags',
        ]
            if $args{detail};
        $envres = [200, "OK", \@res, \%resmeta];
        goto L_END;
    }

    # DEPRECATED/now undocumented, see before_parse_participants for more
    # appropriate hook
    if ($parsed->{before_list_participants}) {
        $log->infof("Executing before_list_participants hook ...");
        $parsed->{before_list_participants}->(
            hook_name => 'before_list_participants',
            scenario  => $parsed,
            stash     => $stash,
        );
    }

    if ($action eq 'list-participant-modules') {
        my @modules = _get_participant_modules($parsed);
        $envres = [200, "OK", \@modules];
        goto L_END;
    }

    if ($action eq 'list-participants') {
        my @res;
        my $has_summary = 0;
        for my $p (@{ $parsed->{participants} }) {

            my $cmdline;
            if ($p->{cmdline_template}) {
                $cmdline = "#TEMPLATE: ".
                    (ref($p->{cmdline_template}) eq 'ARRAY' ? join(" ", @{$p->{cmdline_template}}) : $p->{cmdline_template});
            } elsif ($p->{cmdline}) {
                $cmdline =
                    (ref($p->{cmdline}) eq 'ARRAY' ? join(" ", @{$p->{cmdline}}) : $p->{cmdline});
            } elsif ($p->{perl_cmdline_template}) {
                $cmdline = "#TEMPLATE: #perl ".
                    (ref($p->{perl_cmdline_template}) eq 'ARRAY' ? join(" ", @{$p->{perl_cmdline_template}}) : $p->{perl_cmdline_template});
            } elsif ($p->{cmdline}) {
                $cmdline = "#perl ".
                    (ref($p->{perl_cmdline}) eq 'ARRAY' ? join(" ", @{$p->{perl_cmdline}}) : $p->{perl_cmdline});
            }
            my $rec = {
                seq      => $p->{seq},
                type     => $p->{type},
                include_by_default => $p->{include_by_default},
                name     => $p->{name} // $p->{_name},
                function => $p->{function},
                module   => $p->{modules} ? join("+", @{$p->{modules}}) : $p->{module},
                cmdline  => $cmdline,
                tags     => join(", ", @{$p->{tags} // []}),
            };
            if (defined $p->{summary}) {
                $has_summary = 1;
                $rec->{summary} = $p->{summary};
            }
            push @res, $rec;
        }

        unless ($args{detail}) {
            @res = map {$_->{name}} @res;
        }
        my %resmeta;
        $resmeta{'table.fields'} = [
            'seq',
            'type',
            'include_by_default',
            'name',
            ('summary') x $has_summary,
            'module',
            'function',
            'cmdline',
            'tags',
        ]
            if $args{detail};
        $envres = [200, "OK", \@res, \%resmeta];
        goto L_END;
    }

    my $items;
    my $gen_items_res;
  GEN_ITEMS:
    {
        if ($parsed->{items}) {
            $items = $parsed->{items};
            last;
        }
        if ($parsed->{before_gen_items}) {
            $log->infof("Executing before_gen_items hook ...");
            $parsed->{before_gen_items}->(
                hook_name => 'before_gen_items',
                scenario  => $parsed,
                stash     => $stash,
            );
        }

        $gen_items_res = _gen_items(scenario=>$parsed, parent_args=>\%args);
        unless ($gen_items_res->[0] == 200) {
            $envres = $gen_items_res;
            goto L_END;
        }
        $items = $gen_items_res->[2];
    }

    if ($action eq 'list-items') {
        my @rows;
        my @columns;
        for my $it0 (@$items) {
            my $it = {%$it0};
            delete $it->{$_} for grep {/^_/} keys %$it;
            if (!@columns) {
                push @columns, sort keys %$it;
            }
            push @rows, $it;
        }
        unless ($args{detail}) {
            for (@rows) {
                $_ = $_->{seq};
            }
        }
        my %resmeta;
        $resmeta{'table.fields'} = \@columns if $args{detail};
        $envres = [200, "OK", \@rows, \%resmeta];
        goto L_END;
    }

    if ($action eq 'show-items-codes') {
        $envres = [200, "OK", join(
            "",
            map {(
                "#", _item_label(item=>$_, bencher_args=>\%args), ":\n",
                $_->{_code_str} // dmp($_->{_code}),
                "\n\n",
            )} @$items
        )];
        goto L_END;
    }

    if ($action =~ /\A(show-items-results-sizes|show-items-results|show-items-outputs|bench)\z/) {
        require Capture::Tiny;
        require Module::Load;
        require Time::HiRes;

        my $participants = $parsed->{participants};
        my $datasets = $parsed->{datasets};
        $envres = [200, "OK", [], {}];

        $envres->[3]{'func.permute'} = $gen_items_res->[3]{'func.permute'};

        my $result_dir = $args{result_dir} // $ENV{BENCHER_RESULT_DIR};
        my $save_result = $args{save_result} // defined($result_dir);
        $result_dir //= $ENV{HOME};
        my $return_meta = $args{return_meta} // ($save_result ? 1:undef) // 1;
        my $capture_stdout = $args{capture_stdout} // $parsed->{capture_stdout} // 0;
        $capture_stdout = 1 if $action eq 'show-items-outputs';
        my $capture_stderr = $args{capture_stderr} // $parsed->{capture_stderr} // 0;
        $capture_stderr = 1 if $action eq 'show-items-outputs';

        $envres->[3]{'func.module_startup'} = $module_startup;
        $envres->[3]{'func.module_versions'}{perl} = "$^V" if $return_meta;
        {
            no strict 'refs';
            $envres->[3]{'func.module_versions'}{__PACKAGE__} = ${__PACKAGE__.'::VERSION'} if $return_meta;
        }

        my $code_load = sub {
            no strict 'refs';
            my ($mod, $optional) = @_;
            $log->tracef("Loading module: %s", $mod);
            if ($optional) {
                eval { Module::Load::load($mod) };
                $log->infof("Failed loading optional module %s: %s, skipped",
                            $mod, $@);
                return;
            } else {
                Module::Load::load($mod);
            }
            if ($return_meta) {
                # we'll just use ${"$mod\::VERSION"} because we are already
                # loading the module
                $envres->[3]{'func.module_versions'}{$mod} =
                    ${"$mod\::VERSION"};
            }
        };

        my $runner = $args{runner} // $parsed->{runner} // 'Benchmark::Dumb';
        $code_load->($runner);

        $code_load->('Devel::Platform::Info') if $return_meta;
        $code_load->('Sys::Info')             if $return_meta;
        $code_load->('Sys::Load', 'optional') if $return_meta;

        # load all participant modules & helper modules
        {
            my %seen;
            my @modules = _get_participant_modules($parsed);
            my @helper_modules = _get_participant_helper_modules($parsed);
            for my $mod (@modules, @helper_modules) {
                $code_load->($mod);
            }
            for my $mod (keys %{$parsed->{modules}}) {
                next if $mod eq 'perl';
                $code_load->($mod);
            }
        }

        # loading extra modules
        $code_load->($_) for @{ $parsed->{extra_modules} // [] };

        if ($parsed->{before_bench}) {
            $log->infof("Executing before_bench hook ...");
            $parsed->{before_bench}->(
                hook_name => 'before_bench',
                scenario  => $parsed,
                stash     => $stash,
            );
        }

        my $with_process_size = $args{with_process_size} //
            $parsed->{with_process_size} //
            # turn on with_process_size by default if we are in module_startup
            # mode on linux
            ($module_startup && $^O =~ /linux/);

        # test code first
        my $test = $args{test} // $parsed->{test} // 1;
        my $on_failure = $args{on_failure} // $parsed->{on_failure} // 'die';
        my $on_result_failure = $args{on_result_failure} //
            $parsed->{on_result_failure} // $on_failure;
        my $with_args_size = $args{with_args_size} //
            $parsed->{with_args_size} // 0;
        my $with_result_size = $args{with_result_size} //
            $parsed->{with_result_size} // 0;
        $with_args_size   = 0 if $module_startup;
        $with_result_size = 1 if $action eq 'show-items-results-sizes';
        $with_result_size = 0 if $module_startup;
        {
            last if $args{multiperl} || $args{multimodver} || !$test;
            my $fitems = [];
            for my $it (@$items) {
                if ($parsed->{before_test_item}) {
                    $parsed->{before_test_item}->(
                        hook_name => 'before_test_item',
                        scenario  => $parsed,
                        stash     => $stash,
                        item      => $it,
                    );
                }
                $log->tracef("Testing code for item #%d (%s) ...",
                             $it->{seq}, $it->{_name});

                my $participant = _find_record_by_seq($participants, $it->{_permute}{participant});

                eval {
                    my $result_is_list = $participant->{result_is_list} // 0;
                    if ($capture_stdout && $capture_stderr) {
                        my ($stdout, $stderr, @res) = &Capture::Tiny::capture($it->{_code});
                        $it->{_stdout} = $stdout;
                        $it->{_stderr} = $stderr;
                        $it->{_result} = $result_is_list ? \@res : $res[0];
                    } elsif ($capture_stdout) {
                        my ($stdout, @res) = &Capture::Tiny::capture_stdout($it->{_code});
                        $it->{_stdout} = $stdout;
                        $it->{_result} = $result_is_list ? \@res : $res[0];
                    } elsif ($capture_stderr) {
                        my ($stderr, @res) = &Capture::Tiny::capture_stderr($it->{_code});
                        $it->{_stderr} = $stderr;
                        $it->{_result} = $result_is_list ? \@res : $res[0];
                    } else {
                        $it->{_result} = $result_is_list ?
                            [$it->{_code}->()] : $it->{_code}->();
                    }
                };
                my $err = $@;

                if ($parsed->{after_test_item}) {
                    $err = $parsed->{after_test_item}->(
                        hook_name => 'after_test_item',
                        scenario  => $parsed,
                        stash     => $stash,
                        item      => $it,
                    );
                }

                if ($err) {
                    if ($on_failure eq 'skip' || $action eq 'show-items-results') {
                        warn "Skipping item #$it->{seq} ($it->{_name}) ".
                            "due to failure: $err\n";
                        next;
                    } else {
                        die "Item #$it->{seq} ($it->{_name}) fails: $err\n";
                    }
                }

                $err = "";
                # check against expected result, if specified
                {
                    my $dmp_exp_result;
                    if (exists $it->{_permute}{dataset}) {
                        my $dataset = _find_record_by_seq($datasets, $it->{_permute}{dataset});
                        if (exists $dataset->{result}) {
                            $dmp_exp_result = dmp($dataset->{result});
                            goto CHK;
                        }
                    }
                    if (exists $parsed->{result}) {
                        $dmp_exp_result = dmp($parsed->{result});
                        goto CHK;
                    }
                    last;
                  CHK:
                    my $dmp_result = dmp($it->{_result});
                    if ($dmp_result ne $dmp_exp_result) {
                        $err = "Result ($dmp_result) is not as expected ($dmp_exp_result)";
                    }
                }

                if ($err) {
                    if ($on_result_failure eq 'skip') {
                        warn "Skipping item #$it->{seq} ($it->{_name}) ".
                            "due to failure (2): $err\n";
                        next;
                    } elsif ($on_result_failure eq 'warn' || $action eq 'show-items-results') {
                        warn "Warning: item #$it->{seq} ($it->{_name}) ".
                            "has failure (2): $err\n";
                    } else {
                        die "Item #$it->{seq} ($it->{_name}) fails (2): $err\n";
                    }
                }
                $it->{_code_error} = $err;

                {
                    last unless $with_args_size;
                    last unless $it->{_template_vars};
                    require Devel::Size;
                    for my $arg (keys %{ $it->{_template_vars} }) {
                        $it->{_arg_sizes}{$arg} = Devel::Size::total_size(
                            $it->{_template_vars}{$arg});
                    }
                }

                if ($with_result_size) {
                    require Devel::Size;
                    $it->{_result_size} = Devel::Size::total_size($it->{_result});
                }

                if ($with_process_size) {
                    _get_process_size($parsed, $it);
                }

                push @$fitems, $it;
            }
            $items = $fitems;
        }

        if ($action eq 'show-items-results') {
            die "show-items-results currently not supported on multiperl or multimodver\n" if $args{multiperl} || $args{multimodver};
            if ($is_cli_and_text_format) {
                require Data::Dump;
                $envres->[3]{'cmdline.skip_format'} = 1;
                $envres->[2] = join(
                    "",
                    map {(
                        "#", _item_label(item=>$_, bencher_args=>\%args), ":\n",
                        $args{raw} ? $_->{_result} : Data::Dump::dump($_->{_result}),
                        "\n\n",
                    )} @$items
                );
            } else {
                $envres->[2] = [map {$_->{_result}} @$items];
            }
            goto RETURN_RESULT;
        }

        if ($action eq 'show-items-results-sizes') {
            die "show-items-results currently not supported on multiperl or multimodver\n" if $args{multiperl} || $args{multimodver};
            if ($is_cli_and_text_format) {
                $envres->[3]{'cmdline.skip_format'} = 1;
                $envres->[2] = join(
                    "",
                    map {(
                        "#", _item_label(item=>$_, bencher_args=>\%args), ":\n",
                        $_->{_result_size},
                        "\n\n",
                    )} @$items
                );
            } else {
                $envres->[2] = [map {$_->{_result_size}} @$items];
            }
            goto RETURN_RESULT;
        }

        if ($action eq 'show-items-outputs') {
            die "show-items-outputs currently not supported on multiperl or multimodver\n" if $args{multiperl} || $args{multimodver};
            if ($is_cli_and_text_format) {
                $envres->[3]{'cmdline.skip_format'} = 1;
                $envres->[2] = join(
                    "",
                    map {(
                        "#", _item_label(item=>$_, bencher_args=>\%args), " stdout (", length($_->{_stdout} // ''), " bytes):\n",
                        ($_->{_stdout} // ''),
                        "\n\n",
                        "#", _item_label(item=>$_, bencher_args=>\%args), " stderr (", length($_->{_stderr} // ''), " bytes):\n",
                        ($_->{_stderr} // ''),
                        "\n\n",
                    )} @$items
                );
            } else {
                $envres->[2] = [map {$_->{_result_size}} @$items];
            }
            goto RETURN_RESULT;
        }

        # at this point, action = bench

        my $precision;
        if ($runner eq 'Benchmark') {
            $precision = $args{precision} // -0.5;
            if (defined $args{precision_limit}) {
                if ($precision < 0) {
                    if ($precision < $args{precision_limit}) {
                        $precision = $args{precision_limit};
                    }
                } else {
                    if ($precision > $args{precision_limit}) {
                        $precision = $args{precision_limit};
                    }
                }
            }
        } elsif ($runner eq 'Benchmark::Dumb::SimpleTime') {
            $precision = $args{precision} // 1;
            return [400, "When running with runner '$runner', precision must be an integer >= 1"]
                unless $precision =~ /\A[1-9][0-9]*\z/;
            if (defined $args{precision_limit}) {
                return [400, "When running with runner '$runner', precision_limit must be an integer >= 1"]
                    unless $args{precision_limit} =~ /\A[1-9][0-9]*\z/;
                if ($precision > $args{precision_limit}) {
                    $precision = $args{precision_limit};
                }
            }
        } else {
            $precision = $args{precision} //
                $parsed->{precision} // $parsed->{default_precision} // 0;
            if (defined($args{precision_limit}) && $precision < $args{precision_limit}) {
                $precision = $args{precision_limit};
            }
        }

        if ($runner eq 'Benchmark') {
            die "Bench with Benchmark.pm currently does not support on multiperl or multimodver\n" if $args{multiperl} || $args{multimodver};
            my %codes;
            my %legends;
            for my $it (@$items) {
                my $key = $it->{_name};
                if (!length($key)) {
                    $key = $it->{seq};
                }
                if (exists $codes{$key}) {
                    $key .= " #$it->{seq}";
                }
                $codes{$key} = $it->{_code};
                $legends{$key} = join(
                    " ", map {"$_=$it->{$_}"}
                        grep { !/^_/ }
                            sort keys %$it
                        );
            }
            my ($stdout, @res) = &Capture::Tiny::capture_stdout(
                sub {
                    Benchmark::cmpthese($precision, \%codes);
                    print "\n";
                    print "Legends:\n";
                    for (sort keys %legends) {
                        print "  ", $_, ": ", $legends{$_}, "\n";
                    }
                });
            $envres->[3]{'cmdline.skip_format'} = 1;
            $envres->[2] = $stdout;
            goto RETURN_RESULT;
        }

        my $time_start = Time::HiRes::time();
        if ($return_meta) {
            $envres->[3]{'func.bencher_version'} = $Bencher::VERSION;
            $envres->[3]{'func.bencher_args'} = {
                map {$_=>$args{$_}} grep {!/\A-/} keys %args};
            if ($args{scenario_file}) {
                $envres->[3]{'func.scenario_file'} = $args{scenario_file};
                my @st = stat($args{scenario_file});
                $envres->[3]{'func.scenario_file_mtime'} = $st[9];
                my $digests = _digest($args{scenario_file});
                $envres->[3]{'func.scenario_file_md5sum'} = $digests->{md5};
                $envres->[3]{'func.scenario_file_sha1sum'} = $digests->{sha1};
                $envres->[3]{'func.scenario_file_sha256sum'} = $digests->{sha256};
            } elsif (my $mod = $args{scenario_module}) {
                $mod = "Bencher::Scenario::$mod";
                no strict 'refs';
                $envres->[3]{'func.scenario_module'} = $mod;
                (my $mod_pm = "$mod.pm") =~ s!::!/!g;
                $INC{$mod_pm} or die "BUG: Can't find '$mod_pm' in \%INC";
                my @st = stat($INC{$mod_pm});
                $envres->[3]{'func.scenario_module_mtime'} = $st[9];
                my $digests = _digest($INC{$mod_pm});
                $envres->[3]{'func.scenario_module_md5sum'} = $digests->{md5};
                $envres->[3]{'func.scenario_module_sha1sum'} = $digests->{sha1};
                $envres->[3]{'func.scenario_module_sha256sum'} = $digests->{sha256};
                $envres->[3]{'func.module_versions'}{$mod} =
                    ${"$mod\::VERSION"};
            }
            $envres->[3]{'func.sysload_before'} = [Sys::Load::getload()]
                if $INC{"System/Load.pm"};
            $envres->[3]{'func.time_start'} = $time_start;
        }

        $envres->[3]{'func.precision'} = $precision if $return_meta;

        if ($parsed->{env_hashes}) {
            require Data::Clone;
            $envres->[3]{'func.scenario_env_hashes'} =
                Data::Clone::clone($parsed->{env_hashes});
        }

        $log->tracef("Running benchmark (precision=%g) ...", $precision);

        my @columns       = (qw/seq participant dataset/);
        my @column_aligns = ('right', 'left', 'left');
        my @rows;
        my %arg_size_columns;
        if ($args{multiperl} || $args{multimodver}) {
            require Data::Clone;
            require Devel::Size;
            my %perl_exes;
            my %perl_opts;
            for my $it (@$items) {
                $perl_exes{$it->{perl}} = $it->{_perl_exe};
                $perl_opts{$it->{modver}} = $it->{_perl_opts} if defined $it->{modver};
            }
            if (!keys(%perl_opts)) {
                $perl_opts{""} = [];
            }

            my $sc = Data::Clone::clone($parsed);
            for (keys %$sc) { delete $sc->{$_} if /^(before|after)_/ } # remove all hooks

            my %item_mems; # key = item seq
            for my $perl (sort keys %perl_exes) {
                for my $modver (sort keys %perl_opts) {
                    my $scd_path = _get_tempfile_path("scenario-$perl");
                    $sc->{items} = [];
                    for my $it (@$items) {
                        next unless $it->{perl} eq $perl;
                        next unless !length($it->{modver}) ||
                            $it->{modver} eq $modver;
                        next if $item_mems{$it->{seq}}++; # avoid duplicate item
                        push @{$sc->{items}}, $it;
                    }
                    #use DD; dd {perl=>$perl, modver=>$modver, items=>$sc->{items}};
                    $log->debugf("Creating scenario dump file for %s (modver %s) at %s", $perl, $modver, $scd_path);
                    open my($fh), ">", $scd_path or die "Can't open file $scd_path: $!";
                    print $fh dmp($sc), ";\n";
                    close $fh;
                    my $res_path = _get_tempfile_path("benchresult-$perl");
                    my $cmd = join(
                        " ",
                        $perl_exes{$perl},
                        "-MBencher::Backend",
                        "-MData::Dmp",
                        @{ $perl_opts{$modver} // [] },
                        "-e'print dmp(Bencher::Backend::bencher(action=>q[bench], runner=>q[$runner], precision=>$precision, scenario_file=>q[$scd_path], with_args_size=>q[$with_args_size], with_result_size=>q[$with_result_size], return_meta=>0, capture_stdout=>$capture_stdout, capture_stderr=>$capture_stderr))' > '$res_path'",
                    );
                    $log->debugf("Running %s ...", $cmd);
                    system $cmd;
                    die "Failed running bencher for perl $perl (1)" if $?;
                    my $res = do $res_path;
                    die "Failed running bencher for perl $perl (2): can't parse result: $@" if $@;
                    die "Failed running bencher for perl $perl (3): result not an enveloped result" if ref($res) ne 'ARRAY';
                    die "Failed running bencher for perl $perl (4): $res->[0] - $res->[1]" if $res->[0] != 200;

                    for my $row (@{ $res->[2] }) {
                        $row->{perl} = $perl;
                        unless (grep {$_ eq 'perl'} @columns) {
                            push @columns,        "perl";
                            push @column_aligns, 'left';
                        }
                        if (length $modver) {
                            $row->{modver} = $modver;
                            unless (grep {$_ eq 'modver'} @columns) {
                                push @columns,       "modver";
                                push @column_aligns, "left";
                            }

                        }
                        push @rows, $row;
                    }
                } # for modver
            } # for perl
        } else {
            my $tres;
            my $doit = sub {
                no strict 'refs';
                $tres = &{"$runner\::_timethese_guts"}(
                    $precision,
                    {
                        map { $_->{seq} => $_->{_code} } @$items
                    },
                    "silent",
                );
            };

            if ($capture_stdout && $capture_stderr) {
                my ($stdout, $stderr, @res) = &Capture::Tiny::capture($doit);
            } elsif ($capture_stdout) {
                my ($stdout, @res) = &Capture::Tiny::capture_stdout($doit);
            } elsif ($capture_stderr) {
                my ($stdout, @res) = &Capture::Tiny::capture_stderr($doit);
            } else {
                $doit->();
            }

            if ($return_meta) {
                $envres->[3]{'func.time_end'} = Time::HiRes::time();
                $envres->[3]{'func.elapsed_time'} =
                    $envres->[3]{'func.time_end'} - $envres->[3]{'func.time_start'};
                $envres->[3]{'func.sysload_after'} = [Sys::Load::getload()]
                    if $INC{"System/Load.pm"};
            }

            for my $seq (sort {$a<=>$b} keys %$tres) {
                my $it = _find_record_by_seq($items, $seq);
                my $row = {
                    rate    => 1 / $tres->{$seq}{result}{num},
                    time    => $tres->{$seq}{result}{num},

                    ($with_args_size && $it->{_arg_sizes} ?
                        (map { my $c = "arg_${_}_size"; $arg_size_columns{$c}++; ($c => $it->{_arg_sizes}{$_})}
                         keys %{ $it->{_arg_sizes} }) : ()),

                    (result_size => $it->{_result_size}) x !!$with_result_size,

                    errors  => $tres->{$seq}{result}{errors}[0],
                    samples => $tres->{$seq}{result}{_dbr_nsamples},
                    notes   => $it->{_code_error},
                };

                for my $k (sort keys %$it) {
                    next unless $k =~ /^(seq|participant|p_.+|dataset|ds_.+|env_hash|perl|modver|item_.+|arg_.+|proc_.+)$/;
                    unless (grep {$k eq $_} @columns) {
                        push @columns,       $k;
                        push @column_aligns, 'left';
                    }
                    $row->{$k} = $it->{$k};
                }
                push @rows, $row;
            }
        }

        push @columns,       qw/seq rate time/;
        push @column_aligns, qw/number number number/;

        if ($with_args_size) {
            for my $col (keys %arg_size_columns) {
                push @columns,       $col;
                push @column_aligns, 'number';
            }
        }
        if ($with_result_size) {
            push @columns,       qw/result_size/;
            push @column_aligns, 'number';
        }
        # XXX proc_* fields should be put here
        push @columns      , qw/errors samples notes/;
        push @column_aligns, 'number', 'number', 'left';

        $envres->[2] = \@rows;
        $envres->[3]{'table.fields'}       = \@columns;
        $envres->[3]{'table.field_aligns'} = \@column_aligns;

        if (grep { $_->{time} && $_->{time} < 0 } @{ $envres->[2] }) {
            warn "There are some negative time in the results, you might ".
                "want to increase the precision";
        }

        if ($parsed->{after_bench}) {
            $log->infof("Executing after_bench hook ...");
            $parsed->{after_bench}->(
                hook_name => 'after_bench',
                scenario  => $parsed,
                stash     => $stash,
                result    => $envres,
            );
        }

        if ($return_meta) {
            $envres->[3]{'func.platform_info'} =
                Devel::Platform::Info->new->get_info;
            my $info = Sys::Info->new;
            $envres->[3]{'func.cpu_info'} = [$info->device('CPU')->identify];
            $envres->[3]{'func.note'} = $args{note} if exists $args{note};
        }

        # XXX separate to sub?
        if ($save_result) {
            require Data::Clean::JSON;
            require File::Slurper;
            require JSON::MaybeXS;
            require POSIX;

            my $result_filename = $args{result_filename} // do {
                my $mod = $args{scenario_module} // "NO_MODULE";
                $mod =~ s!(::|/)!-!g;
                sprintf(
                    "%s%s.%s.json",
                    $mod,
                    $module_startup ? ".module_startup" : "",
                    POSIX::strftime("%Y-%m-%dT%H-%M-%S",
                                    localtime($time_start)),
                );
            };
            my $path = "$result_dir/$result_filename";
            my $cleanser = Data::Clean::JSON->get_cleanser;
            $log->tracef("Saving result to %s ...", $path);
            File::Slurper::write_text(
                $path,
                JSON::MaybeXS::encode_json(
                    $cleanser->clone_and_clean($envres)
                )
            );
        }

      FORMAT:
        {
            last unless $is_cli_and_can_format_as_table;

            my $fres = format_result($envres, undef, {
                sort => $args{sorts},
                scientific_notation => $args{scientific_notation},
                render_as_text_table => $is_cli_and_text_format,
            });

            if ($is_cli_and_text_format) {
                my $num_cores = $envres->[3]{'func.cpu_info'}[0]{number_of_cores};
                my $platform_info = join(
                    "",
                    "Run on: ",
                    "perl ", _ver_or_vers($envres->[3]{'func.module_versions'}{perl}), ", ",
                    "CPU ", $envres->[3]{'func.cpu_info'}[0]{name}, " ($num_cores cores), ",
                    "OS ", $envres->[3]{'func.platform_info'}{osname}, " ", $envres->[3]{'func.platform_info'}{oslabel}, " version ", $envres->[3]{'func.platform_info'}{osvers}, ", ",
                    "OS kernel: ", $envres->[3]{'func.platform_info'}{kname}, " version ", $envres->[3]{'func.platform_info'}{kvers},
                );
                my $elapsed_info = join(
                    "",
                    "Elapsed time: ",
                    sprintf("%.2fs", $envres->[3]{'func.elapsed_time'}),
                );
                $fres = "# $platform_info\n# $elapsed_info\n$fres";
            }

            $envres = $is_cli_and_text_format ?
                [200, "OK", $fres, {"cmdline.skip_format" => 1}] : $fres;
        }

      RETURN_RESULT:

        goto L_END;

    }

    $envres = [400,"Unknown action"];

  L_END:

    if ($parsed->{before_return}) {
        $log->infof("Executing before_return hook ...");
        $parsed->{before_return}->(
            hook_name => 'before_return',
            scenario  => $parsed,
            stash     => $stash,
            result    => $envres,
        );
    }

    $envres;
}

$SPEC{parse_scenario} = {
    v => 1.1,
    summary => 'Parse scenario (fill in default values, etc)',
    args => {
        scenario => {
            summary => 'Unparsed scenario',
            schema  => 'hash*',
        },
    },
};
sub parse_scenario {
    my %args = @_;

    _parse_scenario(scenario => $args{scenario}, parent_args => {});
}

1;
# ABSTRACT: Backend for Bencher

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Backend - Backend for Bencher

=head1 VERSION

This document describes version 1.036 of Bencher::Backend (from Perl distribution Bencher-Backend), released on 2017-02-20.

=head1 FUNCTIONS


=head2 bencher

Usage:

 bencher(%args) -> [status, msg, result, meta]

A benchmark framework.

Bencher is a benchmark framework. You specify a I<scenario> (either in a
C<Bencher::Scenario::*> Perl module, or a Perl script, or over the command-line)
containing list of I<participants> and I<datasets>. Participants are codes or
commands to run, and datasets are arguments for the codes/commands. Bencher will
permute the participants and datasets into benchmark items, ready to run.

You can choose to include only some participants, datasets, or items. And there
are options to view your scenario's participants/datasets/items/mentioned
modules, run benchmark against multiple perls and module versions, and so on.
Bencher comes as a CLI script as well as Perl module. See the
L<Bencher::Backend> documentation for more information.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "bench")

=item * B<capture_stderr> => I<bool>

Trap output to stderr.

=item * B<capture_stdout> => I<bool>

Trap output to stdout.

=item * B<datasets> => I<array[hash]>

Add datasets.

=item * B<detail> => I<bool>

=item * B<env_hashes> => I<array[hash]>

Add environment hashes.

=item * B<exclude_dataset_names> => I<array[str]>

Exclude datasets whose name matches this.

=item * B<exclude_dataset_pattern> => I<re>

Exclude datasets matching this regex pattern.

=item * B<exclude_dataset_seqs> => I<array[int]>

Exclude datasets whose sequence number matches this.

=item * B<exclude_dataset_tags> => I<array[str]>

Exclude datasets whose tag matches this.

You can specify C<A & B> to exclude datasets that have I<both> tags A and B.

=item * B<exclude_datasets> => I<array[str]>

Exclude datasets whose seq/name matches this.

=item * B<exclude_function_pattern> => I<re>

Exclude function(s) matching this regex pattern.

=item * B<exclude_functions> => I<array[str]>

Exclude functions specified in this list.

=item * B<exclude_item_names> => I<array[str]>

Exclude items whose name matches this.

=item * B<exclude_item_pattern> => I<re>

Exclude items matching this regex pattern.

=item * B<exclude_item_seqs> => I<array[int]>

Exclude items whose sequence number matches this.

=item * B<exclude_items> => I<array[str]>

Exclude items whose seq/name matches this.

=item * B<exclude_module_pattern> => I<re>

Exclude module(s) matching this regex pattern.

=item * B<exclude_modules> => I<array[str]>

Exclude modules specified in this list.

=item * B<exclude_participant_names> => I<array[str]>

Exclude participants whose name matches this.

=item * B<exclude_participant_pattern> => I<re>

Exclude participants matching this regex pattern.

=item * B<exclude_participant_seqs> => I<array[int]>

Exclude participants whose sequence number matches this.

=item * B<exclude_participant_tags> => I<array[str]>

Exclude participants whose tag matches this.

You can specify C<A & B> to exclude participants that have I<both> tags A and B.

=item * B<exclude_participants> => I<array[str]>

Exclude participants whose seq/name matches this.

=item * B<exclude_perls> => I<array[str]>

Exclude some perls.

=item * B<exclude_pp_modules> => I<bool>

Exclude PP (pure-Perl) modules.

=item * B<exclude_xs_modules> => I<bool>

Exclude XS modules.

=item * B<include_dataset_names> => I<array[str]>

Only include datasets whose name matches this.

=item * B<include_dataset_pattern> => I<re>

Only include datasets matching this regex pattern.

=item * B<include_dataset_seqs> => I<array[int]>

Only include datasets whose sequence number matches this.

=item * B<include_dataset_tags> => I<array[str]>

Only include datasets whose tag matches this.

You can specify C<A & B> to include datasets that have I<both> tags A and B.

=item * B<include_datasets> => I<array[str]>

Only include datasets whose seq/name matches this.

=item * B<include_function_pattern> => I<re>

Only include functions matching this regex pattern.

=item * B<include_functions> => I<array[str]>

Only include functions specified in this list.

=item * B<include_item_names> => I<array[str]>

Only include items whose name matches this.

=item * B<include_item_pattern> => I<re>

Only include items matching this regex pattern.

=item * B<include_item_seqs> => I<array[int]>

Only include items whose sequence number matches this.

=item * B<include_items> => I<array[str]>

Only include items whose seq/name matches this.

=item * B<include_module_pattern> => I<re>

Only include modules matching this regex pattern.

=item * B<include_modules> => I<array[str]>

Only include modules specified in this list.

=item * B<include_participant_names> => I<array[str]>

Only include participants whose name matches this.

=item * B<include_participant_pattern> => I<re>

Only include participants matching this regex pattern.

=item * B<include_participant_seqs> => I<array[int]>

Only include participants whose sequence number matches this.

=item * B<include_participant_tags> => I<array[str]>

Only include participants whose tag matches this.

You can specify C<A & B> to include participants that have I<both> tags A and B.

=item * B<include_participants> => I<array[str]>

Only include participants whose seq/name matches this.

=item * B<include_path> => I<array[str]>

Additional module search paths.

Used when searching for scenario module, or when in multimodver mode.

=item * B<include_perls> => I<array[str]>

Only include some perls.

=item * B<module_startup> => I<bool>

Benchmark module startup overhead instead of normal benchmark.

=item * B<multimodver> => I<str>

Benchmark multiple module versions.

If set to a module name, will search for all (instead of the first occurrence)
of the module in C<@INC>. Then will generate items for each version.

Currently only one module can be multi version.

=item * B<multiperl> => I<bool> (default: 0)

Benchmark against multiple perls.

Requires L<App::perlbrew> to be installed. Will use installed perls from the
perlbrew installation. Each installed perl must have L<Bencher::Backend>
module installed (in addition to having all modules that you want to benchmark,
obviously).

By default, only perls having Bencher::Backend will be included. Use
C<--include-perl> and C<--exclude-perl> to include and exclude which perls you
want.

Also note that due to the way this is currently implemented, benchmark code that
contains closures (references to variables outside the code) won't work.

=item * B<note> => I<str>

Put additional note in the result.

=item * B<on_failure> => I<str>

What to do when there is a failure.

For a command participant, failure means non-zero exit code. For a Perl-code
participant, failure means Perl code dies or (if expected result is specified)
the result is not equal to the expected result.

The default is "die". When set to "skip", will first run the code of each item
before benchmarking and trap command failure/Perl exception and if that happens,
will "skip" the item.

=item * B<on_result_failure> => I<str>

What to do when there is a result failure.

This is like C<on_failure> except that it specifically refer to the failure of
item's result not being equal to expected result.

There is an extra choice of C<warn> for this type of failure, which is to print a
warning to STDERR and continue.

=item * B<participants> => I<array[hash]>

Add participants.

=item * B<precision> => I<float>

Precision.

When benchmarking with the default L<Benchmark::Dumb> runner, will pass the
precision to it. The value is a fraction, e.g. 0.5 (for 5% precision), 0.01 (for
1% precision), and so on. Or, it can also be a positive integer to speciify
minimum number of iterations, usually need to be at least 6 to avoid the "Number
of initial runs is very small (<6)" warning. The default precision is 0, which
is to let Benchmark::Dumb determine the precision, which is good enough for most
cases.

When benchmarking with L<Benchmark> runner, will pass this value as the
C<$count> argument. Which can be a positive integer to mean the number of
iterations to do (e.g. 10, or 100). Or, can also be set to a negative number
(e.g. -0.5 or -2) to mean minimum number of CPU seconds. The default is -0.5.

When benchmarking with L<Benchmark::Dumb::SimpleTime>, this value is a
positive integer which means the number of iterations to perform.

This setting overrides C<default_precision> property in the scenario.

=item * B<precision_limit> => I<float>

Set precision limit.

Instead of setting C<precision> which forces a single value, you can also set
this C<precision_limit> setting. If the precision in the scenario is higher
(=number is smaller) than this limit, then this limit is used. For example, if
the scenario specifies C<default_precision> 0.001 and C<precision_limit> is set to
0.005 then 0.005 is used.

This setting is useful on slower computers which might not be able to reach the
required precision before hitting maximum number of iterations.

=item * B<raw> => I<bool>

Show "raw" data.

When action=show-items-result, will print result as-is instead of dumping as
Perl.

=item * B<result_dir> => I<str>

Directory to use when saving benchmark result.

Default is from C<BENCHER_RESULT_DIR> environment variable, or the home
directory.

=item * B<result_filename> => I<str>

Filename to use when saving benchmark result.

Default is:

 <NAME>.<yyyy-dd-dd-"T"HH-MM-SS>.json

or, when running in module startup mode:

 <NAME>.module_startup.<yyyy-dd-dd-"T"HH-MM-SS>.json

where <NAME> is scenario module name, or C<NO_MODULE> if scenario is not from a
module. The C<::> (double colon in the module name will be replaced with C<->
(dash).

=item * B<return_meta> => I<bool>

Whether to return extra metadata.

When set to true, will return extra metadata such as platform information, CPU
information, system load before & after the benchmark, system time, and so on.
This is put in result metadata under C<func.*> keys.

The default is to true (return extra metadata) unless when run as CLI and format
is text (where the extra metadata is not shown).

=item * B<runner> => I<str>

Runner module to use.

The default is C<Benchmark::Dumb> which should be good enough for most cases.

You can use C<Benchmark> runner (C<Benchmark.pm>) if you are accustomed to it and
want to see its output format.

You can use C<Benchmark::Dumb::SimpleTime> if your participant code runs for at
least a few to many seconds and you want to use very few iterations (like 1 or
2) because you don't want to wait for too long.

=item * B<save_result> => I<bool>

Whether to save benchmark result to file.

Will also be turned on automatically if C<BENCHER_RESULT_DIR> environment
variabl is defined.

When this is turned on, will save a JSON file after benchmark, containing the
result along with metadata. The directory of the JSON file will be determined
from the C<results_dir> option, while the filename from the C<results_filename>
option.

=item * B<scenario> => I<hash>

Load a scenario from data structure.

=item * B<scenario_file> => I<str>

Load a scenario from a Perl file.

Perl file will be do()'ed and the last expression should be a hash containing
the scenario specification.

=item * B<scenario_module> => I<str>

Load a scenario from a Bencher::Scenario:: Perl module.

Will try to load module C<< Bencher::Scenario::E<lt>NAMEE<gt> >> and expect to find a package
variable in the module called C<$scenario> which should be a hashref containing
the scenario specification.

=item * B<scientific_notation> => I<bool>

=item * B<sorts> => I<array[str]> (default: ["-time"])

=item * B<test> => I<bool>

Whether to test participant code once first before benchmarking.

By default, participant code is run once first for testing (e.g. whether it dies
or return the correct result) before benchmarking. If your code runs for many
seconds, you might want to skip this test and set this to 0.

=item * B<with_args_size> => I<bool>

Also return memory usage of item's arguments.

Memory size is measured using L<Devel::Size>.

=item * B<with_process_size> => I<bool>

Also return process size information for each item.

This is done by dumping each item's code into a temporary file and running the
file with a new perl interpreter process and measuring the process size at the
end (so it does not need to load Bencher itself or the other items). Currently
only works on Linux because process size information is retrieved from
C</proc/PID/smaps>. Not all code can work, e.g. if the code tries to access a
closure or outside data or extra modules (modules not specified in the
participant or loaded by the code itself). Usually does not make sense to use
this on external command participants.

=item * B<with_result_size> => I<bool>

Also return memory usage of each item code's result (return value).

Memory size is measured using L<Devel::Size>.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 chart_result

Usage:

 chart_result(%args) -> [status, msg, result, meta]

Generate chart from the result.

Will use gnuplot (via L<Chart::Gnuplot>) to generate the chart. Will produce
C<.png> files in the specified directory.

Currently only results with one or two permutations of different items will be
chartable.

Options to customize the look/style of the chart will be added in the future.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<envres>* => I<array>

Enveloped result from bencher.

=item * B<output_file>* => I<str>

=item * B<overwrite> => I<bool>

=item * B<title> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 format_result

Usage:

 format_result($envres, $formatters, $options) -> [status, msg, result, meta]

Format bencher result.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$envres>* => I<array>

Enveloped result from bencher.

=item * B<$formatters>* => I<array[str|array]>

Formatters specification.

=item * B<$options> => I<hash>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 parse_scenario

Usage:

 parse_scenario(%args) -> [status, msg, result, meta]

Parse scenario (fill in default values, etc).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<scenario> => I<hash>

Unparsed scenario.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 split_result

Usage:

 split_result($envres, $fields, $options) -> any

Split results based on one or more fields.

This routine splits a table into multiple table based on one or more fields. If
you want to split a result, you should do it before C<format_result()> and then
format the split results individually.

A common use-case is to produce separate tables for each participant or dataset,
to make the benchmark results more readable (this is an alternative to having to
perform separate benchmark run per participant or dataset).

Each split result clones all the result metadata (like C<func.module_version>,
C<func.platform_info>, C<table.fields>, and so on). But the result items are only
a subset of the original result.

Return an array where each element is C<[\%field_values, $split_result]>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$envres>* => I<array>

Enveloped result from bencher.

=item * B<$fields>* => I<array[str]>

Fields to split the results on.

=item * B<$options> => I<hash>

=back

Return value:  (any)

=head1 ENVIRONMENT

=head2 BENCHER_RESULT_DIR => str

Set default for C<--results-dir>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<bencher>

L<Bencher>

C<Bencher::Manual::*>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
