package Bio::MUST::Core::SeqMask;
# ABSTRACT: Sequence mask for selecting specific sites
# CONTRIBUTOR: Catherine COLSON <ccolson@doct.uliege.be>
# CONTRIBUTOR: Raphael LEONARD <rleonard@doct.uliege.be>
$Bio::MUST::Core::SeqMask::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments '###';

use Carp;
use File::Basename;
use IPC::System::Simple qw(system);
use List::AllUtils 0.08 qw(uniq max sum natatime first_index last_index pairmap mesh bundle_by);
use Path::Class qw(file);
use POSIX qw(ceil floor);

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:gaps :files);
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdList';
with 'Bio::MUST::Core::Roles::Commentable';


# public array
# Note: mask methods use the 0-based C/Perl array indexing
# ...but block methods encode bounds using the usual 1-based indexing
has 'mask' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bool]',
    default  => sub { [] },
    writer   => '_set_mask',
    handles  => {
        mask_len     => 'count',
        all_states   => 'elements',
        add_state    => 'push',
        set_state    => 'set',
            state_at => 'get',
    },
);



sub first_site {
    my $self = shift;
    return first_index { $_ } $self->all_states;
}



sub last_site {
    my $self = shift;
    return last_index { $_ } $self->all_states;
}



sub count_sites {
    my $self = shift;
    my $count = grep { $_ } $self->all_states;
    return $count;
}



sub coverage {
    my $self = shift;
    return $self->count_sites / $self->mask_len;
}



sub empty_mask {
    my $class = shift;
    my $len   = shift // 0;

    return $class->new( mask => [ (0) x $len ] );
}



sub custom_mask {
    my $class = shift;
    my $len   = shift;
    my $sites = shift;

    my $mask = $class->empty_mask($len);
       $mask->set_state($_, 1) for @{$sites};

    return $mask;
}



sub mark_block {                            ## no critic (RequireArgUnpacking)
    return shift->_change_block(1, @_);
}



sub unmark_block {                          ## no critic (RequireArgUnpacking)
    return shift->_change_block(0, @_);
}


sub _change_block {
    my $self  = shift;
    my $state = shift;
    my $start = shift;
    my $end   = shift;

    $self->set_state($_, $state) for $start-1 .. $end-1;

    return $self;
}



sub mask2blocks {
    my $self = shift;

    my @blocks;
    my $start = -1;
    my $site  =  0;
    while ($site < $self->mask_len) {

        # open a new block (if not yet open)
        if ( $self->state_at($site) ) {
            $start = $site+1 if $start < 0;
        }

        # close the current block (if any open)
        else {
            if ($start >= 0) {
                push @blocks, [ $start, $site ];
                $start = -1;
            }
        }

        $site++;
    }

    # close last block (if still open)
    push @blocks, [ $start, $site ] if $start >= 0;

    return \@blocks;
}



sub blocks2mask {
    my $class  = shift;
    my $blocks = shift;

    # old code: only handled non-overlapping ordered blocks
    # my @mask;
    # for my $block ( @{$blocks} ) {
    #     my ($start, $end) = @{$block};
    #     push @mask, (0) x ($start-@mask-1);     # pad last block
    #     push @mask, (1) x ($end-$start+1);      # mark new block
    # }
    # return \@mask;

    # Note: blocks can now overlap and come in any order
    # this allows using SeqMask for computing seq coverages

    # setup empty mask going up to max end (second slot)
    my $max = max map { $_->[1] } @{$blocks};
    my $mask = $class->empty_mask($max);

    # mark all states included in each block
    $mask->mark_block( @{$_} ) for @{$blocks};

    return $mask;
}


# Ali-based SeqMask factory methods


sub neutral_mask {
    my $class = shift;
    my $ali   = shift;

    my $width = $ali->width;
    return $class->new( mask => [ (1) x $width ] );
}



sub variable_mask {
    my $class = shift;
    my $ali   = shift;

    # TODO: profile and optimize as ideal_mask below (if needed)

    my @mask;
    my $width = $ali->width;
    my $regex = $ali->gapmiss_regex;

    # filter out sites with only one state
    for (my $site = 0; $site < $width; $site++) {
        my $state_n = uniq                      # count unique states
            grep { $_ !~ m/$regex/xms  }        # which are valid
            map  { $_->state_at($site) }        # and found at that site
            $ali->all_seqs                      # across all seqs
        ;
        push @mask, $state_n > 1 ? 1 : 0;
    }

    return $class->new( mask => \@mask );
}



