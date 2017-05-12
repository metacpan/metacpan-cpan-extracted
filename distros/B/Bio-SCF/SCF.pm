package Bio::SCF;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
use Bio::SCF::Arrays;
use Carp 'croak';

@ISA = qw(DynaLoader);
$VERSION = '1.03';
use constant KEYS => {
		     index	=> 0,
		     A		=> 1,
		     C		=> 2,
		     G		=> 3,
		     T		=> 4,
		     bases	=> 5,
		     spare1	=> 6,
		     spare1	=> 7,
		     spare1	=> 8,
		     samplesA	=> 11,
		     samplesC	=> 12,
		     samplesG	=> 13,
		     samplesT	=> 14
		    };

use constant HEADER_FIELDS => {
			       samples_length => 0,
			       bases_length   => 1,
			       version        => 2,
			       sample_size    => 3,
			       code_set       => 4,
};

bootstrap Bio::SCF $VERSION;

sub new {
  my $class       = shift;
  my $file_name   = shift;
  my $sample_hash = shift || 0;

  defined $file_name or die "SCF :: Unable to tie hash to undefined file name\n";
  my $scf_pointer;
  if ($sample_hash) {
    $scf_pointer = $file_name; # file name became scf pointer
  }
  else {
    if ( defined fileno($file_name)){
      $scf_pointer = get_scf_fpointer($file_name); # file_name here is file handle
    }else{
      $scf_pointer = get_scf_pointer($file_name); # actually reads scf file into memory
    }
  }
  my $scf_file = {
		  file_name     => $file_name,
		  scf_pointer   => $scf_pointer,
		  sample_hash   => $sample_hash,
		  cache         => {}
		 };
  return bless $scf_file, $class;
}


sub TIEHASH {
  shift->new(@_);
}

sub FETCH {
  my $self = shift;
  my $key = shift;
  my @array;

  if ($self->{sample_hash}) {
    my $k = "sample_$key";
    return $self->{cache}{$k} if exists $self->{cache}{$k};
    tie @array, 'Bio::SCF::Arrays', $self->{scf_pointer}, $k;
    return $self->{cache}{$k} = \@array;
  }

  else {

    if (defined( my $header_field = HEADER_FIELDS->{$key})) {
      return get_from_header($self->{scf_pointer}, $header_field);
    }

    elsif ($key eq "comments") {
      return get_comments($self->{scf_pointer});
    }

    elsif ($key eq 'samples') {
      return $self->{cache}{$key} if exists $self->{cache}{$key};
      my %sample;
      tie %sample, 'Bio::SCF', $self->{scf_pointer}, 1;
      $self->{cache}{key} = \%sample;
      return \%sample;
    }

    elsif (exists KEYS->{$key}) {
      return $self->{cache}{$key} if exists $self->{cache}{$key};
      tie @array, 'Bio::SCF::Arrays', $self->{scf_pointer}, $key;
      $self->{cache}{$key} = \@array;
      return \@array;
    }

  }
}

sub bases_length {
  my $self = shift;
  get_from_header($self->{scf_pointer},HEADER_FIELDS->{bases_length});
}

sub samples_length {
  my $self = shift;
  get_from_header($self->{scf_pointer},HEADER_FIELDS->{samples_length});
}

sub sample_size {
  my $self = shift;
  get_from_header($self->{scf_pointer},HEADER_FIELDS->{sample_size});
}

sub code_set {
  my $self = shift;
  get_from_header($self->{scf_pointer},HEADER_FIELDS->{code_set});
}

sub index {
  my $self = shift;
  my $index = shift;
  my $d = $self->at('index',$index);
  $self->set('index',$index,shift) if @_;
  $d;
}

sub sample {
  my $self  = shift;
  my $base  = uc shift;
  my $index = shift;
  my $d = $self->at("samples${base}",$index);
  $self->set("samples${base}",$index,shift) if @_;
  $d;
}

sub base {
  my $self = shift;
  my $index = shift;
  my $d = $self->at('bases',$index);
  $self->set('bases',$index,shift) if @_;
  $d;
}

sub base_score {
  my $self  = shift;
  my $base  = uc shift;
  my $index = shift;
  my $d = $self->at($base,$index);
  $self->set($base,$index,shift) if @_;
  $d;
}

