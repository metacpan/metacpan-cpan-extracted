package Algorithm::SetCovering;

use strict;
use warnings;
use Log::Log4perl qw(:easy);

our $VERSION = '0.05';

##################################################
sub new {
##################################################
    my($class, @options) = @_;

    my %options = @options;

    die "No value given for mandatory parameter 'columns'"
        unless exists $options{columns};

    my $self = {
        mode     => "greedy",
        @options,
        rows     => [],
        prepared => 0,
        combos   => [],
    };

    bless $self, $class;
}

##############################################
sub add_row {
##############################################
    my($self, @columns) = @_;

    if($self->{columns} != scalar @columns) {
        die "add_row expects $self->{columns} columns" .
            "but received " . scalar @columns . "\n";
    }
  
    DEBUG "Adding row @columns";

    push @{$self->{rows}}, [@columns];

    $self->{prepared} = 0;
}

##############################################
sub row {
##############################################
    my($self, $idx) = @_;

    return @{$self->{rows}->[$idx]};
}

##############################################
sub min_row_set {
##############################################
    my($self, @columns_to_cover) = @_;

    if($self->{mode} eq "brute_force") {
        return brute_force_run(@_);
    } elsif($self->{mode} eq "greedy") {
        return greedy_run(@_);
    } else {
        die "$self->{mode} not implemented\n";
    }
}

##############################################
sub brute_force_run {
##############################################
    my($self, @columns_to_cover) = @_;

    $self->brute_force_prepare() unless $self->{prepared};

    COMBO:
    for my $combo (@{$self->{combos}}) {

        for(my $idx = 0; $idx < @columns_to_cover; $idx++) {
            # Check if the combo covers it, [0] is a ref
            # to a hash for quick lookups.
            next unless $columns_to_cover[$idx];
            next COMBO unless $combo->[0]->[$idx];
        }
            # We found a minimal set, return all of its elements 
            # (which are idx numbers into the @rows array)
        return @{$combo->[1]};
    }

        # Can't find a minimal set
    return ();
}

##############################################
sub brute_force_prepare {
##############################################
# Create data structures for fast lookups
##############################################
    my($self) = @_;
    
        # Delete old combos;
    $self->{combos} = [];

    my $nrows = scalar @{$self->{rows}};

    # Create all possible permutations of keys.
    # (TODO: To optimize, we should get rid of
    #        keys which are subsets of other 
    #        keys)
    # Sort combos ascending by the number of keys 
    # they contain, i.e. combos with fewer keys
    # come first.
    my @combos =
        sort { bitcount($a) <=> bitcount($b) }
             (1..2**$nrows-1);
    
    DEBUG "Combos are: @combos";

    # A bunch of bitmasks to easily determine
    # if a combo contains a certain key or not.
    my @masks = map { 2**$_ } (0..$nrows-1);

    for my $combo (@combos) {
            # The key values of the combo as (1,0,...)
        my @keys    = ();
        my @covered = ();

        for(my $key_idx = 0; $key_idx < @masks; $key_idx++) {
            if($combo & $masks[$key_idx]) {
                # Key combo contains the current key. Iterate
                # over all locks and store in @covered if
                # the current key opens them.
                for(0..$self->{columns}-1) {
                    $covered[$_] ||= $self->{rows}->[$key_idx]->[$_];
                }
                push @keys, $key_idx;
            }
        }

        DEBUG "Combo '@keys' covers '@covered'";

            # Push hash ref and combo fields to 'combos'
            # array
        push @{$self->{combos}}, [\@covered, \@keys];
    }

    $self->{prepared} = 1;
}

##############################################
sub bitcount {
##############################################
# Count the number of '1' bits in a number
##############################################
    my($num) = @_;

    my $count = 0;

    while ($num) {
         $count += ($num & 0x1) ;
         $num >>= 1 ;
    }

    return $count ;
}

##############################################
sub greedy_run {
##############################################
    my($self, @columns_to_cover) = @_;

    my @hashed_rows    = ();
    my %column_hash    = ();
    my @result         = ();

    for(my $i=0; $i<@columns_to_cover; $i++) {
        $column_hash{$i} = 1 if $columns_to_cover[$i];
    }

    for my $row (@{$self->{rows}}) {
        my $rowhash = {};
        for(my $i=0; $i<@columns_to_cover; $i++) {
            $rowhash->{$i}++ if $columns_to_cover[$i] and $row->[$i];
        }
        push @hashed_rows, $rowhash;
        DEBUG("Hash of idx (", join('-', keys %$rowhash), ")");
    }

    my %not_covered = %column_hash;

    do {
            # Get the longest list
        my $max_len  = 0;
        my @max_keys = ();
        my $max_idx  = 0;
        for my $idx (0..$#hashed_rows) {
            my $row = $hashed_rows[$idx];
            my @keys = keys %$row;
            if(scalar @keys > $max_len) {
                @max_keys = @keys;
                $max_len  = scalar @keys;
                $max_idx  = $idx;
            }
        }

        # Return empty solution if rows can't cover columns_to_cover
        return () unless $max_len;
  
        DEBUG("Removing max_keys: @max_keys");

        delete $not_covered{$_} for @max_keys;
        push @result, $max_idx;

            # Remove max_keys columns from all keys
        foreach my $row (@hashed_rows) {
            delete $row->{$_} for @max_keys;
            DEBUG("Remain (", join('-', keys %$row), ")");
        }
 
        DEBUG("Not covered: (", join('-', keys %not_covered), ")");
        
    } while(scalar keys %not_covered);

    return @result;
}
    