sub parsimony_mask {
    my $class = shift;
    my $ali   = shift;

    # TODO: profile and optimize as ideal_mask below (if needed)

    my @mask;
    my $width = $ali->width;
    my $regex = $ali->gapmiss_regex;

    # filter out sites with only one state
    for (my $site = 0; $site < $width; $site++) {
        my @states =                            # get states
            grep { $_ !~ m/$regex/xms  }        # which are valid
            map  { $_->state_at($site) }        # and found at that site
            $ali->all_seqs;                     # across all seqs
        ;
        #### @states

        # check whether at least two states are seen at least twice
        my %count_for;
        $count_for{$_}++ for @states;
        #### %count_for
        my $state_n = grep { $count_for{$_} >= 2 } keys %count_for;
        #### $state_n
        push @mask, $state_n >= 2 ? 1 : 0;
    }

    return $class->new( mask => \@mask );
}


sub ideal_mask {
    my $class   = shift;
    my $ali     = shift;
    my $max_res = shift // 0;           # defaults to shared gaps only

    # convert fractional max_res to conservative integer (if needed)
    $max_res = floor($max_res * $ali->count_seqs)
        if 0 < $max_res && $max_res < 1;

    # pick up right regex based on sequence type
    my $regex = $ali->gapmiss_regex;

    # determine count of non-gap-nor-missing states for each site

    # original version: easy to understand but much too slow on large matrices
    # because of unavoidable regex recompilation for each character state
    # (lots of calls to CORE::regcomp in output Devel::NYTProf)
    # my @counts;
    # for my $seq ($ali->all_seqs) {
    #     my $site = 0;
    #     $counts[$site++] += ($_ !~ $regex) for $seq->all_states;
    # }

    # 'all magic comes with a price' version: the /o regex modifier does speed
    # up things but compiles the regex once for all, which leads to bugs when
    # dealing with both nucleotide and protein alignments in the same run
    # my @counts;
    # for my $seq ($ali->all_seqs) {
    #     my $site = 0;
    #     $counts[$site++] += ($_ !~ m/$regex/o) for $seq->all_states;
    # }

    # improved version: more convoluted but much faster
    # idea: directly search in sequence strings
    # algorithm: set maximal count for each site
    #      then: decrease corrresponding count for each gap-or-missing state
    # my @counts = ( $ali->count_seqs ) x $ali->width;
    # for my $seq ($ali->all_seqs) {
    #     my $str = $seq->seq;
    #     while ($str =~ m/$regex/xmsg) {
    #         $counts[ pos($str) - 1 ]--;
    #     }
    # }

    # parallel version: quite complex and inefficient
    # setup threading
    # my $thread_n = 2;
    # my $pl = Parallel::Loops->new($thread_n);
    # my %counts;
    # $pl->share( \%counts );
    #
    # # define sites ranges
    # my $site_n = $ali->width;
    # my $chunk = ceil( $site_n / $thread_n );
    # my @ranges;
    # for (my $start = 0; $start < $site_n; $start += $chunk) {
    #     my $end = min( $start + $chunk, $site_n );
    #     push @ranges, [ $start..$end-1 ];
    # }
    #
    # # process ranges in parallel
    # my @seqs = $ali->all_seqs;
    # $pl->foreach( \@ranges, sub {
    #     for my $seq (@seqs) {
    #         $counts{$_} += $seq->state_at($_) !~ $regex for @{$_};
    #     }
    # } );
    #
    # # filter out sites with at most max_res non-gap-nor-missing states
    # my @mask = map { $counts{$_} > $max_res ? 1 : 0 }
    #     sort { $a <=> $b } keys %counts;      # watch the sorting cost!

    # current version: even more complex but even more faster
    # idea: search for (long) gaps instead of individual states
    # algorithm: set maximal count for each site
    #      then: decrease counts for each stretch of gap-or-missing states
    my @counts = ( $ali->count_seqs ) x $ali->width;
    for my $seq ($ali->all_seqs) {
        my $str = $seq->seq;
        while ($str =~ m/($regex+)/xmsg) {      # look for next gap
            my $end = pos($str) - 1;            # compute gap start
            my $begin = $end - length($1) + 1;  #     and gap end
            $counts[$_]-- for $begin..$end;     # decrease count over the gap
        }
    }

    # filter out sites with at most max_res non-gap-nor-missing states
    my @mask = map { $_ > $max_res ? 1 : 0 } @counts;

    return $class->new( mask => \@mask );
}


