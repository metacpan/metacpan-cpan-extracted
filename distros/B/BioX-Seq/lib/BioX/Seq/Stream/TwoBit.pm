package BioX::Seq::Stream::TwoBit;

use strict;
use warnings;
use POSIX qw/ceil/;

use constant MAGIC => 0x1a412743;
use constant LE_MAGIC_S => pack('C2', 0x43, 0x27);
use constant LE_MAGIC_L => pack('C2', 0x41, 0x1a);
use constant BE_MAGIC_S => pack('C2', 0x1a, 0x41);
use constant BE_MAGIC_L => pack('C2', 0x27, 0x43);

my @byte_map = map {
    my $i = $_; join '', map {qw/T C A G/[ vec(chr($i),3-$_,2) ]} 0..3
} 0..255;

sub _check_type {

    my ($class,$self) = @_;
    return 1 if $self->{buffer} eq LE_MAGIC_S;
    return 1 if $self->{buffer} eq BE_MAGIC_S;
    return 0;

}

sub _init {

    my ($self) = @_;
   
    binmode $self->{fh};
    my $fh = $self->{fh};

    # Determine endianness
    my $magic = $self->{buffer} . _safe_read( $fh, 2 );
    my $byte_order = unpack('V', $magic) == MAGIC ? 'V'
                   : unpack('N', $magic) == MAGIC ? 'N'
                   : die "File signature check failed";
    $self->{byte_order} = $byte_order;

    # Unpack rest of header
    my ($version, $seq_count, $reserved) = unpack "$byte_order*",
        _safe_read( $fh, 12 );
    die "File header check failed" if ($version != 0 || $reserved != 0);
    $self->{seq_count} = $seq_count;

    # Build index
    my $last_name;
    my $buf;
    my @index;
    for (1..$self->{seq_count}) {
        read $fh, $buf, 1;
        read $fh, $buf, ord($buf);
        my $name = $buf;
        read $fh, $buf, 4;
        my $offset   = unpack $byte_order, $buf;
        die "$name already defined" if (defined $self->{index}->{$name});
        push @index, [$name, $offset];
    }
    $self->{index} = [@index];
    $self->{curr_idx} = 0;

    return;

}

sub next_seq {
    
    my ($self) = @_;

    return undef if ($self->{curr_idx} >= $self->{seq_count});

    my $seq = $self->_fetch_record( $self->{curr_idx} );
    ++$self->{curr_idx};
    return $seq;

}

sub _safe_read {

    my ($fh, $bytes) = @_;
    my $r = read($fh, my $buffer, $bytes);
    die "Unexpected read length" if ($r != $bytes);
    return $buffer;

}

sub _fetch_record {

    my ($self, $idx) = @_;

    my ($id,$offset) = @{ $self->{index}->[$idx] };
    my $byte_order = $self->{byte_order};
    my $fh         = $self->{fh};
    seek $fh, $offset, 0;
    
    my $seq_len = unpack "$byte_order*", _safe_read($fh, 4);
    my $N_count = unpack "$byte_order*", _safe_read($fh, 4);
    my @N_data  = unpack "$byte_order*", _safe_read($fh, 4 * $N_count * 2);
    my %N_lens;
    @N_lens{ @N_data[0..$N_count-1] } = @N_data[$N_count..$#N_data];

    my $mask_count = unpack "$byte_order*", _safe_read($fh, 4);
    my @mask_data  = unpack "$byte_order*", _safe_read($fh, 4 * $mask_count * 2);
    my %mask_lens;
    @mask_lens{ @mask_data[0..$mask_count-1] } = @mask_data[$mask_count..$#mask_data];

    # reserved field
    my $reserved = unpack "$byte_order*", _safe_read($fh, 4);

    my $to_read  = ceil($seq_len/4);

    # this is the speed bottleneck, but haven't found a better way yet
    my $string;
    $string .= $byte_map[$_] for (unpack "C*", _safe_read($fh, $to_read));

    $string = substr $string, 0, $seq_len;

    # N and mask
    for (keys %N_lens) {
        my $len = $N_lens{$_};
        substr($string, $_, $len) = 'N' x $len;
    }
    for (keys %mask_lens) {
        my $len = $mask_lens{$_};
        substr($string, $_, $len) ^= (' ' x $len);
    }
    return BioX::Seq->new($string, $id, '');

}

1;

__END__

=head1 NAME

BioX::Seq::Stream::TwoBit - the TwoBit parser for C<BioX::Seq:Stream>;

=head1 DESCRIPTION

This module performs parsing of TwoBit sequence streams. It is not
intended to be used directly but is called by C<BioX::Seq::Stream> after file
format autodetection. Please see the documentation for that module for more
details.

NOTE: This module is currently considered a proof-of-principle (or perhaps
programming exercise). It is B<very slow> compared to Jim Kent's TwoBit C
utilities and should be avoided for any production code where execution speed
matters.

=head1 CAVEATS AND BUGS

Please report any bugs or feature requests to the issue tracker
at L<https://github.com/jvolkening/p5-BioX-Seq>.

=head1 AUTHOR

Jeremy Volkening <jeremy *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2014-2017 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut



