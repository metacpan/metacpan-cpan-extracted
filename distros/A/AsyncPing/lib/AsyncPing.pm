package AsyncPing;

use 5.006;
use IO::Socket;

=head1 NAME

AsyncPing - ping a huge number of servers in several seconds

=head1 VERSION

Version 2016.1207

=cut

our $VERSION = '2016.1207';


=head1 SYNOPSIS

  use AsyncPing;
  use Data::Dumper;

  my $asyncping=new AsyncPing(timeout=>3,try=>2);
  my @servers=("host1","host2","host3");
  my $result=$asyncping->ping(\@servers);
  print Dumper $result;

=head1 DESCRIPTION

  First of all, I tried some of the Async Ping modules on cpan, none of them really worked when I tried to ping 10,000 servers.
  This AsyncPing is designed to ping a huge number of servers. As I tested, it can send out ICMP request to 25,000 servers per second on a very common server.
  Also I tested if I fork a seperate process handling the recieving work, it can be improved to about 45,000 ping per second.
  The timeout value start to work after this module sends out all the requests. 
  The retry will only work on the failed ones.

  Please notice that ICMP is not TCP connection, there is no guarantee that if you send a request to a server, you'll get a response. So you may want to set the try to 2.
  So if you have a million servers to ping(10% of them are down) and you set the timeout to 3 and retry to 2, I can estimate the time to be about (1M/25k+3)+(100k/25k+3)=50 seconds.

  Please also notice that since ICMP can only be sent by root, if you want to use this library, you'll have to run your program as root.
  If the ping requests are going through firewall, your ping requests could possibly be discarded by firewall, don't blame the library.

  since every process share same network interface and usually there is only 1 network interface on a server, I think it doens't really help if you make it parallel 
  or multi-threaded to increase speed. Just like you don't get much benefit if you make more threads while you have only 1 CPU. But you can test on your own, good luck!
  
=cut

my $ICMP_PING = 'ccnnna*';
my $identifier = 1;
my $sequence   = 2;
my $data       = 'abcdefghijklmn';

sub new{
        my ($class,%arg)=@_;
        my $timeout=3;
        my $try=1;
        my $socket = IO::Socket::INET->new(
                Proto    => 'icmp',
                Type     => SOCK_RAW,
                Blocking => 0
        ) or Carp::croak "Unable to create icmp socket : $!";
        if($arg{timeout}){
                $timeout=$arg{timeout};
        }
        if($arg{try}>0){
                $try=$arg{try};
        }
        return bless {socket=>$socket, timeout=>$timeout, try=>$try}, $class;
}

sub _ping{
        my ($self,$list)=@_;
        my $expected;
        my %resultmap;
        my $revlistmap;
        my @nlist;
        my $got=0;
        my $sent=0;
	my %tmp;
        foreach my $h(@$list){
                chomp($h);
		my $n;
		my $ip;
		eval{
                 $n=inet_aton($h);
                 $ip=inet_ntoa($n);
		};
		if($@){
			$resultmap{$h}=0;
		}
		if($n && $ip){
			$expected->{$ip}=0;
			$revlistmap->{$ip}=$h;
			push @nlist,$n;
			$tmp{$n}=$ip;
		}else{
			$resultmap{$h}=0;
		}
        }
        my $count=@nlist;
        my $start=time();
        my $endtime;
        while(! $endtime || (time()<$endtime+$self->{timeout}) ){
                my $bytesread=$self->{socket}->sysread(my $chunk, 4096, 0);
                if($bytesread>0){
                        my $dest_ip=substr($chunk, 12,4);
                        my @ip=unpack('C*',$dest_ip);
                        my $ipstr=join('.',@ip);
                        if(exists $expected->{$ipstr} && $expected->{$ipstr}==0){
                                $got++;
                                $expected->{$ipstr}=1;
                        }
                        last if($count==$got);
                }else{
                        if($sent<$count){
                                my $ip=$nlist[$sent];
                                my $checksum   = 0x0000;
                                my $msg = pack($ICMP_PING, 0x08, 0x00, $checksum, $identifier, $sequence, $data);
                                $checksum = &_asyncping_checksum($msg);
                                $msg = pack($ICMP_PING, 0x08, 0x00, $checksum, $identifier, $sequence, $data);
                                $self->{socket}->send($msg, 0, scalar sockaddr_in(0, $ip)) or print "Error: on ip";
                                $sent++;
                        }elsif(! $endtime){
                                $endtime=time();
                        }
                }
        }

        foreach my $ip(sort keys %$expected){
                if($expected->{$ip}==1){
                        $resultmap{$revlistmap->{$ip}}=1;
                }else{
                        $resultmap{$revlistmap->{$ip}}=0;
                }
        }
        return \%resultmap;
}

sub ping{
        my ($self,$list)=@_;
        my $result=$self->_ping($list);
        my $try=$self->{try};
        my %failed;
        while(--$try>0){
                foreach my $h(keys %$result){
                        if($result->{$h}==0){
                                $failed{$h}=0;
                        }
                }
                my @failedservers=keys %failed;
                if(@failedservers){
                        my $retryresult=$self->_ping(\@failedservers);
                        foreach my $h(keys %$retryresult){
                                if($retryresult->{$h}==1){
                                        delete $failed{$h};
                                        $result->{$h}=1;
                                }
                        }
                }
        }
        return $result;
}

sub _asyncping_checksum {
        my ($msg) = @_;
        my $res = 0;
        foreach my $int (unpack "n*", $msg) {
                $res += $int;
        }
        $res += unpack('C', substr($msg, -1, 1)) << 8 if length($msg) % 2;
        $res = ($res >> 16) + ($res & 0xffff);
        $res = ($res >> 16) + ($res & 0xffff);
        return ~$res;
}

1;

=head1 AUTHOR

Xinfeng Wang(xinfwang@ebay.com)

=head1 BUGS

Please report any bugs or feature requests to C<bug-asyncping at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AsyncPing>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AsyncPing


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AsyncPing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AsyncPing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AsyncPing>

=item * Search CPAN

L<http://search.cpan.org/dist/AsyncPing/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Xinfeng Wang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of AsyncPing
