use strict;
use warnings;

package Bio::SeqAlignment::Components::Libraries::edlib::OpenMP;
$Bio::SeqAlignment::Components::Libraries::edlib::OpenMP::VERSION = '0.03';
# ABSTRACT: basic edlib library that uses OpenMP for parallelism
use Config;
use Alien::SeqAlignment::edlib;
use Carp;
use Inline (
    C         => 'DATA',
    CC        => 'g++',
    LD        => 'g++',
    INC       => Alien::SeqAlignment::edlib->cflags,
    ccflagsex => q{-fopenmp},
    lddlflags => join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} ),
    libs      =>
      join( q{ }, $Config::Config{libs}, Alien::SeqAlignment::edlib->libs ),
    myextlib => ''
);
use Exporter qw(import);
## EdlibAlignMode enum
use constant EDLIB_MODE_NW  => 0;
use constant EDLIB_MODE_SHW => 1;
use constant EDLIB_MODE_HW  => 2;

## EdlibAlignTask enum
use constant EDLIB_TASK_DISTANCE => 0;
use constant EDLIB_TASK_LOC      => 1;
use constant EDLIB_TASK_PATH     => 2;

## EdlibCigarFormat
use constant EDLIB_CIGAR_STANDARD => 0;
use constant EDLIB_CIGAR_EXTENDED => 1;

## status codes
use constant EDLIB_STATUS_OK    => 0;
use constant EDLIB_STATUS_ERROR => 1;

## edit operations
use constant EDLIB_EDOP_MATCH    => 0;
use constant EDLIB_EDOP_INSERT   => 1;
use constant EDLIB_EDOP_DELETE   => 2;
use constant EDLIB_EDOP_MISMATCH => 3;

# Export the status of the alignment tasks

our @EXPORT = ();

## export the functions and structures
our @EXPORT_OK = qw(
  EDLIB_MODE_NW
  EDLIB_MODE_SHW
  EDLIB_MODE_HW
  EDLIB_TASK_DISTANCE
  EDLIB_TASK_LOC
  EDLIB_TASK_PATH
  EDLIB_STATUS_OK
  EDLIB_STATUS_ERROR
  configure_edlib_aligner
  edlibAlign
  make_C_index
  print_config
  fork_around_find_out
);

our %EXPORT_TAGS = (
    all       => \@EXPORT_OK,
    functions => [
        qw(
          configure_edlib_aligner
          edlibAlign
          make_C_index
          fork_around_find_out
        )
    ]
);
## edit operations
use constant EDLIB_EDOP_MATCH    => 0;
use constant EDLIB_EDOP_INSERT   => 1;
use constant EDLIB_EDOP_DELETE   => 2;
use constant EDLIB_EDOP_MISMATCH => 3;

my %align_modes = (
    'NW'  => EDLIB_MODE_NW,
    'SHW' => EDLIB_MODE_SHW,
    'HW'  => EDLIB_MODE_HW
);

my %align_tasks = (
    'DISTANCE' => EDLIB_TASK_DISTANCE,
    'LOC'      => EDLIB_TASK_LOC,
    'PATH'     => EDLIB_TASK_PATH
);

sub fork_around_find_out {
     _fork_around_find_out();
}
sub make_C_index {
    my ($sequences) = @_;
    return _make_C_index($sequences);
}

sub print_config {
    my ($config) = @_;
    return _print_config($config);
}

sub edlibAlign {
    my ( $query_seq, $query_len, $ref_DB, $config ) = @_;
    return _edlib_align( $query_seq, $query_len, $ref_DB, $config );
}

