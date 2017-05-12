##################################################
package Algorithm::Bucketizer;
##################################################
# Documentation attached as POD below
##################################################

use 5.006;
use strict;
use warnings;

our $VERSION = '0.13';

##################################################
sub new {
##################################################
    my($class, @options) = @_;

    my $self = {     # Overwritable parameters
                 bucketsize      => 100,
                 algorithm       => "simple",
                 add_buckets     => 1,

                 @options,
           
                     # Internal stuff

                   # index (0-..) of bucket we're currently 
                   # inserting items into
                 cur_bucket_idx  => 0,

                 buckets         => [],
               };

    bless $self, $class;
}

##################################################
sub add_item {
##################################################
    my($self, $item, $size) = @_;

      # in 'simple' mode, we continue with the bucket we
      # inserted the last item into
    my $first = $self->{cur_bucket_idx};

      # retry tries all buckets
    $first = 0 if $self->{algorithm} eq 'retry';

        # Check if it fits in any existing bucket.
    for(my $idx = $first; exists $self->{buckets}->[$idx]; $idx++) {

        my $bucket = $self->{buckets}->[$idx];

        if($bucket->probe_item($item, $size)) {
            $bucket->add_item($item, $size);
            $self->{ cur_bucket_idx } = $idx;
            return $bucket;
        }
    }

        # It didn't fit anywhere. Create a new bucket.
    return undef unless $self->{add_buckets};
    my $bucket = $self->add_bucket();

    if($bucket->probe_item($item, $size)) {
        $bucket->add_item($item, $size);
        $self->{ cur_bucket_idx } = $bucket->{ idx };
        return $bucket;
    }

    # It didn't even fit in a new bucket. Forget it.
    return undef;
}

##################################################
sub current_bucket_idx {
##################################################
    my($self, $idx ) = @_;

    if( defined $idx ) {
        $self->{ cur_bucket_idx } = $idx;
    }

    return $self->{ cur_bucket_idx };
}

###########################################
sub add_bucket {
###########################################
    my($self, @options) = @_;

    my $bucket = Algorithm::Bucketizer::Bucket->new(
        maxsize => $self->{bucketsize},
        idx     => $#{ $self->{ buckets } } + 1,
        @options,
    );

      # adding a bucket won't increase the current bucket index,
      # just append it to the end of the chain
    push @{$self->{buckets}}, $bucket;

    return $bucket;
}

##################################################
sub buckets {
##################################################
    my($self) = @_;
   
    return @{$self->{buckets}};
}

##################################################
sub prefill_bucket {
##################################################
    my($self, $bucket_idx, $item, $size) = @_;
   
    my $bucket = $self->{buckets}->[$bucket_idx];

        # Create the bucket if it doesn't exist yet
    if(!exists $self->{buckets}->[$bucket_idx]) {
        $bucket = Algorithm::Bucketizer::Bucket->new(
            maxsize => $self->{bucketsize},
            idx     => $bucket_idx,
        );
        $self->{buckets}->[$bucket_idx] = $bucket;
        $self->{cur_bucket_idx}  = $bucket_idx;
    }

    $bucket->add_item($item, $size);
    return $bucket;
}

