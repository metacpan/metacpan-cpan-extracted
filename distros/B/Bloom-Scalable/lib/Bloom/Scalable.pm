package Bloom::Scalable;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Bloom::Simple();
use MCE::Grep;
use Carp;
# XXX remove the hardcoding to something better
use constant SERIALIZED_FILE => '/var/tmp/scalable_bloom_serialized.txt';
use Storable;
use Exporter();


=head1 NAME

Bloom::Scalable - Implementation of the probalistic datastructure - ScalableBloomFilter

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our @EXPORT = qw(new add contains);
our @ISA    = qw(Exporter);

sub new {
    my($class, $fresh_instance, $initial_capacity, $error_rate, $ratio) = @_;
    # XXX clean up and use named arguments
    return _new_from_file() if((-e SERIALIZED_FILE) and (!-z SERIALIZED_FILE) and !$fresh_instance);
    $initial_capacity = $initial_capacity || 1000;
    $error_rate = $error_rate || 0.01;
    $ratio = $ratio || 0.9;
    
    my $bloom_filter_list->[0] = new Bloom::Simple(1,$initial_capacity, $error_rate);
    my $self = bless {
    	    RATIO            => $ratio,
    	    INITIAL_CAPACITY => $initial_capacity,
    	    ERROR_RATE       => $error_rate,
            FILTER_LIST      => $bloom_filter_list,
            FRESH_INSTANCE   => $fresh_instance
    
    	}, $class;

    $self;
}


sub add {
    my ($self, $key) = @_;
    return 1 if($self->contains($key));
    # get the last filter in the list to add
    my $filter = $self->{FILTER_LIST}->[-1];
    if ($filter->is_full()){
        #carp "ScalableBloomFilter full, adding next filter";
        # error rate needs to be decreased so that the 
        # sigma error rate of all the filters remains within predefined bounds.
        # as per the research paper, ideal ratio is between 0.8 - 0.9
        my $error_rate = $self->{ERROR_RATE} * (1 - ($self->{RATIO}));
        $filter = new Bloom::Simple(1, $self->{INITIAL_CAPACITY}, $error_rate);
        push(@{$self->{FILTER_LIST}}, $filter);
    }
    $filter->add($key);
         
}


sub contains {
    my ($self, $key) = @_;
    # In a Scalable Bloom Filter we need to go through each 
    # filter in the list to check if the key is available
    # multicore grep eases the pain by parallelizing the task...
    # However benchmarking has revealed that for smaller tasks
    # standard grep works faster.
    my @result = (scalar(@{$self->{FILTER_LIST}}) > 10) ? 
     mce_grep { $_->contains($key) } @{$self->{FILTER_LIST}} :
     grep { $_->contains($key) } @{$self->{FILTER_LIST}};
    
    return scalar @result;
}

sub _new_from_file {
    croak "can't call me, I am private class method" if(scalar(@_));
    croak "Bloom File doesn't exist" unless -e SERIALIZED_FILE;
    croak "Bloom File empty" if -z SERIALIZED_FILE;
    
    return retrieve(SERIALIZED_FILE);    
}

sub DESTROY {
    my($self) = @_;
    # don't keep records of fresh instances
    store $self, SERIALIZED_FILE unless($self->{FRESH_INSTANCE});
}

1;

__END__



=head1 SYNOPSIS

  use Bloom::Scalable;
  
  my $scalable_bloom = new Bloom::Scalable();
  open my $fh, "</usr/share/dict/words" or die "couldn't open dict";
  my @words = map { chomp; $_ } <$fh>;

  foreach my $word ( @words[0..100] ) {
    $scalable_bloom->add($word);
  }
  # check the presence of a random word in the Bloom Filter
  my $random_index = int(rand(100));
  $scalable_bloom->contains($words[$random_index]);

=head1 DESCRIPTION

Bloom Filters were around since 1970 as a probabilistic datastructures
primarily used for their property of configurable false positives 
but *no* false negatives.

While risking false positives, Bloom filters have a strong space advantage
over other data structures for representing sets.
A Bloom filter with 1% error and an optimal value of k(number of filters) 
requires only about 9.6 bits per element — regardless of the size of the elements. 
This advantage comes partly from its compactness, inherited from arrays, 
and partly from its probabilistic nature. 
The 1% false-positive rate can be reduced by a factor of ten 
by adding only about 4.8 bits per element.

Bloom filters also have the unusual property that the time needed either to add items 
or to check whether an item is in the set is a fixed constant, O(k), 
completely independent of the number of items already in the set.
No other constant-space set data structure has this property,

Scalable Bloom Filter entered the stage a bit later, primarily due to the work of
Paulo Sergio Almeida, Carlos Baquero, Nuno Preguica(Lancaster University).
Refer to their research paper titled - "Scalable Bloom Filter"
Their rationale was a Scalable Bloom Filter could be created by chaining together filters
with decreasing error probabilities so that that the entire datastructure respects the predefined
false positive probability agreement. The factor for decreasing the false positive probability
as per their work was determined as between 0.8 - 0.9.

Murmur2 Hashing has been used in this module primarily for its speed.
The quality of the hashing has been further fine tuned by using the technique
defined in the paper by Kirsch, Adam; Mitzenmacher, Michael (2006), 
"Less Hashing, Same Performance: Building a Better Bloom Filter"

Persisting the BloomFilter, using the Perl MultiCoreEngine are a couple of bells and whistles
added for ease and performance.


=head1 LIMITATIONS

Currently the module is not thread safe, its the clients responsibility to streamline 
incoming adds.
This implmentation doesn't support Counting Bloom Filter hence doesn't allow deletes. This 
was more a choice as adding deletions unnecessarily complicates the code. The solution is 
to build a fresh BloomFilter and replacing the persistent file with this new file.

Ideally the complete implementation in C with a Perl XS wrapper would be the fastest solution and hence 
this pure Perl implementation might be slower than the native solution... Saying this, my statment
needs to be benchmarked to find out the XS speedup.


=head1 AUTHOR

Subhojit Banerjee, C<< <subhojit20 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bloom-scalable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bloom-Scalable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bloom::Scalable


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bloom-Scalable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bloom-Scalable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bloom-Scalable>

=item * Search CPAN

L<http://search.cpan.org/dist/Bloom-Scalable/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Subhojit Banerjee.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Bloom::Scalable
