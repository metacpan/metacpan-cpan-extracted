package Bio::Gonzales::Seq::Filter;

use warnings;
use strict;
use Carp;
use Scalar::Util qw/blessed/;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(clean_peptide_seq clean_dna_seq clean_rna_seq clean_pep_seq);

sub clean_pep_seq {
    my ( $seqs, $config ) = @_;

    $seqs = [ $seqs ] if(blessed( $seqs) && $seqs->isa('Bio::Gonzales::Seq'));
    confess "please supply the sequences as an arrayref" unless ( ref $seqs eq 'ARRAY' );
    confess "config format not readable" if ( $config && ref $config ne 'HASH' );

    for my $s (@$seqs) {

        my $seq = $s->seq;

        $seq =~ tr/*//d if ( !exists( $config->{terminal} )     || $config->{terminal} );
        $seq =~ s/\*$// if ( !exists( $config->{end_terminal} ) || $config->{end_termninal} );
        $seq =~ s/[^*SFTNKYEVZQMCLAOWXPBHDIRGsftnkyevzqmclaowxpbhdirg]/X/g
            if ( !exists( $config->{uncommon_aa} ) || $config->{uncommon_aa} );
        $s->seq($seq);
        $s->desc('') if ( !exists( $config->{no_desc} ) || $config->{no_desc} );
    }
    return $seqs;
}

sub clean_peptide_seq { return clean_pep_seq(@_); }

sub clean_rna_seq {
    my ( $seqs, $config ) = @_;

    $seqs = [ $seqs ] if(blessed($seqs) && $seqs->isa('Bio::Gonzales::Seq'));
    confess "please supply the sequences as an arrayref" unless ( ref $seqs eq 'ARRAY' );
    confess "config format not readable" if ( $config && ref $config ne 'HASH' );

    for my $s (@$seqs) {

        my $seq = $s->seq;
        $seq =~ y/Tt/Uu/;
        $seq =~ y/AGCUNagcun/N/c;
        $s->seq($seq);
        $s->desc('') if ( !exists( $config->{no_desc} ) || $config->{no_desc} );
    }
    return $seqs;

}

sub clean_dna_seq {
    my ( $seqs, $config ) = @_;


    $seqs = [ $seqs ] if(blessed($seqs) && $seqs->isa('Bio::Gonzales::Seq'));
    confess "please supply the sequences as an arrayref" unless ( ref $seqs eq 'ARRAY' );
    confess "config format not readable" if ( $config && ref $config ne 'HASH' );

    for my $s (@$seqs) {

        my $seq = $s->seq;
        $seq =~ y/AGCTNagctn/N/c;
        $s->seq($seq);
        $s->desc('') if ( !exists( $config->{no_desc} ) || $config->{no_desc} );
    }
    return $seqs;

}

1;

__END__

=head1 NAME

Bio::Gonzales::Seq::Filter - filter sequence data

=head1 SYNOPSIS

    use Bio::Gonzales::Seq::Filter qw(clean_pep_seq clean_dna_seq clean_rna_seq);

=head1 DESCRIPTION

=head1 SUBROUTINES

=over 4

=item B<< $seqs = clean_dna_seq(\@seqs!, \%config)  >>

Do some cleaning, substitute invalid nucleotides with N, remove the
description of the sequence objects.

C<clean_dna_seq> leaves the sequence object description untouched if 

  %config = ( no_desc => 0 );

=item B<< $seqs = clean_pep_seq(\@seqs!, \%config)  >>

=item B<< $seqs = clean_rna_seq(\@seqs!, \%config)  >>

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
