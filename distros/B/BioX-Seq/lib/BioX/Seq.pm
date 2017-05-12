package BioX::Seq 0.006001;

use 5.012;
use strict;
use warnings;

use overload
    '""' => \&_stringify,
    '.=' => \&_concat;

my %genetic_code = (
    
    # Standard codon table

    TTT => 'F' , TCT => 'S' , TAT => 'Y' , TGT => 'C' ,
    TTC => 'F' , TCC => 'S' , TAC => 'Y' , TGC => 'C' ,
    TTA => 'L' , TCA => 'S' , TAA => '*' , TGA => '*' ,
    TTG => 'L' , TCG => 'S' , TAG => '*' , TGG => 'W' ,
    
    CTT => 'L' , CCT => 'P' , CAT => 'H' , CGT => 'R' ,
    CTC => 'L' , CCC => 'P' , CAC => 'H' , CGC => 'R' ,
    CTA => 'L' , CCA => 'P' , CAA => 'Q' , CGA => 'R' ,
    CTG => 'L' , CCG => 'P' , CAG => 'Q' , CGG => 'R' ,

    ATT => 'I' , ACT => 'T' , AAT => 'N' , AGT => 'S' ,
    ATC => 'I' , ACC => 'T' , AAC => 'N' , AGC => 'S' ,
    ATA => 'I' , ACA => 'T' , AAA => 'K' , AGA => 'R' ,
    ATG => 'M' , ACG => 'T' , AAG => 'K' , AGG => 'R' ,

    GTT => 'V' , GCT => 'A' , GAT => 'D' , GGT => 'G' ,
    GTC => 'V' , GCC => 'A' , GAC => 'D' , GGC => 'G' ,
    GTA => 'V' , GCA => 'A' , GAA => 'E' , GGA => 'G' ,
    GTG => 'V' , GCG => 'A' , GAG => 'E' , GGG => 'G' ,
    
    # Extension containing all permutations using ambiguity codes
    
    AAU => 'N' , AAR => 'K' , AAY => 'N' , ACU => 'T' ,
    ACM => 'T' , ACR => 'T' , ACW => 'T' , ACS => 'T' ,
    ACY => 'T' , ACK => 'T' , ACV => 'T' , ACH => 'T' ,
    ACD => 'T' , ACB => 'T' , ACN => 'T' , AGU => 'S' ,
    AGR => 'R' , AGY => 'S' , ATU => 'I' , ATM => 'I' ,
    ATW => 'I' , ATY => 'I' , ATH => 'I' , AUA => 'I' ,
    AUC => 'I' , AUG => 'M' , AUT => 'I' , AUU => 'I' ,
    AUM => 'I' , AUW => 'I' , AUY => 'I' , AUH => 'I' ,
    CAU => 'H' , CAR => 'Q' , CAY => 'H' , CCU => 'P' ,
    CCM => 'P' , CCR => 'P' , CCW => 'P' , CCS => 'P' ,
    CCY => 'P' , CCK => 'P' , CCV => 'P' , CCH => 'P' ,
    CCD => 'P' , CCB => 'P' , CCN => 'P' , CGU => 'R' ,
    CGM => 'R' , CGR => 'R' , CGW => 'R' , CGS => 'R' ,
    CGY => 'R' , CGK => 'R' , CGV => 'R' , CGH => 'R' ,
    CGD => 'R' , CGB => 'R' , CGN => 'R' , CTU => 'L' ,
    CTM => 'L' , CTR => 'L' , CTW => 'L' , CTS => 'L' ,
    CTY => 'L' , CTK => 'L' , CTV => 'L' , CTH => 'L' ,
    CTD => 'L' , CTB => 'L' , CTN => 'L' , CUA => 'L' ,
    CUC => 'L' , CUG => 'L' , CUT => 'L' , CUU => 'L' ,
    CUM => 'L' , CUR => 'L' , CUW => 'L' , CUS => 'L' ,
    CUY => 'L' , CUK => 'L' , CUV => 'L' , CUH => 'L' ,
    CUD => 'L' , CUB => 'L' , CUN => 'L' , GAU => 'D' ,
    GAR => 'E' , GAY => 'D' , GCU => 'A' , GCM => 'A' ,
    GCR => 'A' , GCW => 'A' , GCS => 'A' , GCY => 'A' ,
    GCK => 'A' , GCV => 'A' , GCH => 'A' , GCD => 'A' ,
    GCB => 'A' , GCN => 'A' , GGU => 'G' , GGM => 'G' ,
    GGR => 'G' , GGW => 'G' , GGS => 'G' , GGY => 'G' ,
    GGK => 'G' , GGV => 'G' , GGH => 'G' , GGD => 'G' ,
    GGB => 'G' , GGN => 'G' , GTU => 'V' , GTM => 'V' ,
    GTR => 'V' , GTW => 'V' , GTS => 'V' , GTY => 'V' ,
    GTK => 'V' , GTV => 'V' , GTH => 'V' , GTD => 'V' ,
    GTB => 'V' , GTN => 'V' , GUA => 'V' , GUC => 'V' ,
    GUG => 'V' , GUT => 'V' , GUU => 'V' , GUM => 'V' ,
    GUR => 'V' , GUW => 'V' , GUS => 'V' , GUY => 'V' ,
    GUK => 'V' , GUV => 'V' , GUH => 'V' , GUD => 'V' ,
    GUB => 'V' , GUN => 'V' , TAU => 'Y' , TAR => '*' ,
    TAY => 'Y' , TCU => 'S' , TCM => 'S' , TCR => 'S' ,
    TCW => 'S' , TCS => 'S' , TCY => 'S' , TCK => 'S' ,
    TCV => 'S' , TCH => 'S' , TCD => 'S' , TCB => 'S' ,
    TCN => 'S' , TGU => 'C' , TGY => 'C' , TTU => 'F' ,
    TTR => 'L' , TTY => 'F' , TUA => 'L' , TUC => 'F' ,
    TUG => 'L' , TUT => 'F' , TUU => 'F' , TUR => 'L' ,
    TUY => 'F' , TRA => '*' , UAA => '*' , UAC => 'Y' ,
    UAG => '*' , UAT => 'Y' , UAU => 'Y' , UAR => '*' ,
    UAY => 'Y' , UCA => 'S' , UCC => 'S' , UCG => 'S' ,
    UCT => 'S' , UCU => 'S' , UCM => 'S' , UCR => 'S' ,
    UCW => 'S' , UCS => 'S' , UCY => 'S' , UCK => 'S' ,
    UCV => 'S' , UCH => 'S' , UCD => 'S' , UCB => 'S' ,
    UCN => 'S' , UGA => '*' , UGC => 'C' , UGG => 'W' ,
    UGT => 'C' , UGU => 'C' , UGY => 'C' , UTA => 'L' ,
    UTC => 'F' , UTG => 'L' , UTT => 'F' , UTU => 'F' ,
    UTR => 'L' , UTY => 'F' , UUA => 'L' , UUC => 'F' ,
    UUG => 'L' , UUT => 'F' , UUU => 'F' , UUR => 'L' ,
    UUY => 'F' , URA => '*' , MGA => 'R' , MGG => 'R' ,
    MGR => 'R' , YTA => 'L' , YTG => 'L' , YTR => 'L' ,
    YUA => 'L' , YUG => 'L' , YUR => 'L' , 

);

