package Array::Parallel;
use 5.006;
$VERSION = '.01';
use strict;
use Carp;
use warnings;

sub new {
    my ($self, @args) = @_;  #Get the data Passed
    my $primary_array = shift @args; #Array that is the basis for sorting
    my %return;
    for (my $i = 0; $i <= $#{@{$primary_array}}; $i++) {
         my $key = $primary_array->[$i];
         for my $num ((0 .. $#args)) {
             my $other_arrays = $args[$num];
             push(@{$return{$key}[$num]}, $other_arrays->[$i]);
         }
    }
    $return{'primary_array'} = $primary_array;;
    return bless \%return, $self
}
sub parasort {
    no strict 'refs';
    my ($self, @sorted, @arrays, $cmp, $primary);
    ($self, $cmp) = @_;
    $primary = $self->{primary_array}; delete $self->{primary_array};
    $cmp = 'cmp' if ! $cmp;
    if ($cmp eq 'num') {
       @sorted = sort {$a <=> $b} keys %{$self};
       @{$primary} = sort {$a <=> $b} @{$primary};
    } elsif ($cmp eq 'cmp') {
       @sorted = sort {$a cmp $b} keys %{$self};
       @{$primary} = sort {$a cmp $b} @{$primary};
    }
    foreach my $sorted ((0 .. $#sorted)) {
     foreach my $args ((0 .. $#{@{$self->{$sorted[$sorted]}}})) {
       foreach my $finally ((0 .. $#{@{$self->{$sorted[$sorted]}[$args]}})) {
         push @{$arrays[$args]}, $self->{$sorted[$sorted]}[$args][$finally];
       }
      }
    }

    unshift (@arrays, \@{$primary});
    return @arrays;
}
*sort = *parasort;

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Array::Parallel - Sorting Parallel Arrays

=head1 VERSION

This document describes version 0.01 of Array::Parallel, released
January 2004

=head1 SYNOPSIS

      use Array::Parallel;

      @your_ratings = (2, 3, 1);
      @husbands = ('fred', 'archie', 'homer');
      @wives = ('wilma', 'edith', 'marge');

      $array = Array::Parallel->new(\@your_ratings, \@husbands, \@wives);
      ($your_ratings, $husbands, $wives) = $array->sort('num');

      for my $num ( (0 .. $#{@{$your_ratings}} ) ) {
          print "You rated $husbands->[$num] and $wives->[$num] number $your_ratings->[$num]\n";
      }

=head1 DESCRIPTION

Does Parallel Array sorting. Sorting 1 Array and then matching up the keys from the first one to sort a second array, third array, ect. Take a look at the Synopsis if you are confussed about what I mean.

A more efficent way would be to use hash keys instead of using this module. But, this might be good for a lot of cases. I would test this module with the extremes of what data you expect before trusting it though.

=head1 METHODS

Just two methods for now

=head2 new

  Just the constuctor
  Usage: $a = Array::Parallel->new(\@sorted_array, \@next, ..);

=head2 sort

  Sorts arrays to first array. Returns references to all arrays supplied. Takes 1 arguement. Either "num" to sort $a <=> $b, and "cmp" to sort $a cmp $b
  Usage: ($sorted_array, $next, ..) = $a->sort("num");


=head1 EXPORT

OO Nothing

=head1 HISTORY

=over 8

=item 0.01

Version .01 - Everythins new. Functions are: new (constructor) and sort/parasort. Probably bugy. I wouldn't trust it for important things.

=back

=head1 BUGS

Unknown, but they're there.

Please use the Module RIGHT. Not much in way of error messenging (well, not error messenging actually).
As long as you give it arrays of equal length it won't freak out.
If it doesn't work right tell me. This is a beta for a reason.

=head1 TODO

They call this version .01 for a reason. I have to do a lot. Contribution will be well accepted :-)

=head1 AUTHOR

Will Gunther <lt>williamgunther@aol.com<gt>

=head1 SEE ALSO

L<perl>.

=cut