sub configure_edlib_aligner {
    my (%config) = @_;
    my %align_config;

    $config{mode} = $config{mode} // 'NW';
    $config{task} = $config{task} // 'DISTANCE';
    ## do a check that the modes and tasks are valid by looking at the keys

    croak "Invalid alignment mode: $config{mode}"
      unless defined $align_modes{ $config{mode} };
    croak "Invalid alignment task: $config{task}"
      unless defined $align_tasks{ $config{task} };

    $align_config{filter}               = $config{filter} // -1;
    $align_config{mode}                 = $align_modes{ $config{mode} };
    $align_config{task}                 = $align_tasks{ $config{task} };
    $align_config{additionalEqualities} = $config{additionalEqualities} // [];
    $align_config{additionalEqualitiesLength} =
      $config{additionalEqualitiesLength} // 0;
    return {
        edlib_config => _configure_edlib_aligner(
            $align_config{filter}, $align_config{mode},
            $align_config{task},   $align_config{additionalEqualities}
        ),
        align_config => {
            filter                     => $align_config{filter},
            mode                       => $config{mode},
            task                       => $config{task},
            additionalEqualities       => $align_config{additionalEqualities},
            additionalEqualitiesLength =>
              $align_config{additionalEqualitiesLength}
        }
    };
}

1;

=head1 NAME

Bio::SeqAlignment::Components::Libraries::edlib::OpenMP - basic edlib library that uses OpenMP for parallelism

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Bio::SeqAlignment::Components::Libraries::edlib::OpenMP;
  my $ffi = Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->new_edlib_aligner();
  my $configuration = Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->configure_edlib_aligner( $ffi, %config );
  my $align = Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->edlibAlign( $query_seq, $query_len, $ref_seq, $ref_seq_len, $configuration->{edlib_config} );
  Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->edlibFreeAlignResult( $align );

=head1 DESCRIPTION

This module provides a basic interface to the edlib library that uses OpenMP
for parallelism.
In its current form, it is a thin wrapper around the edlib library, that only
finds the best alignment (smaller edit distance) of a query against a collection
of reference sequences. This particular module is meant to be used as a component 
in a larger sequence alignment tool, e.g. one that combines a Linear dataflow  
and a generic sequence mapper. 
Future versions will include the alignment path and the alignment locations in 
order to handle multiple/overlapping hits. 

=head1 METHODS

=head2 configure_edlib_aligner

  my $configuration = Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->configure_edlib_aligner( $ffi, %config );

This method configures the edlib aligner with the given configuration. The configuration
is a hash with the following keys: mode, task, filter, additionalEqualities, and
additionalEqualitiesLength. The configuration is returned as a hash reference with two keys:
edlib_config and align_config. The edlib_config key contains the configuration for the edlib
aligner, while the align_config key contains the configuration for the alignment.

=head2 edlibAlign

  my $align = Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->edlibAlign( $query_seq, $query_len, $ref_seq, $ref_seq_len, $configuration->{edlib_config} );

This method aligns the query sequence against the reference sequences using the given configuration.

=head2 make_C_index

  my $C_index = Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->make_C_index( $sequences );

This method creates a C index from the given sequences.

=head2 print_config

  Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->print_config( $configuration->{edlib_config} );

This method prints the configuration to the standard output (only meant for debugging)

=head2 fork_around_find_out

  Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->fork_around_find_out();

This method pauses all OpenMP resources and allows the user to generate multiple
threads for parallel processing, from forked Perl processes


=head1 SEE ALSO

=over 4

=item * L<Alien::SeqAlignment::edlib>

=item * L<Bio::SeqAlignment::Components::Libraries::edlib|https://metacpan.org/pod/Bio::SeqAlignment::Components::Libraries::edlib>;
An alternative implementation of the edlib library that does not use OpenMP

=back

=head1 TODO

=over 4

=item * Add support for obtaining/parsing the alignment path

=item * Add support for obtaining/parsing the alignment locations

=item * Add support for mapping multiple and/or overlapping hits

=back

=head1 AUTHOR

Christos Argyropoulos <chrisarg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christos Argyropoulos.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut


__DATA__
__C__
#include <omp.h>
#include "edlib.h"