sub score {
  my $self  = shift;
  my $index = shift;
  my $base = uc $self->base($index);
  my $d = exists KEYS->{$base} ? $self->base_score($base,$index) : 0;
  $self->set($base,$index,shift) if @_;
  $d;
}

sub comments {
  my $self = shift;
  get_comments($self->{scf_pointer});
}

sub at {
  my $self = shift;
  # possible keys { bases, A, C, G, T, spare1/2/3, sampleA/C/G/T }
  my $key   = shift;
  my $index = shift;
  return get_at($self->{scf_pointer}, $index, KEYS->{$key});
}

sub set {
  my $self = shift;
  # possible keys { bases, A, C, G, T, spare1/2/3, sampleA/C/G/T }
  my $key = shift; 
  my $index = shift;
  my $value = shift or die "Bio::SCF::set(...) value not defined\n";
  if ( $key eq "bases" ){
    set_base_at($self->{scf_pointer}, $index, KEYS->{$key}, $value);
  }else{
    set_at($self->{scf_pointer}, $index, KEYS->{$key}, $value);
  }
}

sub write {
  my $self = shift;
  my $file_name = shift || $self->{file_name};
  return scf_write($self->{scf_pointer}, $file_name);
}

sub fwrite {
  my $self = shift;
  my $file_handle = shift || 
    die "Bio::SCF::fwrite(...) :  file handle is not defined\n";
  return scf_fwrite($self->{scf_pointer}, $file_handle);
}

sub STORE {
  my $self = shift;
  my $key = shift;
  my $value = shift;
 SWITCH: {
    $key eq "comments" && do {
      set_comments($self->{scf_pointer}, $value);
      last SWITCH;
    };
    die "Bio::SCF::STORE field $key doesn't exist or not allowed to be modified\n";
  }
}

sub FIRSTKEY {
  my $self = shift;
  my $a = keys %{KEYS()};
  each %{KEYS()}
}

sub NEXTKEY {
  my $self = shift;
  each %{KEYS()};
}

sub CLEAR {
  croak "The Bio::SCF module does not support this operation";
}

sub DELETE {
  croak "The Bio::SCF module does not support this operation";
}

