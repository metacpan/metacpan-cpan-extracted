package Bio::MUST::Apps::HmmCleaner::Cleaner;
# ABSTRACT: Cleaner class for HmmCleaner
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>
$Bio::MUST::Apps::HmmCleaner::Cleaner::VERSION = '0.243280';
use Moose;
use namespace::autoclean;

use Carp;
use Smart::Comments -ENV;
use List::AllUtils qw/max pairmap indexes/;
use Modern::Perl;

use Bio::MUST::Core 0.180230;
use Bio::MUST::Core::Constants qw(:gaps :files);
use aliased 'Bio::MUST::Core::SeqMask';
use aliased 'Bio::MUST::Core::Seq';

####### [PROCESS] Value of env verbosity : scalar(split ' ', $ENV{Smart_Comments})

# ATTRIBUTES

has 'seq' => (
    is          => 'ro',
    isa         => 'Bio::MUST::Core::Seq',
    required    => 1,
);

has 'score' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has 'nogap_seq' => (
    is          => 'ro',
    isa         => 'Bio::MUST::Core::Seq',
    lazy        => 1,
    builder     => '_build_nogap_seq',
);

has 'threshold' => (
    is            => 'ro',
    isa            => 'Int',
    required    => 1,
    writer      => '_set_threshold',
);

has 'delchar' => (
    is            => 'ro',
    isa            => 'Str',
    default        => ' ',
);

has 'nogap_shifts' => (
    is          => 'ro',
    isa         => 'ArrayRef[Int]', # Future 'Bio::MUST::Core::SeqMask' or not
    lazy        => 1,
    writer      => '_set_nogap_shifts',
    builder     => '_build_nogap_shifts',
);

has 'shifts' => (
    is          => 'ro',
    isa         => 'ArrayRef[Int]', # Future 'Bio::MUST::Core::SeqMask' or not
    lazy        => 1,
    writer      => '_set_shifts',
    builder     => '_build_shifts',
);

has 'costs' => (
    traits        => ['Array'],
    is            => 'ro',
    isa            => 'ArrayRef[Num]',
    required    => 1,
    writer      => '_set_costs',
    handles        => {
        _get_cost => 'get',
    }

);

has 'consider_X' => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 1,
);

has 'is_protein' => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 1,
);


# BUILDER

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_nogap_seq {
    my $self = shift;
    my $seq = $self->seq;
    my $nogap_seq = ($self->consider_X) ? $seq->clone->gapify('X')->degap : $seq->clone->gapify->degap;
    ##### [CLEANER] Nogap seq : $nogap_seq->seq
    return $nogap_seq;
}

sub _build_nogap_shifts {
    return shift->_get_nogap_shifts;
}

sub _build_shifts {
    return shift->_get_shifts;
}

## use critic


# METHOD

sub update {
    my $self = shift;
    my $threshold = shift;
    my $costs = shift;

    $self->_set_costs($costs);
    $self->_set_threshold($threshold);
    # watch out, the order is important here
    $self->_set_nogap_shifts($self->_get_nogap_shifts);
    $self->_set_shifts($self->_get_shifts);

    return 1;
}

sub get_nogap_result {
    my $self = shift;

    #~ my $nogap_result = _erasezone($self, $self->nogap_seq->seq, $self->nogap_mask);
    #~ #### $nogap_result
    #~ return Seq->new( seq_id => $self->nogap_seq->full_id, seq => $nogap_result );

    return $self->_apply_mask($self->nogap_seq, $self->get_nogap_seqmask);

}

sub get_result {
    my $self = shift;

    #~ my $result = _erasezone( $self, $self->seq->seq, $self->mask );
    #~ #### $result
    #~ return Seq->new( seq_id => $self->seq->full_id, seq => $result );

    return $self->_apply_mask($self->seq, $self->get_seqmask);
}

# PRIVATE SUB

sub _get_nogap_shifts {
    my $self = shift;

    my $concat_scoreseq = $self->score;

    # this function return a list of shifts between good and bad positions, ArrayRef
    ##### [CLEANER] Finding shifts...
    my $shifts = _findingShifts($self, $concat_scoreseq);
    ###### [CLEANER] $shifts

    return $shifts;
}


sub _get_shifts {
    my $self = shift;
    my $shifts = $self->nogap_shifts;

    ##### [CLEANER] Looking for gaps in full sequence...
    my @gaps_n_seqs;
    my $push = 0;

    my $regex = ($self->consider_X)
              ? $GAP
              : ( ($self->is_protein) ? $GAPPROTMISS : $GAPDNAMISS );
    foreach my $tab ( split /$regex/x, $self->seq->seq ) {
        if( length($tab) == 0){
            $push++;
        }
        else{
            push(@gaps_n_seqs, $push);
            push(@gaps_n_seqs, length($tab));
            $push = 1;
        }
    }

    ###### [CLEANER] @gaps_n_seqs

    # Updating frameshift position by taking gaps into account
    my $shifts_withgaps = _pushingShifts( $shifts, \@gaps_n_seqs );

    ##### [CLEANER] shifts after _pushingShifts: $shifts_withgaps

    return $shifts_withgaps;

}

