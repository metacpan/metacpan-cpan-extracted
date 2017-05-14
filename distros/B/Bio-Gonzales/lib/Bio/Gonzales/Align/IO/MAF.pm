package Bio::Gonzales::Align::IO::MAF;

use Mouse;

use warnings;
use strict;

use 5.010;
use Data::Dumper;
use Bio::Gonzales::Feat;
use Bio::Gonzales::Util qw/invslice/;
use Bio::Gonzales::Seq;
use Bio::Gonzales::Align;

with 'Bio::Gonzales::Util::Role::FileIO';
our $VERSION = '0.0546'; # VERSION

sub BUILD {
    my ($self) = @_;

    $self->record_separator("");
}

sub next_aln {
    my ( $self, $noseq ) = @_;

    my $fhi = $self->_fhi;

    my $record = $fhi->();

    return unless ($record);

    my @lines = grep { !/^#/ } split /\n/, $record;

    return unless ( @lines > 2 );

    die "this is not a maf alignment file::" . $record . "::"
        unless ( $lines[0] =~ /^a/ );

    my $a = _a_line( shift(@lines) );
    my $s = _s_lines( \@lines, $noseq );

    return Bio::Gonzales::Align->new(seqs => $s, score => (exists($a->{score}) ? $a->{score} : -1 ));
}

sub _a_line {
    my ($line) = @_;

    ( undef, my @parts ) = split /\s+/, $line;

    my %a_hash;
    for my $p (@parts) {
        my ( $k, $v ) = split /=/, $p, 2;
        $a_hash{$k} = $v;
    }

    return \%a_hash;
}

sub _s_lines {
    my ($lines) = @_;

    my @s;
    for my $l (@$lines) {
        my ( undef, $src, $begin, $len, $strand, $src_size, $seq ) = split /\s+/, $l;

        given ($strand) {
            when ('-') { $strand = -1; }
            when ('+') { $strand = 1; }
            when ('.') { $strand = 0; }
        }
        push @s,
            Bio::Gonzales::Seq->new(
            {
                id   => $src,
                info => {
                    start   => $begin + 1,
                    end     => $begin + $len,
                    length     => $len,
                    seq_length => $src_size,
                    strand  => $strand
                },
                seq => $seq
            }
            );

    }
    return \@s;
}

__PACKAGE__->meta->make_immutable;

1;
