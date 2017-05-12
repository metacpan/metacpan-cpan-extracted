use utf8;
use strict;
use warnings;

package DR::Tnt::Msgpack::Types::Int;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use Scalar::Util ();

sub new {
    my ($class, $v) = @_;
    if (defined $v) {
        croak "$v is not looks_like_number"
            unless Scalar::Util::looks_like_number $v;
    }
    bless \$v => ref($class) || $class;
}


sub TO_MSGPACK {
    my ($self) = @_;
    my $v = $$self;

    return pack 'C', 0xC0 unless defined $v;
    if ($v < 0) {
        return pack 'c', $v                 if $v >= -0x1F - 1;
        return pack 'Cc', 0xD0, $v          if $v >= -0x7F - 1;
        return pack 'Cs>', 0xD1, $v         if $v >= -0x7FFF - 1;
        return pack 'Cl>', 0xD2, $v         if $v >= -0x7FFF_FFFF - 1;
        return pack 'cq>', 0xD3, $v;
    }
    
    return pack 'C',    $v                  if $v <= 0x7F;
    return pack 'Cs>',  0xD1, $v            if $v <= 0x7FFF;
    return pack 'Cl>',  0xD2, $v            if $v <= 0x7FFF_FFFF;
    return pack 'Cq>',  0xD3, $v;
}

sub TO_JSON {
    my ($self) = @_;
    return $$self // 'null';
}


=head1 NAME

DR::Tnt::Msgpack::Types::Int - container for integer.

=head1 SYNOPSIS

    use DR::Tnt::Msgpack::Types::Int;

    my $o = DR::Tnt::Msgpack::Types::Int->new(123);
    my $blob = msgpack($o);

=head1 DESCRIPTION

See L<DR::Tnt::Msgpack::Types>.

=cut

1;
