package AnyEvent::DNS::Nameserver;
our $VERSION = "1.2";
use Net::DNS;
use AnyEvent::Handle::UDP;
use Socket qw(sockaddr_in sockaddr_in6 inet_ntop sockaddr_family AF_INET6);
use strict;

sub new {
    my $class = shift;
    my %p = @_;
    my $self = {};
    $self->{LocalAddr}      = $p{LocalAddr} || '0.0.0.0';
    $self->{LocalPort}      = $p{LocalPort} || 53;
    $self->{ReplyHandler}   = $p{ReplyHandler} or die "ReplyHandler invalid\n";
    $self->{Verbose}        = $p{Verbose}   || 0;
    $self->{Truncate}       = $p{Truncate}  || 1;
    $self->{IdleTimeout}    = $p{IdleTimeout} || 120;
    $self->{NotifyHandler}  = $p{NotifyHandler};

    $self->{watchers}       = [];

    my @LocalAddr =ref $self->{LocalAddr} eq 'ARRAY'?@{$self->{LocalAddr}}:($self->{LocalAddr});
    for my $la (@LocalAddr){ 
        my $hdl;$hdl = AnyEvent::Handle::UDP->new(
            bind    =>  [$la,$self->{LocalPort}],
            on_recv => sub {
                my ($data, $ae_handle, $client_addr) = @_;
                my $family = sockaddr_family($client_addr);
                my ($peerport, $peerhost) = ( $family == AF_INET6 ) ? sockaddr_in6($client_addr) : sockaddr_in($client_addr);
                $peerhost = inet_ntop($family, $peerhost);
                my $query = new Net::DNS::Packet( \$data );
                if ( my $err = $@ ) {
                    print "Error decoding query packet: $err\n" if $self->{Verbose};
                    undef $query; 
                }   
                my $conn = {
                        sockhost=>$la,
                        sockport=>$self->{LocalPort},
                        peerhost=>$peerhost,
                        peerport=>$peerport,
                };
                print "UDP connection from $peerhost:$peerport to $conn->{sockhost}:$conn->{sockport}\n" if $self->{Verbose};
                my $reply = make_reply($self,$query,$peerhost,$conn) || return;
                my $max_len = ( $query && $self->{Truncate} ) ? $query->edns->size : undef;
                if ( $self->{Verbose} ) {
                    local $| = 1;
                    print "Maximum UDP size advertised by $peerhost:$peerport: $max_len bytes\n" if $max_len;
                    print "Sending response to $peerhost:$peerport\n";
                    $reply->print ;
                }
                $ae_handle->push_send($reply->data($max_len), $client_addr);
            },
        );
        push @{$self->{watchers}},$hdl;
    }
    return bless $self,$class;
}

#copy from Net::DNS::Nameserver
sub make_reply {
        my ( $self, $query, $peerhost, $conn ) = @_;
 
        unless ($query) {
                print "ERROR: invalid packet\n" if $self->{Verbose};
                my $empty = new Net::DNS::Packet();             # create empty reply packet
                my $reply = $empty->reply();
                $reply->header->rcode("FORMERR");
                return $reply;
        }
 
        if ( $query->header->qr() ) {
                print "ERROR: invalid packet (qr set), dropping\n" if $self->{Verbose};
                return;
        }
 
        my $reply  = $query->reply();
        my $header = $reply->header;
        my $headermask;
 
        my $opcode  = $query->header->opcode;
        my $qdcount = $query->header->qdcount;
 
        unless ($qdcount) {
                $header->rcode("NOERROR");
 
        } elsif ( $qdcount > 1 ) {
                print "ERROR: qdcount $qdcount unsupported\n" if $self->{Verbose};
                $header->rcode("FORMERR");
 
        } else {
                my ($qr)   = $query->question;
                my $qname  = $qr->qname;
                my $qtype  = $qr->qtype;
                my $qclass = $qr->qclass;
 
                my $id = $query->header->id;
                $query->print if $self->{Verbose};
 
                my ( $rcode, $ans, $auth, $add );
                my @arglist = ( $qname, $qclass, $qtype, $peerhost, $query, $conn );
 
                if ( $opcode eq "QUERY" ) {
                        ( $rcode, $ans, $auth, $add, $headermask ) =
                                        &{$self->{ReplyHandler}}(@arglist);
 
                } elsif ( $opcode eq "NOTIFY" ) {               #RFC1996
                        if ( ref $self->{NotifyHandler} eq "CODE" ) {
                                ( $rcode, $ans, $auth, $add, $headermask ) =
                                                &{$self->{NotifyHandler}}(@arglist);
                        } else {
                                $rcode = "NOTIMP";
                        }
 
                } else {
                        print "ERROR: opcode $opcode unsupported\n" if $self->{Verbose};
                        $rcode = "FORMERR";
                }
 
                if ( !defined($rcode) ) {
                        print "remaining silent\n" if $self->{Verbose};
                        return undef;
                }
 
                $header->rcode($rcode);
 
                $reply->{answer}     = [@$ans]       if $ans;
                $reply->{authority}  = [@$auth] if $auth;
                $reply->{additional} = [@$add]       if $add;
        }
 
        if ( !defined($headermask) ) {
                $header->ra(1);
                $header->ad(0);
        } else {
                $header->opcode( $headermask->{opcode} ) if $headermask->{opcode};
 
                $header->aa(1) if $headermask->{aa};
                $header->ra(1) if $headermask->{ra};
                $header->ad(1) if $headermask->{ad};
        }
        return $reply;
}

sub main_loop{
    my $self = shift;
    AE::cv->recv; 
}
1;
=pod

=head1 NAME

AnyEvent::DNS::Nameserver - DNS server class using AnyEvent

=head1 SYNOPSIS

    use AnyEvent::DNS::Nameserver;
    my $nameserver = new Net::DNS::Nameserver(
        LocalAddr        => ['192.168.1.1' , '127.0.0.1' ],
        LocalPort        => "53",
        ReplyHandler => \&reply_handler,
        Verbose          => 1,
        Truncate         => 0
    );
    $nameserver->main_loop;

=head1 DESCRIPTION

Net::DNS::Nameserver doesn't work with AnyEvent so I wrote this module in honor of Net::DNS::Nameserver

AnyEvent::DNS::Nameserver try to be compatible with all the methods and features of Net::DNS::Nameserver

You can find more information and usage from Net::DNS::Nameserver

AnyEvent::DNS::Nameserver only support udp query and answer by now

=head1 SEE ALSO

L<https://github.com/sjdy521/AnyEvent-DNS-Nameserver>

L<Net::DNS::Nameserver>

=head1 AUTHOR

sjdy521, E<lt>sjdy521@163.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Perfi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
