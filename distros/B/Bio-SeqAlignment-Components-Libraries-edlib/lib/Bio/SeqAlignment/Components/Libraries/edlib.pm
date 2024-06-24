use strict;
use warnings;

package Bio::SeqAlignment::Components::Libraries::edlib;
$Bio::SeqAlignment::Components::Libraries::edlib::VERSION = '0.03';
# ABSTRACT: basic edlib library
use Alien::SeqAlignment::edlib;
use Carp;
use FFI::Platypus;

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

our @EXPORT = qw( EDLIB_STATUS_OK EDLIB_STATUS_ERROR);

## export the XS stub and structures
our @EXPORT_OK = qw(
  EDLIB_MODE_NW
  EDLIB_MODE_SHW
  EDLIB_MODE_HW
  EDLIB_TASK_DISTANCE
  EDLIB_TASK_LOC
  EDLIB_TASK_PATH
  EDLIB_STATUS_OK
  EDLIB_STATUS_ERROR
  EdlibEqualityPair
  configure_edlib_aligner
  edlibAlign
  EdlibAlignResult
  edlibFreeAlignResult
  edlibNewAlignConfig
  new_edlib_aligner
);

our %EXPORT_TAGS = (
    all       => \@EXPORT_OK,
    records   => [qw(EdlibEqualityPair EdlibAlignResult EdlibAlignConfig)],
    functions => [
        qw(
          configure_edlib_aligner
          edlibNewAlignConfig
          edlibAlign
          edlibFreeAlignResult
          new_edlib_aligner
        )
    ]
);
## edit operations
use constant EDLIB_EDOP_MATCH    => 0;
use constant EDLIB_EDOP_INSERT   => 1;
use constant EDLIB_EDOP_DELETE   => 2;
use constant EDLIB_EDOP_MISMATCH => 3;

package EdlibAlignConfig {
    use FFI::Platypus::Record;
    our @ISA = qw( FFI::Platypus::Record );
    record_layout_1(
        qw(
          int     k
          int     mode
          int     task
          opaque  additionalEqualities
          int     additionalEqualitiesLength
        )
    );
}
$EdlibAlignConfig::VERSION = '0.03';

package EdlibAlignResult {
    use FFI::Platypus::Record;
    record_layout_1(
        qw(
          int     status
          int     editDistance
          opaque  endLocations
          opaque  startLocations
          int     numLocations
          string  alignment
          int     alphabetLength
        )
    );
}
$EdlibAlignResult::VERSION = '0.03';

package EdlibEqualityPair {
    use FFI::Platypus::Record;
    record_layout_1(
        qw(
          char    first
          char    second
        )
    );
}
$EdlibEqualityPair::VERSION = '0.03';

use Env qw( @PATH );
unshift @PATH, Alien::SeqAlignment::edlib->bin_dir;

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

sub new_edlib_aligner {
    my $edlib_dynlib = Alien::SeqAlignment::edlib->dynamic_libs;
    my $ffi          = FFI::Platypus->new(
        api => 2,
        lib => $edlib_dynlib,
    );

    $ffi->type( 'record(EdlibEqualityPair)' => 'EdlibEqualityPair' );
## create a platypus record for the EdlibAlignConfig struct
    $ffi->type( 'record(EdlibAlignConfig)' => 'EdlibAlignConfig' );
## create a platypus record for the EdlibAlignResult struct
    $ffi->type( 'record(EdlibAlignResult)' => 'EdlibAlignResult' );
    $ffi->attach(
        edlibNewAlignConfig => [ 'int', 'int', 'int', 'opaque', 'int' ] =>
          'EdlibAlignConfig' );
    $ffi->attach( edlibAlign =>
          [ 'string', 'int', 'string', 'int', 'EdlibAlignConfig', ] =>
          'EdlibAlignResult' );
    $ffi->attach( edlibFreeAlignResult => ['EdlibAlignResult'] => 'void' );
    return $ffi;
}

