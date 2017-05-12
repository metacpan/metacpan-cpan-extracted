package Algorithm::SVM;

use 5.006;
use strict;
use Carp;

require DynaLoader;
require Exporter;
use AutoLoader;

# SVM types
my %SVM_TYPES = ('C-SVC'       => 0,
		 'nu-SVC'      => 1,
		 'one-class'   => 2,
		 'epsilon-SVR' => 3,
		 'nu-SVR'      => 4);
my %SVM_TYPESR = (0 => 'C-SVC',
		  1 => 'nu-SVC',
		  2 => 'one-class',
		  3 => 'epsilon-SVR',
		  4 => 'nu-SVR');

# Kernel types
my %KERNEL_TYPES = ('linear'     => 0,
		    'polynomial' => 1,
		    'radial'     => 2,
		    'sigmoid'    => 3);
my %KERNEL_TYPESR = (0 => 'linear',
		     1 => 'polynomial',
		     2 => 'radial',
		     3 => 'sigmoid');

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION);

@ISA = qw(Exporter DynaLoader);

%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );

$VERSION = '0.13';

sub AUTOLOAD {
  my $constname;
  use vars qw($AUTOLOAD);
  ($constname = $AUTOLOAD) =~ s/.*:://;
  croak "& not defined" if $constname eq 'constant';
  my $val = constant($constname, @_ ? $_[0] : 0);
  if ($! != 0) {
    if ($! =~ /Invalid/ || $!{EINVAL}) {
      $AutoLoader::AUTOLOAD = $AUTOLOAD;
      goto &AutoLoader::AUTOLOAD;
    }
    else {
      croak "Your vendor has not defined Algorithm::SVM macro $constname";
    }
  }
  {
    no strict 'refs';
    # Fixed between 5.005_53 and 5.005_61
    if ($] >= 5.00561) {
      *$AUTOLOAD = sub () { $val };
    }
    else {
      *$AUTOLOAD = sub { $val };
    }
  }
  goto &$AUTOLOAD;
}

bootstrap Algorithm::SVM $VERSION;

=head1 NAME

Algorithm::SVM - Perl bindings for the libsvm Support Vector Machine library.

=head1 SYNOPSIS

  use Algorithm::SVM;

  # Load the model stored in the file 'sample.model'
  $svm = new Algorithm::SVM(Model => 'sample.model');

  # Classify a dataset.
  $ds1 = new Algorithm::SVM::DataSet(Label => 1,
                                     Data  => [0.12, 0.25, 0.33, 0.98]);
  $res = $svm->predict($ds);

  # Train a new SVM on some new datasets.
  $svm->train(@tset);

  # Change some of the SVM parameters.
  $svm->gamma(64);
  $svm->C(8);
  # Retrain the SVM with the new parameters.
  $svm->retrain();

  # Perform cross validation on the training set.
  $accuracy = $svm->validate(5);

  # Save the model to a file.
  $svm->save('new-sample.model');

  # Load a saved model from a file.
  $svm->load('new-sample.model');

  # Retreive the number of classes.
  $num = $svm->getNRClass();

  # Retreive labels for dataset classes
  (@labels) = $svm->getLabels();

  # Probabilty for regression models, see below for details
  $prob = $svm->getSVRProbability();

=head1 DESCRIPTION

Algorithm::SVM implements a Support Vector Machine for Perl.  Support Vector
Machines provide a method for creating classifcation functions from a set of
labeled training data, from which predictions can be made for subsequent data
sets.

=head1 CONSTRUCTOR

  # Load an existing SVM.
  $svm = new Algorithm::SVM(Model  => 'sample.model');

  # Create a new SVM with the specified parameters.
  $svm = new Algorithm::SVM(Type   => 'C-SVC',
                            Kernel => 'radial',
                            Gamma  => 64,
                            C      => 8);

An Algorithm::SVM object can be created in one of two ways - an existing
SVM can be loaded from a file, or a new SVM can be created an trained on
a dataset.

An existing SVM is loaded from a file using the Model named parameter.
The model file should be of the format produced by the svm-train program
(distributed with the libsvm library) or from the $svm->save() method.

New SVM's can be created using the following parameters:

  Type    - The type of SVM that should be created.  Possible values are:
            'C-SVC', 'nu-SVC', 'one-class', 'epsilon-SVR' and 'nu-SVR'.
            Default os 'C-SVC'.

  Kernel  - The type of kernel to be used in the SVM.  Possible values
            are: 'linear', 'polynomial', 'radial' and 'sigmoid'.
            Default is 'radial'.

  Degree  - Sets the degree in the kernel function.  Default is 3.

  Gamma   - Sets the gamme in the kernel function.  Default is 1/k,
            where k is the number of training sets.

  Coef0   - Sets the Coef0 in the kernel function.  Default is 0.

  Nu      - Sets the nu parameter for nu-SVC SVM's, one-class SVM's
            and nu-SVR SVM's.  Default is 0.5.

  Epsilon - Sets the epsilon in the loss function of epsilon-SVR's.
            Default is 0.1.

