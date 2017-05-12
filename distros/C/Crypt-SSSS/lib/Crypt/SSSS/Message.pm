package Crypt::SSSS::Message;

use strict;
use warnings;

require Carp;

sub new {
    my $class = shift;
    my %args  = @_;

    Carp::croak('Missed "p" argument') unless $args{p};

    bless {
        _data => $args{data} || [],
        _p    => $args{p},
        _size => _determine_chunk_size($args{p} - 1)
    }, $class;
}

sub build_from_binary {
    my ($class, $p, $string) = @_;

    my $self = $class->new(p => $p);

    my $rdata = 0;
    my $rsize = 0;

    my @chunks = unpack 'C*', $string;

    my $size = $self->{_size};

    my $smask = 0;
    $smask = ($smask << 1) | 1 for (1 .. $size);

    while (@chunks > 0) {
        $rdata = $rdata << 8 | shift @chunks;
        $rsize += 8;

        while ($rsize >= $size) {
            $rsize -= $size;

            my $mask = $smask << $rsize;
            $self->push_data(($rdata & $mask) >> $rsize);
            $rdata &= ~$mask;
        }
    }

    $self;
}

sub push_data {
    my ($self, $data) = @_;

    Carp::croak('Data greater than p') if $data > $self->{_p};
    push @{$self->{_data}}, $data;
}

sub binary {
    my $self = shift;

    my $rsize = 0;
    my $rdata = 0x00;

    my $str;

    foreach my $lchunk (@{$self->{_data}}) {
        my $size = $self->{_size};

        my $chunk = $rdata << $size | $lchunk;
        $size += $rsize;

        while ($size >= 8) {
            $size -= 8;
            my $mask = 0xff << $size;

            my $data = ($chunk & $mask) >> $size;
            $chunk &= ~$mask;

            $str .= pack 'C', $data;
        }
        $rsize = $size;
        $rdata = $chunk;
    }

    $str .= pack 'C', ($rdata << 8 - $rsize) if $rsize;

    $str;
}

sub get_data {
    my $self = shift;
    return $self->{_data};
}

sub get_p {
    my $self = shift;
    return $self->{_p};
}

# Hope we will not have p greater than dword can have
# Same as log2
sub _sig_bit {
    my $x = shift;

    my $i = 0;
    while ($x) {
        $x >>= 1;
        $i++;
    };
    $i;
}

sub _determine_chunk_size {
    my ($p) = @_;

    _sig_bit($p);
}


1;
