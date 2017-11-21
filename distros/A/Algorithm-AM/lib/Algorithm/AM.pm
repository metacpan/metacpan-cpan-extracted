package Algorithm::AM;
use strict;
use warnings;
our $VERSION = '3.11';
# ABSTRACT: Classify data with Analogical Modeling
use feature 'state';
use Carp;
our @CARP_NOT = qw(Algorithm::AM);

# Place this accessor here so that Class::Tiny doesn't generate
# a getter/setter pair.
sub training_set {
    my ($self) = @_;
    return $self->{training_set};
}

use Class::Tiny qw(
    exclude_nulls
    exclude_given
    linear
    training_set
), {
    exclude_nulls     => 1,
    exclude_given    => 1,
    linear      => 0,
};

sub BUILD {
    my ($self, $args) = @_;

    # check for invalid arguments
    my $class = ref $self;
    my %valid_attrs = map {$_ => 1}
        Class::Tiny->get_all_attributes_for($class);
    my @invalids = grep {!$valid_attrs{$_}} sort keys %$args;
    if(@invalids){
        croak "Invalid attributes for $class: " . join ' ',
            sort @invalids;
    }

    if(!exists $args->{training_set}){
        croak "Missing required parameter 'training_set'";
    }

    if('Algorithm::AM::DataSet' ne ref $args->{training_set}){
        croak 'Parameter training_set should ' .
            'be an Algorithm::AM::DataSet';
    }
    $self->_initialize();
    # delete $args->{training_set};
    return;
}

use Algorithm::AM::Result;
use Algorithm::AM::BigInt 'bigcmp';
use Algorithm::AM::DataSet;
use Import::Into;
# Use Import::Into to export classes into caller
sub import {
    my $target = caller;
    Algorithm::AM::BigInt->import::into($target, 'bigcmp');
    Algorithm::AM::DataSet->import::into($target, 'dataset_from_file');
    Algorithm::AM::DataSet::Item->import::into($target, 'new_item');
    return;
}

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Log::Any qw($log);

# do all of the classification data structure initialization here,
# as well as calling the XS initialization method.
sub _initialize {
    my ($self) = @_;

    my $train = $self->training_set;

    # compute sub-lattices sizes here so that lattice space can be
    # allocated in the _xs_initialize method. If certain features are
    # thrown out later, each sub-lattice can only get smaller, so
    # this is safe to do once here.
    my $lattice_sizes = _compute_lattice_sizes($train->cardinality);

    # sum is intitialized to a list of zeros
    @{$self->{sum}} = (0.0) x ($train->num_classes + 1);

    # preemptively allocate memory
    # TODO: not sure what this does
    @{$self->{itemcontextchain}} = (0) x $train->size;

    $self->{$_} = {} for (
        qw(
            itemcontextchainhead
            context_to_class
            contextsize
            pointers
            gang
        )
    );

    # Initialize XS data structures
    # TODO: Perl crashes unless this is saved. The XS
    # must not be increasing the reference count
    $self->{save_this} = $train->_data_classes;
    $self->_xs_initialize(
        $lattice_sizes,
        $self->{save_this},
        $self->{itemcontextchain},
        $self->{itemcontextchainhead},
        $self->{context_to_class},
        $self->{contextsize},
        $self->{pointers},
        $self->{gang},
        $self->{sum}
    );
    return;
}

