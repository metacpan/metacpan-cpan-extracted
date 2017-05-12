use utf8;
use strict;
use warnings;

package DR::Tnt::Msgpack::Types::Str;
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

    return pack 'Ca*', 0xA0 | $len, $v      if $len <= 0x1F;
    return pack 'CC/a*', 0xD9, $v           if $len <= 0xFF;
    return pack 'CS>/a*', 0xDA, $v          if $len <= 0xFFFF;
    return pack 'CL>/a*', 0xDB, $v;
}

sub TO_JSON {
    my ($self) = @_;
    return 'null' unless defined $$self;
    return sprintf '"%s"', quotemeta $$self;
}

=head1 NAME

DR::Tnt::Msgpack::Types::Str - container for string.

=head1 SYNOPSIS

    use DR::Tnt::Msgpack::Types::Str;

    my $o = DR::Tnt::Msgpack::Types::Str->new(123);
    my $blob = msgpack($o);

=head1 DESCRIPTION

See L<DR::Tnt::Msgpack::Types>.

=cut

1;