sub DESTROY {
  my $self = shift;
  Bio::SCF::scf_free($self->{scf_pointer}) unless $self->{sample_hash};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Bio::SCF - Perl extension for reading and writting SCF sequence files

=head1 SYNOPSIS

use Bio::SCF;

# tied interface
tie %hash,'Bio::SCF','my_scf_file.scf';

my $sequence_length            = $hash{bases_length};
my $chromatogram_sample_length = $hash{samples_length};
my $third_base                 = $hash{bases}[2];
my $quality_score              = $hash{$third_base}[2];
my $sample_A_at_time_1400      = $hash{samples}{A}[1400];

# change the third base and write out new file
$hash{bases}[2] = 'C';
tied (%hash)->write('new.scf');

# object-oriented interface
my $scf                        = Bio::SCF->new('my_scf_file.scf');
my $sequence_length            = $scf->bases_length;
my $chromatogram_sample_length = $scf->samples_length;
my $third_base                 = $scf->bases(2);
my $quality_score              = $scf->score(2);
my $sample_A_at_time_1400      = $scf->sample('A',1400);

# change the third base and write out new file
$scf->bases(2,'C');
$scf->write('new.scf');

=head1 DESCRIPTION

This module provides a perl interface to SCF DNA sequencing files. It
has both tied hash and an object-oriented interfaces. It provides the
ability to read fields from SCF files and limited ability to modify
them and write them back.

=head2 Tied Methods

=over 4

=item $obj = tie %hash,'Bio::SCF',$filename_or_handle

Tie the Bio::SCF module to a filename or filehandle. If successful, tie()
will return the object.

=item $value = $hash{'key'}

Fetch a field from the SCF file. Valid keys are as follows:

  Key             Value
  ---             -----

  bases_length    Number of called bases in the sequence (read-only)

  samples_length  Number of samples in the file (read-only)

  version         SCF version (read-only)

  code_set        Code set used to code bases (read-only)

  comments        Structured comments (read-only)

  bases           Array reference to a list of the base calls

  index           Array reference to a list of the sample position
                    for each of the base calls (e.g. the position of
                    the base calling peak)

  A               An array reference that can be used to determine the
                    probability that the base in position $i is an "A".

  G               An array reference that can be used to determine the
                    probability that the base in position $i is a "G".

  C               An array reference that can be used to determine the
                    probability that the base in position $i is a "C".

  T               An array reference that can be used to determine the
                    probability that the base in position $i is a "T".

  samples         A hash reference with keys "A", "C", "G" and "T". The
                    value of each hash is an array reference to the list
                    of intensity values for each sample.

To get the length of the called sequence:              $scf{bases_length}

To get the value of the called sequence at position 3: $scf{bases}[3]

To get the sample position at which base 3 was called: $scf{index}[3]

To get the value of the "C" curve under base 3:        $scf{samples}{C}[$scf{index}[3]]

To get the probability that base 3 is a "C":           $scf{C}[3]

To print out the chromatogram as a four-column list:

    my $samples = $scf{samples};
    for (my $i = 0; $i<$scf{samples_length}; $i++) {
       print join "\t",$samples->{C}[$i],$samples->{G}[$i],
                       $samples->{A}[$i],$samples->{T}[$i],"\n";
    }

=item $scf{bases}[$index] = $new_value

The base call probability scores, base call values, base call
positions, and sample values are all read/write, so that you can
change them:

   $samples->{C}[500] = 0;

=item each %scf

Will return keys and values for the tied object.

=item delete $scf{$key}

=item %scf = ()

These operations are not supported and will return a run-time error

=back

=head2 Object Methods

=over 4

=item $scf = Bio::SCF->new($scf_file_or_filehandle)

Create a new Bio::SCF object. The single argument is the name of a file or
a previously-opened filehandle. If successful, new() returns the Bio::SCF
object.

=item $length = $scf->bases_length

Return the length of the called sequence.

=item $samples = $scf->samples_length

Return the length of the list of chromatogram samples in the
file. There are four sample series, one for each base.

=item $sample_size = $scf->sample_size

Returns the size of each sample (bytes).

=item $code_set = $scf->code_set

Return the code set used for base calling.

=item $base = $scf->base($base_no [,$new_base])

Get the base call at the indicated position. If a new value is
provided, will change the base call to the indicated base.

=item $index = $scf->index($base_no [,$new_index])

Translates the indicated base position into the sample index for that
called base. Here is how to fetch the intensity values at base number 5:

  my $sample_index = $scf->index(5);
  my ($g,$a,$t,$c) = map { $scf->sample($_,$sample_index) } qw(G A T C);

If you provide a new value for the sample index, it will be updated.

=item $base_score = $scf->base_score($base,$base_no [,$new_score])

Get the probability that the indicated base occurs at position
$base_no. Here is how to fetch the probabilities for the four bases at
base position 5:

  my ($g,$a,$t,$c) = map { $scf->base_score($_,5) } qw(G A T C);

If you provide a new value for the base probability score, it will be
updated.

=item $score = $scf->score($base_no)

Get the quality score for the called base at the indicated position.

=item $intensity = $scf->sample($base,$sample_index [,$new_value])

Get the intensity value for the channel corresponding to the indicated
base at the indicated sample index. You may update the intensity by
providing a new value.

=item $scf->write('file_path')

Write the updated SCF file to the indicated file path.

=item $scf->fwrite($file_handle)

Write the updated SCF file to the indicated filehandle. The file must
previously have been opened for writing. The filehandle is actually
reopened in append mode, so you can call fwrite() multiple times and
interperse your own record separators.

=back

=head1 EXAMPLES

Reading information from a preexisting file:

   tie %scf, 'Bio::SCF', "data.scf";
   print "Base calls:\n";
   for ( my $i=0; $i<$scf{bases}; $i++ ){
      print "$scf{base}[$i] ";
   }
   print "\n";

   print "Intensity values for the A curve\n";
   for ( my $i=0; $i<$scf{samples}; $i++ ){
      print "$scf{sample}{A}[$i];
   }
   print "\n";

Another example, where we set all bases to "A", indexes to 10 and write
the file back:

   my $obj = tie %scf,'Bio::SCF','data.scf';
   for (0...@{$scf{bases}}-1){
      $scf{base}[$_] = "A";
      $obj->set('index', $_, 10);
   }
   $obj->write('data.scf');

=head1 AUTHOR

Dmitri Priimak, priimak@cshl.org (1999)

with some cleanups by
Lincoln Stein, lstein@cshl.edu (2006)

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER for disclaimers of warranty.

=head1 SEE ALSO

perl(1).

=cut
