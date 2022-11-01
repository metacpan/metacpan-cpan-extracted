package App::shcompgen;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::Slurper qw(read_text write_text);
use Perinci::Object;
use Perinci::Sub::Util qw(err);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-11'; # DATE
our $DIST = 'App-shcompgen'; # DIST
our $VERSION = '0.324'; # VERSION

our %SPEC;

my $re_progname = qr/\A[A-Za-z0-9_.,:-]+\z/;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Generate shell completion scripts',
};

my $_complete_prog = sub {
    require Complete::File;
    require Complete::Program;

    my %args = @_;
    my $word = $args{word} // '';
    if ($word =~ m!/!) {
        # user might want to mention a program file (e.g. ./foo)
        return {
            words => Complete::File::complete_file(
                word=>$word, filter=>'d|rxf'),
            path_sep => '/',
        };
    } else {
        # or user might want to mention a program in PATH
        Complete::Program::complete_program(word=>$word);
    }
};

our @supported_shells = qw(bash fish zsh tcsh);
our %shell_arg = (
    shell => {
        summary => 'Override guessing and select shell manually',
        schema => ['str*', {in=>\@supported_shells}],
        tags => ['common'],
        cmdline_aliases => {
            fish => {summary=>"Shortcut for --shell=fish", is_flag=>1, code=>sub { $_[0]{shell} = "fish" }},
            zsh  => {summary=>"Shortcut for --shell=zsh" , is_flag=>1, code=>sub { $_[0]{shell} = "zsh"  }},
            tcsh => {summary=>"Shortcut for --shell=tcsh", is_flag=>1, code=>sub { $_[0]{shell} = "tcsh" }},
        },
    },
);
our %common_args = (
    %shell_arg,
    global => {
        summary => 'Use global completions directory',
        schema => ['bool*'],
        cmdline_aliases => {
            per_user => {
                is_flag => 1,
                code    => sub { $_[0]{global} = 0 },
                summary => 'Alias for --no-global',
            },
        },
        description => <<'_',

Shell has global (system-wide) completions directory as well as per-user. For
example, in fish the global directory is by default `/etc/fish/completions` and
the per-user directory is `~/.config/fish/completions`.

By default, if running as root, the global is chosen. And if running as normal
user, per-user directory is chosen. Using `--global` or `--per-user` overrides
that and manually select which.

_
        tags => ['common'],
    },

    bash_global_dir => {
        summary => 'Directory to put completions scripts',
        schema  => ['array*', of => 'str*'],
        default => ['/etc/bash/completions'],
        tags => ['common'],
    },
    bash_per_user_dir => {
        summary => 'Directory to put completions scripts',
        schema  => ['array*', of => 'str*'],
        tags => ['common'],
    },

    fish_global_dir => {
        summary => 'Directory to put completions scripts',
        schema  => ['array*', of => 'str*'],
        default => ['/etc/fish/completions'],
        tags => ['common'],
    },
    fish_per_user_dir => {
        summary => 'Directory to put completions scripts',
        schema  => ['array*', of => 'str*'],
        tags => ['common'],
    },

    tcsh_global_dir => {
        summary => 'Directory to put completions scripts',
        schema  => ['array*', of => 'str*'],
        default => ['/etc/tcsh/completions'],
        tags => ['common'],
    },
    tcsh_per_user_dir => {
        summary => 'Directory to put completions scripts',
        schema  => ['array*', of => 'str*'],
        tags => ['common'],
    },

    zsh_global_dir => {
        summary => 'Directory to put completions scripts',
        schema  => ['array*', of => 'str*'],
        default => ['/usr/local/share/zsh/site-functions'],
        tags => ['common'],
    },
    zsh_per_user_dir => {
        summary => 'Directory to put completions scripts',
        schema  => ['array*', of => 'str*'],
        tags => ['common'],
    },

    helper_global_dir => {
        summary => 'Directory to put helper scripts',
        schema  => ['str*'],
        default => '/etc/shcompgen/helpers',
        tags => ['common'],
    },
    helper_per_user_dir => {
        summary => 'Directory to put helper scripts',
        schema  => ['str*'],
        tags => ['common'],
    },

    per_option => {
        summary => 'Create per-option completion script if possible',
        description => <<'_',

If set to true, then attempt to create completion script that register each
option. This creates nicer completion in some shells, e.g. fish and zsh. For
example, option description can be shown.

This is possible for only some types of scripts, e.g. <pm:Perinci::CmdLine>-
(that does not have subcommands) or <pm:Getopt::Long::Descriptive>-based ones.

_
        schema => 'bool',
    },
);

sub _all_exec_in_PATH {
    my @res;
    for my $dir (split /:/, $ENV{PATH}) {
        opendir my($dh), $dir or next;
        for my $f (readdir $dh) {
            next if $f eq '.' || $f eq '..';
            next if $f =~ /~\z/; # skip backup files
            next unless ((-f "$dir/$f") && (-x _));
            push @res, "$dir/$f";
        }
    }
    \@res;
}