##################################################
sub optimize {
##################################################
    my($self, %options) = @_;

    $options{algorithm} = "random" unless defined $options{algorithm};
    $options{maxtime}   = 3 if exists $options{maxtime} and 
                                       $options{maxtime} < 3;
    my($next);

    my @items = $self->items();

        # Create next() closure for appropriate variation algorithm
    if($options{algorithm} eq "brute_force") {
        require Algorithm::Permute;
        my $p = Algorithm::Permute->new([@items]);
        $next = sub { return $p->next };
    } elsif($options{algorithm} eq "random") {
        # fisher-yates shuffle
        $next = sub { $self->shuffle(@items) };
        die "Need maxrounds|maxtime for 'random' optimizer" 
            if !exists $options{maxrounds} and !exists $options{maxtime};
    }

    my $round = 0;

    my $minbuckets;
    my @minitems;
    my $start_time = time();

        # Run through different setups and determine the one
        # requiring a minimum of buckets.
    while (my @res = $next->()) {

       my $b = Algorithm::Bucketizer->new(bucketsize => $self->{bucketsize},
                                          algorithm  => 'retry');
       for (@res) {
           my($name, $weight) = @$_;
           $b->add_item($name, $weight);
       }

       my $nof_buckets = scalar $b->buckets;

       if(! defined $minbuckets or $nof_buckets < $minbuckets) {
           $minbuckets = $nof_buckets;
           @minitems = @res;
       }

       ++$round;
       last if exists $options{maxrounds} and $round >= $options{maxrounds};
       last if exists $options{maxtime} and 
           time() > $start_time + $options{maxtime};
    }

    # We should have a ideal distribution now, nuke all buckets and refill
    $self->{buckets}         = [];
    $self->{cur_bucket_idx}  = 0;
    $self->{algorithm}       = "retry"; # We're optimizing

    for (@minitems) {
        my($name, $weight) = @$_;
        $self->add_item($name, $weight);
    }
}

##################################################
sub items {
##################################################
    my($self) = @_;

    my @items = ();

    for my $bucket (@{$self->{buckets}}) {
        for(my $idx = 0; exists $bucket->{items}->[$idx]; $idx++) {
            push @items, [$bucket->{items}->[$idx], $bucket->{sizes}->[$idx]];
        }
    }

    return @items;
}

###########################################
sub shuffle {
###########################################
    my($self, @array) = @_;

    for(my $i=@array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @array[$i,$j] = @array[$j,$i];
    }

    return @array;
}

##################################################
package Algorithm::Bucketizer::Bucket;
##################################################

##################################################
sub new {
##################################################
    my($class, @options) = @_;

    my $self = { size      => 0,
                 items     => [],
                 sizes     => [],
                 maxsize   => undef,
                 maxitems  => undef,
                 idx       => 0,
                 @options,
               };

    bless $self, $class;
}

##################################################
sub serial {
##################################################
    my($self) = @_;

    return ($self->{idx} + 1);
}

##################################################
sub level {
##################################################
    my($self) = @_;

    return ($self->{size});
}

##################################################
sub idx {
##################################################
    my($self) = @_;

    return ($self->{idx});
}

##################################################
sub add_item {
##################################################
    my($self, $item, $size) = @_;

        # Does item fit in container?
    if($self->probe_item($item, $size)) {
            # Add it
        push @{$self->{items}}, $item;
        push @{$self->{sizes}}, $size;
        $self->{size} += $size;
        return 1;
    }

    return undef;
}

##################################################
sub probe_item {
##################################################
    my($self, $item, $size) = @_;

        # Does item fit in container?
    if($self->{maxitems}) {
        if(scalar $self->{items} >= $self->{maxitems}) {
            return 0;
        }
    }

    if($self->{size} + $size <= $self->{maxsize}) {
        return 1;
    } else {
        return 0;
    }
}

##################################################
sub items {
##################################################
    my($self) = @_;

    return @{$self->{items}};
}

1;

__END__

=head1 NAME

Algorithm::Bucketizer - Distribute sized items to buckets with limited size

=head1 SYNOPSIS

  use Algorithm::Bucketizer;

      # Create a bucketizer
  my $bucketizer = Algorithm::Bucketizer->new(bucketsize => $size);

      # Add items to it
  $bucketizer->add_item($item, $size);

      # Optimize distribution
  $bucketizer->optimize(maxrounds => 100);

      # When done adding, get the buckets
      # (they're of type Algorithm::Bucketizer::Bucket)
  my @buckets = $bucketizer->buckets();

      # Access bucket content by using
      # Algorithm::Bucketizer::Bucket methods
  my @items  = $bucket->items();
  my $serial = $bucket->serial();
  
