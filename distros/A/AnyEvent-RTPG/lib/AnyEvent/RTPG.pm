package AnyEvent::RTPG;
our $VERSION = "0.01";

use 5.008;

use common::sense 2.02;
use parent        0.223 "Object::Event";
use AnyEvent      5.202;
use RTPG          0.3;

sub new {
   my $this  = shift;
   my $class = ref($this) || $this;
   my $self  = $class->SUPER::new(@_);
   $self->{_rtpg} = RTPG->new(url=>$self->{url});
   return $self
}

sub _tick {
    my $self = shift;
    my $list=$self->{_rtpg}->torrents_list;
    $self->event("refresh_status"=>\@$list);
}

sub start {
    my $self = shift;
    $self->{_tick_timer} = AE::timer(0, 10, sub { $self->_tick });
}

sub rpc_command {
    my $self = shift;
    my ($result, $error)=$self->{_rtpg}->rpc_command(@_);
    my $cmd=shift;
    if ($cmd =~ /^d.erase$/) {
        my $hash=shift;
        print $cmd,$hash;
        $self->event("rtorrent_remove_torrent"=>$hash);
    }else{
        $self->_tick;
    }
}

1;

=head1 NAME

AnyEvent::RTPG - A RTPG interface for AE

=head1 SYNOPSIS

    # Add "scgi_port = localhost:5000" to your ~/.rtorrent.rc first

    my $rtorrent = AnyEvent::RTPG->new(url => "localhost:5000");

    $rtorrent->reg_cb(
        refresh_status => sub {
            my ($rtorrent, $lists) = @_;
            ...
        },
        rtorrent_remove_torrent => sub {
            my ($rtorrent, $torrent_hash) = @_;
            ...
        }
    );

    $rtorrent->start;

=head1 METHODS

=over 4

=item new(url => "localhost:5000")

=item reg_cb(event_name => $cb, ...)

=item start

=back

=head1 EVENTS

=over 4

=item refresh_status

=item rtorrent_remove_torrent

=back

=head1 AUTHOR

Tka Lu C<< <tka@handlino.com> >>, Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Tka Lu C<< <tka@handlino.com> >>, Kang-min Liu  C<< <gugod@gugod.org> >>

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
