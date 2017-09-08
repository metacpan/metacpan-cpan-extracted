package App::RemoteCommand;
use strict;
use warnings;

use App::RemoteCommand::Pool;
use App::RemoteCommand::SSH;
use App::RemoteCommand::Util 'prompt';

use File::Basename ();
use File::Temp ();
use Getopt::Long qw(:config no_auto_abbrev no_ignore_case bundling);
use List::Util ();
use POSIX 'strftime';
use Pod::Usage 'pod2usage';
use String::Glob::Permute 'string_glob_permute';

use constant TICK_SECOND => 0.1;
use constant DEBUG => $ENV{PERL_RCOMMAND_DEBUG} ? 1 : 0;

our $VERSION = '0.92';

my $SCRIPT = File::Basename::basename($0);
my $SUDO_PROMPT = sprintf "sudo password (asking with %s): ", $SCRIPT;
my $SUDO_FAIL = "Sorry, try again.";

sub logger { my $f = shift; $f = "-> $f\n"; warn @_ ? sprintf $f, @_ : $f }

sub new {
    my ($class, %option) = @_;
    bless {
        %option,
        pending => [],
        relay => App::RemoteCommand::Pool->new,
        running => App::RemoteCommand::Pool->new,
    }, $class;
}

sub run {
    my ($self, @argv) = @_;
    $self = $self->new unless ref $self;
    $self->parse_options(@argv);
    $self->register;

    my $INT; local $SIG{INT} = sub { $INT++ };
    my $TERM; local $SIG{TERM} = sub { $TERM++ };
    while (1) {
        if ($INT || $TERM) {
            $self->handle_signal($TERM ? "TERM" : "INT");
            $INT = $TERM = 0;
        }
        $self->one_tick;
        last if @{$self->{pending}} == 0
             && $self->{relay}->count == 0
             && $self->{running}->count == 0;
    }

    my @success = sort grep { $self->{exit}{$_} == 0 } keys %{$self->{exit}};
    my @fail    = sort grep { $self->{exit}{$_} != 0 } keys %{$self->{exit}};
    if (!$self->{quiet}) {
        print STDERR "\e[32mSUCCESS\e[m $_\n" for @success;
        print STDERR "\e[31mFAIL\e[m $_\n"    for @fail;
    }
    return @fail ? 1 : 0;
}

sub parse_options {
    my ($self, @argv) = @_;
    local @ARGV = @argv;
    GetOptions
        "c|concurrency=i"     => \($self->{concurrency} = 5),
        "h|help"              => sub { pod2usage(verbose => 99, sections => 'SYNOPSIS|OPTIONS|EXAMPLES') },
        "s|script=s"          => \($self->{script}),
        "v|version"           => sub { printf "%s %s\n", __PACKAGE__, $VERSION; exit },
        "a|ask-sudo-password" => \(my $ask_sudo_password),
        "H|host-file=s"       => \(my $host_file),
        "sudo-password=s"     => \($self->{sudo_password}),
        "append-hostname!"    => \(my $append_hostname = 1),
        "append-time!"        => \(my $append_time),
        "sudo=s"              => \($self->{sudo_user}),
        "q|quiet"             => \($self->{quiet}),
    or exit(2);

    my $host_arg = $host_file ? undef : shift @ARGV;
    if ($self->{script}) {
        $self->{script_arg} = \@ARGV;
    } else {
        $self->{command} = \@ARGV;
    }

    if (!@{$self->{command} || []} && !$self->{script}) {
        warn "COMMANDS or --script option is required\n";
        exit(2);
    }
    if ($self->{script}) {
        open my $fh, "<", $self->{script} or die "$self->{script}: $!\n";
        my $content = do { local $/; <$fh> };
        my ($tempfh, $tempfile) = File::Temp::tempfile(UNLINK => 1, EXLOCK => 0);
        print {$tempfh} $content;
        close $tempfh;
        chmod 0700, $tempfile;
        $self->{script} = $tempfile;
    }

    $self->{format} = $self->make_format(
        append_hostname => $append_hostname,
        append_time => $append_time,
    );

    if ($ask_sudo_password) {
        my $password = prompt $SUDO_PROMPT;
        $self->{sudo_password} = $password;
    }
    $self->{host} = $host_file ? $self->parse_host_file($host_file)
                               : $self->parse_host_arg($host_arg);
    $self;
}