sub _set_args_defaults {
    my $args = shift;

    if (!$args->{shell}) {
        require Shell::Guess;
        my $sh = Shell::Guess->running_shell;
        my $n = $sh->{name};
        $n = "zsh" if $n eq 'z';
        $n = "tcsh" if $n eq 'c';
        $n = "bash" if $n eq 'bourne'; # under make
        $args->{shell} = $n;
    }
    unless (grep { $_ eq $args->{shell} } @supported_shells) {
        return [412, "Unsupported shell '$args->{shell}'"];
    }

    $args->{global} //= ($> ? 0:1);

    $args->{bash_global_dir}   //= ['/etc/bash/completions'];
    $args->{bash_per_user_dir} //= ["$ENV{HOME}/.config/bash/completions"];
    $args->{fish_global_dir}   //= ['/etc/fish/completions'];
    $args->{fish_per_user_dir} //= ["$ENV{HOME}/.config/fish/completions"];
    $args->{tcsh_global_dir}   //= ['/etc/tcsh/completions'];
    $args->{tcsh_per_user_dir} //= ["$ENV{HOME}/.config/tcsh/completions"];
    $args->{zsh_global_dir}    //= ['/usr/local/share/zsh/site-functions'];
    $args->{zsh_per_user_dir}  //= ["$ENV{HOME}/.config/zsh/completions"];
    $args->{helper_global_dir}   //= '/etc/shcompgen/helpers';
    $args->{helper_per_user_dir} //= "$ENV{HOME}/.config/shcompgen/helpers";
    [200];
}

sub _tcsh_init_script_path {
    my %args = @_;
    if ($args{global}) {
        return "/etc/shcompgen.tcshrc";
    } else {
        return "$ENV{HOME}/.config/shcompgen.tcshrc";
    }
}

sub _gen_tcsh_init_script {
    my %args = @_;
    my $dirs = $args{global} ?
        $args{tcsh_global_dir} : $args{tcsh_per_user_dir};
    my @defs;
    for my $dir (@$dirs) {
        next unless -d $dir;
        for my $file (glob "$dir/*") {
            open my $fh, "<", $file or do {
                warn "Can't open '$file': $!, skipped\n";
                next;
            };
            my $line = <$fh>;
            $line .= "\n" unless $line =~ /\n\z/;
            push @defs, $line;
            close $fh;
        }
    }
    join(
        "",
        "# Generated by shcompgen on ", scalar(localtime), "\n",
        @defs,
    );
}

