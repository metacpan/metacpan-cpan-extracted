use utf8;
use strict;
use warnings;

package DR::Tnt::Msgpack::Types::Blob;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

sub new {
    my ($class, $v) = @_;
    bless \$v => ref($class) || $class;
}

sub TO_MSGPACK {
    my ($self) = @_;
    my $v = $$self;

    return pack 'C', 0xC0 unless defined $v;

    utf8::encode $v if utf8::is_utf8 $v;
    my $len = length $v;

    return pack 'CC/a*',  0xC4, $v          if $len <= 0xFF;
    return pack 'CS>/a*', 0xC5, $v          if $len <= 0xFFFF;
    return pack 'CL>/a*',  0xC6, $v;
}

sub TO_JSON {
    my ($self) = @_;
    return $$self;
}

=head1 NAME

DR::Tnt::Msgpack::Types::Blob - container for blob.

=head1 SYNOPSIS

    use DR::Tnt::Msgpack::Types::Blob;

    my $o = DR::Tnt::Msgpack::Types::Blob->new(123);
    my $blob = msgpack($o);

=head1 DESCRIPTION

See L<DR::Tnt::Msgpack::Types>.

=cut

1;