sub handle_signal {
    my ($self, $name) = @_;
    DEBUG and logger "handling signal $name";
    for my $ssh ($self->{running}->all) {
        $ssh->cancel;
        if ($ssh->type eq "cmd") {
            DEBUG and logger "kill %s, %d", $name, $ssh->pid;
            kill $name => $ssh->pid;
        }
    }
    @{$self->{pending}} = ();
    $self->{relay}->remove_all; # this might block
}

sub one_tick {
    my $self = shift;

    DEBUG and logger "one tick";
    DEBUG and logger "running %d, relay %d, pending %d",
        $self->{running}->count, $self->{relay}->count, scalar @{$self->{pending}};

    while ($self->{relay}->count + $self->{running}->count < $self->{concurrency} and my $ssh = shift @{$self->{pending}}) {
        DEBUG and logger "start %s", $ssh->host;
        $ssh->start;
        $self->{relay}->add($ssh);
    }

    for my $ssh (grep { $_->is_ready } $self->{relay}->all) {
        $self->{relay}->remove(host => $ssh->host);
        if ($ssh->next and !$ssh->error) {
             DEBUG and logger "next %s, pid %d", $ssh->host, $ssh->pid;
             $self->{running}->add($ssh);
        } else {
            print $self->{format}->($ssh->host, $ssh->error || "FAILED");
            $self->{exit}{$ssh->host} = 255;
        }
    }

    if ($self->{running}->select->count == 0) {
        select undef, undef, undef, TICK_SECOND;
    }

    my $NEED_STOP;
    for my $fh ($self->{running}->select->can_read(TICK_SECOND)) {
        my $ssh = $self->{running}->find(fh => $fh);
        my $n = sysread $fh, my $buf, 64*1024;
        my ($errno, $errmsg) = (0+$!, "$!");
        DEBUG and logger "read %s, pid %d, len %s", $ssh->host, $ssh->pid, defined $n ? $n : 'undef';
        if ($n) {
            my $host = $ssh->host;
            my $buffer = $ssh->buffer;
            if (my @line = $buffer->add($buf)->get) {
                print $self->{format}->($host, $_) for @line;
                if ($ssh->sudo and @line == 1 and $line[0] eq $SUDO_FAIL) {
                    $NEED_STOP++;
                    $self->{running}->select->remove($fh);
                    $ssh->delete_fh;
                    close $fh;
                }
            }
            if (!$ssh->sudo and $buffer->raw eq $SUDO_PROMPT) {
                $ssh->sudo(1);
                my ($line) = $buffer->get(1);
                print $self->{format}->($host, $line);
                if (my $sudo_password = $self->{sudo_password}) {
                    syswrite $fh, "$sudo_password\n";
                } else {
                    $NEED_STOP++;
                    my $err = "have to provide sudo passowrd first, try again with --ask-sudo-password option.";
                    print $self->{format}->($host, $err);
                    $self->{running}->select->remove($fh);
                    $ssh->delete_fh;
                    close $fh;
                }
            }
        } elsif (!defined $n) {
            if ($errno != Errno::EIO) { # this happens when use ssh proxy, so skip
                print $self->{format}->($ssh->host, "sysread $errmsg");
            }
        }
    }
    @{$self->{pending}} = () if $NEED_STOP;

    my $pid = waitpid -1, POSIX::WNOHANG;
    my $exit = $?;
    return if $pid == 0 || $pid == -1;

    my $ssh = $self->{running}->remove(pid => $pid);
    if (!$ssh) {
        my $ssh;
        if ($ssh = $self->{relay}->remove(master_pid => $pid)) {
            # login fails, cannot resolve hostname, ...
            DEBUG and logger "wait %s, master pid %d", $ssh->host, $pid;
            $ssh->master_exited;
            my $err = $ssh->error || "master process exited unexpectedly";
            print $self->{format}->($ssh->host, $err);
            $self->{exit}{$ssh->host} = $exit == 0 ? 255 : $exit;
            return;
        } elsif ($ssh = $self->{running}->remove(master_pid => $pid)) {
            # THIS IS UNEXPECTED
            DEBUG and logger "wait %s, master pid %d", $ssh->host, $pid;
            $ssh->master_exited;
            my $err = $ssh->error || "master process exited unexpectedly";
            print $self->{format}->($ssh->host, $err);
            $self->{exit}{$ssh->host} = $exit == 0 ? 255 : $exit;
            return;
        } else {
            die "Must not reach here";
        }
    }
    DEBUG and logger "wait %s, pid %d, exit %d", $ssh->host, $pid, $exit;
    if (my $fh = $ssh->fh) {
        my $rest = do { local $/; <$fh> };
        my $buffer = $ssh->buffer;
        $buffer->add($rest) if length $rest;
        my @line = $buffer->get(1);
        my $host = $ssh->host;
        print $self->{format}->($host, $_) for @line;
    }

    if ($ssh->type eq 'cmd') {
        $self->{exit}{$ssh->host} = $exit;
        $ssh->cancel if $exit != 0;
    }

    if ($ssh->next) {
        if (!$ssh->error) {
            DEBUG and logger "next %s, pid %d", $ssh->host, $ssh->pid;
            $self->{running}->add($ssh);
        } else {
            print $self->{format}->($ssh->host, $ssh->error || "FAILED");
            $self->{exit}{$ssh->host} = 255 if $ssh->type eq "cmd";
        }
    }

}