1;

__END__

=head1 NAME

Algorithm::SetCovering - Algorithms to solve the "set covering problem"

=head1 SYNOPSIS

    use Algorithm::SetCovering;

    my $alg = Algorithm::SetCovering->new(
        columns => 4,
        mode    => "greedy");

    $alg->add_row(1, 0, 1, 0);
    $alg->add_row(1, 1, 0, 0);
    $alg->add_row(1, 1, 1, 0);
    $alg->add_row(0, 1, 0, 1);
    $alg->add_row(0, 0, 1, 1);

    my @to_be_opened = (@ARGV || (1, 1, 1, 1));
    
    my @set = $alg->min_row_set(@to_be_opened);
    
    print "To open (@to_be_opened), we need ",
          scalar @set, " keys:\n";

    for(@set) {
        print "$_: ", join('-', $alg->row($_)), "\n";
    }

=head1 DESCRIPTION

Consider having M keys and N locks. Every key opens one or more locks:

         | lock1 lock2 lock3 lock4
    -----+------------------------
    key1 |   x           x
    key2 |   x     x
    key3 |   x     x     x
    key4 |         x           x
    key5 |               x     x

Given an arbitrary set of locks you have to open (e.g. 2,3,4), 
the task is to find a minimal set of keys to accomplish this.
In the example above, the set [key4, key5] fulfils that condition.

The underlying problem is called "set covering problem" and
the corresponding decision problem is NP-complete.

=head2 Methods

=over 4

=item $alg = Algorithm::SetCovering->new(columns => $cols, [mode => $mode]);

Create a new Algorithm::SetCovering object. The mandatory parameter
C<columns> needs to be set to the number of columns in the matrix
(the number of locks in the introductory example).

C<mode> is optional and selects an algorithm for finding the solution. 
The following values for C<mode> are implemented:

=over 4

=item "brute_force"

Will iterate over all permutations of keys. Only recommended for
very small numbers of keys.

=item "greedy"

Greedy algorithm. Scales O(mn^2). Can't do much better for a NP-hard
problem.

=back

The default for C<mode> is set to "greedy".

=item $alg->add_row(@columns)

Add a new row to the matrix. In the example above, this adds one key
and specifies which locks it is able to open. 

    $alg->add_row(1,0,0,1);

specifies that the new key can open locks #1 and #4.

The number of elements
in @columns needs to match the previously defined number of columns.

=item $alg->min_row_set(@columns_to_cover)

Determines a minimal set of keys to cover a given set of locks
and returns an array of index numbers for those keys.

Defines which columns have to be covered by passing in an array
with true values on element positions that need to be covered.
For example,

    my @idx_set = $alg->min_row_set(1,1,0,1);

specifies that all but the third column have to be covered and returns
an array of index numbers into an array, defined previously
(and implicitely) via successive add_row() commands.

If no set of keys can be found that satisfies the given requirement,
an empty list is returned.

If you've forgotten which locks the key referred to by a certain index number
can open, use the C<rows()> method to find out:

    my(@opens_locks) = $alg->rows($idx_set[0]);

will give back an array of 0's and 1's, basically returning the
very parameters we've passed on to the
add_row() command previously.

=back

=head2 Strategies

Currently, the module implements the Greedy algorithm and also
(just for scientific purposes) a dumb brute force method, 
creating all possible combinations of keys, sorting them by 
the number of keys used (combinations with fewer keys have priority)
and trying for each of them if it fits the requirement of opening
a given number of locks.

This obviously won't scale beyond a really small number of keys (N), 
because the number of permutations will be 2**N-2.

The Greedy Algorithm, on the other hand scales with O(mn^2), with
m being the number of keys and n being the number of locks.

=head2 Limitations

Julien Gervais-Bird E<lt>j.bird@usherbrooke.caE<gt> points out:
The greedy algorithm does not always return the minimal set of
keys. Consider this example:

         | lock1 lock2 lock3 lock4 lock5 lock6
    -----+------------------------------------
    key1 |   x           x           x
    key2 |   x     x
    key3 |               x     x
    key4 |                           x     x

The minimal set of keys to open all the locks is (key2, key3, key4),
however the greedy algorithm will return (key1,key2,key3,key4) because
key1 opens more locks than any other key.

=head1 AUTHOR

Mike Schilli, 2003, E<lt>m@perlmeister.comE<gt>

Thanks to the friendly guys on rec.puzzles, who provided me with
valuable input to analyze the problem and explained the algorithm:

    Craig <c_quest000@yahoo.com>
    Robert Israel <israel@math.ubc.ca>
    Patrick Hamlyn <path@multipro.n_ocomsp_am.au>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mike Schilli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