my %gb_parms_for = (
    strict => [ 0.85, 8, 10, 'N' ],     # emulate original MUST settings
    medium => [ 0.75, 5,  5, 'H' ],
    loose  => [ 0.55, 5,  5, 'H' ],
);

sub gblocks_mask {
    my $class = shift;
    my $ali   = shift;
    my $mode  = shift // 'strict';

    # check Gblocks settings
    if ( !defined $gb_parms_for{$mode} ) {
        carp "[BMC] Warning: invalid Gblocks settings: $mode; using strict!";
        $mode = 'strict';
    }

    # create temp .fasta infile for Gblocks
    my $infile = $ali->temp_fasta;

    # compute Gblocks parms depending on specified mode
    my ($t, $b1, $b2, $b3, $b4, $b5) = (
        ($ali->is_protein ? 'p' : 'd'),                    # Sequence Type
        int($ali->count_seqs / 2) + 1,                     # Conserved Position
        int($ali->count_seqs * $gb_parms_for{$mode}[0]),   # Flank Position
        @{ $gb_parms_for{$mode} }[1..3],                   # other block parms
    );
    $b2 = max($b1, $b2);    # with few seqs 0.55*n can be smaller than n/2+1

    # create Gblocks command
    my $cmd = "Gblocks $infile -t=$t"
        . " -b1=$b1 -b2=$b2 -b3=$b3 -b4=$b4 -b5=$b5"
        . ' -s=n > /dev/null 2> /dev/null'              # minimal output
    ;

    # try to robustly execute Gblocks
    my $ret_code = system( [ 1, 127 ], $cmd);   # Gblocks always returns 1?!?
    if ($ret_code == 127) {
        carp '[BMC] Warning: cannot execute Gblocks command;'
            . ' returning neutral mask!';
        return $class->neutral_mask($ali);
    }
    # TODO: try to bypass shell (need for absolute path to executable then)

    # parse Gblocks output to get blocks
    my $outfile = $infile . '-gb.htm';
    open my $out, '<', $outfile;

    my @blocks;
    while (my $line = <$out>) {

        # only use the 'Flanks:' line
        my ($flanks) = $line =~ m/\AFlanks:\s+(.*)/xms;
        if (defined $flanks) {

            # isolate numbers
            chomp $flanks;
            $flanks =~ s/[\[\]]//xmsg;
            my @bound_pairs = split /\s+/xms, $flanks;

            # take number pairs as block bounds
            my $it = natatime 2, @bound_pairs;
            while ( my @bounds = $it->() ) {
                push @blocks, \@bounds;
            }
        }

        # ...and the 'New number of positions' line
        # to check Gblocks didn't shrink the original Ali due to shared gaps
        # which would left-shift all blocks bounds!
        my ($width) = $line =~ m/original\s+(\d+)\s+positions/xms;
        if (defined $width && $width != $ali->width) {
            carp '[BMC] Warning: shared gaps detected; returning neutral mask!';
            return $class->neutral_mask($ali);
        }
    }

    # unlink temp files
    file( $infile)->remove;
    file($outfile)->remove;

    # compute SeqMask from Gblocks blocks
    return $class->blocks2mask( \@blocks );
}


# TODO: check interface for BMGE 2.x
my %bmge_parms_for = (
    strict => [ 0.4, 0.05 ],
    medium => [ 0.5, 0.20 ],
    loose  => [ 0.6, 0.40 ],
);

