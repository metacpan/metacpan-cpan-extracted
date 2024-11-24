package Bio::MUST::Apps::HmmCleaner;
# ABSTRACT: Main class for HmmCleaner
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>
$Bio::MUST::Apps::HmmCleaner::VERSION = '0.243280';
use Moose;
use namespace::autoclean;

use Smart::Comments -ENV;
use List::AllUtils qw/uniq max/;
use Modern::Perl;

use Carp;
use Path::Class;

use Bio::MUST::Core 0.180230;
use Bio::MUST::Core::Constants qw(:gaps :files);
use Bio::MUST::Drivers 0.180270;
use Bio::MUST::Drivers::Hmmer::Model::Temporary;

use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdList';

use aliased 'Bio::MUST::Apps::HmmCleaner::Process';
use aliased 'Bio::MUST::Apps::HmmCleaner::Cleaner';

# ATTRIBUTES

has 'ali' => (
    is            => 'ro',
    isa            => 'Bio::MUST::Core::Ali',
    required    => 1,
    coerce        => 1,
);

has 'ali_model' => (
    is          => 'ro',
    isa         => 'Bio::MUST::Core::Ali',
    required    => 1,
    coerce      => 1,
);

has 'threshold' => (
    is          => 'ro',
    isa         => 'Int',
    required    => 1,
    writer      => '_set_threshold',
    default     => 1,
);

has 'changeID' => (
    is          => 'ro',
    isa            => 'Bool',
    default        => 0,
);

has 'consider_X' => (
    is            => 'ro',
    isa            => 'Bool',
    default        => 1,
);

has 'symfrac' => (
    is          => 'ro',
    isa         => 'Num',
    default     => 0.5,
);

has 'delchar' => (
    is            => 'ro',
    isa            => 'Str',
    default        => ' ',
);

has 'costs' => (
    traits        => ['Array'],
    is            => 'ro',
    isa            => 'ArrayRef[Num]',
    lazy        => 1,
    builder        => '_build_cost',
    handles        => {
        _get_cost => 'get',
    }

);

has '_cleaners' => (
    traits      => ['Array'],
    is            => 'ro',
    isa            => 'ArrayRef[Bio::MUST::Apps::HmmCleaner::Cleaner]',
    lazy        => 1,
    builder        => '_build_cleaners',
    handles  => {
        all_cleaners => 'elements',
    },
);

has 'outfile' => (
    is            => 'ro',
    isa            => 'Str',
    lazy        => 1,
    builder        => '_build_outfile',
    writer      => '_set_outfile',
);

has 'outfile_type' => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 0,
);

has 'perseq_profile' => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 1,
);

has 'debug_mode' => (
    is          => 'ro',
    isa         => 'Bool',
    default     => 0,
);


# BUILD

# launch on new but before the object construction
sub BUILD {
    ##### [HMMCLEANER] BUILD...
    my $self = shift;

    my $costs = $self->costs;
    carp "Your costs must be increasing" if ( ($$costs[0] > $$costs[1]) || ($$costs[1] > 0) || ($$costs[2] < 0) || ($$costs[2] > $$costs[3]) );

    carp 'Your MSA file is not aligned' unless ($self->ali->is_aligned);

    $self->_cleaners;

    ##### End of BUILD...
    return;
}


# BUILDER

## no critic (ProhibitUnusedPrivateSubroutines)

# delayed costs creation
sub _build_cost {
    return shift->_get_default_cost;
}

sub _build_outfile {
    my $self = shift;

    my $infile = $self->ali->filename;

    (my $outfile = $infile) =~ s/\.[^\.]+$//x;
    $outfile .= '_hmm';

    return $outfile;
}

# produce the cleaned sequences
sub _build_cleaners {
    #### [HMMCLEANER] building cleaners...

    my $self = shift;

    my $ali = $self->ali;
    my $ali_model = $self->ali_model;
    my $lookup = $ali->new_lookup;

    # Cleaners container
    my @cleaners;

    # arguments for Hmmer driver
    my $model_args = {
        '--plaplace'    => undef,
        '--fragthresh'  => "0.0",
        '--symfrac'     => $self->symfrac,
        #~ '--wnone'     => undef,
    };

    # arguments for Temporary fasta files
    my $alitemp_args = {
            degap       => 0,
            persistent  => ($self->debug_mode) ? 1 : 0,
            gapify      => ($self->consider_X) ? 'X' : '*', # if consider_X changing MISS Char to X ...
            clean       => 1,
    };

    # Creation of global profile
    my $hmmer;
    unless ($self->perseq_profile) {
        ### Global profile ...
        $hmmer = Bio::MUST::Drivers::Hmmer::Model::Temporary->new(
            seqs        => [$ali_model->all_seqs],
            model_args  => $model_args,
            args        => $alitemp_args,
        );
    }

    SEQ:
    for my $seq ($ali->all_seqs) {
        ##### [HMMCLEANER] actual sequence : $seq->foreign_id

        # Creation of perseq profile
        if ($self->perseq_profile) {
            ### Perseq profile ...
            my $lookup = $self->ali_model->new_lookup;  ## no critic (ProhibitReusedNames)
            my @new = map { $_->full_id } grep { $_->full_id ne $seq->full_id } $self->ali_model->all_seqs;
            my $list = IdList->new( ids => \@new);

            # ali without current seq
            my $shorted_ali = $list->reordered_ali($self->ali_model, $lookup);

            $hmmer = Bio::MUST::Drivers::Hmmer::Model::Temporary->new(
                seqs        => [ $shorted_ali->all_seqs ],
                model_args  => $model_args,
                args        => $alitemp_args,
            );
        }

        ##### [HMMCLEANER] HMM driver : $hmmer->model->filename

        # Creation of process
        my $process = Process->new(
            'ali'           => $self->ali,
            'seq'           => $seq,
            'model'         => $hmmer,
            'consider_X'    => $self->consider_X,
            'debug_mode'    => $self->debug_mode,
        );

        my $score = $process->score;
        undef $process;

        my $cleaner = Cleaner->new(
            'seq'           => $seq,
            'score'         => $score,
            'consider_X'    => $self->consider_X,
            'costs'         => $self->costs,
            'threshold'     => $self->threshold,
            'delchar'       => $self->delchar,
            'is_protein'    => $self->ali->is_protein,
        );

        push @cleaners, $cleaner;

        $hmmer->model->remove if ($self->perseq_profile && !$self->debug_mode); # if debug
    }

    ##### [HMMCLEANER] end of building cleaners...

    $hmmer->model->remove unless ($self->debug_mode); # if debug

    return \@cleaners;
}

