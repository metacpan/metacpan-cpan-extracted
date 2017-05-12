package Algorithm::SVMLight;

use strict;
use DynaLoader ();

use vars qw($VERSION @ISA);

$VERSION = '0.09';
@ISA = qw(DynaLoader);
__PACKAGE__->bootstrap( $VERSION );


sub new {
  my $package = shift;
  my $self = bless {
		    @_,
		    features => {},
		    rfeatures => [undef],
		   }, $package;
  $self->_xs_init;
  $self->_param_init(@_);
  return $self;
}

my %params = map {$_,1}
  qw(
     type
     svm_c
     eps
     svm_costratio
     transduction_posratio
     biased_hyperplane
     sharedslack
     svm_maxqpsize
     svm_newvarsinqp
     kernel_cache_size
     epsilon_crit
     epsilon_shrink
     svm_iter_to_shrink
     maxiter
     remove_inconsistent
     skip_final_opt_check
     compute_loo
     rho
     xa_depth
     predfile
     alphafile

     kernel_type
     poly_degree
     rbf_gamma
     coef_lin
     coef_const
     custom
    );


sub _param_init {
  my ($self, %args) = @_;

  while (my ($k, $v) = each %args) {
    if (exists $params{$k}) {
      my $method = "set_$k";
      $self->$method($v);
    } else {
      die "Unknown parameter '$k'\n";
    }
  }
}

sub is_trained {
  my $self = shift;
  return exists $self->{_model};
}

sub feature_names {
  my $self = shift;
  return keys %{ $self->{features} };
}

sub predict {
  my ($self, %params) = @_;
  for ('attributes') {
    die "Missing required '$_' parameter" unless exists $params{$_};
  }
  
  my (@values, @indices);
  while (my ($key) = each %{ $params{attributes} }) {
    push @indices, $self->{features}{$key} if exists $self->{features}{$key};
  }

  @indices = sort {$a <=> $b} @indices;
  foreach my $i (@indices) {
    push @values, $params{attributes}{ $self->{rfeatures}[$i] };
  }

  # warn "Predicting: (@indices), (@values)\n";
  $self->predict_i(\@indices, \@values);
}

sub add_instance {
  my ($self, %params) = @_;
  for ('attributes', 'label') {
    die "Missing required '$_' parameter" unless exists $params{$_};
  }
  for ($params{label}) {
    die "Label must be a real number, not '$_'" unless /^-?\d+(\.\d+)?$/;
  }
  
  my @values;
  my @indices;
  while (my ($key, $val) = each %{ $params{attributes} }) {
    unless ( exists $self->{features}{$key} ) {
      $self->{features}{$key} = 1 + keys %{ $self->{features} };
      push @{ $self->{rfeatures} }, $key;
    }
    push @indices, $self->{features}{$key};
  }

  @indices = sort { $a <=> $b} @indices;
  foreach my $i (@indices) {
    push @values, $params{attributes}{ $self->{rfeatures}[$i] };
  }

  #warn "Adding document: (@indices), (@values) => $params{label}\n";
  my $id = exists $params{query_id} ? $params{query_id} : 0;
  my $slack = exists $params{slack_id} ? $params{slack_id} : 1;
  my $cost = exists $params{cost_factor} ? $params{cost_factor} : 1.0;
  $self->add_instance_i($params{label}, "", \@indices, \@values, $id, $slack, $cost);
}

sub write_model {
  my ($self, $file) = @_;
  $self->_write_model($file);

  # Write a footer line
  if ( my $numf = keys %{ $self->{features} } ) {
    open my($fh), ">> $file" or die "Can't write footer to $file: $!";
    print $fh ('#rfeatures: [undef, ' ,
	       join( ', ', map _escape($self->{rfeatures}[$_]), 1..$numf ),
	       "]\n");
  }
}