sub bmge_mask {
    my $class = shift;
    my $ali   = shift;
    my $mode  = shift // 'strict';

    # check BMGE settings
    if ( !defined $bmge_parms_for{$mode} ) {
        carp "[BMC] Warning: invalid BMGE settings: $mode; using strict!";
        $mode = 'strict';
    }

    # create temp .fasta infile for BMGE
    my $infile = $ali->temp_fasta;

    # compute BMGE parms depending on specified mode
    my ($entropy_cutoff, $gap_cutoff) = @{ $bmge_parms_for{$mode} };
    my $coding_type = $ali->is_protein ? 'AA' : 'DNA';
    my $outfile = $infile . '-bmge.htm';

    # create BMGE command
    my $cmd = "bmge.sh $infile"
        . " $coding_type $entropy_cutoff $gap_cutoff $outfile > /dev/null";

    # try to robustly execute BMGE
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp '[BMC] Warning: cannot execute BMGE command;'
            . ' returning neutral mask!';
        return $class->neutral_mask($ali);
    }
    # TODO: try to bypass shell (need for absolute path to executable then)

    # parse BMGE output to get selected sites
    open my $out, '<', $outfile;
    my $len = $ali->width;
    my $sites;

    LINE:
    while (my $line = <$out>) {
        if ($line =~ m/\s+ selected: \s+ ([\ (0-9)]+)/xms) {
            $sites = [ map { $_ - 1 } split /\s+/xms, $1 ];
            last LINE;
        }
    }

    # unlink temp files
    file($infile)->remove;
    file($outfile)->remove;

    return $class->custom_mask($len, $sites);
}


# mask manipulation methods
# TODO: improve interface? $mask1 should be $self for and_mask and or_mask