For a more detailed explanation of what the above parameters actually do,
refer to the documentation distributed with libsvm.

=head1 METHODS

  $svm->degree($degree);
  $svm->gamma($gamma);
  $svm->coef0($coef0);
  $svm->C($C);
  $svm->nu($nu);
  $svm->epsilon($epsilon);
  $svm->kernel_type($ktype);
  $svm->svm_type($svmtype);

  $svm->retrain();

The Algorithm::SVM object provides accessor methods for the various SVM
parameters.  When a value is provided to the method, the object will
attempt to set the corresponding SVM parameter.  If no value is provided,
the current value will be returned.  See the constructor documentation for
a description of appropriate values.

The retrain method should be called if any of the parameters are modified
from their initial values so as to rebuild the model with the new values.
Note that you can only retrain an SVM if you've previously trained the
SVM on a dataset.  (ie. You can't currently retrain a model loaded with the
load method.)  The method will return a true value if the retraining was
successful and a false value otherwise.

  $res = $svm->predict($ds);

The predict method is used to classify a set of data according to the
loaded model.  The method accepts a single parameter, which should be
an Algorithm::SVM::DataSet object.  Returns a floating point number
corresponding to the predicted value.

  $res = $svm->predict_value($ds);

The predict_value method works similar to predict, but returns a
floating point value corresponding to the output of the trained
SVM. For a linear kernel, this can be used to reconstruct the
weights for each attribute as follows: the bias of the linear
function is returned when calling predict_value on an empty dataset
(all zeros), and by setting each variable in turn to one and all
others to zero, you get one value per attribute which corresponds
to bias + weight_i. By subtracting the bias, the final linear
model is obtained as sum of (weight_i * attr_i) plus bias. The
sign of this value corresponds to the binary prediction.


  $svm->save($filename);

Saves the currently loaded model to the specified filename.  Returns a
false value on failure, and truth value on success.

  $svm->load($filename);

Loads a model from the specified filename.  Returns a false value on failure,
and truth value on success.

  $svm->train(@tset);

Trains the SVM on a set of Algorithm::SVM::DataSet objects.  @tset should
be an array of Algorithm::SVM::DataSet objects.


  $accuracy = $svm->validate(5);

Performs cross validation on the training set.  If an argument is provided,
the set is partioned into n subsets, and validated against one another.
Returns a floating point number representing the accuracy of the validation.

  $num = $svm->getNRClass();

For a classification model, this function gives the number of classes.
For a regression or a one-class model, 2 is returned.

  (@labels) = $svm->getLabels();

For a classification model, this function returns the name of the labels
in an array.  For regression and one-class models undef is returned.

  $prob = $svm->getSVRProbability();

For a regression model with probability information, this function
outputs a value sigma > 0.  For test data, we consider the probability
model: target value = predicted value + z, z: Laplace distribution
e^(-|z|/sigma)/2sigma)

If the model is not for svr or does not contain required information,
undef is returned.

=head1 MAINTAINER

Matthew Laird <matt@brinkman.mbb.sfu.ca>
Alexander K. Seewald <alex@seewald.at>

=head1 SEE ALSO

Algorithm::SVM::DataSet and the libsvm homepage:
http://www.csie.ntu.edu.tw/~cjlin/libsvm/

=head1 ACKNOWLEDGEMENTS

Thanks go out to Fiona Brinkman and the other members of the Simon Fraser
University Brinkman Laboratory for providing me the opportunity to develop
this module.  Additional thanks go to Chih-Jen Lin, one of the libsvm authors,
for being particularly helpful during the development process.

As well to Dr. Alexander K. Seewald of Seewald Solutions for many bug fixes,
new test cases, and lowering the memory footprint by a factor of 20.  Thank
you very much!

=cut