sub read_model {
  my ($self, $file) = @_;
  $self->_read_model($file);

  # Read the footer line
  open my($fh), $file or die "Can't read $file: $!";
  local $_;
  while (<$fh>) {
    next unless /^#rfeatures: (\[.*\])$/;
    my $rf = $self->{rfeatures} = eval $1;
    die $@ if $@;
    $self->{features} = { map {$rf->[$_], $_} 1..$#$rf };
  }
}

sub _escape {
  local $_ = shift;
  s/([\\'])/\\$1/g;
  s/\n/\\n/g;
  s/\r/\\r/g;
  return "'$_'";
}

1;
__END__

=head1 NAME

Algorithm::SVMLight - Perl interface to SVMLight Machine-Learning Package

=head1 SYNOPSIS

  use Algorithm::SVMLight;
  my $s = new Algorithm::SVMLight;
  
  $s->add_instance
    (attributes => {foo => 1, bar => 1, baz => 3},
     label => 1);
  
  $s->add_instance
    (attributes => {foo => 2, blurp => 1},
     label => -1);
  
  ... repeat for several more instances, then:
  $s->train;

  # Find results for unseen instances
  my $result = $s->predict
    (attributes => {bar => 3, blurp => 2});


=head1 DESCRIPTION

This module implements a perl interface to Thorsten Joachims' SVMLight
package:

=over 4

SVMLight is an implementation of Vapnik's Support Vector Machine
[Vapnik, 1995] for the problem of pattern recognition, for the problem
of regression, and for the problem of learning a ranking function. The
optimization algorithms used in SVMlight are described in [Joachims,
2002a ]. [Joachims, 1999a]. The algorithm has scalable memory
requirements and can handle problems with many thousands of support
vectors efficiently.

 -- http://svmlight.joachims.org/

=back

Support Vector Machines in general, and SVMLight specifically,
represent some of the best-performing Machine Learning approaches in
domains such as text categorization, image recognition, bioinformatics
string processing, and others.

For efficiency reasons, the underlying SVMLight engine indexes features by integers, not
strings.  Since features are commonly thought of by name (e.g. the
words in a document, or mnemonic representations of engineered
features), we provide in C<Algorithm::SVMLight> a simple mechanism for
mapping back and forth between feature names (strings) and feature
indices (integers).  If you want to use this mechanism, use the
C<add_instance()> and C<predict()> methods.  If not, use the
C<add_instance_i()> (or C<read_instances()>) and C<predict_i()>
methods.

=head1 INSTALLATION

For installation instructions, please see the F<README> file included
with this distribution.

=head1 METHODS

=over 4

=item new(...)

Creates a new C<Algorithm::SVMLight> object and returns it.  Any named
arguments that correspond to SVM parameters will cause their
corresponding C<set_I<***>()> method to be invoked:

  $s = Algorithm::SVMLight->new(
         type => 2,              # Regression model
         biased_hyperplane => 0, # Nonbiased
         kernel_type => 3,       # Sigmoid
  );

See the C<set_I<***>(...)> method for a list of such parameters.

=item set_I<***>(...)

The following parameters can be set by using methods with their
corresponding names - for instance, the C<maxiter> parameter can be
set by using C<set_maxiter($x)>, where C<$x> is the new desired value.

  Learning parameters:
     type
     svm_c
     eps
     svm_costratio
     transduction_posratio
     biased_hyperplane
     sharedslack
     svm_maxqpsize
     svm_newvarsinqp
     kernel_cache_size
     epsilon_crit
     epsilon_shrink
     svm_iter_to_shrink
     maxiter
     remove_inconsistent
     skip_final_opt_check
     compute_loo
     rho
     xa_depth
     predfile
     alphafile

  Kernel parameters:
     kernel_type
     poly_degree
     rbf_gamma
     coef_lin
     coef_const
     custom

For an explanation of these parameters, you may be interested in
looking at the F<svm_common.h> file in the SVMLight distribution.

It would be a good idea if you only set these parameters via arguments
to C<new()> (see above) or right after calling C<new()>, since I don't
think the underlying C code expects them to change in the middle of a
process.

=item add_instance(label => $x, attributes => \%y)

Adds a training instance to the set of instances which will be used to
train the model.  An C<attributes> parameter specifies a hash of
attribute-value pairs for the instance, and a C<label> parameter
specifies the label.  The label must be a number, and typically it
should be C<1> for positive training instances and C<-1> for negative
training instances.  The keys of the C<attributes> hash should be
strings, and the values should be numbers (the values of each attribute).

All training instances share the same attribute-space; if an attribute
is unspecified for a certain instance, it is equivalent to specifying
a value of zero.  Typically you can save a lot of memory (and
potentially training time) by omitting zero-valued attributes.

Each training instance may have a "cost factor" assigned to it,
indicating the relative cost of misclassification of the instance.
The default is a cost of 1.0; to assign a different cost, pass a
C<cost_factor> parameter with the desired value.

When using a ranking SVM, you may also pass a C<query_id> parameter,
whose integer value will identify the group of instances in which this
instance belongs for ranking purposes.

Finally, a C<slack_id> parameter may also be passed and it will become
the C<slackid> member of the underlying C<DOC> C struct, used in an
"OPTIMIZATION" SVM (C<type==4>).

=item add_instance_i($label, $name, \@indices, \@values, $query_id=0, $slack_id=0, $cost_factor=1.0)

This is just like C<add_instance()>, but bypasses all the
string-to-integer mapping of feature names.  Use this method when you
already have your features represented as integers.  The C<$label>
parameter must be a number (typically C<1> or C<-1>), and the
C<@indices> and C<@values> arrays must be parallel arrays of indices
and their corresponding values.  Furthermore, the indices must be
positive integers and given in strictly increasing order.

If you like C<add_instance_i()>, I've got a C<predict_i()> I bet
you'll just love.

=item read_instances($file)

An alternative to calling C<add_instance_i()> for each instance is to
organize a collection of training data into SVMLight's standard
"example_file" format, then call this C<read_instances()> method to
import the data.  Under the hood, this calls SVMLight's
C<read_documents()> C function.  When it's convenient for you to
organize the data in this manner, you may see speed improvements.

=item ranking_callback(\&function)

When using a ranking SVM, it is possible to customize the cost of
ranking each pair of instances incorrectly by supplying a custom Perl
callback function.

For two instances C<i> and C<j>, the custom function will receive four
arguments: the C<rankvalue> of instance C<i> and C<j>, and the
C<costfactor> of instance C<i> and C<j>.  It should return a real
number indicating the cost.

By default, SVMLight will use an internal C function assigning a cost
of the average of the C<costfactor>s for the two instances.

=item train()

After a sufficient number of instances have been added to your model,
call C<train()> in order to actually learn the underlying
discriminative Machine Learning model.

Depending on the number of instances (and to a lesser extent the total
number of attributes), this method might take a while.  If you want to
train the model only once and save it for later re-use in a different
context, see the C<write_model()> and C<read_model()> methods.

=item is_trained()

Returns a boolean value indicating whether or not C<train()> has been
called on this model.

=item predict(attributes => \%y)

After C<train()> has been called, the model may be applied to
previously-unseen combinations of attributes.  The C<predict()> method
accepts an C<attributes> parameter just like C<add_instance()>, and
returns its best prediction of the label that would apply to the given
attributes.  The sign of the returned label (positive or negative)
indicates whether the new instance is considered a positive or
negative instance, and the magnitude of the label corresponds in some
way to the confidence with which the model is making that assertion.

=item predict_i(\@indices, \@values)

This is just like C<predict()>, but bypasses all the string-to-integer
mapping of feature names.  See also C<add_instance_i()>.

=item write_model($file)

Saves the given trained model to the file C<$file>.  The model may
later be re-loaded using the C<read_model()> method.  The model is
written using SVMLight's C<write_model()> C function, so it will be
fully compatible with SVMLight command-line tools like
C<svm_classify>.

=item read_model($file)

Reads a model that has previously been written with C<write_model()>:

  my $m = Algorithm::SVMLight->new();
  $m->read_model($file);

The model file is read using SVMLight's C<read_model()> C function, so
if you want to, you could initially create the model with one of
SVMLight's command-line tools like C<svm_learn>.

=item get_linear_weights()

After training a linear model (or reading in a model file), this
method will return a reference to an array containing the linear
weights of the model.  This can be useful for model inspection, to see
which features are having the greatest impact on decision-making.

 my $arrayref = $m->get_linear_weights();

The first element (position 0) of the array will be the threshold
C<b>, and the rest of the elements will be the weights themselves.
Thus from 1 upward, the indices align with SVMLight's internal
indices.

If the model has not yet been trained, or if the kernel type is not
linear, an exception will be thrown.

=item feature_names()

Returns a list of feature names that have been fed to
C<add_instance()> as keys of the C<attribute> parameter, or in a
scalar context the number of such names.

=item num_features()

Returns the number of features known to this model.  Note that if you
use C<add_instance_i()> or C<read_instances()>, some of the features
may never actually have been I<seen> before, because you could add
instances with only indices 2, 5, and 37, never having added any
instances with the indices in between, but C<num_features()> will
return 37 in this case.  This is because after training, an instance
could be passed to the C<predict()> method with real values for these
previously unseen features.  If you just use C<add_instance()>
instead, you'll probably never run into this issue, and in a scalar
context C<num_features()> will look just like C<feature_names()>.

=item num_instances()

Returns the number of training instances known to the model.  It
should be fine to call this method either before or after training
actually occurs.

=back

=head1 SEE ALSO

L<Algorithm::NaiveBayes>, L<AI::DecisionTree>

L<http://svmlight.joachims.org/>

=head1 AUTHOR

Ken Williams, E<lt>kwilliams@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The C<Algorithm::SVMLight> perl interface is copyright (C) 2005-2008
Thomson Legal & Regulatory, and written by Ken Williams.  It is free
software; you can redistribute it and/or modify it under the same
terms as C<perl> itself.

Thorsten Joachims and/or Cornell University of Ithaca, NY control the
copyright of SVMLight itself - you will find full copyright and
license information in its distribution.  You are responsible for
obtaining an appropriate license for SVMLight if you intend to use
C<Algorithm::SVMLight>.  In particular, please note that SVMLight "is
granted free of charge for research and education purposes. However
you must obtain a license from the author to use it for commercial
purposes."

To avoid any copyright clashes, the F<SVMLight.patch> file distributed
here is granted under the same license terms as SVMLight itself.

=cut
