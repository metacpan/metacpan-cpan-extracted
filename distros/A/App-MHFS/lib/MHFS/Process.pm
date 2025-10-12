package MHFS::Process v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Symbol 'gensym';
use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
use POSIX ":sys_wait_h";
use IO::Socket::INET;
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use Errno qw(EINTR EIO :POSIX);
use Fcntl qw(:seek :mode);
use File::stat;
use IPC::Open3;
use Scalar::Util qw(looks_like_number weaken);
use Data::Dumper;
use Devel::Peek;
use MHFS::FD::Reader;
use MHFS::FD::Writer;
use MHFS::EventLoop::Poll;
use Carp;

#my %CHILDREN;
#$SIG{CHLD} = sub {
#    while((my $child = waitpid(-1, WNOHANG)) > 0) {
#        my ($wstatus, $exitcode) = ($?, $?>> 8);
#        if(defined $CHILDREN{$child}) {
#            say "PID $child reaped (func) $exitcode";
#            $CHILDREN{$child}->($exitcode);
#            # remove file handles here?
#            $CHILDREN{$child} = undef;
#        }
#        else {
#            say "PID $child reaped (No func) $exitcode";
#        }
#    }
#};

sub _setup_handlers {
    my ($self, $in, $out, $err, $fddispatch, $handlesettings) = @_;
    my $pid = $self->{'pid'};
    my $evp = $self->{'evp'};

    if($fddispatch->{'SIGCHLD'}) {
        say "PID $pid custom SIGCHLD handler";
        #$CHILDREN{$pid} = $fddispatch->{'SIGCHLD'};
        $evp->register_child($pid, $fddispatch->{'SIGCHLD'});
    }
    if($fddispatch->{'STDIN'}) {
        $self->{'fd'}{'stdin'} = MHFS::FD::Writer->new($self, $in, $fddispatch->{'STDIN'});
        $evp->set($in, $self->{'fd'}{'stdin'}, POLLOUT | MHFS::EventLoop::Poll->ALWAYSMASK);
    }
    else {
        $self->{'fd'}{'stdin'}{'fd'} = $in;
    }
    if($fddispatch->{'STDOUT'}) {
        $self->{'fd'}{'stdout'} = MHFS::FD::Reader->new($self, $out, $fddispatch->{'STDOUT'});
        $evp->set($out, $self->{'fd'}{'stdout'}, POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK());
    }
    else {
        $self->{'fd'}{'stdout'}{'fd'} = $out;
    }
    if($fddispatch->{'STDERR'}) {
        $self->{'fd'}{'stderr'} = MHFS::FD::Reader->new($self, $err, $fddispatch->{'STDERR'});
        $evp->set($err, $self->{'fd'}{'stderr'}, POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK);
    }
    else {
        $self->{'fd'}{'stderr'}{'fd'} = $err;
    }

    if($handlesettings->{'O_NONBLOCK'}) {
        # stderr
        {
            my $flags =  fcntl($err, Fcntl::F_GETFL, 0) or die "$!";
            fcntl($err, Fcntl::F_SETFL, $flags | Fcntl::O_NONBLOCK) or die "$!";
        }
        # stdout
        {
            my $flags =  fcntl($out, Fcntl::F_GETFL, 0) or die "$!";
            fcntl($out, Fcntl::F_SETFL, $flags | Fcntl::O_NONBLOCK) or die "$!";
        }
        # stdin
        defined($in->blocking(0)) or die($!);
        #(0 == fcntl($in, Fcntl::F_GETFL, $flags)) or die("$!");#return undef;
        #$flags |= Fcntl::O_NONBLOCK;
        #(0 == fcntl($in, Fcntl::F_SETFL, $flags)) or die;#return undef;
        return $self;
    }
}

sub sigkill {
    my ($self, $cb) = @_;
    if($cb) {
        $self->{'evp'}{'children'}{$self->{'pid'}} = $cb;
    }
    kill('KILL', $self->{'pid'});
}

sub stopSTDOUT {
    my ($self) = @_;
    $self->{'evp'}->set($self->{'fd'}{'stdout'}{'fd'}, $self->{'fd'}{'stdout'}, MHFS::EventLoop::Poll->ALWAYSMASK);
}

