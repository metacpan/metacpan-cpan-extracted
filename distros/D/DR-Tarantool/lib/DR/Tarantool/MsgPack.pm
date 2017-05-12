use utf8;
use strict;
use warnings;

=head1 NAME

DR::Tarantool::MsgPack - msgpack encoder/decoder.

=head1 SYNOPSIS

    use DR::Tarantool::MsgPack 'msgpack', 'msgunpack', 'msgcheck';

    # encode object
    my $pkt = msgpack({ a => 'b' });

    # decode object
    my $object = msgunpack($pkt);

    # decode object with utf8-strings
    my $object = msgunpack($pkt, 1);

    # check if $string is valid msgpack
    $object = msgunpack($str, 1) if msgcheck($str);

=head1 METHODS

=head2 msgpack($OBJECT)

Encode perl object (scalar, hash, array) to octets.

=head2 msgunpack($OCTETS[, $UTF8])

Decide octets to perl object. Return perl object and tail of input string.

If C<$UTF8> is true, L<msgunpack> will decode utf8-strings.

=cut


package DR::Tarantool::MsgPack;
use Carp;
require DR::Tarantool;
use base qw(Exporter);
our @EXPORT_OK = qw(msgpack msgunpack msgcheck);

sub msgpack($) {
    DR::Tarantool::_msgpack($_[0])
}

sub msgunpack($;$) {
    my ($pkt, $utf8) = @_;
    $utf8 ||= 0;
    $utf8 &&= 1;
    DR::Tarantool::_msgunpack($pkt, $utf8)
}

sub msgcheck($) {
    DR::Tarantool::_msgcheck($_[0])
}

sub TRUE()  { DR::Tarantool::MsgPack::Bool->new(1) };
sub FALSE() { DR::Tarantool::MsgPack::Bool->new(0) };


=head2 true and false

Protocol supports C<true> and C<false> statements.
L<msgunpack> unpacks them to C<1> and C<0>.

If You want to pack C<true> You can use B<DR::Tarantool::MsgPack::Bool>:

    use DR::Tarantool::MsgPack 'msgpack';

    my $to_pack = { a => DR::Tarantool::MsgPack::Bool->new(0) };
    my $pkt = msgpack($to_pack);

=cut

package DR::Tarantool::MsgPack::Bool;
use Carp;
use overload
    'int'   => sub { ${ $_[0] } },
    '""'    => sub { ${ $_[0] } },
    'bool'  => sub { ${ $_[0] } }
;

sub new {
    my ($class, $v) = @_;
    my $bv = $v ? 1 : 0;
    return bless \$v => ref($class) || $class;
}

sub msgpack :method {
    my ($self) = @_;
    return scalar pack 'C', ($$self ? 0xC3 : 0xC2);
}


1;