sub new {

    my ($class, $seq, $id, $desc, $qual) = @_;
    my $self = bless {}, $class;
    $self->{seq}  = $seq  // '';
    $self->{id}   = $id   // undef;
    $self->{desc} = $desc // undef;
    $self->{qual} = $qual // undef;
    return $self;

}

sub seq : lvalue {

    my ($self,$new_val) = @_;
    $self->{seq} = $new_val if (defined $new_val);
    return $self->{seq};

}

sub id : lvalue {

    my ($self,$new_val) = @_;
    $self->{id} = $new_val if (defined $new_val);
    return $self->{id};

}

sub desc : lvalue {

    my ($self,$new_val) = @_;
    $self->{desc} = $new_val if (defined $new_val);
    return $self->{desc};

}

sub qual : lvalue {

    my ($self,$new_val) = @_;
    $self->{qual} = $new_val if (defined $new_val);
    return $self->{qual};

}

sub range {

    my ($self, $start, $end) = @_;
    if ($start < 1 || $end > length($self->{seq})) {
        warn "Range outside of sequence length\n";
        return undef;
    }
    my $seq = substr $self->{seq}, $start-1, $end-$start+1;
    my $qual = defined $self->{qual}
        ? substr $self->{qual}, $start-1, $end-$start+1
        : undef;
    return __PACKAGE__->new(
        $seq,
        "$self->{id}_$start-$end",
        $self->{desc},
        $qual,
    );

}

