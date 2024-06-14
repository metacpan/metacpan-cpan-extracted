
package Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearLinearGeneric;
$Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearLinearGeneric::VERSION = '0.02';
use strict;
use warnings;

use Moose::Role;
use Carp;
use MCE;
use MCE::Candy;
use namespace::autoclean;

requires 'seq_align';          ## the method that does (pseudo)alignment
requires 'extract_sim_metric'; ## extract the similarity metric from the search
requires 'reduce_sim_metric';  ## reduce the similarity metric to a single value
requires 'cleanup';

sub sim_seq_search {

    my ( $self, $workload, %args ) = @_;

    croak 'expect an array(ref) as workload' unless ref $workload eq 'ARRAY';

    my $max_workers = $args{max_workers}
      // 1;    # set default value if not defined
    my $chunk_size = $args{chunk_size} // 1;  # set default value if not defined
    my $cleanup    = $args{cleanup}    // 1;  # set default value if not defined
    my @results;

    if ( $max_workers == 1 ) {
        foreach my $chunk ( @{$workload} ) {
            my $seq_align      = $self->seq_align->($chunk);
            my $sim_metric     = $self->extract_sim_metric->($seq_align);
            my $reduced_metric = $self->reduce_sim_metric->($sim_metric);
            push @results, $reduced_metric->@*; ## append to the results
            $self->cleanup->( $seq_align, $sim_metric, $reduced_metric )
              if $cleanup;
        }
        return \@results;
    }
    else {
        my $mce = MCE->new(
            max_workers => $max_workers,
            chunk_size  => $chunk_size,
            gather      => MCE::Candy::out_iter_array( \@results ),
            user_func   => sub {
                my ( $mce, $chunk_ref, $chunk_id ) = @_;
                my @chunk_results;
                foreach my $chunk ( @{$chunk_ref} ) {
                    my $seq_align  = $self->seq_align->($chunk);
                    my $sim_metric = $self->extract_sim_metric->($seq_align);
                    my $reduced_metric =
                      $self->reduce_sim_metric->($sim_metric);
                    push @chunk_results, $reduced_metric->@*;
                    $self->cleanup->( $seq_align, $sim_metric, $reduced_metric )
                      if $cleanup;
                }
                $mce->gather( $chunk_id, @chunk_results );
            }
        );
        $mce->process($workload);
        $mce->shutdown();
    }
    return \@results;
}

1;

=head1 NAME

Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearLinearGeneric - A role to implement a linear-linear dataflow for sequence mapping

=head1 VERSION

version 0.02

=head1 DESCRIPTION

This role provides a linear-linear dataflow for sequence mapping. By that we
mean that the input, i.e. a reference to a (list) of any object that can hold 
biological sequences such as BioX::Seq objects, FASTA files, etc) undergoes a
multi step process for mapping. The first step is to carry out a similarity 
search against a database of reference sequences, using (pseudo)alignment and
extract a similarity metric. The second step is to reduce the similarity metric
to a single value, that identifies the reference sequence each user provided 
sequence is most similar to. The output is a list containing the sequence ID,  
the reference sequence that was mapped to and the similarity metric used to 
decide which reference sequence to map to. The "linear-linear" part of the
dataflow refers to the fact that each atomic unit of work is processed 
independently of all others for both the alignment and the reduction steps,
and that Perl is given access to the intermediate results of the similarity
search, before directing them to the reduction step. Due to the lack of any
dependencies between the atomic units of work, the dataflow can be parallelized
if the user desires so, using the MCE module. Parallelization is optional and
the user can choose to run the dataflow in a single thread if desired. This
feature is useful when the user wants to run the dataflow consuming the 
resources of a single core, and leaving the rest of the cores free for e.g. 
multithreaded  logic that implements the similarity search and the similarity  
metric reduction steps.
The module is intended to be B<applied> as a role to the class 
Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic
The latter is pluggable Moose mapper that provides the necessary logic to 
implement the methods required by this role module.

The method requires the implementation of the following methods by the class 
composing the role:

* seq_align : aligns an atomic unit of work provided as the single argument 
    and returns the similarity metric. It is passed only one argument:  
        1.  The atomic unit of work
    The method may return any object that can hold the similarity metric for
    each sequence in the atomic unit of work. This could be for example a file,
    a hashref, an arrayref, etc. A specialized extraction method will then be
    used to extract the similarity metric from the output of this method.
* extract_sim_metric : extracts the similarity metric for each B<sequence> in the
    atomic unit of work from the search results. It is passed only one argument:
        1.  The output of the seq_align method
    The method should return a hashref where the keys are the sequence IDs and 
    the values are references to arrays that contain the similarity metric for 
    each sequence in an atomic unit of work. 
* reduce_sim_metric : reduces the similarity metric for each sequence to a 
    single value. It receives one argument:
        1.  A hashref containing the similarity metric for each sequence in the
            atomic unit of work. The keys are the sequence IDs and the values
            are references to arrays that contain the similarity metric for each
            sequence against each reference sequence in the database used for
            searching. All the values of the hash are  hashrefs themselves. 
    This function returns a reference to an array containing the sequence ID, 
    the reference sequence that was mapped to and the similarity metric used to
    decide which reference sequence to map to.
* cleanup : does any cleanup necessary after the mapping has been done if the
    user desires so. The function will be provided with three arguments:
        1. the output of the seq_align method
        2. the output of the extract_sim_metric method
        3. the output of the reduce_sim_metric method

Note that these functions are provided as code references to the constructor of
the class that composes the role. The role does not provide any default 
implementation for these methods, as they are highly dependent on the
implementation of the similarity search and the similarity metric reduction
steps. The user is free to implement these methods in any way they see fit,
e.g. using BioPerl, BioX, BioPython, command line and use Perl to wrap them
into functions that are provided as arguments to:
Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic


=head1 METHODS

=head2 sim_seq_search

This is the single L<public> method provided by the role. It takes the following
arguments:
* $workload : an array reference containing the atomic units of work to be
    processed. The atomic units of work can be any object that can hold a 
    biological sequence, and the format depends entirely on the class composing
    the role. This gives immense flexibility to the user to define the space
    the dataflow operates in, e.g. in-memory, on-disk, etc.
* %args : a hash containing the following optional arguments, that control 
    parallelization and cleanup after the mapping has been done. The keys are:
    * max_workers : the number of workers to use for parallelization. Default
        value is 1, i.e. no parallelization.
    * chunk_size : the number of atomic units of work to be processed by each
        worker. Default value is 1.
    * cleanup : a boolean value that indicates whether to do cleanup after the
        mapping has been done. Default value is 1, i.e. cleanup after the mess.

    $mapper->sim_seq_search(
        $workload,
        max_workers => 4,
        chunk_size  => 10,
        cleanup     => 1
    );

=head1 SEE ALSO

=over 4

=item * L<Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic|https://metacpan.org/pod/Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic>

Documentation of the Generic Mapper class that uses this role.

=item * L<Bio::SeqAlignment::Examples::EnhancingEdlib|https://metacpan.org/pod/Bio::SeqAlignment::Examples::EnhancingEdlib>

Example of how to use the Generic Mapper with the LinearLinearGeneric and the 
LinearGeneric Dataflow roles, along with the Edlib alignment library.

=back

=head1 AUTHOR

Christos Argyropoulos, C<< <chrisarg at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