sub register {
    my $self = shift;

    my @prefix = ("env", "SUDO_PROMPT=$SUDO_PROMPT");
    push @prefix, "sudo", "-u", $self->{sudo_user} if $self->{sudo_user};

    my (@ssh_cmd, $ssh_at_exit);
    my @command;
    if (my $script = $self->{script}) {
        my $name = sprintf "/tmp/%s.%d.%d", $SCRIPT, time, rand(10_000);
        push @ssh_cmd, sub {
            my $ssh = shift;
            my $pid = $ssh->scp_put({async => 1, copy_attrs => 1}, $script, $name);
            return ($pid, undef);
        };
        $ssh_at_exit = sub {
            my $ssh = shift;
            my $pid = $ssh->system({async => 1}, "rm", "-f", $name);
            return ($pid, undef);
        };
        @command = (@prefix, $name, @{$self->{script_arg}});
    } else {
        @command = @{$self->{command}};
        unshift @command, "bash", "-c" if @command == 1;
        unshift @command, @prefix;
    }
    DEBUG and logger "execute: %s", join(" ", map { qq('$_') } @command);
    push @ssh_cmd, sub {
        my $ssh = shift;
        my ($fh, $pid) = $ssh->open2pty(@command);
        return ($pid, $fh);
    };

    for my $host (@{$self->{host}}) {
        my $ssh = App::RemoteCommand::SSH->new($host);
        $ssh->add($_) for @ssh_cmd;
        $ssh->at_exit($ssh_at_exit) if $ssh_at_exit;
        push @{$self->{pending}}, $ssh;
    }
}

sub make_format {
    my ($self, %opt) = @_;
    if ($opt{append_time} && $opt{append_hostname}) {
        sub { my ($host, $msg) = @_; "[@{[strftime '%F %T', localtime]}][$host] $msg\n" };
    } elsif ($opt{append_time}) {
        sub { my ($host, $msg) = @_; "[@{[strftime '%F %T', localtime]}] $msg\n" };
    } elsif ($opt{append_hostname}) {
        sub { my ($host, $msg) = @_; "[$host] $msg\n" };
    } else {
        sub { my ($host, $msg) = @_; "$msg\n" };
    }
}

sub parse_host_arg {
    my ($self, $host_arg) = @_;
    [ List::Util::uniq string_glob_permute($host_arg) ];
}

sub parse_host_file {
    my ($self, $host_file) = @_;
    open my $fh, "<", $host_file or die "Cannot open '$host_file': $!\n";
    my @host;
    while (my $line = <$fh>) {
        $line =~ s/^\s+//; $line =~ s/\s+$//;
        push @host, string_glob_permute($line) if $line =~ /^[^#\s]/;
    }
    [ List::Util::uniq @host ];
}

1;
__END__

=encoding utf-8

=for stopwords passphrase

=head1 NAME

App::RemoteCommand - simple remote command launcher via ssh

=head1 SYNOPSIS

    > rcommand [OPTIONS] HOSTS COMMANDS
    > rcommand [OPTIONS] --script SCRIPT HOSTS
    > rcommand [OPTIONS] --host-file FILE COMMANDS

=head1 DESCRIPTION

=begin html

<a href="https://asciinema.org/a/119109?autoplay=1" target="_blank"><img src="https://asciinema.org/a/119109.png" alto="usage" /></a>

=end html

App::RemoteCommand is a simple remote command launcher via ssh. The features are:

=over 4

=item * execute remote command in parallel

=item * remember sudo password first, and never ask again

=item * you may specify a script file in local machine

=item * append hostname and time to each command output lines

=item * report success/fail summary

=back

=head1 CAVEATS

Currently this module assumes you can ssh the target hosts
without password or passphrase.
So if your ssh identity (ssh private key) requires a passphrase,
please use C<ssh-agent>.

=head1 LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji

=cut
