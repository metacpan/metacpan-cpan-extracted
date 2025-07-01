package Bio::MUST::Core::Seq;
# ABSTRACT: Nucleotide or protein sequence
# CONTRIBUTOR: Catherine COLSON <ccolson@doct.uliege.be>
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>
$Bio::MUST::Core::Seq::VERSION = '0.251810';
use Moose;
use MooseX::SemiAffordanceAccessor;
use namespace::autoclean;

# use Smart::Comments '###';

use autodie;
use feature qw(say);

use Carp;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:seqtypes :seqids :gaps);
use aliased 'Bio::MUST::Core::SeqId';

has 'seq_id' => (
    is       => 'rw',
    isa      => 'Bio::MUST::Core::SeqId',
    required => 1,
    coerce   => 1,
    handles  => qr{.*}xms,      # expose all SeqId methods (and attributes)
);


has 'seq' => (
    traits   => ['String'],
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::Seq',
    default  => q{},            # can be empty
    coerce   => 1,
    writer   => '_set_seq',
    handles  => {
            seq_len => 'length',
         append_seq => 'append',
        replace_seq => 'replace',
           edit_seq => 'substr',
    },
);



# TODO: check whether this could be done by some Moose extension

sub clone {
    my $self = shift;

    return $self->new(
        seq_id => $self->full_id, seq => $self->seq
    );
}


# boolean assertions
# TODO: optimize these assertions via caching


sub is_protein {
    my $self = shift;
    return 1 if $self->seq =~ $PROTLIKE;
    return 0;                               # at least 1 non-nt char
}


sub is_rna {
    my $self = shift;
    return 1 if $self->seq =~ $RNALIKE && (not $self->is_protein);
    return 0;                               # at least 1 'U'
}


sub is_aligned {
    my $self = shift;
    return 1 if $self->seq =~ $GAP;         # at least 1 gap-like char
    return 0;
}


sub is_subseq_of {
    my $self = shift;
    my $seq2 = shift;                       # can be a mere string

    $self = $self->raw_str;
    $seq2 = $seq2->isa('Bio::MUST::Core::Seq')
        ? $seq2->raw_str : _strip_gaps($seq2);
    return 1 if $seq2 =~ m/$self/xmsi;      # case-insensitive comparison
    return 0;                               # only here because expensive!
}


sub is_superseq_of {
    my $self = shift;
    my $seq2 = shift;                       # can be a mere string

    $self = $self->raw_str;
    $seq2 = $seq2->isa('Bio::MUST::Core::Seq')
        ? $seq2->raw_str : _strip_gaps($seq2);
    return 1 if $self =~ m/$seq2/xmsi;      # case-insensitive comparison
    return 0;                               # only here because expensive!
}


sub first_site {
    my $self = shift;

    my ($leading_gaps) = $self->seq =~ m{ \A ($GAP+) }xms;
    return length $leading_gaps // 0;
}


sub uc {                            ## no critic (ProhibitBuiltinHomonyms)
    my $self = shift;

    $self->_set_seq( uc $self->seq );
    return $self;
}

sub uc_seq {                                ## no critic (RequireArgUnpacking)
    carp '[BMC] Warning: Method uc_seq is deprecated; use uc instead!';
    return shift->uc(@_);
}


sub recode {
    my $self     = shift;
    my $base_for = shift;

    my @states = $self->all_states;
    my @rec_states;

    for my $state (@states) {
        my $rec_state = $base_for->{$state} // $FRAMESHIFT;
        push @rec_states, $rec_state;
    }

    my $new_seq = join q{}, @rec_states;
    $self->_set_seq($new_seq);

    return $self;
}

sub recode_seq {                            ## no critic (RequireArgUnpacking)
    carp '[BMC] Warning: Method recode_seq is deprecated; use recode instead!';
    return shift->recode(@_);
}

# gap cleaning methods


sub degap {
    my $self = shift;

    $self->_set_seq($self->raw_str);
    return $self;
}


