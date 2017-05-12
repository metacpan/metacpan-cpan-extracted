package App::MrShell;

use strict;
use warnings;

use Carp;
use POSIX;
use Config::Tiny;
use POE qw( Wheel::Run );
use Term::ANSIColor qw(:constants);
use Text::Balanced;

our $VERSION = '2.0207';
our @DEFAULT_SHELL_COMMAND = (ssh => '-o', 'BatchMode yes', '-o', 'StrictHostKeyChecking no', '-o', 'ConnectTimeout 20', '[%u]-l', '[]%u', '%h');

# new {{{
sub new {
    my $class = shift;
    my $this  = bless { hosts=>[], cmd=>[], _shell_cmd=>[@DEFAULT_SHELL_COMMAND] }, $class;

    return $this;
}
# }}}

# _process_space_delimited {{{
sub _process_space_delimited {
    my $this = shift;
    my $that = shift;

    my @output;
    while( $that ) {
        if( $that =~ m/^\s*['"]/ ) {
            my ($tok, $rem) = Text::Balanced::extract_delimited($that, qr(["']));

            ($tok =~ s/^(['"])// and $tok =~ s/$1$//) or die "internal error processing space delimited";

            push @output, $tok;
            $that = $rem;

        } else {
            my ($tok, $rem) = split ' ', $that, 2; 

            push @output, $tok;
            $that = $rem;
        }
    }

    return @output
}
# }}}
# _process_hosts {{{
sub _process_hosts {
    my $this = shift;

    my @h = do {
        my @tmp = map { my $k = $_; $k =~ s/^\@// ? @{$this->{groups}{$k} or die "couldn't find group: \@$k\n"} : $_ } @_;
        my %h; @h{@tmp} = ();
        for(keys %h) {
            if(my ($k) = m/^\-(.+)/) {
                delete $h{$_};
                delete $h{$k};
            }
        }
        sort keys %h;
    };

    my $o = my $l = $this->{_host_width} || 0;
    for( map { length $this->_host_route_to_nick($_) } @h ) {
        $l = $_ if $_>$l
    }

    $this->{_host_width} = $l if $l != $o;

    return @h;
}
# }}}
# _host_route_to_nick {{{
sub _host_route_to_nick {
    my $this = shift;

    return join "", shift =~ m/(?:!|[^!]+$)/g
}
# }}}

# set_shell_command_option {{{
sub set_shell_command_option {
    my $this = shift;
    my $arg = shift;

    if( ref($arg) eq "ARRAY" ) {
        $this->{_shell_cmd} = [ @$arg ]; # make a real copy

    } else {
        $this->{_shell_cmd} = [ $this->_process_space_delimited($arg||"") ];
    }

    return $this;
}
# }}}
# set_group_option {{{
sub set_group_option {
    my $this   = shift;
    my $groups = ($this->{groups} ||= {});

    my ($name, $value);
    while( ($name, $value) = splice @_, 0, 2 and $name and $value ) {
        if( ref($value) eq "ARRAY" ) {
            $groups->{$name} = [ @$value ]; # make a real copy

        } else {
            $groups->{$name} = [ $this->_process_space_delimited( $value ) ];
        }
    }

    my @groups = keys %{ $this->{groups} };
    my $replace_limit = 30;
    REPLACE_GROPUS: {
        my $replaced = 0;

        for my $group (@groups) {
            my $hosts = $groups->{$group};

            my $r = 0;
            for(@$hosts) {
                if( m/^@(.+)/ ) {
                    if( my $g = $groups->{$1} ) {
                        $_ = $g;

                        $r ++;
                    }
                }
            }

            if( $r ) {
                my %h;
                @h{ map {ref $_ ? @$_ : $_} @$hosts } = ();
                $groups->{$group} = [ keys %h ];
                $replaced ++;
            }
        }

        $replace_limit --;
        last if $replace_limit < 1;
        redo if $replaced;
    }

    return $this;
}
# }}}
# set_logfile_option {{{
sub set_logfile_option {
    my $this = shift;
    my $file = shift;
    my $trunc = shift;

    unless( our $already_compiled++ ) {
        my $load_ansi_filter_package = q {
            package App::MrShell::ANSIFilter;
            use Symbol;
            use Tie::Handle;
            use base 'Tie::StdHandle';

            my %orig;

            sub PRINT {
                my $this = shift;
                my @them = @_;
                s/\e\[[\d;]+m//g for @them;
                print {$orig{$this}} @them;
            }

            sub filtered_handle {
                my $pfft = gensym();
                my $it = tie *{$pfft}, __PACKAGE__ or die $!;
                $orig{$it} = shift;
                $pfft;
            }

        1};

        eval $load_ansi_filter_package or die $@; ## no critic -- sometimes this kind of eval is ok
        # (This probably isn't one of them.)
    }

    open my $log, ($trunc ? ">" : ">>"), $file or croak "couldn't open $file for write: $!"; ## no critic -- I mean to pass this around, shut up

    $this->{_log_fh} = App::MrShell::ANSIFilter::filtered_handle($log);

    return $this;
}
# }}}
# set_debug_option {{{
sub set_debug_option {
    my $this = shift;
    my $val = shift;

    # -d 0 and -d 1 are the same
    # -d 2 is a level up, -d 4 is even more
    # $val==undef clears the setting

    if( not defined $val ) {
        delete $this->{debug};
        return $this;
    }

    $this->{debug} = $val ? $val : 1;

    return $this;
}
# }}}
# set_no_command_escapes_option {{{
sub set_no_command_escapes_option {
    my $this = shift;

    $this->{no_command_escapes} = shift || 0;

    return $this;
}
# }}}

# groups {{{
sub groups {
    my $this = shift;

    return unless $this->{groups};
    return wantarray ? %{$this->{groups}} : $this->{groups};
}
# }}}

# set_usage_error($&) {{{
sub set_usage_error($&) { ## no critic -- prototypes are bad how again?
    my $this = shift;
    my $func = shift;
    my $pack = caller;
    my $name = $pack . "::$func";
    my @args = @_;

    $this->{_usage_error} = sub {
        no strict 'refs'; ## no critic -- how would you call this by name without this?
        $name->(@args)
    };

    return $this;
}
# }}}
# read_config {{{
sub read_config {
    my ($this, $that) = @_;

    $this->{_conf} = Config::Tiny->read($that) if -f $that;

    for my $group (keys %{ $this->{_conf}{groups} }) {
        $this->set_group_option( $group => $this->{_conf}{groups}{$group} );
    }

    if( my $c = $this->{_conf}{options}{'shell-command'} ) {
        $this->set_shell_command_option( $c );
    }

    if( my $c = $this->{_conf}{options}{'logfile'} ) {
        my $t = $this->{_conf}{options}{'truncate-logfile'};
        my $v = ($t ? 1:0);
           $v = 0 if $t =~ m/(?:no|false)/i;

        $this->set_logfile_option($c, $v);
    }

    if( my $c = $this->{_conf}{options}{'no-command-escapes'} ) {
        my $v = ($c ? 1:0);
           $v = 0 if $c =~ m/(?:no|false)/i;

        $this->set_no_command_escapes_option( $v );
    }

    return $this;
}
# }}}
# set_hosts {{{
sub set_hosts {
    my $this = shift;

    $this->{hosts} = [ $this->_process_hosts(@_) ];

    return $this;
}
# }}}
# queue_command {{{
sub queue_command {
    my $this = shift;
    my @hosts = @{$this->{hosts}};

    unless( @hosts ) {
        if( my $h = $this->{_conf}{options}{'default-hosts'} ) {
            @hosts = $this->_process_hosts( $this->_process_space_delimited($h) );

        } else {
            if( my $e = $this->{_usage_error} ) {
                warn "Error: no hosts specified\n";
                $e->();

            } else {
                croak "set_hosts before issuing queue_command";
            }
        }
    }

    for my $h (@hosts) {
        push @{$this->{_cmd_queue}{$h}}, [@_]; # make a real copy
    }

    return $this;
}
# }}}
# run_queue {{{
sub run_queue {
    my $this = shift;

    $this->{_session} = POE::Session->create( inline_states => {
        _start       => sub { $this->poe_start(@_) },
        child_stdout => sub { $this->line(1, @_) },
        child_stderr => sub { $this->line(2, @_) },
        child_signal => sub { $this->sigchld(@_) },
        stall_close  => sub { $this->_close(@_) },
        ErrorEvent   => sub { $this->error_event },
    });

    POE::Kernel->run();

    return $this;
}
# }}}

# std_msg {{{
sub std_msg {
    my $this  = shift;
    my $host  = shift;
    my $cmdno = shift;
    my $fh    = shift;
    my $msg   = shift;

    my $host_msg = $host ? $this->_host_route_to_nick($host) . ": " : "";
    my $time_str = strftime('%H:%M:%S', localtime);

    print $time_str,
        sprintf(' %-*s', $this->{_host_width}+2, $host_msg),
            ( $fh==2 ? ('[',BOLD,YELLOW,'stderr',RESET,'] ') : () ), $msg, RESET, "\n";

    if( $this->{_log_fh} ) {
        $time_str = strftime('%Y-%m-%d %H:%M:%S', localtime);

        # No point in printing colors, stripped anyway.  Formatting columns is
        # equally silly -- in append mode anyway.
        $host_msg = $host ? "$host: " : "";
        print {$this->{_log_fh}} "$time_str $host_msg", ($fh==2 ? "[stderr] " : ""), $msg, "\n";
    }

    return $this;
}
# }}}

# line {{{
sub line {
    my $this = shift;
    my $fh   = shift;
    my ($line, $wid) = @_[ ARG0, ARG1 ];
    my ($kid, $host, $cmdno, $lineno) = @{$this->{_wid}{$wid}};

    $$lineno ++;
    $this->std_msg($host, $cmdno, $fh, $line);

    return;
}
# }}}

# sigchld {{{
sub _sigchld_exit_error {
    my $this = shift;
    my ($pid, $exit) = @_[ ARG1, ARG2 ];
    $exit >>= 8;

    $this->std_msg("?", -1, 0, BOLD.RED."-- sigchld received for untracked pid($pid, $exit), probably a bug in Mr. Shell --");

    return;
}

sub sigchld {
    my $this = shift; # ARG0 is the signal name string
    my ($kid, $host, $cmdno, @c) = @{ $this->{_pid}{ $_[ARG1] } || return $this->_sigchld_exit_error(@_) };

    # NOTE: this usually isn't an error, sometimes the sigchild will arrive
    # before the handles are "closed" in the traditional sense.  We get error
    # eveents for errors.
    #### # $this->std_msg($host, $cmdno, 0, RED.'-- error: unexpected child exit --');

    # NOTE: though, the exit value may indicate an actual error.
    if( (my $exit = $_[ARG2]) != 0 ) {
        # XXX: I'd like to do more here but I'm waiting to see what Paul
        # Fenwick has to say about it.
        $exit >>= 8;

        my $reset = RESET;
        my $black = BOLD.BLACK;
        my $red   = RESET.RED;

        $this->std_msg($host, $cmdno, 0, "$black-- shell exited with nonzero status: $red$exit$black --");
    }

    $_[KERNEL]->yield( stall_close => $kid->ID, 0 );

    return;
}
# }}}
# _close {{{
sub _close {
    my $this = shift;
    my ($wid, $count) = @_[ ARG0, ARG1 ];

    return unless $this->{_wid}{$wid}; # sometimes we'll get a sigchild *and* a close event

    # NOTE: I was getting erratic results with some fast running commands and
    # guessed that I was sometimes getting the close event before the stdout
    # event. Waiting through the kernel loop once is probably enough, but I
    # used 3 because it does't hurt either.

    if( $count > 3 ) {
        my ($kid, $host, $cmdno, $lineno, @c) = @{ delete $this->{_wid}{$wid} };

        $this->std_msg($host, $cmdno++, 0, BOLD.BLACK.'-- eof --') if $$lineno == 0;
        if( @c ) {
            $this->start_queue_on_host($_[KERNEL] => $host, $cmdno, @c);
            $this->std_msg($host, $cmdno, 0, BOLD.BLACK."-- starting: @{$c[0]} --");
        }

        delete $this->{_pid}{ $kid->PID };

    } else {
        $_[KERNEL]->yield( stall_close => $wid, $count+1 );
    }

    return;
}
# }}}
# error_event {{{
sub error_event {
    my $this = shift;
    my ($operation, $errnum, $errstr, $wid) = @_[ARG0 .. ARG3];
    my ($kid, $host, $cmdno, @c) = @{ delete $this->{_wid}{$wid} || return };
    delete $this->{_pid}{ $kid->PID };

    $errstr = "remote end closed" if $operation eq "read" and not $errnum;
    $this->std_msg($host, $cmdno, 0, RED."-- $operation error $errnum: $errstr --");

    return;
}
# }}}

# set_subst_vars {{{
sub set_subst_vars {
    my $this = shift;

    while( my ($k,$v) = splice @_, 0, 2 ) {
        $this->{_subst}{$k} = $v unless exists $this->{_subst}{$k};
    }

    return $this;
}
# }}}
# subst_cmd_vars {{{
sub subst_cmd_vars {
    my $this = shift;
    my %h = %{ delete($this->{_subst}) || {} };
    my $host = $h{'%h'};

    my @c = @_; # copy this so it doesn't get altered upstream
                # (I'd swear I shoulnd't need to do this at all, but it's
                #  proovably true that I do.)

    if( $host =~ m/\b(?!<\\)!/ ) {
        my @hosts = split '!', $host;

        my @indexes_of_replacements;
        for(my $i=0; $i<@c; $i++) {
            if( $c[$i] eq '%h' ) {
                splice @c, $i, 1, $hosts[0];

                push @indexes_of_replacements, $i;

                for my $h (reverse @hosts[1 .. $#hosts]) {
                    splice @c, $i+1, 0, @c[0 .. $i-1] => $h;
                    push @indexes_of_replacements, $i+1 + $indexes_of_replacements[-1];

                    unless( $this->{no_command_escapes} ) {
                        for my $arg (@c[$i+1 .. $#c]) {

                            # NOTE: This escaping is going to be an utter pain to maintain...

                            $arg =~ s/([`\$])/\\$1/g;

                            if( $arg =~ m/[\s()]/ ) {
                                $arg =~ s/([\\"])/\\$1/g;
                                $arg = "\"$arg\"";
                            }
                        }
                    }
                }
            }
        }

        my $beg = 0;
        for my $i (@indexes_of_replacements) {
            if( $c[$i] =~ s/^([\w.\-_]+)@// ) {
                my $u = $1;
                for(@c[$beg .. $i-1]) {
                    s/^(\[\%u\]|\[\](?=\%u))//;
                    $_ = $u if $_ eq '%u';
                }

            } else {
                # NOTE: there's really no need to go through and remove [%u]
                # conditional options, they'll automatically get nuked below
                $c[$i] =~ s/\\@/@/g;
            }
            $beg = $i+1;
        }

        delete $h{'%h'};

    } else {
        $h{'%h'} =~ s/\\!/!/g;
    }

    if( $h{'%h'} ) {
        $h{'%u'} = $1 if $h{'%h'} =~ s/^([\w.\-_]+)@//;
        $h{'%h'} =~ s/\\@/@/g;
    }

    @c = map {exists $h{$_} ? $h{$_} : $_}
         map { m/^\[([^\[\]]+)\]/ ? ($h{$1} ? do{s/^\[\Q$1\E\]//; $_} : ()) : ($_) } ## no critic: why on earth not?
         map { s/\[\]\%(\w+)/[\%$1]\%$1/; $_ }                                       ## no critic: why on earth not?
         @c;

    if( $this->{debug} ) {
        local $" = ")(";
        $this->std_msg($host, $h{'%n'}, 0, BOLD.BLACK."DEBUG: exec(@c)");
    }

    return @c;
}
# }}}
# start_queue_on_host {{{
sub start_queue_on_host {
    my ($this, $kernel => $host, $cmdno, $cmd, @next) = @_;

    # NOTE: used (and deleted) by subst_cmd_vars
    $this->set_subst_vars(
        '%h' => $host,
        '%n' => $cmdno,
    );

    my $kid = POE::Wheel::Run->new(
        Program     => [ my @debug_rq = ($this->subst_cmd_vars(@{$this->{_shell_cmd}} => @$cmd)) ],
        StdoutEvent => "child_stdout",
        StderrEvent => "child_stderr",
        CloseEvent  => "child_close",
    );

    $kernel->sig_child( $kid->PID, "child_signal" );

    my $lineno = 0;
    my $info = [ $kid, $host, $cmdno, \$lineno, @next ];
    $this->{_wid}{ $kid->ID } = $this->{_pid}{ $kid->PID } = $info;

    return;
}
# }}}

# poe_start {{{
sub poe_start {
    my $this = shift;

    my %starting;
    my @hosts = keys %{ $this->{_cmd_queue} };
    for my $host (@hosts) {
        my @c = @{ $this->{_cmd_queue}{$host} };

        $this->start_queue_on_host($_[KERNEL] => $host, 1, @c);
        push @{$starting{"@{$c[0]}"}}, $host;
    }

    for my $message (keys %starting) {
        my @hosts = @{ $starting{$message} };

        if( @hosts == 1 ) {
            $this->std_msg($this->_host_route_to_nick($hosts[0]), 1, 0, BOLD.BLACK."-- starting: $message --");

        } else {
            $this->std_msg("", 1, 0, BOLD.BLACK."-- starting: $message on @hosts --");
        }
    }

    delete $this->{_cmd_queue};

    return;
}
# }}}

1;
