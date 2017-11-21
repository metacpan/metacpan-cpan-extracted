package Algorithm::AM::Batch;
use strict;
use warnings;
our $VERSION = '3.11';
# ABSTRACT: Classify items in batch mode
use feature 'state';
use Carp;
use Log::Any qw($log);
our @CARP_NOT = qw(Algorithm::AM::Batch);

# Place this accessor here so that Class::Tiny doesn't generate
# a getter/setter pair.
sub test_set {
    my ($self) = @_;
    return $self->{test_set};
}

use Class::Tiny qw(
    training_set

    exclude_nulls
    exclude_given
    linear
    probability
    repeat
    max_training_items

    begin_hook
    begin_test_hook
    begin_repeat_hook
    training_item_hook
    end_repeat_hook
    end_test_hook
    end_hook

    test_set
), {
    exclude_nulls     => 1,
    exclude_given    => 1,
    linear      => 0,
    probability => 1,
    repeat      => 1,
};

use Algorithm::AM;
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
    if(!(ref $args) || !$args->{training_set}->isa(
            'Algorithm::AM::DataSet')){
        croak 'Parameter training_set should be an ' .
            'Algorithm::AM::DataSet';
    }
    for(qw(
        begin_hook
        begin_test_hook
        begin_repeat_hook
        training_item_hook
        end_repeat_hook
        end_test_hook
        end_hook
    )){
        if(exists $args->{$_} and 'CODE' ne ref $args->{$_}){
            croak "Input $_ should be a subroutine";
        }
    }

    return;
}

sub classify_all {
    my ($self, $test_set) = @_;

    if(!$test_set || 'Algorithm::AM::DataSet' ne ref $test_set){
        croak q[Must provide a DataSet to classify_all];
    }
    if($self->training_set->cardinality != $test_set->cardinality){
        croak 'Training and test sets do not have the same ' .
            'cardinality (' . $self->training_set->cardinality .
                ' and ' . $test_set->cardinality . ')';
    }
    $self->_set_test_set($test_set);

    if($self->begin_hook){
        $self->begin_hook->($self);
    }

    # save the result objects from all items, all iterations, here
    my @all_results;

    foreach my $item_number (0 .. $test_set->size - 1) {
        if($log->is_debug){
            $log->debug('Test items left: ' .
                $test_set->size + 1 - $item_number);
        }
        my $test_item = $test_set->get_item($item_number);
        # store the results just for this item
        my @item_results;

        if($self->begin_test_hook){
            $self->begin_test_hook->($self, $test_item);
        }

        if($log->is_debug){
            my ( $sec, $min, $hour ) = localtime();
            $log->info(
                sprintf( "Time: %2s:%02s:%02s\n", $hour, $min, $sec) .
                $test_item->comment . "\n" .
                sprintf( "0/$self->{repeat}  %2s:%02s:%02s",
                    $hour, $min, $sec ) );
        }

        my $iteration = 1;
        while ( $iteration <= $self->repeat ) {
            if($self->begin_repeat_hook){
                $self->begin_repeat_hook->(
                    $self, $test_item, $iteration);
            }

            # this sets excluded_items
            my ($training_set, $excluded_items) = $self->_make_training_set(
                $test_item, $iteration);

            # classify the item with the given training set and
            # configuration
            my $am = Algorithm::AM->new(
                training_set => $training_set,
                exclude_nulls => $self->exclude_nulls,
                exclude_given => $self->exclude_given,
                linear => $self->linear,
            );
            my $result = $am->classify($test_item);

            _log_result($result)
                if($log->is_info);

            if($log->is_info){
                my ( $sec, $min, $hour ) = localtime();
                $log->info(
                    sprintf(
                        $iteration . '/' . $self->repeat .
                        '  %2s:%02s:%02s',
                        $hour, $min, $sec
                    )
                );
            }

            if($self->end_repeat_hook){
                # pass in self, test item, data, and result
                $self->end_repeat_hook->($self, $test_item,
                    $iteration, $excluded_items, $result);
            }
            push @item_results, $result;
            $iteration++;
        }

        if($self->end_test_hook){
            $self->end_test_hook->($self, $test_item, @item_results);
        }

        push @all_results, @item_results;
    }

    if($log->is_info){
        my ( $sec, $min, $hour ) = localtime();
        $log->info(
            sprintf( "Time: %2s:%02s:%02s", $hour, $min, $sec ) );
    }

    if($self->end_hook){
        $self->end_hook->($self, @all_results);
    }
    $self->_set_test_set(undef);
    return @all_results;
}

# log the summary printouts from the input result object
sub _log_result {
    my ($result) = @_;

    $log->info(${$result->statistical_summary});

    $log->info(${$result->analogical_set_summary()});

    if($log->is_debug){
        $log->debug(${ $result->gang_summary(1) });
    }elsif($log->is_info){
        $log->info(${ $result->gang_summary(0) })
    }
    return;
}