sub new {
  my ($class, %args) = @_;
  my $self = bless({ }, $class);

  # Ensure we have a valid SVM type.
  $args{Type} = 'C-SVC' if(! exists($args{Type}));
  my $svmtype = $SVM_TYPES{$args{Type}};
  croak("Invalid SVM type: $args{Type}") if(! defined($svmtype));

  # Ensure we have a valid kernel type.
  $args{Kernel} = 'radial' if(! exists($args{Kernel}));
  my $kernel = $KERNEL_TYPES{$args{Kernel}};
  croak("Invalid SVM kernel type: $args{Kernel}") if(! defined($svmtype));

  # Set some defaults.
  my $degree  = exists($args{Degree}) ? $args{Degree} + 0 : 3;
  my $gamma   = exists($args{Gamma}) ? $args{Gamma} + 0 : 0;
  my $coef0   = exists($args{Coef0}) ? $args{Coef0} + 0 : 0;
  my $c       = exists($args{C}) ? $args{C} + 0 : 1;
  my $nu      = exists($args{Nu}) ? $args{Nu} + 0 : 0.5;
  my $epsilon = exists($args{Epsilon}) ? $args{Epsilon} + 0 : 0.1;

  $self->{svm} = _new_svm($svmtype, $kernel, $degree, $gamma, $coef0,
			  $c, $nu, $epsilon);

  # Load the model if one was specified.
  if(my $model = $args{Model}) {
    croak("Model file not found or bad permissions: $model")
      if((! -r $model) || (! -f $model));

    # Load the model.
    $self->load($model);

    # Ensure that the model loaded correctly.
    croak("Error loading model file: $model") if(! $self->{svm});
  }

  return $self;
}

sub predict {
  my ($self, $x) = @_;

  # Check if we got a dataset object.
  croak("Not an Algorithm::DataSet") if(ref($x) ne "Algorithm::SVM::DataSet");

  return _predict($self->{svm}, $x);
 }

sub predict_value {
  my ($self, $x) = @_;

  # Check if we got a dataset object.
  croak("Not an Algorithm::DataSet") if(ref($x) ne "Algorithm::SVM::DataSet");

  return _predict_value($self->{svm}, $x);
 }

sub save {
  my ($self, $file) = @_;

  croak("Can't save model because no filename provided") if(! $file);

  return _saveModel($self->{svm}, $file);
}

sub load {
  my ($self, $file) = @_;

  croak("Can't load model because no filename provided") if(! $file);

  return _loadModel($self->{svm}, $file);
}

sub getNRClass {
    my ($self) = @_;

    return _getNRClass($self->{svm});
}

sub getLabels {
    my ($self) = @_;

    my $class = $self->getNRClass();
    if($class) {
	return _getLabels($self->{svm}, $class);
    }

    return 0;
}

sub getSVRProbability {
    my ($self) = @_;

    return _getSVRProbability($self->{svm});
}

sub checkProbabilityModel {
    my ($self) = @_;

    return _checkProbabilityModel($self->{svm});
}

sub train {
  my ($self, @tset) = @_;

  croak("No training data provided") if(! @tset);

  # Delete the old training data.
  _clearDataSet($self->{svm});

  # Ensure we've got the right format for the training data.
  for(@tset) {
    croak("Not an Algorithm::SVM::DataSet object")
      if(ref($_) ne "Algorithm::SVM::DataSet");
  }

  # Train a new model.
  _addDataSet($self->{svm}, $_) for(@tset);

  return _train($self->{svm}, 0);
}

sub retrain {
  my $self = shift;

  return _train($self->{svm}, 1);
}

sub validate {
  my ($self, $nfolds) = @_;

  $nfolds = 5 if(! defined($nfolds));
  croak("NumFolds must be >= 2") if($nfolds < 2);

  return _crossValidate($self->{svm}, $nfolds + 0);
}

sub svm_type {
  my ($self, $type) = @_;

  if(defined($type)) {
    croak("Invalid SVM type: $type") if(! exists($SVM_TYPES{$type}));
    _setSVMType($self->{svm}, $SVM_TYPES{$type});
  } else {
    $SVM_TYPESR{_getSVMType($self->{svm})};
  }
}

sub kernel_type {
  my ($self, $type) = @_;

  if(defined($type)) {
    croak("Invalid kernel type: $type") if(! exists($KERNEL_TYPES{$type}));
    _setKernelType($self->{svm}, $KERNEL_TYPES{$type});
  } else {
    $KERNEL_TYPESR{_getKernelType($self->{svm})};
  }
}

sub degree {
  my $self = shift;

  (@_) ? _setDegree($self->{svm}, shift(@_) + 0) : _getDegree($self->{svm});
}

sub gamma {
  my $self = shift;

  (@_) ? _setGamma($self->{svm}, shift(@_) + 0) : _getGamma($self->{svm});
}
sub coef0 {
  my $self = shift;

  (@_) ? _setCoef0($self->{svm}, shift(@_) + 0) : _getCoef0($self->{svm});
}

sub C {
  my $self = shift;

  (@_) ? _setC($self->{svm}, shift(@_) + 0) : _getC($self->{svm});
}

sub nu {
  my $self = shift;

  (@_) ? _setNu($self->{svm}, shift(@_) + 0) : _getNu($self->{svm});
}

sub epsilon {
  my $self = shift;

  (@_) ? _setEpsilon($self->{svm}, shift(@_) + 0) : _getEpsilon($self->{svm});
}

sub display {
  my $self = shift;

  _dumpDataSet($self->{svm});
}

1;

__END__