// macro for the creation of a new SV buffer of a given size w/o resizing
#define NEW_SV_BUFFER(sv, buf , buffer_size) \
    SV *sv = newSV(0);                       \
    char *buf;                               \
    Newxz(buf,buffer_size,char);             \
    sv_usepvn_flags(sv, buf, buffer_size,SV_HAS_TRAILING_NUL|SV_SMAGIC)


// Define a struct to hold sequence data
typedef struct {
    uintptr_t seq_address;
    int seq_len;
} Seq;


AV* edlib_align(char* query_seq, int query_len,SV* ref_DB, SV* config);
SV*  _make_C_index(AV* sequences);
void _ENV_set_num_threads();
void _fork_around_find_out();

void _fork_around_find_out(){
    omp_pause_resource_all(omp_pause_hard);
}

SV* _make_C_index(AV* sequences) {
    int i;
    int n = av_len(sequences) + 1;
    _ENV_set_num_threads();
    size_t buffer_size = n * sizeof(Seq);      // how much space do we need?
    NEW_SV_BUFFER(retval, buf, buffer_size);
    Seq* RefDB = (Seq *)buf;
    #pragma omp parallel
    {
       
        int nthreads = omp_get_num_threads();
        size_t thread_id = omp_get_thread_num();
        size_t tbegin = thread_id * n / nthreads;
        size_t tend = (thread_id + 1) * n / nthreads;
        for (size_t i = tbegin; i < tend; i++) {
            SV** elem = av_fetch_simple(sequences, i, 0); // perl 5.36 and above
            STRLEN len = SvCUR(*elem);
            RefDB[i].seq_address = (uintptr_t)SvPVbyte_nolen(*elem);
            RefDB[i].seq_len = len;
        }
    }
    return retval;
}

// note that k is really a filter on the edit distance
SV* _configure_edlib_aligner(int k, int mode, int task, AV* additionalEqualities) {
    int n = av_len(additionalEqualities) + 1;
    NEW_SV_BUFFER(retval, buf, sizeof(EdlibAlignConfig));
    EdlibAlignConfig* config=( EdlibAlignConfig* )buf;
    if(n > 0) {
        NEW_SV_BUFFER(additionalEqualitiesArray_SV, buf2, n * sizeof(EdlibEqualityPair));
        EdlibEqualityPair* additionalEqualitiesArray = (EdlibEqualityPair *)buf2;

        for (int i = 0; i < n; i++) {
            SV** elem = av_fetch_simple(additionalEqualities, i, 0); // perl 5.36 and above
            STRLEN len = SvCUR(*elem);
            additionalEqualitiesArray[i].first = SvPVbyte_nolen(*elem)[0];
            additionalEqualitiesArray[i].second = SvPVbyte_nolen(*elem)[1];
        }
        config->additionalEqualities = additionalEqualitiesArray;
    }
    config->k = k;
    config->mode = (EdlibAlignMode)mode;
    config->task = (EdlibAlignTask)task;
    config->additionalEqualitiesLength = n;
    return retval;

}

// This version for version 0.03
AV *_edlib_align(char *query_seq, int query_len, SV *ref_DB, SV *config) {

  // initialization for the mapping
  int min_val = INT_MAX;
  int min_idx = -1;

  // get stuff from perl
  Seq *RefDB = (Seq *)SvPVbyte_nolen(ref_DB);
  int n_of_seqs = SvCUR(ref_DB) / sizeof(Seq); // size of database
  EdlibAlignConfig alignconfig = *(EdlibAlignConfig *)SvPVbyte_nolen(config);

  // prepare to send stuff back to perl
  AV *mapping = newAV();
  sv_2mortal((SV *)mapping);

  _ENV_set_num_threads();
#pragma omp parallel
{
    int thread_min_val = INT_MAX;
    int thread_min_idx = -1;
#pragma omp for schedule(dynamic, 1) nowait
    for (size_t i = 0; i < n_of_seqs; i++) {
      EdlibAlignResult align =
          edlibAlign(query_seq, query_len, (char *)RefDB[i].seq_address,
                     RefDB[i].seq_len, alignconfig);
      if (align.editDistance < thread_min_val) {
        thread_min_val = align.editDistance;
        thread_min_idx = i;
      }
      edlibFreeAlignResult(align);
    }
#pragma omp critical
    {
      unsigned int absthread_min_val = abs(thread_min_val);
      if (absthread_min_val < min_val) {
        min_val = absthread_min_val;
        min_idx = thread_min_idx;
      }
    }
  }
  // perl 5.36 and above
  av_push_simple(mapping, newSViv(min_idx)); // best match index
  av_push_simple(mapping, newSViv(min_val)); // match score (min edit distance)
  return mapping;
}

