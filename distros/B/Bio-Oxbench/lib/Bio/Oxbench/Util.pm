package Bio::Oxbench::Util;

use strict;
use warnings;
use Carp;
use English qw/-no_match_vars/;

sub fasta2bloc {
    my ( $in, $out ) = @_;

    my $ifh;
    if ( $in eq q{-} ) {
        $ifh = \*STDIN;
    }
    else {
        open $ifh, '<', $in or die "$!: $in\n";
    }
    my $alignment = read_fasta($ifh);

    # Write data
    my $ofh;
    if ( $out eq '-' ) {
        $ofh = \*STDOUT;
    }
    else {
        open $ofh, '>', $out or die "$!: $out\n";
    }
    write_bloc( $ofh, $alignment );
    return;
}

sub write_bloc {
    my ( $fh, $align ) = @_;

    for my $id ( @{ $align->{id} } ) {
        print {$fh} ">$id\n";
    }
    print {$fh} "* iteration 1\n";
    for my $i ( 0 .. $align->{alen} - 1 ) {
        for my $seq ( @{ $align->{seq} } ) {
            print {$fh} substr( $seq, $i, 1 );
        }
        print {$fh} "\n";
    }
    print {$fh} "*\n";
    return;
}

sub read_fasta {
    my $fh = shift;

    my $align = {
        seq => [],
        id  => [],
    };

    while (<$fh>) {
        chomp;
        if (/^>/) {
            my $label = substr $_, 1;
            $label =~ s/ .*//;
            push @{ $align->{id} },  $label;
            push @{ $align->{seq} }, q{};
        }
        else {
            $align->{seq}->[-1] .= $_;
        }
    }
    $align->{alen} = length $align->{seq}[0];
    $align->{nseq} = @{ $align->{seq} };
    return $align;
}

1;

__END__

=pod

=head2 FUNCTIONS

=over 4

=item fasta2blc ( FASTA-FILE, BLOC-FILE )

Read the FASTA format alignment file C<FASTA_FILE> and write the alignment 
in BLOC format to C<BLOC-FILE>

=back

=cut