sub resumeSTDOUT {
    my ($self) = @_;
    $self->{'evp'}->set($self->{'fd'}{'stdout'}{'fd'}, $self->{'fd'}{'stdout'}, POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK);
}

sub new {
    my ($class, $torun, $evp, $fddispatch, $handlesettings, $env) = @_;
    my %self = ('time' => clock_gettime(CLOCK_MONOTONIC), 'evp' => $evp);


    my %oldenvvars;
    if($env) {
        foreach my $key(keys %{$env}) {
            # save current value
            $oldenvvars{$key} = $ENV{$key};
            # set new value
            $ENV{$key} = $env->{$key};
            my $oldval = $oldenvvars{$key} // '{undef}';
            my $newval = $env->{$key}  // '{undef}';
            say "Changed \$ENV{$key} from $oldval to $newval";
        }
    }

    my ($pid, $in, $out, $err);
    eval{ $pid = open3($in, $out, $err = gensym, @$torun); };
    if($@) {
        say "BAD process";
        return undef;
    }
    $self{'pid'} = $pid;
    say 'PID '. $pid . ' NEW PROCESS: ' . $torun->[0];
    if($env) {
        # restore environment
        foreach my $key(keys %oldenvvars) {
            $ENV{$key} = $oldenvvars{$key};
            my $oldval = $env->{$key} // '{undef}';
            my $newval = $oldenvvars{$key} // '{undef}';
            say "Restored \$ENV{$key} from $oldval to $newval";
        }
    }
    _setup_handlers(\%self, $in, $out, $err, $fddispatch, $handlesettings);
    return bless \%self, $class;
}

sub _new_ex {
    my ($make_process, $make_process_args, $context) = @_;
        my $process;
    $context->{'stdout'} = '';
    $context->{'stderr'} = '';
    my $prochandlers = {
    'STDOUT' => sub {
        my ($handle) = @_;
        my $buf;
        while(read($handle, $buf, 4096)) {
            $context->{'stdout'} .= $buf;
        }
        if($context->{'on_stdout_data'}) {
            $context->{'on_stdout_data'}->($context);
        }
        return 1;
    },
    'STDERR' => sub {
        my ($handle) = @_;
        my $buf;
        while(read($handle, $buf, 4096)) {
            $context->{'stderr'} .= $buf;
        }
        return 1;
    },
    'SIGCHLD' => sub {
        $context->{exit_status} = $_[0];
        my $obuf;
        my $handle = $process->{'fd'}{'stdout'}{'fd'};
        while(read($handle, $obuf, 100000)) {
            $context->{'stdout'} .= $obuf;
            say "stdout sigchld read";
        }
        my $ebuf;
        $handle = $process->{'fd'}{'stderr'}{'fd'};
        while(read($handle, $ebuf, 100000)) {
            $context->{'stderr'} .= $ebuf;
            say "stderr sigchld read";
        }
        if($context->{'on_stdout_data'}) {
            $context->{'on_stdout_data'}->($context);
        }
        $context->{'at_exit'}->($context);
    },
    };

    if($context->{'input'}) {
        $prochandlers->{'STDIN'} = sub {
            my ($fh) = @_;
            while(1) {
                my $curbuf = $context->{'curbuf'};
                if($curbuf) {
                    my $rv = syswrite($fh, $curbuf, length($curbuf));
                    if(!defined($rv)) {
                        if(! $!{EAGAIN}) {
                            say "Critical write error";
                            return -1;
                        }
                        return 1;
                    }
                    elsif($rv != length($curbuf)) {
                        substr($context->{'curbuf'}, 0, $rv, '');
                        return 1;
                    }
                    else {
                        say "wrote all";
                    }
                }
                $context->{'curbuf'} = $context->{'input'}->($context);
                if(! defined $context->{'curbuf'}) {
                    return 0;
                }
            }
        };
    }

    $process = $make_process->($make_process_args, $prochandlers, {'O_NONBLOCK' => 1});
    return $process;
}

# launch a command process with poll handlers
sub _new_cmd {
    my ($mpa, $prochandlers, $handlesettings) = @_;
    return $mpa->{'class'}->new($mpa->{'cmd'}, $mpa->{'evp'}, $prochandlers, $handlesettings);
}