void _ENV_set_num_threads() {
  char *num;
  num = getenv("OMP_NUM_THREADS");
  omp_set_num_threads(atoi(num));
}


void _print_config(SV* config) {
    EdlibAlignConfig* alignconfig = (EdlibAlignConfig *)SvPVbyte_nolen(config);

    printf("k: %d, mode: %d, task: %d\n", alignconfig->k, alignconfig->mode, alignconfig->task);    
    printf("additionalEqualitiesLength: %d\n", alignconfig->additionalEqualitiesLength);   
    EdlibEqualityPair* additionalEqualities = (EdlibEqualityPair *)alignconfig->additionalEqualities;
    for (int i = 0; i < alignconfig->additionalEqualitiesLength; i++) {
        printf("additionalEqualities[%d]: %c %c\n", i, additionalEqualities[i].first, additionalEqualities[i].second);
    }
}

/* CODE CEMETERY
 * Various snippets of code that were used for testing and debugging
 * but hopefully are no longer needed.

 * This is a snippet of code that was used to test the parallelism of the code
  pid_t pid = getpid();
  printf("Process ID: %d, Threads %d out of %d\n",pid, omp_get_thread_num(), omp_get_num_threads());


* v0.02 version of the alignment function
  AV *_edlib_align(char *query_seq, int query_len, SV *ref_DB, SV *config) {

  // initialization for the mapping
  int min_val = INT_MAX;
  int min_idx = -1;

  // get stuff from perl
  Seq *RefDB = (Seq *)SvPVbyte_nolen(ref_DB);
  int n_of_seqs = SvCUR(ref_DB) / sizeof(Seq); // size of database
  EdlibAlignConfig alignconfig = *(EdlibAlignConfig *)SvPVbyte_nolen(config);

  // prepare to send stuff back to perl
  AV *mapping = newAV();
  sv_2mortal((SV *)mapping);

  _ENV_set_num_threads();
#pragma omp parallel
  {

    int nthreads = omp_get_num_threads();
    size_t thread_id = omp_get_thread_num();
    size_t tbegin = thread_id * n_of_seqs / nthreads;
    size_t tend = (thread_id + 1) * n_of_seqs / nthreads;

    int thread_min_val = INT_MAX;
    int thread_min_idx = -1;
    for (size_t i = tbegin; i < tend; i++) {
      EdlibAlignResult align =
          edlibAlign(query_seq, query_len, (char *)RefDB[i].seq_address,
                     RefDB[i].seq_len, alignconfig);
      if (align.editDistance < thread_min_val) {
        thread_min_val = align.editDistance;
        thread_min_idx = i;
      }
      edlibFreeAlignResult(align);
    }
#pragma omp critical
    {
      unsigned int absthread_min_val = abs(thread_min_val);
      if (absthread_min_val < min_val) {
        min_val = absthread_min_val;
        min_idx = thread_min_idx;
      }
    }
  }
  // perl 5.36 and above
  av_push_simple(mapping, newSViv(min_idx)); // best match index
  av_push_simple(mapping, newSViv(min_val)); // match score (min edit distance)
  return mapping;
}

*/
