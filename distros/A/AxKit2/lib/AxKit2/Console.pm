# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2::Console;

use strict;
use warnings;

use IO::Socket;
use AxKit2::Constants;
use Socket qw(IPPROTO_TCP TCP_NODELAY);

use base 'Danga::Socket';

use fields qw(
    alive_time
    create_time
    line
    );
    
use constant CLEANUP_TIME => 5; # seconds

our $PROMPT = "\nEnter command (or \"HELP\" for help)\n> ";

Danga::Socket->AddTimer(CLEANUP_TIME, \&_do_cleanup);

sub create {
    my $class    = shift;
    my $config = shift;
    
    my $PORT = $config->console_port;
    
    return unless $PORT;
    
    my $sock = IO::Socket::INET->new(
            LocalAddr => $config->console_addr || '127.0.0.1',
            LocalPort => $PORT,
            Proto     => 'tcp',
            Type      => SOCK_STREAM,
            Blocking  => 0,
            Reuse     => 1,
            Listen    => SOMAXCONN )
               or die "Error creating server on port $PORT : $@\n";

    IO::Handle::blocking($sock, 0);
    
    my $accept_handler = sub {
        my $csock = $sock->accept;
        return unless $csock;

        if ($::DEBUG) {
            AxKit2::Client->log(LOGDEBUG, "Listen child making a AxKit2::Connection for ", fileno($csock));
        }

        IO::Handle::blocking($csock, 0);
        setsockopt($csock, IPPROTO_TCP, TCP_NODELAY, pack("l", 1)) or die;

        if (my $client = eval { AxKit2::Console->new($csock, $config) }) {
            $client->watch_read(1);
            return;
        } else {
            die("Error creating new Console: $@") if $@;
        }
    };

    Danga::Socket->AddOtherFds(fileno($sock) => $accept_handler);
}

sub max_idle_time       { 30 }
sub max_connect_time    { 180 }
sub event_err { my AxKit2::Connection $self = shift; $self->close("Error") }
sub event_hup { my AxKit2::Connection $self = shift; $self->close("Disconnect (HUP)") }

sub new {
    my $self = shift;
    my $sock = shift;
    my $conf = shift;
    $self = fields::new($self) unless ref($self);

    $self->SUPER::new($sock);

    my $now = time;
    $self->{alive_time} = $self->{create_time} = $now;
    $self->{line} = '';
    
    $self->write($PROMPT);
    
    return $self;
}

sub event_read {
    my AxKit2::Console $self = shift;
    $self->{alive_time} = time;

    my $bref = $self->read(8192);
    return $self->close($!) unless defined $bref;
    $self->process_read_buf($bref);
}

sub process_read_buf {
    my AxKit2::Console $self = shift;
    my $bref = shift;
    $self->{line} .= $$bref;
    
    while ($self->{line} =~ s/^(.*?\n)//) {
        my $line = $1;
        $self->process_line($line);
    }
}

sub process_line {
    my AxKit2::Console $self = shift;
    my $line = shift;
    
    $line =~ s/\r?\n//;
    my ($cmd, @params) = split(/ +/, $line);
    my $meth = "cmd_" . lc($cmd);
    if (my $lookup = $self->can($meth)) {
        $lookup->($self, @params);
        $self->write($PROMPT);
    }
    else {
        # No such method - i.e. unrecognized command
        return $self->write("command '$cmd' unrecognised\n$PROMPT");
    }
}

my %helptext;

$helptext{help} = "HELP [CMD] - Get help on all commands or a specific command";

sub cmd_help {
    my $self = shift;
    my ($subcmd) = @_;
    
    $subcmd ||= 'help';
    $subcmd = lc($subcmd);
    
    if ($subcmd eq 'help') {
        my $txt = join("\n", map { substr($_, 0, index($_, "-")) } sort values(%helptext));
        $self->write("Available Commands:\n\n$txt\n");
    }
    my $txt = $helptext{$subcmd} || "Unrecognised help option. Try 'help' for a full list.";
    $self->write("$txt\n");
}

$helptext{quit} = "QUIT - Exit the console";
sub cmd_quit {
    my $self = shift;
    $self->close;
}