# create the training set for this iteration, calling training_item_hook and
# updating excluded_items along the way
sub _make_training_set {
    my ($self, $test_item, $iteration) = @_;
    my $training_set;

    # $self->_set_excluded_items([]);
    my @excluded_items;
    # Cap the amount of considered data if specified
    my $max = defined $self->max_training_items ?
        int($self->max_training_items) :
        $self->training_set->size;

    # use the original DataSet object if there are no settings
    # that would trim items from it
    if(!$self->training_item_hook &&
            ($self->probability == 1) &&
            $max >= $self->training_set->size){
        $training_set = $self->training_set;
    }else{
        # otherwise, make a new set with just the selected
        # items
        $training_set = Algorithm::AM::DataSet->new(
            cardinality => $self->training_set->cardinality);

        # don't try to add more items than we have!
        my $num_items = ($max > $self->training_set->size) ?
            $self->training_set->size :
            $max;
        for my $data_index ( 0 .. $num_items - 1 ) {
            my $training_item =
                $self->training_set->get_item($data_index);
            # skip this data item if the training_item_hook returns false
            if($self->training_item_hook &&
                    !$self->training_item_hook->($self,
                        $test_item, $iteration, $training_item)
                    ){
                push @excluded_items, $training_item;
                next;
            }
            # skip this data item with probability $self->{probability}
            if($self->probability != 1 &&
                    rand() > $self->probability){
                push @excluded_items, $training_item;
                next;
            }
            $training_set->add_item($training_item);
        }
    }
    # $self->_set_excluded_items(\@excluded_items);
    return ($training_set, \@excluded_items);
}