## use critic

# PRIVATE SUB

sub _get_default_cost {
    ###### [HMMCLEANER] building cost...
    my $self = shift;

    # need condition to enable non defaults values
    # if set, builder is not activated so ok
    my $costs = [ -0.15, -0.08, 0.15, 0.45 ];

    ###### [HMMCLEANER] end of build cost...
    return $costs;
}

# METHOD

sub get_results {
    my $self = shift;

    my $results;
    for my $cleaner ($self->all_cleaners) {
        push @$results, $cleaner->get_result;
    }

    return $results
}

sub get_result_ali {
    my $self = shift;

    unless ($self->changeID) {
        return Ali->new( seqs => $self->get_results );
    } else {
        my $seqs = $self->get_results;
        for my $seq (@$seqs) {
            $seq->_set_full_id($seq->full_id.'_hmmcleaned');
        };

        return Ali->new( seqs => $seqs );
    }
}

sub store_results {
    my $self = shift;

    my $ali  = $self->get_result_ali;
    if ($self->outfile_type) {
        $ali->store($self->outfile.'.ali');
    } else {
        $ali->store_fasta($self->outfile.'.fasta');
    }

    return;
}

# output file with alignment of degap seq, score and result
sub store_score {
    my $self = shift;

    my $outscore = file($self->outfile.'.score');
    my $score_fh = $outscore->openw;

    for my $cleaner ($self->all_cleaners) {
        # Writing into score file
        say {$score_fh} $cleaner->seq->full_id."\t".$cleaner->nogap_seq->seq;
        say {$score_fh} (" " x length($cleaner->seq->full_id) )."\t".$cleaner->score;
        say {$score_fh} (" " x length($cleaner->seq->full_id) )."\t".$cleaner->get_nogap_result->seq."\n";
    }

    return;
}

# Writing log at the same time, listings of cleaned blocks foreach seq
sub store_log {
    my $self = shift;

    my $outlog = file($self->outfile.'.log');
    my $log_fh = $outlog->openw;

    for my $cleaner ($self->all_cleaners) {
        my $seq = $cleaner->seq;
        # erased will be the number of removed positions
        my $erased = 0;

        my $shifts_withgaps = $cleaner->shifts;
        say {$log_fh} $seq->full_id;
        for(my $i = 0; $i < $#$shifts_withgaps; $i+=2){
            $erased += $$shifts_withgaps[$i+1] - $$shifts_withgaps[$i];
            say {$log_fh} "\t".( 1+$$shifts_withgaps[$i] )."-".( $$shifts_withgaps[$i+1] );
        }

        ##### Number of removed positions : $erased

        say $self->ali->file."\t".$seq->full_id."\t".$erased;
    }

    return;
}

# get log for simulation from non gap seq
sub get_log_simu {
    my $self = shift;

    my %log;
    for my $cleaner ($self->all_cleaners) {
        my $seq = $cleaner->seq;

        my $shifts = $cleaner->nogap_shifts;
        for(my $i = 0; $i < $#$shifts; $i+=2){

            push @{$log{$self->ali->file}->{$seq->full_id}}, [(1+$$shifts[$i] ), ( $$shifts[$i+1] )];
        }

    }

    return \%log;
}

# get log for simulation from gap seq
sub get_log_simualign {
    my $self = shift;

    my %log;
    for my $cleaner ($self->all_cleaners) {
        my $seq = $cleaner->seq;

        my $shifts_withgaps = $cleaner->shifts;
        for(my $i = 0; $i < $#$shifts_withgaps; $i+=2){

            push @{$log{$self->ali->file}->{$seq->full_id}}, [(1+$$shifts_withgaps[$i] ), ( $$shifts_withgaps[$i+1] )];
        }

    }

    return \%log;
}

sub get_matrix_seqmask {
    my $self = shift;

    my %matrix;
    for my $cleaner ($self->all_cleaners) {
        my $seqid = $cleaner->seq->full_id;
        $matrix{$seqid} = $cleaner->get_seqmask;
    }

    return \%matrix;
}

sub update_cleaners {
    my $self = shift;
    my $threshold = shift;
    $self->_set_threshold($threshold);
    my $costs = shift // $self->_get_default_cost;

    for my $cleaner ($self->all_cleaners) {
        $cleaner->update($threshold,$costs);
    }

    return;
}

sub store_all {
    my $self = shift;

    $self->store_results;
    $self->store_score;
    $self->store_log;

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::HmmCleaner - Main class for HmmCleaner

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