sub as_fasta {

    my ($self, $line_length) = @_;
    my $l = $line_length // 60;
    if (! defined $self->{id}) {
        warn "Can't write FASTA with undefined ID\n";
        return 0;
    }
    my $string = '>' . $self->{id};
    $string .= ' ' . $self->{desc} if (defined $self->{desc});
    $string .= "\n";
    my $i = 0;
    while ($i < length($self->{seq})) {
        $string .= substr($self->{seq}, $i, $l) . "\n";
        $i += $l;
    }
    return $string;

}

sub as_fastq {

    my ($self, $qual) = @_;
    $qual = $qual // 20;
    if (! defined $self->{id}) {
        warn "Can't write FASTQ with undefined ID\n";
        return 0;
    }
    my $string = '@' . $self->{id};
    $string .= ' ' . $self->{desc} if (defined $self->{desc});
    $string .= "\n";
    $string .= $self->{seq};
    $string .= "\n+\n";

    # populate qual with constant quality if not defined
    $string .= $self->{qual} // chr($qual+33) x length($self->{seq});
    $string .= "\n";
    return $string;

}

sub rev_com {

    my ($self) = @_;

    my $seq = $self->{seq};
    $seq =~ tr/Xx/Nn/;
     if (! _is_nucleic($seq) ) {
        warn "Bad input sequence\n";
        return;
    }
    $seq = reverse $seq;
    $seq =~ tr
        {ACGTMRWSYKVHDBNacgtmrwsykvhdbn-}
        {TGCAKYWSRMBDHVNtgcakywsrmbdhvn-};

    my $qual = $self->{qual};
    $qual = reverse $qual if (defined $qual);

    # If in void context, act in-place
    if (! defined wantarray) {
        $self->{seq} = $seq;
        $self->{qual} = $qual;
        return 1;
    }

    # else return a new sequence object
    return __PACKAGE__->new(
        $seq,
        $self->{id},
        $self->{desc},
        $qual,
    );

}