# launch a command process
sub new_cmd_process {
    my ($class, $evp, $cmd, $context) = @_;
    my $mpa = {'class' => $class, 'evp' => $evp, 'cmd' => $cmd};
    return _new_ex(\&_new_cmd, $mpa, $context);
}

# subset of command process, just need the data on SIGCHLD
sub new_output_process {
    my ($class, $evp, $cmd, $handler) = @_;

    return new_cmd_process($class, $evp, $cmd, {
        'at_exit' => sub {
            my ($context) = @_;
            say 'run handler';
            $handler->($context->{'stdout'}, $context->{'stderr'});
        }
    });
}

sub new_io_process {
    my ($class, $evp, $cmd, $handler, $inputdata) = @_;
    my $ctx = {
        'at_exit' => sub {
            my ($context) = @_;
            say 'run handler';
            $handler->($context->{'stdout'}, $context->{'stderr'});
        }
    };
    if(defined $inputdata) {
        $ctx->{'curbuf'} = $inputdata;
        $ctx->{'input'} = sub {
            say "all written";
            return undef;
        };
    }
    return new_cmd_process($class, $evp, $cmd, $ctx);
}

# launch a process without a new exe with poll handlers
sub _new_child {
    my ($mpa, $prochandlers, $handlesettings) = @_;

    my %self = ('time' => clock_gettime(CLOCK_MONOTONIC), 'evp' => $mpa->{'evp'});
    # inreader/inwriter   is the parent to child data channel
    # outreader/outwriter is the child to parent data channel
    # errreader/errwriter is the child to parent log channel
    pipe(my $inreader, my $inwriter)   or die("pipe failed $!");
    pipe(my $outreader, my $outwriter) or die("pipe failed $!");
    pipe(my $errreader, my $errwriter) or die("pipe failed $!");
    # the childs stderr will be UTF-8 text
    binmode($errreader, ':encoding(UTF-8)');
    my $pid = fork() // do {
        say "failed to fork";
        return undef;
    };
    if($pid == 0) {
        close($inwriter);
        close($outreader);
        close($errreader);
        open(STDIN,  "<&", $inreader) or die("Can't dup \$inreader to STDIN");
        open(STDOUT, ">&", $errwriter) or die("Can't dup \$errwriter to STDOUT");
        open(STDERR, ">&", $errwriter) or die("Can't dup \$errwriter to STDERR");
        $mpa->{'func'}->($outwriter);
        exit 0;
    }
    close($inreader);
    close($outwriter);
    close($errwriter);
    $self{'pid'} = $pid;
    say 'PID '. $pid . ' NEW CHILD';
    _setup_handlers(\%self, $inwriter, $outreader, $errreader, $prochandlers, $handlesettings);
    return bless \%self, $mpa->{'class'};
}

sub cmd_to_sock {
    my ($name, $cmd, $sockfh) = @_;
    if(fork() == 0) {
        open(STDOUT, ">&", $sockfh) or die("Can't dup \$sockfh to STDOUT");
        exec(@$cmd);
        die;
    }
    close($sockfh);
}

# launch a process without a new exe with just sigchld handler
sub new_output_child {
    my ($class, $evp, $func, $handler) = @_;
    my $mpa = {'class' => $class, 'evp' => $evp, 'func' => $func};
    return _new_ex(\&_new_child, $mpa, {
        'at_exit' => sub {
            my ($context) = @_;
            $handler->($context->{'stdout'}, $context->{'stderr'}, $context->{exit_status});
        }
    });
}

sub remove {
    my ($self, $fd) = @_;
    $self->{'evp'}->remove($fd);
    say "poll has " . scalar ( $self->{'evp'}{'poll'}->handles) . " handles";
    foreach my $key (keys %{$self->{'fd'}}) {
        if(defined($self->{'fd'}{$key}{'fd'}) && ($fd == $self->{'fd'}{$key}{'fd'})) {
            $self->{'fd'}{$key} = undef;
            last;
        }
    }
}


sub DESTROY {
    my $self = shift;
    say "PID " . $self->{'pid'} . ' DESTROY called';
    foreach my $key (keys %{$self->{'fd'}}) {
        if(defined($self->{'fd'}{$key}{'fd'})) {
            #Dump($self->{'fd'}{$key});
            $self->{'evp'}->remove($self->{'fd'}{$key}{'fd'});
            $self->{'fd'}{$key} = undef;
        }
    }
}

1;