sub gapify {
    my $self = shift;
    my $char = shift // '*';                # defaults to gap

    my $regex = $PROTMISS;                  # defaults to protein seq

    # in case of DNA ensure correct 'missification' (if applicable)
    unless ($self->is_protein) {
        $regex = $DNAMISS;
        $char = 'N' if $char =~ $DNAMISS;
    }

    ( my $seq = $self->seq ) =~ s{$regex}{$char}xmsg;

    # alternative versions developed due to a design error in Ali::store_phylip
    # They are now commented because less general and not critical anymore.

    # alt vers 1: hard-coding $char (if possible) gives a 250% boost
    # my $seq = $self->seq;
    # if ($self->is_protein) {
    #     if    ($char eq '*') {
    #         $seq =~ s{$PROTMISS}{*}xmsg;
    #     }
    #     elsif ($char eq 'X') {
    #         $seq =~ s{$PROTMISS}{X}xmsg;
    #     }
    #     else {
    #         $seq =~ s{$PROTMISS}{$char}xmsg;
    #     }
    # }
    # else {
    #     if    ($char eq '*') {
    #         $seq =~ s{$DNAMISS}{*}xmsg;
    #     }
    #     elsif ($char eq 'X') {
    #         $seq =~ s{$DNAMISS}{N}xmsg;
    #     }
    #     else {
    #         $seq =~ s{$DNAMISS}{$char}xmsg;
    #     }
    # }

    # alt vers 2: hard-coded tr/// for 900% boost with s/// fall-back
    # Note: $PROTMISS and $DNAMISS regexes in Constants.pm are ignored!
    # my $seq = $self->seq;
    # if ($self->is_protein) {
    #     if    ($char eq '*') {
    #         $seq =~ tr{?XxBJOUZbjouz}{*};
    #     }
    #     elsif ($char eq 'X') {
    #         $seq =~ tr{?XxBJOUZbjouz}{X};
    #     }
    #     else {
    #         $seq =~ s{[?XxBJOUZbjouz]}{$char}xmsg;
    #     }
    # }
    # else {
    #     if    ($char eq '*') {
    #         $seq =~ tr{?XxNnBDHKMRSVWYbdhkmrsvwy}{*};
    #     }
    #     elsif ($char eq 'X') {
    #         $seq =~ tr{?XxNnBDHKMRSVWYbdhkmrsvwy}{N};
    #     }
    #     else {
    #         $seq =~ s{[?XxNnBDHKMRSVWYbdhkmrsvwy]}{$char}xmsg;
    #     }
    # }

    $self->_set_seq($seq);
    return $self;
}


sub spacify {
    my $self = shift;

    my $seq = $self->seq;

    # uniformize runs of [*-space] having at least one 'true' space
    # Note: we cannot use replace_seq because of the g flag
    $seq =~ s{ ( $GAP+ \ + ) }{ ' ' x length($1) }xmseg;
    $seq =~ s{ ( \ + $GAP+ ) }{ ' ' x length($1) }xmseg;

    # Note: two simpler regexes are muuuuuch faster than one complicated regex!
    # $seq =~ s{ ( $GAP* \ + $GAP* ) }{ ' ' x length($1) }xmseg;

    $self->_set_seq($seq);
    return $self;
}


sub trim {
    my $self = shift;

    $self->replace_seq( qr{ $GAP+\z }xms, q{} );
    return $self;
}


sub pad_to {
    my $self  = shift;
    my $bound = shift;

    $self->append_seq( q{ } x ($bound - $self->seq_len) );
    return $self;
}


sub clear_new_tag {
    my $self = shift;

    (my $full_id = $self->full_id) =~ s{$NEW_TAG\z}{}xms;
    $self->set_seq_id( SeqId->new( full_id => $full_id ) );

    return $self;
}

# site-wise methods (0-numbered)


sub all_states {
    my $self = shift;
    return split //, $self->seq;
}


sub state_at {                              ## no critic (RequireArgUnpacking)
    return shift->edit_seq(@_, 1);
}


sub delete_site {                           ## no critic (RequireArgUnpacking)
    my $self = shift;

    $self->edit_seq(@_, 1, q{});
    return $self;
}


sub is_missing {
    my $self = shift;
    my $site = shift;

    my $state = $self->state_at($site);
    return 1 if $state =~ $PROTMISS;
    return 1 if $state =~  $DNAMISS && (not $self->is_protein);
    return 0;                               # X (or N depending on seq type)
}


sub is_gap {
    my $self = shift;
    my $site = shift;

    return 1 if $self->state_at($site) =~ $GAP;
    return 0;
}


# global methods

