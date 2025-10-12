package MHFS::HTTP::Server::Client v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
use IO::Socket::INET;
use Errno qw(EINTR EIO :POSIX);
use Fcntl qw(:seek :mode);
use File::stat;
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use Scalar::Util qw(looks_like_number weaken);
use Data::Dumper;
use Carp;
use MHFS::HTTP::Server::Client::Request;

sub new {
    my ($class, $sock, $server, $serverhostinfo, $ip) = @_;
    $sock->blocking(0);
    my %self = ('sock' => $sock, 'server' => $server, 'time' => clock_gettime(CLOCK_MONOTONIC), 'inbuf' => '', 'serverhostname' => $serverhostinfo->{'hostname'}, 'absurl' => $serverhostinfo->{'absurl'}, 'ip' => $ip, 'X-MHFS-PROXY-KEY' => $serverhostinfo->{'X-MHFS-PROXY-KEY'});
    $self{'CONN-ID'} = int($self{'time'} * rand()); # insecure uid
    $self{'outheaders'}{'X-MHFS-CONN-ID'} = sprintf("%X", $self{'CONN-ID'});
    bless \%self, $class;
    $self{'request'} = MHFS::HTTP::Server::Client::Request->new(\%self);
    return \%self;
}

# add a connection timeout timer
sub AddClientCloseTimer {
    my ($self, $timelength, $id, $is_requesttimeout) = @_;
    weaken($self); #don't allow this timer to keep the client object alive
    my $server = $self->{'server'};
    say "CCT | add timer: $id";
    $server->{'evp'}->add_timer($timelength, 0, sub {
        if(! defined $self) {
            say "CCT | $id self undef";
            return undef;
        }
        # Commented out as with connection reuse on, Apache 2.4.10 seems sometimes
        # pass 408 on to the next client.
        #if($is_requesttimeout) {
        #    say "CCT | \$timelength ($timelength) exceeded, sending 408";
        #    $self->{request}->Send408;
        #    CT_WRITE($self);
        #}
        say "CCT | \$timelength ($timelength) exceeded, closing CONN $id";
        say "-------------------------------------------------";
        $server->{'evp'}->remove($self->{'sock'});
        say "poll has " . scalar ( $server->{'evp'}{'poll'}->handles) . " handles";
        return undef;
    }, $id);
    return $id;
}

sub KillClientCloseTimer {
    my ($self, $id) = @_;
    my $server = $self->{'server'};
    say "CCT | removing timer: $id";
    $server->{'evp'}->remove_timer_by_id($id);
}

sub SetEvents {
    my ($self, $events) = @_;
    $self->{'server'}{'evp'}->set($self->{'sock'}, $self, $events);
}

use constant {
    RECV_SIZE => 65536,
    CT_YIELD => 1,
    CT_DONE  => undef,
    #CT_READ => 1,
    #CT_PROCESS = 2,
    #CT_WRITE => 3
};

# The "client_thread" consists of 5 states, CT_READ, CT_PROCESS, CT_WRITE, CT_YIELD, and CT_DONE
# CT_READ reads input data from the socket
##    on data read transitions to CT_PROCESS
##    on error transitions to CT_DONE
##    otherwise CT_YIELD

# CT_PROCESS processes the input data
##    on processing done, switches to CT_WRITE or CT_READ to read more data to process
##    on error transitions to CT_DONE
##    otherwise CT_YIELD

# CT_WRITE outputs data to the socket
##   on all data written transitions to CT_PROCESS unless Connection: close is set.
##   on error transitions to CT_DONE
##   otherwise CT_YIELD

# CT_YIELD just returns control to the poll loop to wait for IO or allow another client thread to run

# CT_DONE also returns control to the poll loop, it is called on error or when the client connection should be closed or is closed

sub CT_READ {
    my ($self) = @_;
    my $tempdata;
    if(!defined($self->{'sock'}->recv($tempdata, RECV_SIZE))) {
        if(! ($!{EAGAIN} || $!{EWOULDBLOCK})) {
            print ("CT_READ RECV errno: $!\n");
            return CT_DONE;
        }
        say "CT_YIELD: $!";
        return CT_YIELD;
    }
    if(length($tempdata) == 0) {
        say 'Server::Client read 0 bytes, client read closed';
        return CT_DONE;
    }
    $self->{'inbuf'} .= $tempdata;
    goto &CT_PROCESS;
}