sub _gen_completion_script {
    require String::ShellQuote;

    my %args = @_;

    my $detres = $args{detect_res};
    my $shell  = $args{shell};
    my $prog   = $detres->[3]{'func.completee'} // $args{prog};
    my $progpath = $args{progpath};
    my $qprog  = String::ShellQuote::shell_quote($prog);
    my $comp   = $detres->[3]{'func.completer_command'};
    my $qcomp  = String::ShellQuote::shell_quote($comp);
    my $args   = $detres->[3]{'func.completer_command_args'};
    my $qargs; $qargs = String::ShellQuote::shell_quote($args) if defined $args;

    my $header_at_bottom;
    my $script;
    my @helper_scripts;

    if (($detres->[3]{'func.completer_type'} // '') =~ /\AGetopt::Long(?:::EvenLess|::Descriptive)?\z/) {
        require Data::Dmp;

        my $content;
        my $dump_res;
        if ($detres->[3]{'func.completer_type'} eq 'Getopt::Long::EvenLess') {
            require Getopt::Long::EvenLess::Dump;
            $dump_res = Getopt::Long::EvenLess::Dump::dump_getopt_long_evenless_script(
                filename => $progpath,
                skip_detect => 1,
            );
        } else {
            require Getopt::Long::Dump;
            $dump_res = Getopt::Long::Dump::dump_getopt_long_script(
                filename => $progpath,
                skip_detect => 1,
            );
        }

        if ($dump_res->[0] != 200) {
            log_error("Can't dump Getopt::Long script '%s': %s", $progpath, $dump_res);
            $script = "# Can't dump Getopt::Long script '$progpath': $dump_res->[0] - $dump_res->[1]\n";
            goto L1;
        }
        $content = join(
            "",
            "#!$^X\n",
            "use Getopt::Long::Complete;\n",
            "my \$spec = ", Data::Dmp::dmp($dump_res->[2]), ";\n",
            "GetOptions(\@\$spec);\n",
        );
        $comp = ($args{global} ?
                     $args{helper_global_dir} : $args{helper_per_user_dir}) .
            "/$prog";
        $qcomp = String::ShellQuote::shell_quote($comp);
        push @helper_scripts, {
            path => $comp,
            content => $content,
        };
    }

    if (($detres->[3]{'func.completer_type'} // '') =~ /\AGetopt::Std\z/) {
        require Data::Dmp;
        require Getopt::Long::Util;
        require Getopt::Std::Dump;

        my $content;
        my $dump_res = Getopt::Std::Dump::dump_getopt_std_script(
            filename => $progpath,
            skip_detect => 1,
        );
        if ($dump_res->[0] != 200) {
            log_error("Can't dump Getopt::Std script '%s': %s", $progpath, $dump_res);
            $script = "# Can't dump Getopt::Std script '$progpath': $dump_res->[0] - $dump_res->[1]\n";
            goto L1;
        }
        $content = join(
            "",
            "#!$^X\n",
            "use Getopt::Long::Complete;\n",
            "my \$spec = ", Data::Dmp::dmp(
                Getopt::Long::Util::gen_getopt_long_spec_from_getopt_std_spec(
                    is_getopt => $dump_res->[2][0] eq 'getopt' ? 1:0,
                    spec => $dump_res->[2][1])
              ), ";\n",
            "GetOptions(%\$spec);\n",
        );
        $comp = ($args{global} ?
                     $args{helper_global_dir} : $args{helper_per_user_dir}) .
            "/$prog";
        $qcomp = String::ShellQuote::shell_quote($comp);
        push @helper_scripts, {
            path => $comp,
            content => $content,
        };
    }

    if ($shell eq 'bash') {
        if (defined $args) {

            $script = q|
_|.$prog.q| ()
{
    local words
    words=("${COMP_WORDS[@]:0:1}")
    # insert arguments into the second element
    words+=(|.$qargs.q|)
    words+=("${COMP_WORDS[@]:1:COMP_CWORD}")
    local s1="${words[@]}"
    local point=${#s1}
    words+=("${COMP_WORDS[@]:COMP_CWORD+1}")

    #echo "D:words = ${words[@]}"
    #echo "D:point = $point"

    #echo "D:cmd = COMP_LINE=\"${words[@]}\" COMP_POINT=$point |.$comp.q|"

    COMPREPLY=( `COMP_LINE="${words[@]}" COMP_POINT=$point |.$comp.q|` )

    #echo "D:reply = ${COMPREPLY[@]}"
}
complete -F _|."$prog $qprog".q|
|;
        } else {
            $script = "complete -C $qcomp $qprog";
        }

    } elsif ($shell eq 'zsh') {

      GEN_ZSH:
        {
            $header_at_bottom++;
            if ($args{per_option}) {
                if ($detres->[3]{'func.completer_type'} =~ /^Perinci::CmdLine/) {
                    require Complete::Zsh::Gen::FromPerinciCmdLine;
                    my $res = Complete::Zsh::Gen::FromPerinciCmdLine::gen_zsh_complete_from_perinci_cmdline_script(
                        filename => $progpath,
                        skip_detect => 1,
                    );
                    if ($res->[0] == 200) {
                        log_debug("Using per-option completion script for '%s'", $prog);
                        $script = $res->[2];
                        last GEN_ZSH;
                    } else {
                        log_debug("Can't generate per-option completion script for '%s': %s, falling back", $prog, $res);
                    }
                } elsif ($detres->[3]{'func.completer_type'} =~ /^Getopt::Long::Descriptive/) {
                    require Complete::Zsh::Gen::FromGetoptLongDescriptive;
                    my $res = Complete::Zsh::Gen::FromGetoptLongDescriptive::gen_zsh_complete_from_getopt_long_descriptive_script(
                        filename => $progpath,
                        skip_detect => 1,
                    );
                    if ($res->[0] == 200) {
                        log_debug("Using per-option completion script for '%s'", $prog);
                        $script = $res->[2];
                        last GEN_ZSH;
                    } else {
                        log_debug("Can't generate per-option completion script for '%s': %s, falling back", $prog, $res);
                    }
                }
            }

            if (defined $args) {
                $script = "# TODO: args not yet supported\n";
            } else {
                $script = q|#compdef |.$prog.q|
_|.$prog.q|() {
    si=$IFS
    compadd -- $(COMP_SHELL=zsh COMP_LINE=$BUFFER COMP_POINT=$CURSOR |.$qcomp.q|)
    IFS=$si
}
_|.$prog.q| "$@"
|;
            }
        }

    } elsif ($shell eq 'tcsh') {

        if (defined $args) {
            $header_at_bottom++;
            $script = "complete $qprog 'p/*/`$qcomp $args`/'\n";
        } else {
            $header_at_bottom++;
            $script = "complete $qprog 'p/*/`$qcomp`/'\n";
        }

    } elsif ($shell eq 'fish') {

      GEN_FISH:
        {
            if ($args{per_option}) {
                if ($detres->[3]{'func.completer_type'} =~ /^Perinci::CmdLine/) {
                    require Complete::Fish::Gen::FromPerinciCmdLine;
                    my $res = Complete::Fish::Gen::FromPerinciCmdLine::gen_fish_complete_from_perinci_cmdline_script(
                        filename => $progpath,
                        skip_detect => 1,
                    );
                    if ($res->[0] == 200) {
                        log_debug("Using per-option completion script for '%s'", $prog);
                        $script = $res->[2];
                        last GEN_FISH;
                    } else {
                        log_debug("Can't generate per-option completion script for '%s': %s, falling back", $prog, $res);
                    }
                } elsif ($detres->[3]{'func.completer_type'} =~ /^Getopt::Long::Descriptive/) {
                    require Complete::Fish::Gen::FromGetoptLongDescriptive;
                    my $res = Complete::Fish::Gen::FromGetoptLongDescriptive::gen_fish_complete_from_getopt_long_descriptive_script(
                        filename => $progpath,
                        skip_detect => 1,
                    );
                    if ($res->[0] == 200) {
                        log_debug("Using per-option completion script for '%s'", $prog);
                        $script = $res->[2];
                        last GEN_FISH;
                    } else {
                        log_debug("Can't generate per-option completion script for '%s': %s, falling back", $prog, $res);
                    }
                }
            }

            if (defined $args) {
                $script = "# TODO: args not yet supported\n";
            } else {
                $script = "complete -c $qprog -a '(begin; set -lx COMP_SHELL fish; set -lx COMP_LINE (commandline); set -lx COMP_POINT (commandline -C); $qcomp; end)'\n";
            }
        }

    } else {
        die "Sorry, shell '$shell' is not supported yet";
    }

  L1:
    if ($header_at_bottom) {
        $script = "$script\n".
            "# FRAGMENT id=shcompgen-header note=".
                ($detres->[3]{'func.note'} // ''). "\n";
    } else {
        $script = "# FRAGMENT id=shcompgen-header note=".
            ($detres->[3]{'func.note'} // ''). "\n$script\n";
    }

    my $i = 0;
    for (@helper_scripts) {
        $i++;
        $script .= "# FRAGMENT id=shcompgen-helper-$i path=$_->{path}\n";
    }

    ($script, @helper_scripts);
}

sub _completion_scripts_dirs {
    my %args = @_;

    my $shell  = $args{shell};
    my $global = $args{global};

    my $dirs;
    if ($shell eq 'bash') {
        $dirs = $global ? $args{bash_global_dir} :
            $args{bash_per_user_dir};
    } elsif ($shell eq 'fish') {
        $dirs = $global ? $args{fish_global_dir} :
            $args{fish_per_user_dir};
    } elsif ($shell eq 'tcsh') {
        $dirs = $global ? $args{tcsh_global_dir} :
            $args{tcsh_per_user_dir};
    } elsif ($shell eq 'zsh') {
        $dirs = $global ? $args{zsh_global_dir} :
            $args{zsh_per_user_dir};
    }
    $dirs;
}

sub _completion_script_path {
    my %args = @_;

    my $detres = $args{detect_res};
    my $prog   = $detres->[3]{'func.completee'} // $args{prog};
    my $shell  = $args{shell};
    my $global = $args{global};

    my $dir = $args{dir} // _completion_scripts_dirs(%args)->[-1];
    my $path;
    if ($shell eq 'bash') {
        $path = "$dir/$prog";
    } elsif ($shell eq 'fish') {
        $path = "$dir/$prog.fish";
    } elsif ($shell eq 'tcsh') {
        $path = "$dir/$prog";
    } elsif ($shell eq 'zsh') {
        $path = "$dir/_$prog";
    }
    $path;
}

# detect whether we can generate completion script for a program, under a given
# shell
sub _detect_prog {
    my %args = @_;

    my $shell    = $args{shell};
    my $prog     = $args{prog};
    my $progpath = $args{progpath};

    open my($fh), "<", $progpath or return [500, "Can't open '$progpath': $!"];
    read $fh, my($buf), 2;
    my $is_script = $buf eq '#!';

    # currently we don't support non-scripts at all
    return [200, "OK", 0, {"func.reason"=>"Not a script"}] if !$is_script;

    my $is_perl_script = <$fh> =~ /perl/;
    seek $fh, 0, 0;
    my $content = do { local $/; scalar <$fh> };

    my %extrametas;

  DETECT:
    {
        # split per line to avoid pathological case of slowness when number of
        # source lines reaches many thousands.
        my @lines = split /^/, $content;

        my ($has_hint_cmd, $cmd, $args);
        for my $line (@lines) {
            if ($line =~
                    /^\s*# FRAGMENT id=shcompgen-hint command=(.+?)(?:\s+command_args=(.+))?\s*$/) {
                $has_hint_cmd++;
                $cmd = $1;
                $args = $2;
                last;
            }
        }
        my $has_nohint;
        for my $line (@lines) {
            if ($line =~ /^\s*# FRAGMENT id=shcompgen-nohint\s*$/) {
                $has_nohint++;
                last;
            }
        }
        if ($has_hint_cmd && !$has_nohint) {
            # program give hints in its source code that it can be completed
            # using a certain command
            if (defined($args) && $args =~ s/\A"//) {
                $args =~ s/"\z//;
                $args =~ s/\\(.)/$1/g;
            }
            return [200, "OK", 1, {
                "func.completer_command" => $cmd,
                "func.completer_command_args" => $args,
                "func.note" => "hint(command)",
                %extrametas,
            }];
        }

        my $has_hint_completer;
        my $completee;
        for my $line (@lines) {
            if ($line =~
                    /^\s*# FRAGMENT id=shcompgen-hint completer=1 for=(.+?)\s*$/) {
                $has_hint_completer++;
                $completee = $1;
                last;
            }
        }
        if ($has_hint_completer && !$has_nohint) {
            return [400, "completee specified in '$progpath' is not a valid ".
                        "program name: $completee"]
                unless $completee =~ $re_progname;
            return [200, "OK", 1, {
                "func.completer_command" => $prog,
                "func.completee" => $completee,
                "func.note"=>"hint(completer)",
                %extrametas,
            }];
        }

        if ($is_perl_script) {
            for my $line (@lines) {
                if ($line =~ /^\s*\# PERICMD_INLINE_SCRIPT: /) {
                    # pericmd-inline script cannot complete themselves, but they
                    # usually come with a separate completer script
                    return [200, "OK", 0, {
                        "func.reason" => "Perinci::CmdLine::Inline script",
                    }];
                }
            }

            for my $line (@lines) {
                if ($line =~ /^\s*((?:use|require)\s+
                                  (
                                      Getopt::Std|
                                      Getopt::Long(?:::Complete|::Less|::EvenLess|::Subcommand|::More|::Descriptive)?|
                                      Perinci::CmdLine(?:::Any|::Lite|::Classic)
                              ))\b/x) {
                    return [200, "OK", 1, {
                        "func.completer_command"=> $prog, # later will be set
                        "func.completer_type"=> $2,
                        "func.note"=>"perl use/require statement: $1",
                    }];
                }
            }
        }
    }
    [200, "OK", 0];
}

sub _generate_or_remove {
    my $which0 = shift;
    my %args = @_;

    my $setdef_res = _set_args_defaults(\%args);
    return $setdef_res unless $setdef_res->[0] == 200;

    # to avoid writing a file and then removing the file again in the same run
    my %written_files;

    my %removed_files;

    my $envres = envresmulti();
  PROG:
    for my $prog0 (@{ $args{prog} }) {
        my ($prog, $progpath);
        log_debug("Processing program %s ...", $prog0);
        if ($prog0 =~ m!/!) {
            ($prog = $prog0) =~ s!.+/!!;
            $progpath = $prog0;
            unless (-f $progpath) {
                log_error("No such file %s, skipped", $progpath);
                $envres->add_result(404, "No such file", {item_id=>$prog0});
                next PROG;
            }
        } else {
            require File::Which;
            $prog = $prog0;
            $progpath = File::Which::which($prog0);
            unless ($progpath) {
                log_error("'%s' not found in PATH, skipped", $prog0);
                $envres->add_result(404, "Not in PATH", {item_id=>$prog0});
                next PROG;
            }
        }

        my $which = $which0;
        if ($which eq 'generate') {
            my $detres = _detect_prog(prog=>$prog, progpath=>$progpath, shell=>$args{shell});
            if ($detres->[0] != 200) {
                log_error("Can't detect '%s': %s", $prog, $detres->[1]);
                $envres->add_result($detres->[0], $detres->[1],
                                    {item_id=>$prog0});
                next PROG;
            }
            log_debug("Detection result for '%s': %s", $prog, $detres);
            if (!$detres->[2]) {
                if ($args{remove}) {
                    $which = 'remove';
                    goto REMOVE;
                } else {
                    next PROG;
                }
            }

            my ($script, @helper_scripts) = _gen_completion_script(
                %args, prog => $prog, progpath => $progpath, detect_res => $detres);
            my $comppath = _completion_script_path(
                %args, prog => $prog, detect_res => $detres);

            if ($args{stdout}) {
                print $script;
                next PROG;
            }

            if (-f $comppath) {
                if (!$args{replace}) {
                    log_info("Not replacing completion script for $prog in '$comppath' (use --replace to replace)");
                    $envres->add_result(304, "Not replaced (already exists)", {item_id=>$prog0});
                    next PROG;
                }
            }
            log_info("Writing completion script to %s ...", $comppath);
            $written_files{$comppath}++;
            eval { write_text($comppath, $script) };
            if ($@) {
                $envres->add_result(500, "Can't write to '$comppath': $@",
                                    {item_id=>$prog0});
                next PROG;
            }
            for my $hs (@helper_scripts) {
                log_info("Writing helper script %s ...", $hs->{path});
                $written_files{$hs->{path}}++;
                eval {
                    write_text($hs->{path}, $hs->{content});
                    chmod 0755, $hs->{path};
                };
                if ($@) {
                    $envres->add_result(500, "Can't write helper script to '$hs->{path}': $@",
                                        {item_id=>$prog0});
                    next PROG;
                }
            }
            $envres->add_result(200, "OK", {item_id=>$prog0});
        } # generate

      REMOVE:
        if ($which eq 'remove') {
            my $comppath = _completion_script_path(%args, prog => $prog);
            unless (-f $comppath) {
                log_debug("Skipping %s (completion script does not exist)", $prog0);
                $envres->add_result(304, "Completion does not exist", {item_id=>$prog0});
                next PROG;
            }
            my $content;
            eval { $content = read_text($comppath) };
            if ($@) {
                $envres->add_result(500, "Can't open '$comppath': $@", {item_id=>$prog0});
                next;
            };
            unless ($content =~ /^# FRAGMENT id=shcompgen-header note=(.+)\b/m) {
                log_debug("Skipping %s, not installed by us", $prog0);
                $envres->add_result(304, "Not installed by us", {item_id=>$prog0});
                next PROG;
            }
            if ($written_files{$comppath}) {
                # not removing files we already wrote
                next PROG;
            }
            log_info("Unlinking %s ...", $comppath);
            unless (unlink $comppath) {
                $envres->add_result(500, "Can't unlink '$comppath': $!",
                                    {item_id=>$prog0});
                next PROG;
            }
            # XXX we should only remove helper script if there are no other
            # shells' completion scripts using this
            while ($content =~ /^# FRAGMENT id=shcompgen-helper-\d+ path=(.+)/mg) {
                my $hspath = $1;
                log_info("Unlinking helper script %s ...", $1);
                unless (unlink $hspath) {
                    $envres->add_result(500, "Can't unlink helper script '$hspath': $!",
                                        {item_id=>$prog0});
                    next PROG;
                }
                $removed_files{$hspath}++;
            }
            $envres->add_result(200, "OK", {item_id=>$prog0});
            $removed_files{$comppath}++;
        } # remove

    } # for prog0

    if (keys(%written_files) || keys(%removed_files)) {
        if ($args{shell} eq 'tcsh') {
            my $init_script_path = _tcsh_init_script_path(%args);
            my $init_script = _gen_tcsh_init_script(%args);
            log_debug("Re-writing init script %s ...", $init_script_path);
            write_text($init_script_path, $init_script);
        }
    }

    $envres->as_struct;
}

$SPEC{guess_shell} = {
    v => 1.1,
    summary => 'Guess running shell',
    args => {
    },
};
sub guess_shell {
    my %args = @_;

    my $setdef_res = _set_args_defaults(\%args);
    return $setdef_res unless $setdef_res->[0] == 200;

    [200, "OK", $args{shell}];
}

$SPEC{detect_prog} = {
    v => 1.1,
    summary => "Detect a program",
    args => {
        %shell_arg,
        prog => {
            schema => 'str*',
            completion => $_complete_prog,
            req => 1,
            pos => 0,
        },
    },
    'cmdline.default_format' => 'json',
};
sub detect_prog {
    require File::Which;

    my %args = @_;

    _set_args_defaults(\%args);

    my $progname = $args{prog};
    my $progpath = File::Which::which($progname);

    return [404, "No such program '$progname'"] unless $progpath;
    $progname =~ s!.+/!!;

    _detect_prog(
        prog => $progname,
        progpath => $progpath,
        shell => $args{shell},
    );
}

$SPEC{init} = {
    v => 1.1,
    summary => 'Initialize shcompgen',
    description => <<'_',

This subcommand creates the completion directories and initialization shell
script, as well as run `generate`.

_
    args => {
        %common_args,
    },
};
sub init {
    my %args = @_;

    my $setdef_res = _set_args_defaults(\%args);
    return $setdef_res unless $setdef_res->[0] == 200;

    my $shell = $args{shell};
    my $global = $args{global};

    my $instruction = '';

    my $dirs;
    my $init_location;
    my $init_script;
    my $init_script_path;

    $dirs = _completion_scripts_dirs(%args);

    if ($global) {
        push @$dirs, $args{helper_global_dir};
    } else {
        push @$dirs, $args{helper_per_user_dir};
    }

    if ($shell eq 'bash') {
        $init_location = $global ?
            (-d "/etc/profile.d" ? "/etc/profile.d/shcompgen.sh" : "/etc/bash.bashrc") :
            "~/.bashrc";
        $init_script = <<_;
# generated by shcompgen version $App::shcompgen::VERSION
_
        $init_script .= <<'_';
_shcompgen_loader()
{
    # check if bash-completion is active by the existence of function
    # '_completion_loader'.
    local bc_active=0
    if [[ "`type -t _completion_loader`" = "function" ]]; then bc_active=1; fi

    # XXX should we use --bash-{global,per-user}-dir supplied by user here? probably.
    local dirs
    dirs=(~/.config/bash/completions /etc/bash/completions)
    if [[ "$bc_active" = 1 ]]; then
        # we only search in bash-completion dirs when bash-completion has been
        # initialized because some of the completion scripts require that
        # bash-completion system is initialized first (e.g. _init_completion)
        dirs+=(/etc/bash_completion.d /usr/share/bash-completion/completions)
    fi

    local d
    for d in ${dirs[*]}; do
        if [[ -f "$d/$1" ]]; then . "$d/$1"; return 124; fi
    done

    if [[ $bc_active = 1 ]]; then _completion_loader "$1"; return 124; fi

    # otherwise, do as default (XXX still need to fix this, we don't want to
    # install a fixed completion for unknown commands; but using 'compopt -o
    # default' also creates a 'complete' entry)
    complete -o bashdefault -o default "$1" && return 124
}
complete -D -F _shcompgen_loader
_
        if ($global) {
            $init_script_path = "/etc/shcompgen.bashrc";
        } else {
            $init_script_path = "$ENV{HOME}/.config/shcompgen.bashrc";
        }
        $instruction .= "Please put this into your $init_location:".
            "\n\n" . " . $init_script_path\n\n";
    } elsif ($shell eq 'zsh') {
        $init_location = $global ? "/etc/zsh/zshrc" : "~/.zshrc";
        $init_script = <<_;
# generated by shcompgen version $App::shcompgen::VERSION
_
        $init_script .= <<'_';
local added_dir
for d in ~/.config/zsh/completions; do
  if [[ ${fpath[(i)$d]} == "" || ${fpath[(i)$d]} -gt ${#fpath} ]]; then
    fpath=($d $fpath)
    added_dir=1
  fi
done
if [[ $added_dir == 1 ]]; then compinit; fi
_

        if ($global) {
            $init_script_path = "/etc/shcompgen.zshrc";
        } else {
            $init_script_path = "$ENV{HOME}/.config/shcompgen.zshrc";
        }
        $instruction .= "Please put this into your $init_location:".
            "\n\n" . " . $init_script_path\n\n";
    } elsif ($shell eq 'fish') {
        # nothing to do, ready by default
    } elsif ($shell eq 'tcsh') {
        $init_location = $global ? "/etc/csh.cshrc" : "~/.tcshrc";
        $init_script = _gen_tcsh_init_script(%args);
        $init_script_path = _tcsh_init_script_path(%args);
        $instruction .= "Please put this into your $init_location:".
            "\n\n" . " source $init_script_path\n\n";
    } else {
        return [412, "Shell '$shell' not yet supported"];
    }

    for my $dir (@$dirs) {
        unless (-d $dir) {
            require File::Path;
            log_trace("Creating directory %s ...", $dir);
            File::Path::make_path($dir)
                  or return [500, "Can't create $dir: $!"];
            $instruction .= "Directory '$dir' created.\n\n";
        }
    }

    if ($init_script) {
        write_text($init_script_path, $init_script);
    }

    $instruction = "Congratulations, shcompgen initialization is successful.".
        "\n\n$instruction";

    [200, "OK", $instruction];
}

$SPEC{generate} = {
    v => 1.1,
    summary => 'Generate shell completion scripts for detectable programs',
    args => {
        %common_args,
        prog => {
            summary => 'Program(s) to generate completion for',
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
            description => <<'_',

Can contain path (e.g. `../foo`) or a plain word (`foo`) in which case will be
searched from PATH.

_
            element_completion => $_complete_prog,
        },
        replace => {
            summary => 'Replace existing script',
            schema  => ['bool*', is=>1],
            description => <<'_',

The default behavior is to skip if an existing completion script exists.

_
        },
        remove => {
            summary => 'Remove completion for script that (now) is '.
                'not detected to have completion',
            schema  => ['bool*', is=>1],
            description => <<'_',

The default behavior is to simply ignore existing completion script if the
program is not detected to have completion. When the `remove` setting is
enabled, however, such existing completion script will be removed.

_
        },
        stdout => {
            summary => 'Output completion script to STDOUT',
            schema => ['bool', is=>1],
        },
    },
};
sub generate {
    my %args = @_;
    $args{prog} //= _all_exec_in_PATH();
    _generate_or_remove('generate', %args);
}

$SPEC{list} = {
    v => 1.1,
    summary => 'List all shell completion scripts generated by this script',
    args => {
        %common_args,
        detail => {
            schema => 'bool',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list {
    my %args = @_;

    my $setdef_res = _set_args_defaults(\%args);
    return $setdef_res unless $setdef_res->[0] == 200;

    my $shell = $args{shell};

    my @res;
    my $resmeta = {};
    my $dirs = _completion_scripts_dirs(%args);
    for my $dir (@$dirs) {
        log_debug("Opening dir %s ...", $dir);
        opendir my($dh), $dir or return [500, "Can't read dir '$dir': $!"];
        for my $entry (readdir $dh) {
            next if $entry eq '.' || $entry eq '..';

            # XXX refactor: put to function (_file_to_prog)
            my $prog = $entry;
            if ($shell eq 'fish') {
                $prog =~ s/\.fish\z//;
            } elsif ($shell eq 'zsh') {
                $prog =~ s/\A_//;
            }
            next unless $prog =~ $re_progname;

            # XXX refactor: put to function (_read_completion_script)
            my $comppath = _completion_script_path(
                %args, dir=>$dir, prog=>$prog);
            log_debug("Checking completion script '%s' ...", $comppath);
            my $content;
            eval { $content = read_text($comppath) };
            if ($@) {
                log_warn("Can't open file '%s': %s", $comppath, $@);
                next;
            };
            unless ($content =~ /^# FRAGMENT id=shcompgen-header note=(.+)(?:\s|$)/m) {
                log_debug("Skipping prog %s, not generated by us", $entry);
                next;
            }
            my $note = $1;
            if ($args{detail}) {
                push @res, {
                    prog => $prog,
                    note => $note,
                    path => $comppath,
                };
            } else {
                push @res, $prog;
            }
        }
    } # for $dir

    $resmeta->{'table.fields'} = [qw/prog path note/] if $args{detail};

    [200, "OK", \@res, $resmeta];
}

$SPEC{remove} = {
    v => 1.1,
    summary => 'Remove shell completion scripts generated by this script',
    args => {
        %common_args,
        prog => {
            summary => 'Program(s) to remove completion script of',
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
            description => <<'_',

Can contain path (e.g. `../foo`) or a plain word (`foo`) in which case will be
searched from PATH.

_
            element_completion => sub {
                # list programs in the completion scripts dir
                require Complete::Util;

                my %args = @_;
                my $word = $args{word} // '';

                my $res = list($args{args});
                return unless $res->[0] == 200;
                Complete::Util::complete_array_elem(
                    array=>$res->[2], word=>$word);
            },
        },
    },
};
sub remove {
    my %args = @_;
    $args{prog} //= _all_exec_in_PATH();
    _generate_or_remove('remove', %args);
}

1;
# ABSTRACT: Generate shell completion scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

App::shcompgen - Generate shell completion scripts

=head1 VERSION

This document describes version 0.324 of App::shcompgen (from Perl distribution App-shcompgen), released on 2022-08-11.

=head1 FUNCTIONS


=head2 detect_prog

Usage:

 detect_prog(%args) -> [$status_code, $reason, $payload, \%result_meta]

Detect a program.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<prog>* => I<str>

=item * B<shell> => I<str>

Override guessing and select shell manually.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 generate

Usage:

 generate(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate shell completion scripts for detectable programs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bash_global_dir> => I<array[str]> (default: ["/etc/bash/completions"])

Directory to put completions scripts.

=item * B<bash_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<fish_global_dir> => I<array[str]> (default: ["/etc/fish/completions"])

Directory to put completions scripts.

=item * B<fish_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<global> => I<bool>

Use global completions directory.

Shell has global (system-wide) completions directory as well as per-user. For
example, in fish the global directory is by default C</etc/fish/completions> and
the per-user directory is C<~/.config/fish/completions>.

By default, if running as root, the global is chosen. And if running as normal
user, per-user directory is chosen. Using C<--global> or C<--per-user> overrides
that and manually select which.

=item * B<helper_global_dir> => I<str> (default: "/etc/shcompgen/helpers")

Directory to put helper scripts.

=item * B<helper_per_user_dir> => I<str>

Directory to put helper scripts.

=item * B<per_option> => I<bool>

Create per-option completion script if possible.

If set to true, then attempt to create completion script that register each
option. This creates nicer completion in some shells, e.g. fish and zsh. For
example, option description can be shown.

This is possible for only some types of scripts, e.g. L<Perinci::CmdLine>-
(that does not have subcommands) or L<Getopt::Long::Descriptive>-based ones.

=item * B<prog> => I<array[str]>

Program(s) to generate completion for.

Can contain path (e.g. C<../foo>) or a plain word (C<foo>) in which case will be
searched from PATH.

=item * B<remove> => I<bool>

Remove completion for script that (now) is not detected to have completion.

The default behavior is to simply ignore existing completion script if the
program is not detected to have completion. When the C<remove> setting is
enabled, however, such existing completion script will be removed.

=item * B<replace> => I<bool>

Replace existing script.

The default behavior is to skip if an existing completion script exists.

=item * B<shell> => I<str>

Override guessing and select shell manually.

=item * B<stdout> => I<bool>

Output completion script to STDOUT.

=item * B<tcsh_global_dir> => I<array[str]> (default: ["/etc/tcsh/completions"])

Directory to put completions scripts.

=item * B<tcsh_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<zsh_global_dir> => I<array[str]> (default: ["/usr/local/share/zsh/site-functions"])

Directory to put completions scripts.

=item * B<zsh_per_user_dir> => I<array[str]>

Directory to put completions scripts.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 guess_shell

Usage:

 guess_shell() -> [$status_code, $reason, $payload, \%result_meta]

Guess running shell.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 init

Usage:

 init(%args) -> [$status_code, $reason, $payload, \%result_meta]

Initialize shcompgen.

This subcommand creates the completion directories and initialization shell
script, as well as run C<generate>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bash_global_dir> => I<array[str]> (default: ["/etc/bash/completions"])

Directory to put completions scripts.

=item * B<bash_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<fish_global_dir> => I<array[str]> (default: ["/etc/fish/completions"])

Directory to put completions scripts.

=item * B<fish_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<global> => I<bool>

Use global completions directory.

Shell has global (system-wide) completions directory as well as per-user. For
example, in fish the global directory is by default C</etc/fish/completions> and
the per-user directory is C<~/.config/fish/completions>.

By default, if running as root, the global is chosen. And if running as normal
user, per-user directory is chosen. Using C<--global> or C<--per-user> overrides
that and manually select which.

=item * B<helper_global_dir> => I<str> (default: "/etc/shcompgen/helpers")

Directory to put helper scripts.

=item * B<helper_per_user_dir> => I<str>

Directory to put helper scripts.

=item * B<per_option> => I<bool>

Create per-option completion script if possible.

If set to true, then attempt to create completion script that register each
option. This creates nicer completion in some shells, e.g. fish and zsh. For
example, option description can be shown.

This is possible for only some types of scripts, e.g. L<Perinci::CmdLine>-
(that does not have subcommands) or L<Getopt::Long::Descriptive>-based ones.

=item * B<shell> => I<str>

Override guessing and select shell manually.

=item * B<tcsh_global_dir> => I<array[str]> (default: ["/etc/tcsh/completions"])

Directory to put completions scripts.

=item * B<tcsh_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<zsh_global_dir> => I<array[str]> (default: ["/usr/local/share/zsh/site-functions"])

Directory to put completions scripts.

=item * B<zsh_per_user_dir> => I<array[str]>

Directory to put completions scripts.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list

Usage:

 list(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all shell completion scripts generated by this script.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bash_global_dir> => I<array[str]> (default: ["/etc/bash/completions"])

Directory to put completions scripts.

=item * B<bash_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<detail> => I<bool>

=item * B<fish_global_dir> => I<array[str]> (default: ["/etc/fish/completions"])

Directory to put completions scripts.

=item * B<fish_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<global> => I<bool>

Use global completions directory.

Shell has global (system-wide) completions directory as well as per-user. For
example, in fish the global directory is by default C</etc/fish/completions> and
the per-user directory is C<~/.config/fish/completions>.

By default, if running as root, the global is chosen. And if running as normal
user, per-user directory is chosen. Using C<--global> or C<--per-user> overrides
that and manually select which.

=item * B<helper_global_dir> => I<str> (default: "/etc/shcompgen/helpers")

Directory to put helper scripts.

=item * B<helper_per_user_dir> => I<str>

Directory to put helper scripts.

=item * B<per_option> => I<bool>

Create per-option completion script if possible.

If set to true, then attempt to create completion script that register each
option. This creates nicer completion in some shells, e.g. fish and zsh. For
example, option description can be shown.

This is possible for only some types of scripts, e.g. L<Perinci::CmdLine>-
(that does not have subcommands) or L<Getopt::Long::Descriptive>-based ones.

=item * B<shell> => I<str>

Override guessing and select shell manually.

=item * B<tcsh_global_dir> => I<array[str]> (default: ["/etc/tcsh/completions"])

Directory to put completions scripts.

=item * B<tcsh_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<zsh_global_dir> => I<array[str]> (default: ["/usr/local/share/zsh/site-functions"])

Directory to put completions scripts.

=item * B<zsh_per_user_dir> => I<array[str]>

Directory to put completions scripts.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 remove

Usage:

 remove(%args) -> [$status_code, $reason, $payload, \%result_meta]

Remove shell completion scripts generated by this script.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bash_global_dir> => I<array[str]> (default: ["/etc/bash/completions"])

Directory to put completions scripts.

=item * B<bash_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<fish_global_dir> => I<array[str]> (default: ["/etc/fish/completions"])

Directory to put completions scripts.

=item * B<fish_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<global> => I<bool>

Use global completions directory.

Shell has global (system-wide) completions directory as well as per-user. For
example, in fish the global directory is by default C</etc/fish/completions> and
the per-user directory is C<~/.config/fish/completions>.

By default, if running as root, the global is chosen. And if running as normal
user, per-user directory is chosen. Using C<--global> or C<--per-user> overrides
that and manually select which.

=item * B<helper_global_dir> => I<str> (default: "/etc/shcompgen/helpers")

Directory to put helper scripts.

=item * B<helper_per_user_dir> => I<str>

Directory to put helper scripts.

=item * B<per_option> => I<bool>

Create per-option completion script if possible.

If set to true, then attempt to create completion script that register each
option. This creates nicer completion in some shells, e.g. fish and zsh. For
example, option description can be shown.

This is possible for only some types of scripts, e.g. L<Perinci::CmdLine>-
(that does not have subcommands) or L<Getopt::Long::Descriptive>-based ones.

=item * B<prog> => I<array[str]>

Program(s) to remove completion script of.

Can contain path (e.g. C<../foo>) or a plain word (C<foo>) in which case will be
searched from PATH.

=item * B<shell> => I<str>

Override guessing and select shell manually.

=item * B<tcsh_global_dir> => I<array[str]> (default: ["/etc/tcsh/completions"])

Directory to put completions scripts.

=item * B<tcsh_per_user_dir> => I<array[str]>

Directory to put completions scripts.

=item * B<zsh_global_dir> => I<array[str]> (default: ["/usr/local/share/zsh/site-functions"])

Directory to put completions scripts.

=item * B<zsh_per_user_dir> => I<array[str]>

Directory to put completions scripts.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-shcompgen>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-shcompgen>.

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

This software is copyright (c) 2022, 2020, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-shcompgen>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
