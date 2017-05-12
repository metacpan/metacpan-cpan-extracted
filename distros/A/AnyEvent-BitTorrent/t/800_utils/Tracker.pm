package t::800_utils::Tracker;
use Moo;
use Types::Standard qw[Defined HashRef Int Str];
use AnyEvent::Handle;
use AnyEvent::Socket;
use Net::BitTorrent::Protocol::BEP03::Bencode qw[:all];
#
has port => (isa     => Int,
             is      => 'lazy',
             writer  => '_set_port',
             default => sub {0}
);
has host =>
    (isa => Str, is => 'lazy', writer => '_set_host', default => sub {'::'});
has peers => (
    isa => HashRef [HashRef],    # By (key ^ info_hash)
    is => 'lazy',
    default => sub { {} },
    handles => {

        #forget_peer => 'delete',
        #add_peer    => 'set',
        #peers       => 'values'
        #info_hashes   => ['map', sub { $_->{'info_hash'} } ],
        #peer_ids      => ['map', sub { $_->{'peer_id'} } ],
        #find_info_hash => ['map', sub { $_->{'info_hash'} eq $_[0] } ],
    }
);
has socket => (isa      => Defined,
               is       => 'ro',
               init_arg => undef,
               builder  => '_build_socket'
);
has interval => (is => 'lazy', isa => Int, default => sub { 60 * 10 });
has complete => (is => 'lazy', isa => Int, default => sub {0});

sub on_drain {
    my $s = shift;
    $_[0] = undef;
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
