package App::NDTools::NDProc;

use strict;
use warnings FATAL => 'all';
use parent 'App::NDTools::NDTool';

use Getopt::Long qw(GetOptionsFromArray :config bundling);
use Log::Log4Cli;
use Module::Find qw(findsubmod);
use App::NDTools::Slurp qw(s_decode s_dump s_encode);
use Storable qw(dclone freeze thaw);
use Struct::Diff 0.94 qw(diff split_diff);
use Struct::Path 0.80 qw(path);
use Struct::Path::PerlStyle 0.80 qw(str2path);

our $VERSION = '0.26';

sub arg_opts {
    my $self = shift;

    Getopt::Long::Configure('pass_through');

    my %arg_opts = (
        $self->SUPER::arg_opts(),
        'builtin-format=s' => \$self->{OPTS}->{'builtin-format'},
        'builtin-rules=s' => \$self->{OPTS}->{'builtin-rules'},
        'disable-module=s@' => \$self->{OPTS}->{'disable-module'},
        'dump-blame=s' => \$self->{OPTS}->{'dump-blame'},
        'dump-rules=s' => \$self->{OPTS}->{'dump-rules'},
        'embed-blame=s' => \$self->{OPTS}->{'embed-blame'},
        'embed-rules=s' => \$self->{OPTS}->{'embed-rules'},
        'list-modules|l' => \$self->{OPTS}->{'list-modules'},
        'module|m=s' => \$self->{OPTS}->{module},
        'rules=s@' => \$self->{OPTS}->{rules},
    );
    delete $arg_opts{'help|h'};     # skip in first args parsing -- will be accessable for modules
    delete $arg_opts{'version|V'};  # --"--

    return %arg_opts;
}

sub configure {
    my $self = shift;

    $self->index_modules();

    $self->{rules} = [];
    map { push @{$self->{rules}}, @{$self->load_struct($_)} }
        @{$self->{OPTS}->{rules}}
            if ($self->{OPTS}->{rules});

    if ($self->{OPTS}->{module} or @{$self->{rules}}) {
        log_info { "Explicit rules used: builtin will be ignored" };
        $self->{OPTS}->{'builtin-rules'} = undef;
    }

    $self->{OPTS}->{'disable-module'} =
        { map { $_ => 1 } @{$self->{OPTS}->{'disable-module'}} };
}

sub defaults {
    return {
        'blame' => 1, # may be redefined per-rule
        'builtin-format' => "", # raw
        'modpath' => [ 'App::NDTools::NDProc::Module' ],
    };
}

sub dump_arg {
    my ($self, $uri, $arg) = @_;

    log_debug { "Dumping result to $uri" };
    s_dump($uri, $self->{OPTS}->{ofmt}, $self->{OPTS}->{pretty}, $arg);
}

sub dump_blame {
    my ($self, $blame) = @_;

    return unless (defined $self->{OPTS}->{'dump-blame'});

    log_debug { "Dumping blame to $self->{OPTS}->{'dump-blame'}" };
    s_dump($self->{OPTS}->{'dump-blame'}, $self->{OPTS}->{ofmt},
        $self->{OPTS}->{pretty}, $blame);
}

sub dump_rules {
    my $self = shift;

    for my $rule (@{$self->{rules}}) {
        # remove undefs - defaults will be used anyway
        map { defined $rule->{$_} || delete $rule->{$_} } keys %{$rule};
    }
    log_debug { "Dumping rules to $self->{OPTS}->{'dump-rules'}" };
    s_dump($self->{OPTS}->{'dump-rules'}, $self->{OPTS}->{ofmt},
        $self->{OPTS}->{pretty}, $self->{rules});
}

sub embed {
    my ($self, $data, $path, $thing) = @_;

    my $spath = eval { str2path($path) };
    die_fatal "Unable to parse '$path' ($@)", 4 if ($@);
    my $ref = eval { (path($data, $spath, expand => 1))[0]};
    die_fatal "Unable to lookup '$path' ($@)", 4 if ($@);

    ${$ref} = $self->{OPTS}->{'builtin-format'} ?
        s_encode($thing, $self->{OPTS}->{'builtin-format'}) :
        $thing;
}

sub exec {
    my $self = shift;

    if ($self->{OPTS}->{'list-modules'}) {
        map { printf "%-10s %-8s %s\n", @{$_} } $self->list_modules;
        die_info undef, 0;
    }

    if (defined $self->{OPTS}->{module}) {
        die_fatal "Unknown module specified '$self->{OPTS}->{module}'", 1
            unless (exists $self->{MODS}->{$self->{OPTS}->{module}});
        $self->init_module($self->{OPTS}->{module});

        my $mod = $self->{MODS}->{$self->{OPTS}->{module}}->new();
        for my $rule ($mod->parse_args($self->{ARGV})->get_opts()) {
            $rule->{modname} = $self->{OPTS}->{module},
            push @{$self->{rules}}, $rule;
        }
    }

    # parse the rest of args (unrecognized by module (if was specified by args))
    # to be sure there is no unsupported opts remain
    my @rest_opts = (
        'help|h' => sub { $self->usage; exit 0 },
        'version|V' => sub { print $self->VERSION . "\n"; exit 0 },
    );

    Getopt::Long::Configure('nopass_through');
    unless (GetOptionsFromArray($self->{ARGV}, @rest_opts)) {
        $self->usage;
        die_fatal "Unsupported opts passed", 1;
    }

    if ($self->{OPTS}->{'dump-rules'} and not @{$self->{ARGV}}) {
        $self->dump_rules();
    } else {
        $self->check_args(@{$self->{ARGV}}) or die_fatal undef, 1;
        $self->process_args(@{$self->{ARGV}});
    }

    die_info "All done", 0;
}