around qw(purity reverse_complemented_seq codons) => sub {
    my $method = shift;
    my $self   = shift;

    # Note: we return an explicit undef to emulate other accessor behavior
    if ($self->is_protein) {
        carp '[BMC] Warning: sequence looks like a protein; returning undef!';
        return undef;           ## no critic (ProhibitExplicitReturnUndef)
    }

    return $self->$method(@_);
};


sub nomiss_seq_len {
    my $self = shift;

    my $regex = $self->is_protein ? $PROTMISS : $DNAMISS;
    (my $raw_str = $self->raw_str) =~ s/$regex//xmsg;
    # TODO: decide how to handle ambiguous nucleotides

    return length $raw_str;
}


sub purity {
    my $self = shift;

    (my $pure_seq = $self->seq) =~ s/$NONPUREDNA//xmsg;
    my $purity = 1.0 * length($pure_seq) / $self->seq_len;

    return $purity;
}


sub reverse_complemented_seq {
    my $self = shift;

    # reverse complement and preserve case
    # Note: RNA always becomes DNA
    my $new_seq = scalar reverse $self->seq;
    $new_seq =~ tr/ATUGCYRSWKMBDHVN/TAACGRYSWMKVHDBN/;
    $new_seq =~ tr/atugcyrswkmbdhvn/taacgryswmkvhdbn/;

    return $self->new( seq_id => $self->full_id, seq => $new_seq );
}


sub spliced_seq {
    my $self   = shift;
    my $blocks = shift;

    my $new_seq;
    my $seq = $self->seq;
    for my $block ( @{$blocks} ) {
        my ($start, $end) = @{$block};
        $new_seq .= substr $seq, $start - 1, $end - $start + 1;
    }

    return $self->new( seq_id => $self->full_id, seq => $new_seq );
}


sub raw_str {
    my $self = shift;
    return _strip_gaps($self->seq);
}

sub raw_seq {                               ## no critic (RequireArgUnpacking)
    carp '[BMC] Warning: Method raw_seq is deprecated; use raw_str instead!';
    return shift->raw_str(@_);
}


sub wrapped_str {
    my $self  = shift;
    my $chunk = shift // 60;

    my $nowrap = $chunk < 0 ? 1 : 0;
    my $width = $self->seq_len;
    $chunk = $width      if $nowrap;

    my $str;
    for (my $site = 0; $site < $width; $site += $chunk) {
        $str .= $self->edit_seq($site, $chunk) . "\n";
    }

    return $str;
}


sub codons {
    my $self  = shift;
    my $frame = shift // 1;             # defaults to frame +1

    # get specified DNA strand
    my $dna = $frame < 0 ? $self->reverse_complemented_seq->seq : $self->seq;
    $dna =~ tr/Uu/Tt/;                  # ensure DNA

    # split strand into codons beginning at specified frame
    # ... and discard incomplete codons
    my @codons;
    for (my $i = (abs $frame) - 1; $i < length $dna; $i += 3) {
        my $codon = substr $dna, $i, 3;
        push @codons, $codon if length $codon == 3;
    }

    return \@codons;
}


# private subs

sub _strip_gaps {
    my $seq = shift;

    $seq =~ s/$GAP+//xmsg;
    return $seq;                                    # strip all gaps
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Seq - Nucleotide or protein sequence

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 CONSTRUCTORS

=head2 clone

=head2 reverse_complemented_seq

=head2 spliced_seq

=head1 ACCESSORS

=head2 all_states

=head2 state_at

=head2 delete_site

=head1 PROPERTIES

=head2 is_protein

=head2 is_rna

=head2 is_aligned

=head2 is_subseq_of

=head2 is_superseq_of

=head2 first_site

=head2 is_missing

=head2 is_gap

=head2 nomiss_seq_len

=head2 purity

=head1 MUTATORS

=head2 uc

=head2 recode

=head2 degap

=head2 gapify

=head2 spacify

=head2 trim

=head2 pad_to

=head2 clear_new_tag

=head1 MISC METHODS

=head2 raw_str

=head2 wrapped_str

=head2 codons

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Catherine COLSON Arnaud DI FRANCO Valerian LUPO

=over 4

=item *

Catherine COLSON <ccolson@doct.uliege.be>

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=item *

Valerian LUPO <valerian.lupo@uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