sub _shifts2mask {
    my $shifts  = shift; # shifts as created by _build_shifts or _pushingShifts
    my $max     = shift; # max size of mask -> seq length

    my @blocks;
    push @blocks, [1,$$shifts[0]] if ($$shifts[0]!=0);
    for (my $i=1; $i<@$shifts-1; $i+=2) {
        push @blocks, [$$shifts[$i]+1,$$shifts[$i+1]];
    }

    my $mask = SeqMask->empty_mask($max);
    $mask->mark_block( @{$_} ) for @blocks;

    return $mask;
}

# slide the shifts to match the fullseq with gap
sub _pushingShifts {
    my ($refshifts, $reftabs) = @_;

    my @shifts = @$refshifts;
    my @tabs = @$reftabs;

    my $index = 0;
    my $push = 0;
    my $level = 0;

    # iterate throught length of gaps' block and length of seqs' block
    while(scalar(@tabs) != 0) {

            $push += shift(@tabs); # a total number of gap cross at the moment
            $level += shift(@tabs); # a total number of residue cross at the moment

            # add current crossed number of gap when the number of residue pass the shift position
            while( $shifts[$index] < $level ) {
                $shifts[$index] += $push;
                $index++;
            }

    }
    $shifts[-1] += $push;

    return \@shifts;
}

# slide the shifts to match the fullseq with gap
#~ sub _pushingBlocks {
    #~ use Smart::Comments;
    #~ my ($refblocks, $reftabs) = @_;
    #~
    #~ my @flat_blocks = map {@$_} @$refblocks;
    #~ my @tabs = @$reftabs;
    #~
    #~ my $index = 0;
    #~ my $push = 0;
    #~ my $level = 0;
    #~
    #~ # iterate throught length of gaps' block and length of seqs' block
    #~ while(scalar(@tabs) != 0) {
        #~
            #~ $push += shift(@tabs); # a total number of gap cross at the moment
            #~ $level += shift(@tabs); # a total number of residue cross at the moment
#~
            #~ next if ($index == $#flat_blocks);
            #~ # add current crossed number of gap when the number of residue pass the shift position
            #~ while( $flat_blocks[$index] < $level ) {
                #~ ### in while Blocks : $flat_blocks[$index]
                #~ ### in while level  : $level
                #~ $flat_blocks[$index] += $push;
                #~ $index++;
            #~ }
            #~ last if ($index == $#flat_blocks);
    #~ }
    #~ $flat_blocks[$#flat_blocks] += $push;
    #~ ### End value level : $level
    #~ ### End value push  : $push
#~
    #~ push my @blocks, pairmap { [ $a , $b ] } @flat_blocks;
    #~ return \@blocks;
#~ }


# use shifts informations to replace blocks in sequence by $delchar
#~ sub _erasezone {
    #~ my ($self, $seq, $shifts) = @_;
    #~
    #~ my $result = '';
    #~ my @s = @$shifts;
    #~ my $a1 = 0;
    #~
    #~ while(scalar(@s) != 0) {
            #~ my $a2 = shift(@s);
            #~ $result .= substr($seq, $a1, $a2-$a1);
            #~
            #~ if ( scalar(@s) != 0 ) {
                #~ $a1 = shift(@s);
            #~ } else {
                #~ $a1 = length($seq);
            #~ }
            #~ $result .= $self->delchar x ($a1-$a2);
    #~ }
    #~ $result .= substr($seq, $a1, length($seq)-$a1);
    #~ return $result;
#~ }

sub _apply_mask {
    my $self = shift;
    my $seq  = shift;
    my $mask = shift;

    my $new_seq = $seq->clone;
    # select sites for each seq using a precomputed array slice
    my @indexes = indexes { !$_ } $mask->all_states;
    for my $pos (@indexes) {
        $new_seq->edit_seq($pos,1,$self->delchar);
    }

    return $new_seq;
}

sub get_nogap_seqmask {
    my $self = shift;

    return _shifts2mask($self->nogap_shifts, $self->nogap_seq->seq_len);
}

sub get_seqmask {
    my $self = shift;

    return _shifts2mask($self->shifts, $self->seq->seq_len);
}

