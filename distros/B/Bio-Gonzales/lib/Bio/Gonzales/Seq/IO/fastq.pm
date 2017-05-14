package Bio::Gonzales::Seq::IO::fastq;

use Mouse;

use warnings;
use strict;

use 5.010;

our $VERSION = '0.0546'; # VERSION

our %VARIANT = (
    sanger => {
        'ascii_offset' => 33,
        'q_start'      => 0,
        'q_end'        => 93
    },
    solexa => {
        'ascii_offset' => 64,
        'q_start'      => -5,
        'q_end'        => 62
    },
    illumina => {
        'ascii_offset' => 64,
        'q_start'      => 0,
        'q_end'        => 62
    },
);

has cache         => ( is => 'rw' );
has variant       => ( is => 'rw', default => 'sanger' );
has _ascii_offset => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    given ( $self->variant ) {
        when ('solexa')   { $self->_cache_solexa }
        when ('illumina') { $self->_cache_non_solexa }
        when ('sanger')   { $self->_cache_non_solexa }
    }
}

sub _cache_solexa {
    my ($self) = @_;

    my ( @c2q, @q2c, @sol2phred, %phred_fp2chr, @phred_int2chr );

    my $ascii_offset = $VARIANT{'solexa'}{'ascii_offset'};
    for ( my $i = 0; $i < $VARIANT{'solexa'}{'q_end'} - $VARIANT{'solexa'}{'q_start'} + 1; $i++ ) {
        my $q = $i + $VARIANT{'solexa'}{'q_start'};
        my $c = $q + $ascii_offset;
        $c2q[$c] = $q;
        $q2c[$i] = chr($c);

        # solexa <=> solexa mapping speedup (retain floating pt precision)
        my $s2p = 10 * log( 1 + 10**( $q / 10.0 ) ) / log(10);
        $sol2phred[$i] = $s2p;

        $phred_fp2chr{$s2p} = chr($c);

        next if $q < 0;    # skip loop; PHRED scores greater than 0
        my $p2s = sprintf( "%.0f", ( $q <= 1 ) ? -5 : 10 * log( -1 + 10**( $q / 10.0 ) ) / log(10) );
        # sanger/illumina PHRED <=> Solexa char mapping speedup
        $phred_int2chr[$i] = chr( $p2s + $ascii_offset );
    }
    $self->cache(
        {
            c2q           => \@c2q,
            q2c           => \@q2c,
            sol2phred     => \@sol2phred,
            phred_fp2chr  => \%phred_fp2chr,
            phred_int2chr => \@phred_int2chr,
            q_start       => $VARIANT{'solexa'}{'q_start'},
            q_end         => $VARIANT{'solexa'}{'q_end'},
            ascii_offset  => $ascii_offset,
        }
    );
}

sub _cache_non_solexa {
    my ($self) = @_;
    my $enc = $self->variant;
    my ( @c2q, @q2c );

    my $ascii_offset = $VARIANT{$enc}{'ascii_offset'};
    for ( my $i = 0; $i < $VARIANT{$enc}{'q_end'} - $VARIANT{$enc}{'q_start'} + 1; $i++ ) {
        my $q = $i + $VARIANT{$enc}{'q_start'};
        my $c = $q + $ascii_offset;
        $c2q[$c] = $q;
        $q2c[$i] = chr($c);

    }
    $self->cache(
        {
            c2q          => \@c2q,
            q2c          => \@q2c,
            q_start      => $VARIANT{$enc}{'q_start'},
            q_end        => $VARIANT{$enc}{'q_end'},
            ascii_offset => $ascii_offset

        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