sub CT_PROCESS {
    my ($self) = @_;
    $self->{'request'} //= MHFS::HTTP::Server::Client::Request->new($self);
    if(!defined($self->{'request'}{'on_read_ready'})) {
        die("went into CT_PROCESS in bad state");
        return CT_YIELD;
    }
    my $res = $self->{'request'}{'on_read_ready'}->($self->{'request'});
    if(!$res) {
        return $res;
    }
    if(defined $self->{'request'}{'response'}) {
        goto &CT_WRITE;
    }
    elsif(defined $self->{'request'}{'on_read_ready'}) {
        goto &CT_READ;
    }
    return $res;
}

sub CT_WRITE {
    my ($self) = @_;
    if(!defined $self->{'request'}{'response'}) {
        die("went into CT_WRITE in bad state");
        return CT_YIELD;
    }
    # TODO only TrySendResponse if there is data in buf or to be read
    my $tsrRet = $self->TrySendResponse;
    if(!defined($tsrRet)) {
        say "-------------------------------------------------";
        return CT_DONE;
    }
    elsif($tsrRet ne '') {
        if($self->{'request'}{'outheaders'}{'Connection'} && ($self->{'request'}{'outheaders'}{'Connection'} eq 'close')) {
            say "Connection close header set closing conn";
            say "-------------------------------------------------";
            return CT_DONE;
        }
        $self->{'request'} = undef;
        goto &CT_PROCESS;
    }
    return CT_YIELD;
}

sub do_on_data {
    my ($self) = @_;
    my $res = $self->{'request'}{'on_read_ready'}->($self->{'request'});
    if($res) {
        if(defined $self->{'request'}{'response'}) {
            #say "do_on_data: goto onWriteReady";
            goto &onWriteReady;
            #return onWriteReady($self);
        }
        #else {
        elsif(defined $self->{'request'}{'on_read_ready'}) {
            #say "do_on_data: goto onReadReady inbuf " . length($self->{'inbuf'});
            goto &onReadReady;
            #return onReadReady($self);
        }
        else {
            say "do_on_data: response and on_read_ready not defined, response by timer or poll?";
        }
    }
    return $res;
}


sub onReadReady {
    goto &CT_READ;
    my ($self) = @_;
    my $tempdata;
    if(defined($self->{'sock'}->recv($tempdata, RECV_SIZE))) {
        if(length($tempdata) == 0) {
            say 'Server::Client read 0 bytes, client read closed';
            return undef;
        }
        $self->{'inbuf'} .= $tempdata;
        goto &do_on_data;
    }
    if(! $!{EAGAIN}) {
        print ("MHFS::HTTP::Server::Client onReadReady RECV errno: $!\n");
        return undef;
    }
    return '';
}

sub onWriteReady {
    goto &CT_WRITE;
    my ($client) = @_;
    # send the response
    if(defined $client->{'request'}{'response'}) {
        # TODO only TrySendResponse if there is data in buf or to be read
        my $tsrRet = $client->TrySendResponse;
        if(!defined($tsrRet)) {
            say "-------------------------------------------------";
            return undef;
        }
        elsif($tsrRet ne '') {
            if($client->{'request'}{'outheaders'}{'Connection'} && ($client->{'request'}{'outheaders'}{'Connection'} eq 'close')) {
                say "Connection close header set closing conn";
                say "-------------------------------------------------";
                return undef;
            }
            $client->{'request'} = MHFS::HTTP::Server::Client::Request->new($client);
            # handle possible existing read data
            goto &do_on_data;
        }
    }
    else {
        say "response not defined, probably set later by a timer or poll";
    }
    return 1;
}

sub _TSRReturnPrint {
    my ($sentthiscall) = @_;
    if($sentthiscall > 0) {
        say "wrote $sentthiscall bytes";
    }
}

sub TrySendResponse {
    my ($client) = @_;
    my $csock = $client->{'sock'};
    my $dataitem = $client->{'request'}{'response'};
    defined($dataitem->{'buf'}) or die("dataitem must always have a buf");
    my $sentthiscall = 0;
    do {
        # Try to send the buf if set
        if(length($dataitem->{'buf'})) {
            my $sret = TrySendItem($csock, \$dataitem->{'buf'});
            # critical conn error
            if(! defined($sret)) {
                _TSRReturnPrint($sentthiscall);
                return undef;
            }
            if($sret) {
                $sentthiscall += $sret;
                # if we sent data, kill the send timer
                if(defined $client->{'sendresponsetimerid'}) {
                    $client->KillClientCloseTimer($client->{'sendresponsetimerid'});
                    $client->{'sendresponsetimerid'} = undef;
                }
            }
            # not all data sent, add timer
            if(length($dataitem->{'buf'}) > 0) {
                $client->{'sendresponsetimerid'} //= $client->AddClientCloseTimer($client->{'server'}{'settings'}{'sendresponsetimeout'}, $client->{'CONN-ID'});
                _TSRReturnPrint($sentthiscall);
                return '';
            }

            #we sent the full buf
        }

        # read more data
        my $newdata;
        if(defined $dataitem->{'fh'}) {
            my $FH = $dataitem->{'fh'};
            my $req_length = $dataitem->{'get_current_length'}->();
            my $filepos = $dataitem->{'fh_pos'};
            # TODO, remove this assert
            if($filepos != tell($FH)) {
                die('tell mismatch');
            }
            if($req_length && ($filepos >= $req_length)) {
                if($filepos > $req_length) {
                    say "Reading too much tell: $filepos req_length: $req_length";
                }
                say "file read done";
                close($FH);
            }
            else {
                my $readamt = 24000;
                if($req_length) {
                    my $tmpsend = $req_length - $filepos;
                    $readamt = $tmpsend if($tmpsend < $readamt);
                }
                # this is blocking, it shouldn't block for long but it could if it's a pipe especially
                my $bytesRead = read($FH, $newdata, $readamt);
                if(! defined($bytesRead)) {
                    $newdata = undef;
                    say "READ ERROR: $!";
                }
                elsif($bytesRead == 0) {
                    # read EOF, better remove the error
                    if(! $req_length) {
                        say '$req_length not set and read 0 bytes, treating as EOF';
                        $newdata = undef;
                    }
                    else {
                        say 'FH EOF ' .$filepos;
                        seek($FH, 0, 1);
                        _TSRReturnPrint($sentthiscall);
                        return '';
                    }
                }
                else {
                    $dataitem->{'fh_pos'} += $bytesRead;
                }
            }
        }
        elsif(defined $dataitem->{'cb'}) {
            $newdata = $dataitem->{'cb'}->($dataitem);
        }

        my $encode_chunked = $dataitem->{'is_chunked'};
        # if we got to here and there's no data, fetching newdata is done
        if(! $newdata) {
            $dataitem->{'fh'} = undef;
            $dataitem->{'cb'} = undef;
            $dataitem->{'is_chunked'} = undef;
            $newdata = '';
        }

        # encode chunked encoding if needed
        if($encode_chunked) {
            my $sizeline = sprintf "%X\r\n", length($newdata);
            $newdata = $sizeline.$newdata."\r\n";
        }

        # add the new data to the dataitem buffer
        $dataitem->{'buf'} .= $newdata;

    } while(length($dataitem->{'buf'}));
    $client->{'request'}{'response'} = undef;

    _TSRReturnPrint($sentthiscall);
    say "DONE Sending Data";
    return 'RequestDone'; # not undef because keep-alive
}

sub TrySendItem {
    my ($csock, $dataref) = @_;
    my $sret = send($csock, $$dataref, 0);
    if(! defined($sret)) {
        if($!{EAGAIN}) {
            #say "SEND EAGAIN\n";
            return 0;
        }
        elsif($!{ECONNRESET}) {
            print "ECONNRESET\n";
        }
        elsif($!{EPIPE}) {
            print "EPIPE\n";
        }
        else {
            print "send errno $!\n";
        }
        return undef;
    }
    elsif($sret) {
        substr($$dataref, 0, $sret, '');
    }
    return $sret;
}

sub onHangUp {
    my ($client) = @_;
    return undef;
}

sub DESTROY {
    my $self = shift;
    say "$$ MHFS::HTTP::Server::Client destructor: ";
    say "$$ ".'X-MHFS-CONN-ID: ' . $self->{'outheaders'}{'X-MHFS-CONN-ID'};
    if($self->{'sock'}) {
        #shutdown($self->{'sock'}, 2);
        close($self->{'sock'});
    }
}

1;