sub configure_edlib_aligner {
    my ( $ffi, %config ) = @_;
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
    $align_config{additionalEqualities} = $config{additionalEqualities}
      // undef;
    $align_config{additionalEqualitiesLength} =
      $config{additionalEqualitiesLength} // 0;

    return {
        edlib_config => edlibNewAlignConfig(
            $align_config{filter},
            $align_config{mode},
            $align_config{task},
            $align_config{additionalEqualities},
            $align_config{additionalEqualitiesLength}
        ),
        align_config => {
            filter               => $align_config{filter},
            mode                 => $config{mode},
            task                 => $config{task},
            additionalEqualities => $align_config{additionalEqualities},
            additionalEqualitiesLength =>
              $align_config{additionalEqualitiesLength}
        }
    };
}

1;


=head1 NAME

Bio::SeqAlignment::Components::Libraries::edlib - edlib library for developing sequence alignment tools


=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Bio::SeqAlignment::Components::Libraries::edlib;
  my $ffi = Bio::SeqAlignment::Components::Libraries::edlib->new_edlib_aligner();
  my $configuration = Bio::SeqAlignment::Components::Libraries::edlib->configure_edlib_aligner( $ffi, %config );
  my $align = Bio::SeqAlignment::Components::Libraries::edlib->edlibAlign( $query_seq, $query_len, $ref_seq, $ref_seq_len, $configuration->{edlib_config} );
  Bio::SeqAlignment::Components::Libraries::edlib->edlibFreeAlignResult( $align );

=head1 DESCRIPTION

This module provides a Perl interface to the edlib library for developing sequence
alignment tools. The edlib library is a C/C++ library for sequence alignment using 
edit distance. It supports three alignment modes: global (Needleman-Wunsch), 
semi-global, and local (Smith-Waterman). 
This module provides a Perl interface to the edlib library for developing sequence
alignment tools. This particular module is meant to be used as a component in a
larger sequence alignment tool, e.g. one that combines a Linear dataflow and a 
generic sequence mapper. Currently only the alignment score is returned. 
Future versions will include the alignment path and the alignment locations in 
order to handle multiple/overlapping hits.

=head1 METHODS

=head2 new_edlib_aligner

  my $ffi = Bio::SeqAlignment::Components::Libraries::edlib->new_edlib_aligner();

This method creates a new FFI::Platypus object that can be used to call the functions
from the edlib library. The FFI::Platypus object is returned.

=head2 configure_edlib_aligner

  my $configuration = Bio::SeqAlignment::Components::Libraries::edlib->configure_edlib_aligner( $ffi, %config );

This method configures the edlib aligner with the specified configuration. The configuration
is passed as a hash with the following keys: mode, task, filter, additionalEqualities, and
additionalEqualitiesLength. The configuration is returned as a hash reference with two keys:
edlib_config and align_config. The edlib_config key contains the configuration for the edlib
aligner, while the align_config key contains the configuration for the alignment.

=head2 edlibAlign

  my $align = Bio::SeqAlignment::Components::Libraries::edlib->edlibAlign( $query_seq, $query_len, $ref_seq, $ref_seq_len, $configuration->{edlib_config} );

This method performs the sequence alignment using the edlib library. It takes as input the
query sequence, the length of the query sequence, the reference sequence, the length of the
reference sequence, and the configuration for the edlib aligner. It returns the alignment
result as a hash reference.

=head2 edlibFreeAlignResult

  Bio::SeqAlignment::Components::Libraries::edlib->edlibFreeAlignResult( $align );

This method frees the memory allocated for the alignment result.

=head1 EXPORTS

The following constants are exported by default:

=over 4

=item * EDLIB_STATUS_OK

=item * EDLIB_STATUS_ERROR

=back

The following functions are exported by the 'functions' tag:

=over 4

=item * configure_edlib_aligner

=item * edlibNewAlignConfig

=item * edlibAlign

=item * edlibFreeAlignResult

=item * new_edlib_aligner

=back

The following records are exported by the 'records' tag:

=over 4

=item * EdlibEqualityPair

=item * EdlibAlignResult

=item * EdlibAlignConfig

=back

=head1 SEE ALSO

=over 4

=item * L<Alien::SeqAlignment::edlib>

=item * L<Bio::SeqAlignment::Components::Libraries::edlib::OpenMP|https://metacpan.org/pod/Bio::SeqAlignment::Components::Libraries::edlib::OpenMP>;

An alternative implementation of the edlib library that uses OpenMP for thread level parallelism

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