sub classify {
    my ($self, $test_item) = @_;

    my $training_set = $self->training_set;
    if($training_set->cardinality != $test_item->cardinality){
        croak 'Training set and test item do not have the same ' .
            'cardinality (' . $training_set->cardinality . ' and ' .
                $test_item->cardinality . ')';
    }

    # num_feats is the number of features to be used in classification;
    # if we exclude nulls, then we need to minus the number of '='
    # found in this test item; otherwise, it's just the number of
    # columns in a single item vector
    my $num_feats = $training_set->cardinality;

    if($self->exclude_nulls){
        $num_feats -= grep {$_ eq ''} @{
            $test_item->features };
    }

    # recalculate the lattice sizes with new number of active features
    my $lattice_sizes = _compute_lattice_sizes($num_feats);
##  $activeContexts = 1 << $activeVar;

    my $nullcontext = pack "b64", '0' x 64;

    my $given_excluded = 0;
    my $test_in_training   = 0;

    # initialize classification-related variables
    # it is important to dereference rather than just
    # assigning a new one with [] or {}. This is because
    # the XS code has access to the existing reference,
    # but will be accessing the wrong variable if we
    # change it.
    %{$self->{contextsize}}             = ();
    %{$self->{itemcontextchainhead}}    = ();
    %{$self->{context_to_class}}      = ();
    %{$self->{pointers}}                = ();
    %{$self->{gang}}                    = ();
    @{$self->{itemcontextchain}}        = ();
    # big ints are used in AM.xs; these consist of an
    # array of 8 unsigned longs
    foreach (@{$self->{sum}}) {
        $_ = pack "L!8", 0, 0, 0, 0, 0, 0, 0, 0;
    }

    # calculate context labels and associated structures for
    # the entire data set
    for my $index ( 0 .. $training_set->size - 1 ) {
        my $context = _context_label(
            # Note: this must be copied to prevent infinite loop;
            # see todo note for _context_label
            [@{$lattice_sizes}],
            $training_set->get_item($index)->features,
            $test_item->features,
            $self->exclude_nulls
        );
        $self->{contextsize}->{$context}++;
        # TODO: explain itemcontextchain and itemcontextchainhead
        $self->{itemcontextchain}->[$index] =
            $self->{itemcontextchainhead}->{$context};
        $self->{itemcontextchainhead}->{$context} = $index;

        # store the class for the subcontext; if there
        # is already a different class for this subcontext,
        # then store 0, signifying heterogeneity.
        my $class = $training_set->_index_for_class(
            $training_set->get_item($index)->class);
        if ( defined $self->{context_to_class}->{$context} ) {
            if($self->{context_to_class}->{$context} != $class){
                $self->{context_to_class}->{$context} = 0;
            }
        }
        else {
            $self->{context_to_class}->{$context} = $class;
        }
    }
    # $nullcontext is all 0's, which is a context label for
    # a training item that exactly matches the test item. Exclude
    # the item if required, and set a flag that the test item was
    # found in the training set.
    if ( exists $self->{context_to_class}->{$nullcontext} ) {
        $test_in_training = 1;
        if($self->exclude_given){
           delete $self->{context_to_class}->{$nullcontext};
           $given_excluded = 1;
        }
    }
    # initialize the results object to hold all of the configuration
    # info.
    my $result = Algorithm::AM::Result->new(
        given_excluded => $given_excluded,
        cardinality => $num_feats,
        exclude_nulls => $self->exclude_nulls,
        count_method => $self->linear ? 'linear' : 'squared',
        training_set => $training_set,
        test_item => $test_item,
        test_in_train => $test_in_training,
    );

    $log->debug(${$result->config_info})
        if($log->is_debug);

    $result->start_time([ (localtime)[0..2] ]);
    $self->_fillandcount(
        $lattice_sizes, $self->linear ? 1 : 0);
    $result->end_time([ (localtime)[0..2] ]);

    unless ($self->{pointers}->{'grandtotal'}) {
        #TODO: is this tested yet?
        if($log->is_warn){
            $log->warn('No training items considered. ' .
                'No prediction possible.');
        }
        return;
    }

    $result->_process_stats(
        # TODO: after refactoring to a "guts" object,
        # just pass that in
        $self->{sum},
        $self->{pointers},
        $self->{itemcontextchainhead},
        $self->{itemcontextchain},
        $self->{context_to_class},
        $self->{gang},
        $lattice_sizes,
        $self->{contextsize}
    );
    return $result;
}

# since we split the lattice in four, we have to decide which features
# go where. Given the number of features being used, return an arrayref
# containing the number of features to be used in each of the the four
# lattices.
sub _compute_lattice_sizes {
    my ($num_feats) = @_;

    use integer;
    my @lattice_sizes;
    my $half = $num_feats / 2;
    $lattice_sizes[0] = $half / 2;
    $lattice_sizes[1] = $half - $lattice_sizes[0];
    $half         = $num_feats - $half;
    $lattice_sizes[2] = $half / 2;
    $lattice_sizes[3] = $half - $lattice_sizes[2];
    return \@lattice_sizes;
}