=head1 DESCRIPTION

So, you own a number of mp3-Songs on your hard disc and want to copy them to 
a number of CDs, maxing out the space available on each of them?
You want to distribute your picture collection into several folders, 
so each of them doesn't exceed a certain size? C<Algorithm::Bucketizer>
comes to the rescue.

C<Algorithm::Bucketizer> distributes items of a defined size into
a number of dynamically created buckets, each of them capable of
holding items of a defined total size.

By calling the C<$bucketizer-E<gt>add_item()> method with the item (can be
a scalar or an object reference) and its size as parameters, you're adding
items to the system. The bucketizer will determine if the item
fits into one of the existing buckets and put it in there if possible.
If none of the existing buckets has enough space left to hold the
new item (or if no buckets exist yet for that matter), 
the bucketizer will create a new bucket and put the item 
in there.

After adding all items to the system, the bucketizer lets you iterate
over all buckets 
with the C<$bucketizer-E<gt>items()> method
and determine what's in each of them.

=head2 Algorithms

Currently, C<Algorithm::Bucketizer> comes with two algorithms, C<simple> and
C<retry>. 

In C<simple> mode, the algorithm will just try to fit in your items
in the order in which they're arriving. If an item fits into the current bucket,
it's being dropped in, if not, the algorithm moves on to the next bucket. It
never goes back to previous buckets, although a new item might as well 
fit in there. This mode might be useful if preserving the original order
of items is required. To query/manipulate the bucket the Bucketizer
will try to fit in the next item, use C<current_bucket_index()> explained
below.

In C<retry> mode, the algorithm will try each existing bucket first, 
before opening
a new one. If you have many items of various sizes, C<retry> allows you to fit
them into less buckets than in C<simple> mode.

The C<new()> method chooses the algorithm:

    my $dumb = Algorithm::Bucketizer->new( algorithm => "simple" );

    my $smart = Algorithm::Bucketizer->new( algorithm => "retry" );

In addition to these inserting algorithms, check L<"Optimize">
to optimize the distribution, minimizing the number of required buckets.

=head2 Prefilling Buckets

Sometimes you will have preexisting buckets, which you need to 
tell the algorithm 
about before it starts adding new items. The C<prefill_bucket()> method
does exactly that, simply putting an item into a specified bucket:

    $b->prefill_bucket($bucket_idx, $item, $itemsize);

C<$bucket_idx> is the index of the bucket, starting from 0. Non-existing buckets
are automatically created for you. Make sure you have a consecutive number
of buckets at the end of the prefill.

=head2 Optimize

Once you've inserted all items, you might choose to optimize the distribution
over the buckets, in order to I<minimize> the number of required buckets
to hold all the elements.

Optimally distributing a number discrete-sized items into a 
number of discrete-sized buckets, however, is a non-trivial task. 
It's the "bin-packing problem", related to the 
"knapsack problem", which are both I<NP-complete>.

C<Algorithm::Bucketize> therefore provides different optimization
techniques to (stupidly) approximate an ideal solution, which can't 
be obtained otherwise (yet).

Currently, it implements C<"random"> and C<"brute_force">.

C<"random"> tries to randomly vary the distribution until a time
or round limit is reached.

        # Try randomly to improve distribution, 
        # timing out after 100 rounds
    $b->optimize(algorithm => "random", maxrounds => 100);

        # Try randomly to improve distribution, 
        # timing out after 60 secs
    $b->optimize(algorithm => "random", maxtime => 60);

        # Try to improve distribution by brute_force trying
        # all possible combinations (watch out: can take forever)
    $b->optimize(algorithm => "brute_force",
                 maxtime => ..., 
                 maxrounds => ...,
                );

I'm currently evaluating more sophisticated methods suggested by
more mathematically inclined people :).

=head1 FUNCTIONS

=over 4