$helptext{list} = "LIST [LIMIT] - List current connections, specify limit or negative limit to shrink list";
sub cmd_list {
    my $self = shift;
    my ($count) = @_;
    
    my $descriptors = Danga::Socket->DescriptorMap;
    
    my $list = "Current" . ($count ? (($count > 0) ? " Oldest $count" : " Newest ".-$count) : "") . " Connections: \n\n";
    my @all;
    foreach my $fd (keys %$descriptors) {
        my $pob = $descriptors->{$fd};
        if ($pob->isa("AxKit2::Connection")) {
            next unless $pob->peer_addr_string; # haven't even started yet
            push @all, [$pob+0, $pob->peer_addr_string, $pob->uptime];
        }
    }
    
    @all = sort { $a->[2] <=> $b->[2] } @all;
    if ($count) {
        if ($count > 0) {
            @all = @all[$#all-($count-1) .. $#all];
        }
        else {
            @all = @all[0..(abs($count) - 1)];
        }
    }
    foreach my $item (@all) {
        $list .= sprintf("%x : %s [%s] Connected %0.2fs\n", map { defined()?$_:'' } @$item);
    }
    
    $self->write( $list );
}

$helptext{kill} = "KILL (\$IP | \$REF) - Disconnect all connections from \$IP or connection reference \$REF";
sub cmd_kill {
    my $self = shift;
    my ($match) = @_;
    
    return $self->write("SYNTAX: KILL (\$IP | \$REF)\n") unless $match;
    
    my $descriptors = Danga::Socket->DescriptorMap;
    
    my $killed = 0;
    my $is_ip = (index($match, '.') >= 0);
    foreach my $fd (keys %$descriptors) {
        my $pob = $descriptors->{$fd};
        if ($pob->isa("Qpsmtpd::PollServer")) {
            if ($is_ip) {
                next unless $pob->connection->remote_ip; # haven't even started yet
                if ($pob->connection->remote_ip eq $match) {
                    $pob->write("550 Your connection has been killed by an administrator\r\n");
                    $pob->disconnect;
                    $killed++;
                }
            }
            else {
                # match by ID
                if ($pob+0 == hex($match)) {
                    $pob->write("550 Your connection has been killed by an administrator\r\n");
                    $pob->disconnect;
                    $killed++;
                }
            }
        }
    }
    
    $self->write("Killed $killed connection" . ($killed > 1 ? "s" : "") . "\n");
}

$helptext{dump} = "DUMP \$REF - Dump a connection using Data::Dumper";
sub cmd_dump {
    my $self = shift;
    my ($ref) = @_;
    
    require Data::Dumper;
    $Data::Dumper::Indent=1;
    $Data::Dumper::Terse=1;
    
    my $descriptors = Danga::Socket->DescriptorMap;
    foreach my $fd (keys %$descriptors) {
        my $pob = $descriptors->{$fd};
        if ($pob->isa("AxKit2::Connection")) {
            if ($pob+0 == hex($ref)) {
                return $self->write( Data::Dumper::Dumper($pob) );
            }
        }
    }
    
    $self->write("Unable to find the connection: $ref. Try the LIST command\n");
}

sub DBI::FIRSTKEY {}

$helptext{leaks} = "LEAKS [DUMP] - Run Devel::GC::Helper to list leaks with optional Dumper output";
sub cmd_leaks {
    my $self = shift;
    my $dump = shift || '';
    $dump = (uc($dump) eq 'DUMP') ? 1 : 0;
    
    $self->write("Gathering GC stats in the background...\n");
    
    my $pid = fork;
    die "Can't fork" unless defined $pid;
    return if $pid;

    require Devel::GC::Helper;
    if ($dump) {
        require Data::Dumper;
        $Data::Dumper::Terse = 1;
        $Data::Dumper::Indent = 1;
        #$Data::Dumper::Deparse = 1;
    }
    
    # Child - run the leak sweep...
    my $leaks = Devel::GC::Helper::sweep();
    foreach my $leak (@$leaks) {
        $self->write("Leaked $leak\n");
        $self->write( Data::Dumper::Dumper($leak) ) if $dump;
    }
    $self->write( "Total leaks: " . scalar(@$leaks) . "\n");
    $self->write($PROMPT);
    
    exit;
}

$helptext{stats} = "STATS - Show status and statistics";
sub cmd_stats {
    my $self = shift;
    
    my $output = "Current Status as of " . gmtime() . " GMT\n\n";
    
    if (defined &AxKit2::Plugin::stats::get_stats) {
        # Stats plugin is loaded
        $output .= AxKit2::Plugin::stats->get_stats;
    }
    
    my $descriptors = Danga::Socket->DescriptorMap;
    
    my $current_connections = 0;
    my $current_dns = 0;
    foreach my $fd (keys %$descriptors) {
        my $pob = $descriptors->{$fd};
        if ($pob->isa("AxKit2::Connection")) {
            $current_connections++;
        }
    }
    
    $output .= "Current Connections: $current_connections\n";
    
    $self->write($output);
}

sub cmd_shutdown {
    my $self = shift;
    Danga::Socket->SetPostLoopCallback(sub { 0 });
    $self->close("shutdown");
}

# Cleanup routine to get rid of timed out sockets
sub _do_cleanup {
    my $now = time;
    
    # AxKit2::Client->log(LOGDEBUG, "do cleanup");
    
    Danga::Socket->AddTimer(CLEANUP_TIME, \&_do_cleanup);
    
    my $sf = __PACKAGE__->get_sock_ref;
    
    my $conns = 0;

    my %max_age;  # classname -> max age (0 means forever)
    my %max_connect; # classname -> max connect time
    my @to_close;
    while (my $k = each %$sf) {
        my AxKit2::Connection $v = $sf->{$k};
        my $ref = ref $v;
        next unless $v->isa('AxKit2::Console');
        $conns++;
        unless (defined $max_age{$ref}) {
            $max_age{$ref}      = $ref->max_idle_time || 0;
            $max_connect{$ref}  = $ref->max_connect_time || 0;
        }
        if (my $t = $max_connect{$ref}) {
            if ($v->{create_time} < $now - $t) {
                push @to_close, $v;
                next;
            }
        }
        if (my $t = $max_age{$ref}) {
            if ($v->{alive_time} < $now - $t) {
                push @to_close, $v;
            }
        }
    }
    
    $_->close("Timeout") foreach @to_close;
}

1;
