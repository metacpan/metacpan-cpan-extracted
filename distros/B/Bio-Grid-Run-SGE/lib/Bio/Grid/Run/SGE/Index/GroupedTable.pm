package Bio::Grid::Run::SGE::Index::GroupedTable;

use warnings;
use strict;

use Mouse;

use Carp;
use List::Util qw/sum/;
use List::MoreUtils qw/uniq/;
use Bio::Gonzales::Util::File qw/open_on_demand is_newer/;
use Bio::Grid::Run::SGE::Util qw/glob_list/;
use Data::Dumper;
use Cwd qw/fastcwd/;

our $VERSION = '0.066'; # VERSION

has 'col_sep' => ( is => 'rw', default => "\t" );
has 'col_idx' => ( is => 'rw', default => 0 );
has 'col_type'             => ( is => 'rw' );
has 'num_elems_cumulative' => ( is => 'rw' );
has overwrite              => ( is => 'rw', default => 1 );
has _current_fh            => ( is => 'rw' );
has _current_file_idx      => ( is => 'rw' );

with 'Bio::Grid::Run::SGE::Role::Indexable';

sub BUILD {
  my ($self) = @_;

  confess "index file not set"
    unless ( $self->idx_file );

  # try to load index file if it exists
  if ( -f $self->idx_file ) {
    $self->_load_index;
    $self->_cache_meta_data;
  }

  return $self;
}

sub create {
  my ( $self, $input_files ) = @_;

  confess 'No write permission, set write_flag to write' unless ( $self->writeable );

  my $abs_input_files = glob_list($input_files);

  if ( $self->_is_indexed($abs_input_files) ) {
    $self->log->info("SKIPPING INDEXING STEP, THE INDEX IS UP TO DATE");
    return $self;
  }

  $self->log->info("INDEXING ....");

  my $chunk_size = $self->chunk_size;

  $self->idx( [] )
    if ( $self->overwrite );

  for my $f (@$abs_input_files) {

    # start of file is the first (chunk) element
    my @file_idx         = (0);
    my $num_elems        = 1;
    my $chunk_elem_count = 1;

    open my $fh, '<', $f or confess "Can't open filehandle $f: $!";
    my $first_line = <$fh>;
    unless ($first_line) {
      $fh->close;
      next;
    }

    my $colsep      = $self->col_sep;
    my $colidx      = $self->col_idx;
    my $current_key = ( split /$colsep/, $first_line )[$colidx];

    while (<$fh>) {
      my $key = ( split /$colsep/ )[$colidx];
      if ( $current_key ne $key ) {
        if ( $chunk_elem_count && $chunk_elem_count % $chunk_size == 0 ) {

          push @file_idx, tell($fh) - length($_);
          $num_elems++;
          $chunk_elem_count = 0;
        }
        $chunk_elem_count++;
      }
    }
    push @{ $self->idx },
      {
      eof_pos   => tell($fh),
      num_elems => $num_elems,
      file      => $f,
      pos       => \@file_idx,
      age       => ( stat $f )[9]
      };

    $fh->close;
  }

  for my $attr (qw/col_sep col_idx col_type/) {
    $self->_internal_info()->{$attr} = $self->$attr;
  }
  $self->_store;
  $self->_cache_meta_data;

  return $self;
}

sub _is_indexed {
  my ( $self, $files ) = @_;

  return if ( $self->_reindexing_necessary );
  return unless ( @{ $self->idx } > 0 && -f $self->idx_file );

  # the config file has a different separator than the index
  my $info = $self->_internal_info;
  return unless ($info);

  for my $attr (qw/col_sep col_idx col_type/) {
    return unless ( $info->{$attr} && $info->{$attr} eq $self->$attr );
  }

  my %idx_input_files = map { $_->{file} => $_->{age} } @{ $self->idx };

  for my $f (@$files) {
    return
      if ( !-f $f || !exists( $idx_input_files{$f} ) || ( stat $f )[9] != $idx_input_files{$f} );
  }

  return 1;
}

sub _cache_meta_data {
  my ($self) = @_;

  my $idx = $self->idx;

  return unless (@$idx);
  #sum up entries cumulatively
  my @num_elems_cumulative = ( $idx->[0]{num_elems} );
  for ( my $i = 1; $i < @{$idx}; $i++ ) {
    $num_elems_cumulative[$i] = $idx->[$i]{num_elems} + $num_elems_cumulative[ $i - 1 ];
  }

  $self->num_elems_cumulative( \@num_elems_cumulative );

  return;
}