sub index_modules {
    my $self = shift;

    my $required = { map { $_->{modname} => 1 } @{$self->{rules}} };
    $required->{$self->{OPTS}->{module}} = 1 if ($self->{OPTS}->{module});

    for my $path (@{$self->{OPTS}->{modpath}}) {
        log_trace { "Indexing modules in $path" };
        for my $m (findsubmod $path) {
            $self->{MODS}->{(split('::', $m))[-1]} = $m;
        }
    }

    return $self;
}

sub init_module {
    my ($self, $mod) = @_;

    return if ($self->{_initialized_mods}->{$mod});

    log_trace { "Inititializing module $mod ($self->{MODS}->{$mod})" };
    eval "require $self->{MODS}->{$mod}";
    die_fatal "Failed to initialize module '$mod' ($@)", 1 if ($@);
    $self->{_initialized_mods}->{$mod} = 1;
}

sub list_modules {
    my $self = shift;

    return map {
        $self->init_module($_);
        [ $_, $self->{MODS}->{$_}->VERSION, $self->{MODS}->{$_}->MODINFO ]
    } sort keys %{$self->{MODS}};
}

sub load_arg {
    shift->load_struct(@_);
}

*load_source = \&load_arg;

sub load_builtin_rules {
    my ($self, $data, $path) = @_;

    log_debug { "Loading builtin rules from '$path'" };
    my $spath = eval { str2path($path) };
    die_fatal "Unable to parse path ($@)", 4 if ($@);
    my $rules = eval { (path($data, $spath, deref => 1, strict => 1))[0] };
    die_fatal "Unable to lookup path ($@)", 4 if ($@);

    return $self->{OPTS}->{'builtin-format'} ?
        s_decode($rules, $self->{OPTS}->{'builtin-format'}) :
        $rules;
}

sub process_args {
    my $self = shift;

    for my $arg (@_) {
        log_info { "Processing $arg" };
        my $data = $self->load_arg($arg, $self->{OPTS}->{ifmt});

        if ($self->{OPTS}->{'builtin-rules'}) {
            $self->{rules} = $self->load_builtin_rules($data, $self->{OPTS}->{'builtin-rules'});
            # restore original rules - may be changed while processing structure
            $self->{OPTS}->{'embed-rules'} = $self->{OPTS}->{'builtin-rules'}
                if (not defined $self->{OPTS}->{'embed-rules'});
        }

        if ($self->{OPTS}->{'dump-rules'}) {
            $self->dump_rules();
            next;
        }

        my @blame = $self->resolve_rules($arg)->process_rules(\$data);

        if ($self->{OPTS}->{'embed-blame'}) {
            log_debug { "Embedding blame to '$self->{OPTS}->{'embed-blame'}'" };
            $self->embed($data, $self->{OPTS}->{'embed-blame'}, \@blame);
        }

        if ($self->{OPTS}->{'embed-rules'}) {
            log_debug { "Embedding rules to '$self->{OPTS}->{'embed-rules'}'" };
            $self->embed($data, $self->{OPTS}->{'embed-rules'}, $self->{rules});
        }

        $self->dump_arg($arg, $data);
        $self->dump_blame(\@blame);
    }
}

sub process_rules {
    my ($self, $data) = @_;

    my $rcnt = 0; # rules counter
    my @blame;

    for my $rule (@{$self->{resolved_rules}}) {
        if (exists $self->{OPTS}->{'disable-module'}->{$rule->{modname}}) {
            log_debug { "Skip rule #$rcnt (module $rule->{modname} is disabled by args)" };
            next;
        }
        if ($rule->{disabled}) {
            log_debug { "Rule #$rcnt ($rule->{modname}) is disabled, skip it" };
            next;
        }
        die_fatal "Unknown module specified ($rule->{modname}; rule #$rcnt)", 1
            unless (exists $self->{MODS}->{$rule->{modname}});

        log_debug { "Processing rule #$rcnt ($rule->{modname})" };
        $self->init_module($rule->{modname});

        my $result = ref ${$data} ? dclone(${$data}) : ${$data};
        my $source = exists $rule->{source} ? thaw($self->{sources}->{$rule->{source}}) : undef;
        $self->{MODS}->{$rule->{modname}}->new->process($data, $rule, $source);

        my $changes = { rule_id => 0 + $rcnt };
        if (defined $rule->{blame} ? $rule->{blame} : $self->{OPTS}->{blame}) {
            my $diff = split_diff(diff($result, ${$data}, noO => 1, noU => 1));
            $changes->{R} = delete $diff->{a} if (exists $diff->{a}); # more obvious
            $changes->{A} = delete $diff->{b} if (exists $diff->{b}); # --"--
        }
        map { $changes->{$_} = $rule->{$_} if (defined $rule->{$_}) }
            qw(blame comment source); # preserve useful info
        push @blame, dclone($changes);
    } continue {
        $rcnt++;
    }

    return @blame;
}

sub resolve_rules {
    my ($self, $opt_src) = @_;

    log_debug { "Resolving rules" };
    $self->{resolved_rules} = dclone($self->{rules});

    for my $rule (@{$self->{resolved_rules}}) {
        # single path may be specified as string, convert it to list
        $rule->{path}->[0] = delete $rule->{path}
            if (exists $rule->{path} and not ref $rule->{path});

        next unless (exists $rule->{source});
        unless (defined $rule->{source} and $rule->{source} ne '') {
            # use processing doc as source
            $rule->{source} = $opt_src;
        }
        next if (exists $self->{sources}->{$rule->{source}});
        $self->{sources}->{$rule->{source}} =
            freeze($self->load_source($rule->{source}, $self->{OPTS}->{ifmt}));
    }

    return $self;
}

1; # End of App::NDTools::NDProc
