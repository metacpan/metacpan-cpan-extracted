package Bio::MUST::Apps::Leel::RunProcessor;
# ABSTRACT: Internal class for leel tool
$Bio::MUST::Apps::Leel::RunProcessor::VERSION = '0.210570';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments;                    # logging always enabled here

use Path::Class qw(dir);

use Parallel::Batch;

use aliased 'Bio::MUST::Apps::Leel::AliProcessor';

with 'Bio::MUST::Apps::Roles::RunProcable';


has '+out_suffix' => (
    default  => '-1331',
);


# blast_args


# trim_homologues

# trim_max_shift

# trim_extra_margin


has 'aligner_mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'exonerate',
);


has 'id_match_mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'enforce',
);


has 'round_trip_mode' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'off',
);


# bank_dir

# orgs

# infiles

# out_dir

# debug_mode

# threads?


sub BUILD {
    my $self = shift;

    # TODO: avoid duplicate code wrt Forty-Two::RunProcessor

    # build optional output dir
    if ($self->out_dir) {
        my $dir = dir($self->out_dir)->relative;
        $dir->mkpath();
    }

    if ($self->threads > 1) {
        ### [RUN] Multithreading is on: $self->threads
        ### [RUN] Logging data will be mixed-up!
    }

    # create job queue
    my $batch = Parallel::Batch->new( {
        maxprocs => $self->threads,
        jobs     => [ $self->all_infiles ],
        code     => sub {                       # closure (providing $self)
                        my $infile = shift;
                        ### [RUN] Processing ALI: $infile
                        return AliProcessor->new(
                            run_proc => $self,
                            ali      => $infile,
                        );
                    },
    } );

    # launch jobs
    $batch->run();

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Leel::RunProcessor - Internal class for leel tool

=head1 VERSION

version 0.210570

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