# Base of algorithm, decide if there are frameshift in seq based on domains score
sub _findingShifts {
    my ($self, $score) = @_;

    my $threshold = $self->threshold;
    my $val = $threshold;
    my $previous_pos = -1;
    my $shift = $previous_pos;
    my $hasShift = 0;

    my @shifts;
    for(my $pos=0; $pos != length($score); $pos++){
        my $c = substr($score, $pos, 1);

        # Updating val
        if($c eq " "){
            $val += $self->_get_cost(0); # default -0.15
        }
        elsif($c eq "+"){
            $val += $self->_get_cost(1); # default -0.08
        }
        elsif($c =~ /[a-z]/x){
            $val += $self->_get_cost(2); # default 0.15
        }
        elsif($c =~ /[A-Z]/x){
            $val += $self->_get_cost(3); # default 0.45
        }
        else{
            carp "Found unknowed character in Hmmer output : -$c-";
            exit;
        }


        # Putting mininal value back into window
        if($val < 0){
            $val = 0;
        }
        if($val>$threshold){
            $val = $threshold;
        }

        # Deciding if shift or not
        if($hasShift==0){
            if($val==0){
                push(@shifts, $shift);
                $previous_pos = $pos;
                $shift = $previous_pos;
                $hasShift = 1;
            }
            elsif($val == $threshold){
                $shift = $previous_pos;
            }
            elsif($shift == $previous_pos){
                $shift=$pos;
            }
        }
        else{
            if($val == 0){
                $shift = $previous_pos;
            }
            else{
                if($shift == $previous_pos){
                    $shift = $pos;
                }
                if($val==$threshold){
                    push(@shifts, $shift);
                    $previous_pos = $pos;
                    $hasShift=0;
                    $shift=$previous_pos;
                }
            }
        }

    }
    push(@shifts, length($score));
    #foreach (@shifts) {print "$_ ";}print "\n";
    return \@shifts;
}

# Base of algorithm, decide if there are frameshift in seq based on domains score
#~ sub _findingBlocks {
    #~ my ($self, $score) = @_;
    #~
    #~ my $threshold = $self->threshold;
    #~ my $val = $threshold;
    #~ my $startok = 0;
    #~ my $endok   = 0;
    #~ my $isok    = 1;
    #~
    #~ my @blocks;
    #~ for(my $pos=1; $pos <= length($score); $pos++){
        #~ my $c = substr($score, $pos-1, 1);
        #~
        #~ # Updating val
        #~ if($c eq " "){
            #~ $val += $self->_get_cost(0); # default -3
        #~ }
        #~ elsif($c eq "+"){
            #~ $val += $self->_get_cost(1); # default -1
        #~ }
        #~ elsif($c =~ /[a-z]/){
            #~ $val += $self->_get_cost(2); # default 10/5 = 2
        #~ }
        #~ elsif($c =~ /[A-Z]/){
            #~ $val += $self->_get_cost(3); # default 10/2 = 5
        #~ }
        #~ else{
            #~ carp "Found unknowed character in Hmmer output : -$c-";
            #~ exit;
        #~ }
        #~
        #~
        #~ # Putting minimal value back into window
        #~ $val = 0 if ($val<0);
        #~ $val = $threshold if ($val>$threshold);
        #~
        #~ # Deciding if shift or not
        #~ if($isok){
            #~ if ($val==0) {
                #~ ### not ok anymore start : $startok
                #~ ### not ok anymore end   : $endok
                #~ push(@blocks, [$startok,$endok]) if ($endok);
                #~ $isok = 0;
                #~ $startok = $pos+1;
            #~ } else {
                #~ if ($val == $threshold) {
                    #~ $startok = 1 unless ($endok);
                    #~ $endok = -1;
                #~ } elsif ($endok == -1) {
                    #~ $endok = $pos-1 if ($startok);
                #~ }
            #~ }
        #~ } else {
            #~ if ($val==$threshold) {
                #~ $isok = 1;
                #~ $endok = -1;
                #~ ### ok again start : $startok
                #~ ### ok again end   : $endok
            #~ }
            #~ $startok = $pos+1 if ($val==0);
        #~ }
        #~ ### char Val pos : join("\t", ($c,$val,$pos))
    #~ }
    #~ push(@blocks, [$startok,length($score)]) if ($isok);
    #~ #foreach (@shifts) {print "$_ ";}print "\n";
    #~ return \@blocks;
#~ }


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::HmmCleaner::Cleaner - Cleaner class for HmmCleaner

=head1 VERSION

version 0.243280

=head1 AUTHOR

Arnaud Di Franco <arnaud.difranco@gmail.fr>

=head1 CONTRIBUTOR

=for stopwords Denis BAURAIN

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Arnaud Di Franco.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