sub and_mask {
    my $class = shift;
    my $mask1 = shift;
    my $mask2 = shift;

    my @mask;
    @mask = pairmap { ($a && $b) // 0 } mesh ( @{$mask1}, @{$mask2} );

    return $class->new( mask => \@mask );
}


sub or_mask {
    my $class = shift;
    my $mask1 = shift;
    my $mask2 = shift;

    my @mask;
    @mask = pairmap { ($a || $b) // 0 } mesh ( @{$mask1}, @{$mask2} );

    return $class->new( mask => \@mask );
}


sub negative_mask {
    my $self = shift;
    my $ali  = shift;

    # negate all states over the whole Ali width
    # Note the '+ 0' to ensure proper numeric context (0 or 1)
    my $width = $ali->width;
    my @mask = map { ( not $self->state_at($_) ) + 0 } 0..$width-1;

    return $self->new( mask => \@mask );
}


sub codon_mask {                        ## no critic (RequireArgUnpacking)
    my $self = shift;                   # the critic stems from @_ below
    my $args = shift // {};             # HashRef (should not be empty...)

    my $frame = $args->{frame} // 1;    # defaults to frame +1
    my $chunk = $args->{chunk} // 3;    # defaults to codon
    my $max   = $args->{max}   // 1;

    my @states = $self->all_states;
    my $offset = (abs $frame) - 1;
    my @mask = ( (0) x $offset,         # first skip frame-1 sites
        map { ( ($_ > $max) + 0 ) x $chunk } bundle_by { sum @_ } $chunk,
        @states[$offset..$#states]      # then filter sites by chunks
    );

    return $self->new( mask => [ @mask[0..$#states] ] );
}                                       # truncate mask to original length


# SeqMask-based Ali factory methods


before 'filtered_ali' => sub {
    ## no critic (ProtectPrivateSubs)
    return Bio::MUST::Core::Ali::_premask_check( @_[1,0,2] );   # swap args
    ## use critic
};

sub filtered_ali {
    my $self = shift;
    my $ali  = shift;
    my $list = shift;           # optional: enable masking vs. filtering

    # setup filtering or masking
    my $char = $list ? 'X' : q{};

    # create new Ali object (extending header comment)
    # TODO: allow custom comments
    my $new_ali = Ali->new(
        comments => [ $ali->all_comments,
            'built by ' . ($list ? 'masked_ali' : 'filtered_ali')
        ],
    );

    SEQ:
    for my $seq ($ali->all_seqs) {

        # for non-listed Seqs clone Seq to new Ali
        # Note: when filtering all Seqs will be affected
        if ( $list and not $list->is_listed($seq->full_id) ) {
            $new_ali->add_seq($seq->clone);
            next SEQ;
        }

        # for listed Seqs copy marked sites from original Seq...
        # ... and either filter or mask others (set them to missing state)
        my $new_seq;
        my $site = 0;
        for my $state ($self->all_states) {
            $new_seq .= $state ? $seq->state_at($site) x $state : $char;
            $site++;             # x $state is for Weights objects
        }

        # add Seq to new Ali
        $new_ali->add_seq(
            Seq->new( seq_id => $seq->full_id, seq => $new_seq )
        );
    }

    return $new_ali;
}


# I/O methods


sub load {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $mask = $class->new();

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and process comment lines
        next LINE if $line =~ $EMPTY_LINE
                || $mask->is_comment($line);

        $mask->add_state($line);
    }

    return $mask;
}



sub store {
    my $self = shift;
    my $outfile = shift;

    open my $out, '>', $outfile;

    print {$out} $self->header;
    say {$out} join "\n", $self->all_states;

    close $out;

    return;
}



# sub load_bor {
#   #~ my $self = shift;
#   my $class = shift;
#   my $bor = shift;
#   my $ali = shift;
#
#   #~ my $class = 'Bio::MUST::Core::SeqMask';
#
#   #~ open my $in, '<', $infile;
#   my $bor_file = $bor->stringify;
#   #~ tie my @rows, 'Tie::File', $bor_file;
#   #~ tie my @rows, 'Tie::File', $in;
#   #~ my $delims = $rows[-1];
#   #~ ### $delims
#   my $delims;
#   open my $bof, '<', $bor_file;
#   while ( my $i = <$bof> ) { $delims = $i; }
#   my @blocks = pairmap { [ $a , $b ] } ( split ' ', $delims );
#   #~ ### @blocks
#   my $mask = $class->blocks2mask(\@blocks)->mask;
#   #~ ### $mask
#   my $seq_mask = $class->new( mask => $mask);
#   my $negative = $seq_mask->negative_mask($ali);
#   return $negative;
# }






sub store_una {
    my $self    = shift;
    my $outfile = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    # TODO: check arguments as there are no default values?
    my $ali = $args->{ali};
    my $id  = $args->{id};

    # search for non-gap positions in reference seq
    my $seq = $ali->get_seq_with_id($id);
    my @pos_bases = grep { !( $seq->is_gap($_) ) } 0..($seq->seq_len-1);

    # delete gap positions in mask
    my @mask_degap = @{ $self->mask }[ @pos_bases ];

    # build mask and compute blocks
    my $new_mask = $self->new( mask => \@mask_degap );
    my $new_blocks = $new_mask->mask2blocks;

    open my $out, '>', $outfile;

    my $filename = $ali->file;
    my ($basename, $dir, $ext) = fileparse($filename, qr{\.[^.]*}xms);

    say {$out} "Unambigous numbering for $basename$ext based on $id";
    for my $new_block ( @{$new_blocks} ) {
        say {$out} join '-', @{$new_block};
    }

    close $out;

    return;
}


sub load_blocks {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $mask = $class->new();
    my @blocks;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and process comment lines
        next LINE if $line =~ $EMPTY_LINE
                || $mask->is_comment($line);

        # process block specifications (one or more by line)
        push @blocks, pairmap { [ $a , $b ] } split /\s+/xms, $line;
    }

    # build mask from blocks and replace empty mask
    # this is needed to preserve potential comments
    $mask->_set_mask( $class->blocks2mask( \@blocks )->mask );

    return $mask;
}


sub store_blocks {
    my $self    = shift;
    my $outfile = shift;

    open my $out, '>', $outfile;

    say {$out} "# Coordinates of blocks \n#";

    # compute blocks from mask
    my $blocks = $self->mask2blocks;

    for my $block ( @{$blocks} ) {
        say {$out} join "\t", @{$block};
    }

    close $out;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::SeqMask - Sequence mask for selecting specific sites

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 first_site

=head2 last_site

=head2 count_sites

=head2 coverage

=head2 empty_mask

=head2 custom_mask

=head2 mark_block

=head2 unmark_block

=head2 mask2blocks

=head2 blocks2mask

=head2 neutral_mask

=head2 variable_mask

=head2 parsimony_mask

=head2 ideal_mask

=head2 gblocks_mask

=head2 bmge_mask

=head2 and_mask

=head2 or_mask

=head2 negative_mask

=head2 codon_mask

=head2 filtered_ali

=head2 load

=head2 store

=head2 load_bor

=head2 store_bor

=head2 load_una

=head2 store_una

=head2 load_blocks

=head2 store_blocks

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Catherine COLSON Raphael LEONARD

=over 4

=item *

Catherine COLSON <ccolson@doct.uliege.be>

=item *

Raphael LEONARD <rleonard@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
