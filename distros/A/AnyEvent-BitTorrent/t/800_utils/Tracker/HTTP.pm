package t::800_utils::Tracker::HTTP;
use Net::BitTorrent::Protocol qw[:bencode :compact];    # IPv6
use Moo;
use AnyEvent::Socket;
use Test::More;
#
extends 't::800_utils::Tracker';

sub _build_socket {
    my $s = shift;
    my $x = tcp_server(
        $s->host,
        $s->port,
        sub {
            my ($fh, $paddr, $host, $port) = @_;
            my $hdl;
            $hdl = AnyEvent::Handle->new(
                fh       => $fh,
                on_drain => sub {
                    $s->on_drain($hdl, $fh, $paddr, $host, $port, @_);
                },
                on_read => sub {
                    $s->on_read($hdl, $fh, $paddr, $host, $port, @_);
                },
                on_eof => sub { note 'bye!' }
            );
        },
        sub {
            $s->_set_host($_[1]);
            $s->_set_port($_[2]);
            1;
        }
    );
}

sub on_read {
    my ($s, $h, $fh, $ip, $port) = @_;
    my ($status, $body) = ('404 EH!?', 'Sorry. Play again.');
    if ($h->rbuf =~ s[^GET (.+?)(?:\?(.+))? HTTP/1\.(\d)\015\012][]) {
        my ($path, $args, $ver) = ($1, $2, $3);
        my %args = map { m[^(.+?)(?:=(.*))?$]; $1 => $2; }
            split qr[[&;]], $args;
        my %headers = map { m[^(.+?)\s*:\s*(.+)$]; $1 => $2; }
            split qr[\015\012], $h->rbuf;
        if ($path eq '/announce.pl') {
            my $tracker_id = $args{'tracker id'} // pack 'H*', int rand(time);
            my $max_peers = $args{'max_peers'} // 50;
            my $info_hash = uc $args{'info_hash'};
            my $event = $args{'event'} // '';
            $info_hash =~ s[%(..)][chr hex $1]eg;
            $s->complete($s->complete + 1) if $event eq 'complete';
            my $_id = pack('H*', $args{'key'} // '') ^ $info_hash ^
                pack('B*', $args{'peer_id'});
            $s->peers->{$_id} = {
                address => [$args{'ip'} // $ip, $args{'port'} // $port],
                downloaded => $args{'downloaded'},
                event      => $event,
                info_hash  => $info_hash,
                key        => $args{'key'} // $_id,
                left       => $args{'left'},
                peer_id    => $args{'peer_id'},
                tracker_id => $tracker_id,
                uploaded   => $args{'uploaded'},
                touch      => time
            };
            $status = '200 Alright';
            my $num_peers = 0;
            my @peers     = grep {
                       $_->{'info_hash'} eq $info_hash
                    && $num_peers++ < $max_peers
            } values %{$s->peers};
            $body = {
                complete       => $s->complete,
                incomplete     => ((scalar @peers) - $s->complete),
                'min interval' => int($s->interval / 2),
                interval       => $s->interval,
                'tracker id'   => $tracker_id,
                peers          => (
                    $args{'compact'}
                    ?
                        (compact_ipv4 map { $_->{'address'} } @peers)
                    : (map {
                           {peer_id => $_->{'peer_id'},
                            ip      => $_->{'address'}->[0],
                            port    => $_->{'address'}->[1]
                           }
                       } @peers
                    )
                )
            };
        }
        elsif ($path eq '/scrape.pl') { note 'Scrape!' }
        else                          { note 'NFI!' }
    }
    $h->rbuf = '';
    $body = bencode $body if ref $body;
    $h->push_write(sprintf
                       <<'END', $status, length($body), $body); $h->push_shutdown
HTTP/1.0 %s
Content-Type: text/plain
Content-Length: %d
Connection: close

%s
END
}
1;

=pod

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2008-2013 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

Neither this module nor the L<Author|/Author> is affiliated with BitTorrent,
Inc.

=for rcs $Id$

=cut
