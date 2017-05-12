package Algorithm::SVM::DataSet;

use 5.006;
use strict;
use Carp;

use Algorithm::SVM;

=head1 NAME

Algorithm::SVM::DataSet - A DataSet object for the Algorithm::SVM Support
Vector Machine.

=head1 SYNOPSIS

  use Algorithm::SVM::DataSet;

  # Create a new dataset.
  $ds = new Algorithm::SVM::DataSet(Label => 1,
                                    Data  => [ 0.12, 0.25, 0.33, 0.98 ]);

  # Retrieve/set the label.
  $label = $ds->label();
  $ds->label(1976);

  # Retrieve/set the attribute with an index of 0.
  $attr = $ds->attribute(0);
  $ds->attribute(0, 0.2621);

=head1 DESCRIPTION

Algorithm::SVM::DataSet is a representation of the datasets passed to
Algorithm::SVM object for training or classification.  Each dataset has
an associated label, which classifies it as being part of a specific group.
A dataset object also has one or more key/value pairs corresponding to
the attributes that will be used for classification. Values equal
to zero will not be stored, and are returned by default if no
key/value pair exists. This sparse format saves memory, and is
treated in exactly the same way by libsvm.

=head1 CONSTRUCTORS

 $ds = new Algorithm::SVM::DataSet(Label => 1,
                                   Data  => [ 0.12, 0.25, 0.33, 0.98 ]);

The Algorithm::SVM::DataSet constructor accepts two optional named 
parameters: Label and Data.  Label is used to set the class to which the
dataset belongs, and Data is used to set any initial values.  Data
should be an arrayref of numerical values.  Each value in the arrayref
is assumed to have a key corresponding to its index in the array.

  ie) In the above example, 0.12 has a key of 0, 0.25 has a key of 1,
      0.33 has a key of 2, etc.

=head1 METHODS

  $label = $ds->label();
  $ds->label(1976);

The label method is used to set or retrieve the DataSets label value.
Parameters and return values should be numeric values.

  $attr = $ds->attribute(0);
  $ds->attribute(0, 0.2621);


The attribute method is used to set dataset attribute values.  If a single
value is provided, the method will return the corresponding value.  If
two value are provided, the method will set the first parameter to the
value of the second.


  $ds->asArray();


The asArray method returns the contents of a DataSet object in
an efficient way. An optional parameter, $numAttr, can be used to
pad the array with zeros if the number of attributes is not known
from the beginning (e.g. when creating a word vector on the fly,
since all keys not given are automatically assumed to be zero)

=head1 MAINTAINER

Matthew Laird <matt@brinkman.mbb.sfu.ca>
Alexander K. Seewald <alex@seewald.at>

=head1 SEE ALSO

Algorithm::SVM

=cut


sub new {
  my ($class, %args) = @_;

 # Do some quick error checking on the values we've been passed.
  croak("No label specified for DataSet") if(! exists($args{Label}));
  my $self = _new_dataset($args{Label} + 0);

  if(exists($args{Data})) {
    croak("Data must be an array ref") if(ref($args{Data}) ne "ARRAY");
    for(my $i = 0; $i < @{$args{Data}}; $i++) {
      $self->attribute($i, (@{$args{Data}})[$i] + 0);
    }
  }

  return $self;
}

sub label {
  my ($self, $label) = @_;

  return (defined($label)) ? _setLabel($self, $label + 0) : _getLabel($self);
}

sub attribute {
  my ($self, $key, $val) = @_;

  croak("No key specified") if(! defined($key));
  croak("Negative key specified") if (int($key)<0);

  if (defined($val)) {
		return _setAttribute($self, int($key), $val + 0);
  } else {
		return _getAttribute($self, int($key));
	}
}

sub asArray {
	my ($self,$numAttr) = @_;

  if (!defined($numAttr)) { $numAttr=_getMaxI($self)+1; }
  my @x=(); for (my $i=0; $i<$numAttr; $i++) { push @x,0; }
  
  my $i=0; my $k; my $v;
	$k=_getIndexAt($self,$i);
  $v=_getValueAt($self,$i);
	while ($k!=-1 && $k<$numAttr) {
    $x[$k]=$v;
    $i++;
		$k=_getIndexAt($self,$i);
  	$v=_getValueAt($self,$i);
  };

  return @x;
}
		


1;

__END__