# Create binary context labels for a training item
# by comparing it with a test item. Each training item
# needs one binary label for each sublattice (of which
# there are currently four), but this is packed into a
# single scalar representing an array of 4 shorts (this
# format is used in the XS side).

# TODO: we have to copy lattice_sizes out of $self in order to
# iterate it. Otherwise it goes on forever. Why?
sub _context_label {
    # inputs:
    # number of active features in each lattice,
    # training item features, test item features,
    # and boolean indicating if nulls should be excluded
    my ($lattice_sizes, $train_feats, $test_feats, $skip_nulls) = @_;

    # feature index
    my $index        = 0;
    # the binary context labels for each separate lattice
    my @context_list    = ();

    for my $a (@$lattice_sizes) {
        # binary context label for a single sublattice
        my $context = 0;
        # loop through all features in the sublattice
        # assign 0 if features match, 1 if they do not
        for ( ; $a ; --$a ) {

            # skip null features if indicated
            if($skip_nulls){
                ++$index while $test_feats->[$index] eq '';
            }
            # add a 1 for mismatched variable, 0 for matched variable
            $context = ( $context << 1 ) | (
                $test_feats->[$index] ne $train_feats->[$index] );
            ++$index;
        }
        push @context_list, $context;
    }
    # a context label is an array of unsigned shorts in XS
    my $context = pack "S!4", @context_list;
    return $context;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::AM - Classify data with Analogical Modeling

=head1 VERSION

version 3.11

=head1 SYNOPSIS

 use Algorithm::AM;
 my $dataset = dataset_from_file(path => 'finnverb', format => 'nocommas');
 my $am = Algorithm::AM->new(training_set => $dataset);
 my $result = $am->classify($dataset->get_item(0));
 print @{ $result->winners };
 print ${ $result->statistical_summary };

=head1 DESCRIPTION

This module provides an object-oriented interface for
classifying single items using the analogical modeling algorithm.
To work with sets of items needing to be classified, see
L<Algorithm::AM::Batch>. To run classification from the command line
without writing your own Perl code, see L<analogize>.

This module logs information using L<Log::Any>, so if you
want automatic print-outs you need to set an adaptor. See the
L</classify> method for more information on logged data.

=head1 BACKGROUND AND TERMINOLOGY

Analogical Modeling (or AM) was developed as an exemplar-based
approach to modeling language usage, and has also been found useful
in modeling other "sticky" phenomena. AM is especially suited to this
because it predicts probabilistic occurrences instead of assigning
static labels for instances.

AM was not designed to be a classifier, but as a cognitive theory explaining
variation in human behavior. As such, though in practice it is often used
like any other machine learning classifier, there are fine theoretical points
in which it differs. As a theory of human behavior, much of the value in its
predictions lies in matching observed human behavior, including non-determinism
and degradations in accuracy caused by paucity of data.

The AM algorithm could be called a
L<probabilistic|http://en.wikipedia.org/wiki/Probabilistic_classification>,
L<instance-based|http://en.wikipedia.org/wiki/Instance-based_learning>
classifier. However, the probabilities given for each classification
are not degrees of certainty, but actual probabilities of occurring
in real usage. AM models "sticky" phenomena as being intrinsically
sticky, not as deterministic phenomena that just require more data to be
predicted perfectly.

Though it is possible to choose an outcome probabilistically, in practice
users are generally interested in either the full predicted probability
distribution
or the outcome with the highest probability. The entire outcome probability
distribution can be retrieved via
L<Algorithm::AM::Result/scores_normalized>. The highest probability outcome
can be retrieved via L<Algorithm::AM::Result/winners>.
If you're only interested in classification accuracy based on the highest
probability outcome (treating AM like any other classification algorithm),
use L<Algorithm::AM::Result/result>.
See L<Algorithm::AM::Result> for other types of information available
after classification. See L<Algorithm::AM::algorithm> for details
on the actual mechanism of classification.

AM practitioners often use specialized terminolgy, but most of this
terminology has more common machine learning terminology equivalents.
This software tries to use the specialized terminology for end-user-facing
tasks like reports or command-line API's.

AM uses the term "exemplar" where ML uses "training instance". Historically
the AM software used the word "item" to refer to either training or test
instances, and that term is retained here. AM has "outcomes" and ML has
"class labels" (we use the latter). Finally, AM practitioners refer to
"variables", and we use the ML term "feature" here.

=head1 EXPORTS

When this module is imported, it also imports the following:

=over

=item L<Algorithm::AM::Result>

=item L<Algorithm::AM::DataSet>

Also imports L<Algorithm::AM::DataSet/dataset_from_file>.

=item L<Algorithm::AM::DataSet::Item>

Also imports L<Algorithm::AM::DataSet::Item/new_item>.

=item L<Algorithm::AM::BigInt>

Also imports L<Algorithm::AM::BigInt/bigcmp>.

=back

=head1 METHODS

=for Pod::Coverage BUILD

=head2 C<new>

Creates a new instance of an analogical modeling classifier. This
method takes named parameters which set state described in the
documentation for the relevant methods. The only required parameter
is L</training_set>, which should be an instance of
L<Algorithm::AM::DataSet>, and which defines the set of items used
for training during classification. All of the accepted parameters
are listed below:

=over

=item L</training_set>

=item L</exclude_nulls>

=item L</exclude_given>

=item L</linear>

=back

=head2 C<training_set>

Returns (but will not set) the dataset used for training. This is
an instance of L<Algorithm::AM::DataSet>.

=head2 C<exclude_nulls>

Get/set a boolean value indicating whether features with null
values in the test item should be ignored. If false, they will be
treated as having a specific value representing null.
Defaults to true.

=head2 C<exclude_given>

Get/set a boolean value indicating whether the test item should be
removed from the training set if it is found there during
classification. Defaults to true.

=head2 C<linear>

Get/set a boolean value indicating whether the analogical set should
be computed using I<occurrences> (linearly) or I<pointers>
(quadratically). To understand what this means, you should read the
L<algorithm|Algorithm::AM::algorithm> page. A false value indicates
quadratic counting. Defaults to false.

=head2 C<classify>

  $am->classify(new_item(features => ['a','b','c']));

Using the analogical modeling algorithm, this method classifies
the input test item and returns a L<Result|Algorithm::AM::Result>
object.

L<Log::Any> is used for logging. The full classification configuration
is logged at the info level. A notice is printed at the warning
level if no training items can be compared with the test item,
preventing any classification.

=head1 HISTORY

Initially, Analogical Modeling was implemented as a Pascal program.
Subsequently, it was ported to Perl, with substantial improvements
made in 2000. In 2001, the core of the algorithm was rewritten in C,
while the parsing, printing, and statistical routines remained in C;
this was accomplished by embedding a Perl interpreter into the C code.

In 2004, the algorithm was again rewritten, this time in order to
handle more features and large data sets. The algorithm breaks the
supracontextual lattice into the direct product of four smaller ones,
which the algorithm manipulates individually before recombining.
These lattices can be manipulated in parallel when using the right
hardware, and so the module was named C<AM::Parallel>. This
implementation was written with the core lattice-filling algorithm in
XS, and hooks were provided to help the user create custom reports
and control classification dynamically.

The present version has been renamed to C<Algorithm::AM>, which seemed
a better fit for CPAN. While the XS has largely remained intact, the
Perl code has been completely reorganized and updated to be both more
"modern" and modular. Most of the functionality of C<AM::Parallel>
remains.

=head1 SEE ALSO

The <home page|http://humanities.byu.edu/am/> for Analogical Modeling
includes information about current research and publications, as well as
sample data sets.

The L<Wikipedia article|http://en.wikipedia.org/wiki/Analogical_modeling>
has details and even illustrations on analogical modeling.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/garfieldnate/Algorithm-AM/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/garfieldnate/Algorithm-AM>

  git clone https://github.com/garfieldnate/Algorithm-AM.git

=head1 AUTHOR

Theron Stanford <shixilun@yahoo.com>, Nathan Glenn <garfieldnate@gmail.com>

=head1 CONTRIBUTORS

=for stopwords Nathan Glenn Nick Logan

=over 4

=item *

Nathan Glenn <nathan-gary.glenn@trivago.com>

=item *

Nick Logan <nlogan@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Royal Skousen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