sub translate {

    my ($self,$frame) = @_;

    $frame = $frame // 0;
    die "$frame is not a valid frame (must be between 0 and 5)\n"
        if ($frame < 0 || $frame > 5);

    my $seq = uc( $frame > 2 ? $self->rev_com->seq : $self->seq );
    $seq = substr $seq, $frame%3;
    $seq =~ tr/X/N/;
    if (! _is_nucleic($seq) ) {
        warn "Input doesn't look like DNA\n";
        return undef;
    }

    $seq = join('', map {$genetic_code{$_} // 'X'}
        unpack 'A3' x int(length($seq)/3), $seq);

    # If in void context, act in-place
    if (! defined wantarray) {
        $self->{seq} = $seq;
        $self->{qual} = undef;
        return 1;
    }

    # else return a new sequence object
    return __PACKAGE__->new(
        $seq,
        $self->{id},
        $self->{desc},
    );

}

sub _stringify {

    my ($self) = @_;
    return $self->{seq} // '';

}

sub _concat {

    my ($self,$addition,$other) = @_;
    $self->{seq} .= $addition;
    return $self;

}

sub _is_nucleic {

    my ($seq) = @_;
    return $seq !~ /[^ACGTUMRWSYKVHDBN-]/i;
}


1;


__END__

=head1 NAME

BioX::Seq - a (very) basic biological sequence object

=head1 SYNOPSIS

    use BioX::Seq;

    my $seq = BioX::Seq->new();

    for (qw/AATG TAGG CCAT TTGA/) {
        $seq .= $_;
    }

    $seq->id( 'test_seq' );

    my $rc = $seq->rev_com(); # original untouched
    print $seq->as_fasta();

    # >test_seq
    # AATGTAGGCCATTTGA

    $seq->rev_com(); # original modified in-place
    print $seq->as_fastq(22);

    # @test_seq
    # TCAAATGGCCTACATT
    # +
    # 7777777777777777

    print $seq->range(3,6)->as_fasta();

    # >test_seq
    # AAAT

=head1 DESCRIPTION

C<BioX::Seq> is a simple sequence class that can be used to represent
biological sequences. It was designed as a compromise between using simple
strings and hashes to hold sequences and using the rather bloated objects of
Bioperl. Features (or, depending on your viewpoint, bugs) include
auto-stringification and context-dependent transformations. It is meant
be used primarily as the return object of the C<BioX::Seq::Fastx> parser, but
there may be occasions where it is useful in its own right.

C<BioX::Seq> current implements a small subset of the transformations most
commonly used by the author (reverse complement, translate, subrange) - more
methods may be added in the future as use suggests and time permits, but the
core object will be kept as simple as possible and should be limited to the
four current properties - sequence, ID, description, and quality - that
satisfy 99% of the author's needs.

Some design decisions have been made for the sake of speed over ease of use.
For instance, there is no sanity-checking of the object properties upon
creation of a new object or use of the accessor methods. Parameters to the
constructor are positional rather than named (testing indicates that this
reduces execution times by ~ 40%). 

=head1 METHODS

=over 4

=item B<new>

=item B<new> I<SEQUENCE>

=item B<new> I<SEQUENCE> I<ID>

=item B<new> I<SEQUENCE> I<ID> I<DESCRIPTION>

=item B<new> I<SEQUENCE> I<ID> I<DESCRIPTION> I<QUALITY>

Create a new C<BioX::Seq> object (empty by default). All arguments are optional
but are positional and, if provided, must be given in order.

    $seq = BioX::Seq->new( SEQ, ID, DESC, QUALITY );

Returns a new C<BioX::Seq> object.

=item B<seq>, B<id>, B<desc>, B<qual>

Accessors to the object properties named accordingly. Properties can also be
accessed directly as hash keys. This is probably frowned upon by some, but can be
useful at times e.g. to perform substution on a property in-place.

    $seq->{id} =~ s/^Unnecessary_prefix//;

Takes zero or one arguments. If an argument is given, assigns that value to the
property in question. Returns the current value of the property.

=item B<range> I<START> I<END>

Extract a subsequence from I<START> to I<END>. Coordinates are 1-based.

Returns a new BioX::Seq object, or I<undef> if the coordinates are outside the
limits of the parent sequence.

=item B<rev_com>

Reverse complement the sequence.

Behavior is context-dependent. In scalar or list context, returns a new
BioX::Seq object containing the reverse-complemented sequence, leaving the
original sequence untouched. In void context, updates the original sequence
in-place and returns TRUE if successful.

=item B<translate>

=item B<translate> I<FRAME>

Translate a nucleic acid sequence to a peptide sequence.

I<FRAME> specifies the starting point of the translation. The default is zero.
A I<FRAME> value of 0-2 will return the translation of each of the three
forward reading frames, respectively, while a value of 3-5 will return the
translation of each of the three reverse reading frames, respectively.

=item B<as_fasta>

=item B<as_fasta> I<LINE_LENGTH>

Returns a string representation of the sequence in FASTA format. Requires
that, at a minimum, the <seq> and <id> properties be defined. I<LINE_LENGTH>,
if given, specifies the line length for wrapping purposes (default: 60).

=item B<as_fastq>

=item B<as_fastq> I<DEFAULT_QUALITY>

Returns a string representation of the sequence in FASTQ format. Requires
that, at a minimum, the <seq> and <id> properties be defined.
I<DEFAULT_QUALITY>, if given, specifies the default Phred quality score to be
assigned to each base if missing - for instance, if converting from FASTA to
FASTQ (default: 20).

=back

=head1 CAVEATS AND BUGS

No input validation is performed during construction or modification of the
object properties.

Performing certain operations (for instance, s///) on a BioX::Seq object
relying on auto-stringification may convert the object into a simple unblessed
scalar containing the sequence string. You will likely know if this happens
(you are using strict and using warnings, right?) because your script will
throw an error if you try to perform a class method on the (now) unblessed
scalar.

Please report bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jeremy *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Jeremy Volkening

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