sub get_elem {
  my ( $self, $elem_idx ) = @_;

  my $idx = $self->idx;
  return unless (@$idx);
  my $cur_file_idx         = $self->_current_file_idx;
  my $fh                   = $self->_current_fh;
  my $elem_file_idx        = $self->_binsearch_file_idx($elem_idx);
  my $num_elems_cumulative = $self->num_elems_cumulative;

  # the element index points to a element in a different file, so close the current one, if necessary
  if ( $fh && $cur_file_idx != $elem_file_idx ) {
    close($fh);
    undef($fh);
  }

  # currently no file open, so open the file where the elem_idx points to
  unless ($fh) {
    #say STDERR "DOING JUMP";
    $cur_file_idx = $elem_file_idx;

    #open idx and iterate over it
    open $fh, '<', $idx->[$cur_file_idx]{file}
      or confess "Can't open filehandle: $! - file_idx: $cur_file_idx, file: "
      . $idx->[$cur_file_idx]{file}
      . " dir: "
      . fastcwd();
    $self->_current_file_idx($cur_file_idx);
    $self->_current_fh($fh);

  }

  # index within the file
  my $file_elem_idx = $elem_idx - ( $cur_file_idx == 0 ? 0 : $num_elems_cumulative->[ $cur_file_idx - 1 ] );

  # did we read to this position in the previous call? then seek is not necessary
  my $read_start = $idx->[$cur_file_idx]{pos}[$file_elem_idx];

  unless ( defined($read_start) ) {
    confess "INDEXING ERROR, COULD NOT FIND READ START. STACK: "
      . Dumper {
      elem_idx             => $elem_idx,
      elem_file_idx        => $elem_file_idx,
      cur_file_idx         => $cur_file_idx,
      num_elems_cumulative => $num_elems_cumulative,
      file_elem_idx        => $file_elem_idx,
      self                 => $self
      };
  }

  unless ( tell($fh) == $read_start ) {
    seek $fh, $read_start, 0;
    #say STDERR "+SEEK";
  } else {
    #say STDERR "NO SEEK";
  }

  my $read_length;
  #needed for remove sep operation
  if ( $file_elem_idx + 1 < @{ $idx->[$cur_file_idx]{pos} } ) {
    $read_length = $idx->[$cur_file_idx]{pos}[ $file_elem_idx + 1 ];
  } else {
    $read_length = $idx->[$cur_file_idx]{eof_pos};
  }

  $read_length -= $read_start;
  #say STDERR "$elem_idx, start: $read_start, len: $read_length";

  my $data;
  read $fh, $data, $read_length;

  return $data;
}

sub num_elem {
  my ($self) = @_;

  my $num_elems = 0;

  #sum up number of entries for every index
  for my $i ( @{ $self->idx } ) {
    $num_elems += $i->{num_elems};
  }

  return $num_elems;
}

sub type {
  return;
}

sub _binsearch_file_idx {
  my ( $self, $elem_idx ) = @_;

  my $file_elem_counts = $self->num_elems_cumulative;

  my $posmin = 0;
  my $posmax = $#{$file_elem_counts};

  return 0 if ( $file_elem_counts->[0] > $elem_idx );
  #oder INF zurueckgeben
  return -1 if ( $file_elem_counts->[$posmax] < $elem_idx );

  while (1) {
    my $mid = int( ( $posmin + $posmax ) / 2 );
    my $result = ( $file_elem_counts->[$mid] <=> $elem_idx );

    if ( $result < 0 ) {
      $posmin = $posmax, next if $mid == $posmin && $posmax != $posmin;
      return $mid + 1 if $mid == $posmin;
      $posmin = $mid;
    } elsif ( $result > 0 ) {
      $posmax = $posmin, next if $mid == $posmax && $posmax != $posmin;
      return $mid if $mid == $posmax;
      $posmax = $mid;
    } else {
      return $mid + 1;
    }
  }
}

sub close {
  my ($self) = @_;
  close( $self->_current_fh )
    if ( $self->_current_fh );

}

1;

__END__

=head1 NAME



=head1 SYNOPSIS

  #wenn export, dann hier im qw()
  my $idx = Bio::Grid::Run::SGE::Index::General->new(
    'idx_file' => $idx_file,
    'sep'      => '^>'
    'sep_pos' => '^',
    'sep_remove' => 1,
    'ignore_first_sep' => 1,

  );

=head1 DESCRIPTION

=over 4

=item B<< sep_remove >>

remove the separators between the data records. For sep remove sth. like

  <FILE_START>
  <entry1>
  <sep>
  <entry2>
  <sep>
  ...
  <sep>
  <entryN>
  <FILE_END>

is expected, so no separator at begin or end of file, otherwise it will break! If
you have a separator before the first data record, you can use the
C<ignore_first_sep> option to skip over it.

=item B<< sep_pos >>

Can be '^' or '$'. '^' corresponds to a file layout

  <FILE_START>
  <sep> <--- NOTE: the first sep
  <entry1>
  <sep>
  <entry2>
  <sep>
  ...
  <sep>
  <entryN> <--- NOTE: no last sep
  <FILE_END>

'$' corresponds to a file layout:

  <FILE_START>
  <entry1><--- NOTE: no first sep
  <sep>
  <entry2>
  <sep>
  ...
  <sep>
  <entryN>
  <sep> <--- NOTE: the last sep
  <FILE_END>

=back

=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