=item *

    my $b = Algorithm::Bucketizer->new(
        bucketsize => $size, 
        algorithm  => $algorithm 
       );

Creates a new C<Algorithm::Bucketizer> object and returns a reference to it.

The C<bucketsize> name-value pair is
somewhat mandatory, because you want to set the size of your buckets, otherwise
they will default to 100, which isn't what you want in most cases. 

C<algorithm> can be left out, it defaults to C<"simple">. 
If you want retry behaviour, specify C<"retry"> (see L<"Algorithms">).

Another optional parameter, C<add_buckets> specifies if the bucketizer is
allowed to add new buckets to the end of the brigade as it sees fit. It
defaults to 1. If set to 0, the bucketizer will operate with a limited
number of buckets, usually defined by C<add_bucket> calls.

=item *

    $b->add_item($item_name, $item_size);

Adds an item with the specified name and size to the next 
available bucket, according
to the chosen algorithm. If you want to place an item into a 
specific bucket (e.g. in
order to prefill buckets), use C<prefill_bucket()> instead, 
which is described below.

Returns the Algorithm::Bucketizer::Bucket object of the lucky bucket
on sucess and C<undef> if something goes badly 
wrong (e.g. the bucket size
is smaller than the item, i.e. there's no way it's 
ever going to fit in I<any> bucket).

=item *

    my @buckets = $b->buckets();

Return a list of buckets. The list contains elements of type 
C<Algorithm::Bucketizer::Bucket>, which understand the following methods:

=over 4

=item *

    my @items = $bucket->items();

Returns a list of names of items in the bucket. 
Returns an empty list if the bucket is empty.

=item *

    my $level = $bucket->level();

Return how full the bucket is. That's the size of all items 
in the bucket combined.

=item *

    my $bucket_index = $bucket->idx();

Return the bucket's index. The first bucket has index 0.

=item *

    my $serial_number = $bucket->serial();

Return the bucket serial number. That's the bucket index plus 1.

=back

=item *

    $b->add_bucket(
        maxsize => $maxsize
    );

Adds a new bucket to the end of the bucket brigade. This method is useful
for building brigades with buckets of various sizes.

=item *

    $b->current_bucket_idx( $idx );

Set/retrieve the index of the bucket that the C<simple> algorithm will
use first in order to try to insert the next item.

=item *

    $b->optimize(
        algorithm  => $algorithm,
        maxtime    => $seconds,
        maxrounds  => $number_of_rounds 
       );

Optimize bucket distribution. Currently C<"random"> and C<"brute_force">
are implemented. Both can be (C<"random"> I<must> be) terminated
by either the maximum number of seconds (C<maxtime>) or 
iterations (C<maxrounds>).

=back

=head1 EXAMPLE

We've got buckets which hold a weight of 100 each, 
and we've got 10 items weighing 30, 31, 32, ... 39. Distribute 
them into buckets.

    use Algorithm::Bucketizer;

    my $b = Algorithm::Bucketizer->new( bucketsize => 100 );
    for my $i (1..10) {
        $b->add_item($i, 30+$i);
    }

    for my $bucket ($b->buckets()) {
        for my $item ($bucket->items()) {
            print "Bucket ", $bucket->serial(), ": Item $item\n";
        }
        print "\n";
    }

Output:

    Bucket 1: Item 1
    Bucket 1: Item 2
    Bucket 1: Item 3

    Bucket 2: Item 4
    Bucket 2: Item 5

    Bucket 3: Item 6
    Bucket 3: Item 7

    Bucket 4: Item 8
    Bucket 4: Item 9

    Bucket 5: Item 10

=head1 REQUIRES

Algorithm::Permute 0.04 if you want to use the "brute_force" method.

=head1 SCRIPTS

This distribution comes with a script I<bucketize> which puts files
into directory buckets with limited size. Run C<perldoc bucketize>
for details.

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2007 by Mike Schilli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