sub _set_test_set {
    my ($self, $test_set) = @_;
    $self->{test_set} = $test_set;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::AM::Batch - Classify items in batch mode

=head1 VERSION

version 3.11

=head1 C<SYNOPSIS>

  use Algorithm::AM::Batch;
  my $dataset = dataset_from_file(path => 'finnverb', format => 'nocommas');
  my $batch = Algorithm::AM::Batch->new(
    training_set => $dataset,
    # print the result of each classification as they are provided
    end_test_hook => sub {
      my ($batch, $test_item, $result) = @_;
      print $test_item->comment . ' ' . $result->result . "\n";
    }
  );
  my @results = $batch->classify_all($dataset);

=head1 C<DESCRIPTION>

Batch provides a way to classify entire data sets by repeatedly calling
L<classify|Algorithm::AM/classify> with the provided configuration.
Hooks are also provided so that the training set and classification
parameters can be changed over time. All of the action happens in
L</classify_all>.

=head1 EXPORTS

When this module is imported, it also imports the following:

=over

=item L<Algorithm::AM>

=item L<Algorithm::AM::Result>

=item L<Algorithm::AM::DataSet>

Also imports the L<Algorithm::AM::DataSet/dataset_from_file> function.

=item L<Algorithm::AM::DataSet::Item>

Also imports the L<Algorithm::AM::DataSet::Item/new_item> function.

=item L<Algorithm::AM::BigInt>

Also imports the L<Algorithm::AM::BigInt/bigcmp> function.

=back

=head1 METHODS

=for Pod::Coverage BUILD

=head2 C<new>

Creates a new object instance. This method takes named parameters
which call the methods described in the relevant documentation sections.
The only required parameter is L</training_set>, which should be an
instance of L<Algorithm::AM::DataSet>, and which provides a pool of
items to be used for training during classification. All of the
accepted parameters are listed below:

=over

=item L</training_set>

=item L</repeat>

=item L</probability>

=item L</max_training_items>

=item L</exclude_nulls>

=item L</exclude_given>

=item L</linear>

=back

=head2 C<training_set>

Returns the dataset used for training.

=head2 C<test_set>

Returns the test set currently providing the source of items to
L</classify_all>. Before and after classify_all, this returns undef, and
so is only useful when called from inside one of the hook subroutines.

=head2 C<repeat>

Determines how many times each individual test item will be analyzed.
As the analogical modeling algorithm is deterministics, it only makes
sense to use this if the training set is modifed somehow during each
iteration, i.e. via L</probability> or L</training_item_hook>. The
default value is 1.

=head2 C<probability>

Get/set the probabibility that any one training item would be included
among the training items used during classification, which is 1 by
default.

=head2 C<max_training_items>

Get/set the maximum number of items considered for addition to the
training set. Note that this is the number I<considered>, not actually
added, so combined with L</probability> or I</training_item_hook> your
training set could be smaller than the amount specified.

=head2 C<exclude_nulls>

This is passed directly to the L<new|Algorithm::AM/new> method of
L<Algorithm::AM> during each classification in the L</classify_all>
method.

=head2 C<exclude_given>

This is passed directly to the L<new|Algorithm::AM/new> method of
L<Algorithm::AM> during each classification in the L</classify_all>
method.

=head2 C<linear>

This is passed directly to the L<new|Algorithm::AM/new> method of
L<Algorithm::AM> during each classification in the L</classify_all>
method.

=head2 C<classify_all>

Using the analogical modeling algorithm, this method classifies
the test items in the project and returns a list of
L<Result|Algorithm::AM::Result> objects.

L<Log::Any> is used to log information about the current progress and
timing. The statistical summary, analogical set, and gang summary
(without items listed) are logged at the info level, and the full
gang summary with items listed is logged at the debug level.

Hooks are provided to the user for monitoring or modifying
classification configuration. These hooks may be passed into the
object constructor or set via one of the accessor methods.
Batch classification proceeds as follows:

  call begin_hook
  loop all test set items
    call begin_test_hook
    repeat X times, where X is specified by the "repeat" setting
      call begin_repeat_hook
      create a training set;
          - for each item in the provided training set,
          up to max_training_items
        exclude the item with probability 1 - probability
        exclude the item if specified via training_item_hook
      classify the item with the given training set
      call end_repeat_hook
    call end_test_hook
  call end_hook

The Batch object itself is passed to these hooks, so the user is free
to change settings such as L</probability> or L</max_training_items>,
or even add training data, at any point. Other information is passed to
these hooks as well, as detailed in the method documentation.

=head2 C<begin_hook>

  $batch->begin_hook(sub {
    my ($batch) = @_;
    $batch->probability(.5);
  });

This hook is called first thing in the L</classify_all> method, and is
given the Batch object instance.

=head2 C<begin_test_hook>

  $batch->begin_repeat_hook(sub {
    my ($batch, $test_item) = @_;
    $batch->probability(.5);
    print $test_item->comment . "\n";
  });

This hook is called by L</classify_all> before any iterations of
classification start for each test item. It is provided with the Batch
object instance and the test item.

=head2 C<begin_repeat_hook>

  $batch->begin_repeat_hook(sub {
    my ($batch, $test_item, $iteration) = @_;
    $batch->probability(.5);
    print $test_item->comment . "\n";
    print "I'm on iteration $iteration\n";
  });

This hook is called during L</classify_all> at the beginning of each
iteration of classification of a test item. It is provided with
the Batch object instance, the test item, and the iteration number,
which will vary between 1 and the setting for L</repeat>.

=head2 C<training_item_hook>

  $batch->begin_repeat_hook(sub {
    my ($batch, $test_item, $iteration, $training_item) = @_;
    $batch->probability(.5);
    print $test_item->comment . "\n";
    print "I'm on iteration $iteration\n";
    if($training_item->comment eq 'include me!'){
      return 1;
    }else{
      return 0;
    }
  });

This hook is called by L</classify_all> while populating a training
set during each iteration of classification.  It is provided with
the Batch object instance, the test item, the iteration number, and
an item which may be included in the training set. If the return value
is true, then the item will be included in the training set; otherwise,
it will not.

=head2 C<end_repeat_hook>

  $batch->begin_repeat_hook(sub {
    my ($batch, $test_item, $iteration, $excluded_items, $result) = @_;
    $batch->probability(.5);
    print $test_item->comment . "\n";
    print "I finished iteration $iteration\n";
    print 'I excluded ' . scalar @$excluded_items .
      " items from training\n";
    print ${$result->statistical_summary};
  });

This hook is called during L</classify_all> at the end of each
iteration of classification of a test item. It is provided with
the Batch object instance, the test item, the iteration number, an
array ref containing training items excluded from the training set, and
the result object returned by L<classify|Algorithm::AM/classify>.

=head2 C<end_test_hook>

  $batch->begin_repeat_hook(sub {
    my ($batch, $test_item, @results) = @_;
    $batch->probability(.5);
    print $test_item->comment . "\n";
    my $iterations = @results;
    my $correct = 0;
    for my $result (@result){
      $correct++ if $result->result ne 'incorrect';
    }
    print 'Item ' . $item->comment .
      " correct $correct/$iterations times\n";
  });

This hook is called by L</classify_all> after all classifications
of a single item are  finished. It is provided with the Batch
object instance as well as a list of the
L<Result|Algorithm::AM::Result> objects returned by
L<Algorithm::AM/classify> during each iteration of classification.

=head2 C<end_hook>

  $batch->end_hook(sub {
    my ($batch, @results) = @_;
    for my $result(@results){
      print ${$result->statistical_summary};
    }
  });

This hook is called after all classifications are finished. It is
provided with the Batch object instance as well as a list of all of
the L<Result|Algorithm::AM::Result> objects returned by
L<Algorithm::AM/classify>.

=head1 AUTHOR

Theron Stanford <shixilun@yahoo.com>, Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Royal Skousen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
