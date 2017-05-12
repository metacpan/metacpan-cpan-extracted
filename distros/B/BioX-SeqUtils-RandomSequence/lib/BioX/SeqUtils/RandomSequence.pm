package BioX::SeqUtils::RandomSequence;
use Class::Std;
use Class::Std::Utils;
use Bio::Tools::CodonTable;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.9.4');

{
        my %type_of      :ATTR( :get<type>     :set<type>     :default<'2'>    :init_arg<y> );
        my %length_of    :ATTR( :get<length>   :set<length>   :default<'2'>    :init_arg<l> );
        my %table_of     :ATTR( :get<table>    :set<table>    :default<'1'>    :init_arg<s> );
        my %a_freq_of    :ATTR( :get<a_freq>   :set<a_freq>   :default<'1'>    :init_arg<a> );
        my %c_freq_of    :ATTR( :get<c_freq>   :set<c_freq>   :default<'1'>    :init_arg<c> );
        my %g_freq_of    :ATTR( :get<g_freq>   :set<g_freq>   :default<'1'>    :init_arg<g> );
        my %t_freq_of    :ATTR( :get<t_freq>   :set<t_freq>   :default<'1'>    :init_arg<t> );
        my %tmpl_of      :ATTR( :get<tmpl>     :set<tmpl>     :default<''>     );
                
        sub START {
                my ($self, $ident, $arg_ref) = @_;
		$self->_check_type();
		$self->_reset_tmpl();
                return;
        }

	sub rand_seq {
		my ( $self, $arg_ref ) = @_;

		my $type;
		if    ( defined $arg_ref->{type} )   { $type = $arg_ref->{type};  }
		elsif ( defined $arg_ref->{length} ) { $type = 'dna';             }  # Type not defined but length is = DNA
		else                                 { $type = $self->get_type(); }

		if    ( $type =~ m/^2/ ) { $arg_ref->{length} = 2; return $self->rand_dna( $arg_ref ); }
		elsif ( $type =~ m/^d/ ) { return $self->rand_dna( $arg_ref ); }
		elsif ( $type =~ m/^r/ ) { return $self->rand_rna( $arg_ref ); }
		elsif ( $type =~ m/^p/ ) { return $self->rand_pro( $arg_ref ); }
		elsif ( $type =~ m/^s/ ) { return $self->rand_pro_set( $arg_ref ); }
                return;
        }

	sub rand_dna {
		my ( $self, $arg_ref ) = @_;

		# Set parameters redefined by this method
		$self->_args_to_attributes( $arg_ref );

		# Create random nucleotide sequence of specified length
		my $tmpl_length = $self->get_length();
		my $nucleotides = $self->randomize_tmpl();
		while ( length($nucleotides) < $tmpl_length ) { $nucleotides .= $self->randomize_tmpl(); }
		$nucleotides     =~ s/^([ACGT]{$tmpl_length}).*$/$1/;
                return $nucleotides;
        }

	sub rand_rna {
		my ( $self, $arg_ref ) = @_;
		my $nucleotides = $self->rand_dna( $arg_ref );
		   $nucleotides =~ s/T/U/g;
                return $nucleotides;
        }

	sub rand_pro {
		my ( $self, $arg_ref ) = @_;

		# Set parameters redefined by this method
		$self->_args_to_attributes( $arg_ref );

		my $opt_l       = $arg_ref->{l} ? $arg_ref->{l} * 3 : $self->get_length() * 3;
		my $seq         = $self->rand_dna({ l => $opt_l });
		my $codon_table = Bio::Tools::CodonTable->new( -id => $self->get_table() );
		if ( $codon_table->name() eq '' ) { print "  Error: Codon Table " . $self->get_table() . " not defined.\n"; exit; }
		my $protein     = $codon_table->translate( $seq );
		
                return $protein;
        }

	sub rand_pro_set {
		my ( $self, $arg_ref ) = @_;

		# Set parameters redefined by this method
		$self->_args_to_attributes( $arg_ref );

		my $opt_l       = $arg_ref->{l} ? $arg_ref->{l} * 3 : $self->get_length() * 3;
		my $seq         = $self->rand_dna({ l => $opt_l + 1 });
		my $seq1        = $seq; $seq1  =~ s/.$//;  # Remove the last base
		my $seq2        = $seq; $seq2  =~ s/^.//;  # Remove the first base
		
		my $codon_table = Bio::Tools::CodonTable->new( -id => $self->get_table() );
		if ( $codon_table->name() eq '' ) { print "  Error: Codon Table " . $self->get_table() . " not defined.\n"; exit; }
		my $protein1    = $codon_table->translate( $seq1 );
		my $protein2    = $codon_table->translate( $seq2 );
		
                return wantarray() ? ( $protein1, $protein2 ) : [ $protein1, $protein2 ];
        }

	sub randomize_tmpl {
		my ( $self ) = @_;
		my $tmpl     = $self->get_tmpl();
		my @tmpl     = @$tmpl;
		for ( my $i = @tmpl; $i >= 0; --$i ) {
			my $j = int rand ($i + 1);
			next if $i == $j;
			@tmpl[$i,$j] = @tmpl[$j,$i];
		}
		no warnings 'all';
		return join("", @tmpl);
	}

	sub _args_to_attributes {
		my ( $self, $arg_ref ) = @_;

		if ( defined $arg_ref->{y} ) { $self->set_type( $arg_ref->{y} ); }
		if ( defined $arg_ref->{l} ) { $self->set_length( $arg_ref->{l} ); }

		my $freq_changed       = 0;

		if ( defined $arg_ref->{a} ) { $self->set_a_freq( $arg_ref->{a} ); $freq_changed++; }
		if ( defined $arg_ref->{c} ) { $self->set_c_freq( $arg_ref->{c} ); $freq_changed++; }
		if ( defined $arg_ref->{g} ) { $self->set_g_freq( $arg_ref->{g} ); $freq_changed++; }
		if ( defined $arg_ref->{t} ) { $self->set_t_freq( $arg_ref->{t} ); $freq_changed++; }
		
		# All frequencies must be set together or they are all reset to 1
		if ( $freq_changed && $freq_changed < 4 ) { $self->set_a_freq( 1 ); $self->set_c_freq( 1 ); $self->set_g_freq( 1 ); $self->set_t_freq( 1 ); }

		$self->_check_type();
		$self->_reset_tmpl() if $freq_changed;
		return;
	}

	sub _check_type {
		my ( $self, $arg_ref ) = @_;
		my $type = $self->get_type(); 
		if ( $type =~ m/^[^2drps]/ )   { print STDERR "  Error: Type (y) must be 2, d, r, p, or s.\n"; exit; }
		return;
	}

	sub _reset_tmpl {
		my ( $self, $arg_ref ) = @_;
		my @tmpl = split( //, 'A' x $self->get_a_freq() . 
		                      'C' x $self->get_c_freq() . 
				      'G' x $self->get_g_freq() . 
				      'T' x $self->get_t_freq() );
		$self->set_tmpl( \@tmpl );
		return;
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

BioX::SeqUtils::RandomSequence - Creates a random nuc or prot sequence with given nuc frequencies

=head1 VERSION

This document describes BioX::SeqUtils::RandomSequence version 0.9.4

=head1 SYNOPSIS

The randomizer object accepts parameters for sequence length (l), codon table (s), sequence 
type (y), and frequencies for each of the nucleotide bases in DNA (a, c, g, t). The defaults 
are shown below:

    use BioX::SeqUtils::RandomSequence;

    my $randomizer = BioX::SeqUtils::RandomSequence->new({ l => 2, 
                                                           s => 1,
                                                           y => "dna",
                                                           a => 1,
                                                           c => 1,
                                                           g => 1,
                                                           t => 1 });
    print $randomizer->rand_seq(), "\n";

=head1 DESCRIPTION

Create random DNA, RNA and protein sequences.

=head3 NUCLEOTIDE FREQUENCIES

All four frequencies are set to "1" by default ( so that the probablity of each A, C, G, T is 
0.25 ). The frequencies should always be positive integers, and you should consider what you 
choose. The algorithm works by creating a template with length equal to the sum L of A_freq, 
C_freq, G_freq, and T_freq with exactly the numbers of each assigned to those frequencies. The 
template is resorted for each L length part of the required sequence (and trimmed to required 
length). For example, using the default frequencies, a sequence 100 bases long will have 
exactly 25 A, 25 C, 25 G, and 25 T. If you want sequences from a wider distribution, use 
four digit (or greater) values for the frequencies. For a sequence length of a few dozen bases, 
this example would be broad enough to create repeat 
islands: ($A_freq, $C_freq, $G_freq, $T_freq) = (2245, 2755, 2755, 2245).

=head3 NUCLEOTIDE FREQUENCIES UNDERLIE PROTEINS

Protein sequences are translated from random DNA sequence of the necessary length 
using the assigned nucleotide frequencies. This module does not allow you to directly 
influence the amino acid frequencies. If you need this sort of functionality, please contact 
the author.

=head1 METHODS

=over

=item * rand_seq()

After creating a randomizer object, each sequence type can be accessed using the "y" (tYpe) 
parameter with rand_seq(). The default type is "2" (for dinucleotide, a length two dna 
sequence). The other types are "d" (dna), "r" (rna), "p" (protein), and "s" (protein set).

You can use the same randomizer object to create all types of sequences, by passing the 
changing parameters with each call.

    my $dinucleotide  = $randomizer->rand_seq();                       # Default settings
    my $nuc_short     = $randomizer->rand_seq({ y => 'd', l => 21 });  # Create DNA length 21
    my $nuc_long      = $randomizer->rand_seq({ l => 2200 });          # Still DNA, now length 2200
    my $nuc_richer    = $randomizer->rand_seq({ a => 225, 
                                                c => 275, 
						g => 275, 
						t => 225 });           # Still length 2200, GC richer
    my $protein_now   = $randomizer->rand_seq({ y => 'p' });           # Still richer GC
    my $protein_def   = $randomizer->rand_seq({ a => 1 });             # Missing bases resets all freq to 1
    my $protein_new   = $randomizer->rand_seq({ y => 'p',
                                                s => 3 });             # Use codon table 'Yeast Mitochondrial'

The type parameter only works with rand_seq().

=item * rand_dna()

This method may be used directly to create DNA sequences.

    my $dinucleotide  = $randomizer->rand_dna();
    my $dna           = $randomizer->rand_dna({ l => 2200 });
       $dna           = $randomizer->rand_seq({ l => 200, 
                                                a => 225, 
                                                c => 275, 
						g => 275, 
						t => 225 });           # Larger variance

=item * rand_rna()

This method may be used directly to create RNA sequences.

    my $rna           = $randomizer->rand_rna({ l => 21 });
       $rna           = $randomizer->rand_rna({ l => 1000, 
                                                a => 225, 
                                                c => 275, 
						g => 275, 
						t => 225 });       

=item * rand_pro()

This method may be used directly to create protein sequences.

A protein of the given length L is created by translating a random DNA sequence of 
length L * 3 with the given nucleotide frequencies. 
    
    my $protein       = $randomizer->rand_pro();

=item * rand_pro_set()

This method may be used directly to create a protein sequence set.

A protein set is correlatable at the DNA level by creating a random 
DNA sequence with the given nucleotide frequencies of length L * 3 + 1, removing 
the first base for sequence 1 and removing the last base for sequence 2, then 
translating them into proteins. 

This method uses wantarray(), and will either return a list or list 
reference (scalar) depending on the context:

    my ($pro1, $pro2) = $randomizer->rand_pro_set();
    my $protein_set   = $randomizer->rand_pro_set();

=back

=head1 SCRIPTS

The package includes scripts for random dna, rna, dinucleotide, and protein 
sequences. The length and frequency parameters should always be integers.

To create a dinucleotide sequence:

    ./random-dna.pp                                      # Defaults: length 2, all frequencies 1
    ./random-dna.pp -a250 -c250 -g250 -t250              # Create broader distribution

To create a dna sequence:

    ./random-dna.pp -l21                                 # Defaults: all frequencies 1 ( p = .25 )
    ./random-dna.pp -l2200 -a23 -c27 -g27 -t23           # Enrich GC content with length 2200

To create a rna sequence:

    ./random-rna.pp -l100                                     
    ./random-rna.pp -l2200 -a23 -c27 -g27 -t23           

To create a protein sequence:

    ./random-protein.pp                                  # Defaults: length 2, all frequencies .25
    ./random-protein.pp -l2200 -a23 -c27 -g27 -t23       # Enrich underlying GC content, aa length 2200

To create a protein set (with common DNA shifted by one base):

    ./random-protein-set.pp                              # Defaults: length 2, all frequencies .25
    ./random-protein-set.pp -l2200 -a23 -c27 -g27 -t23   # Enrich underlying GC content 

Additionally, a "master script" uses a tYpe parameter for any:

    ./random-sequence.pp                                 # Type 2 dinucleotide
    ./random-sequence.pp -yd -l100                       # Type d dna
    ./random-sequence.pp -yr -l100                       # Type r rna
    ./random-sequence.pp -yp -l100                       # Type p protein
    ./random-sequence.pp -ys -l100                       # Type s protein set

This module uses Bio::Tools::CodonTable for translations, and the parameter s can be used to 
change from the default (1) "Standard":

    ./random-protein.pp -l2200 -s2                       # Non-standard codon table


=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

    Class::Std;
    Class::Std::Utils;
    Bio::Tools::CodonTable;

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-biox-sequtils-randomsequence@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Roger A Hall  C<< <rogerhall@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyleft (c) 2009, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

Option a	+int		frequency of nucleotide A
Option c	+int		frequency of nucleotide C
Option g	+int		frequency of nucleotide G
Option l	+int		length 
Option t	+int		frequency of nucleotide T
Option s	+int		codon table 
Option y	2,d,r,p,s	type (dinucleotide, dna, rna, protein, set)




