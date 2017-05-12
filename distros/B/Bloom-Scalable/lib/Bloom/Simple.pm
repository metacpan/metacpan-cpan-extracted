package Bloom::Simple;

use 5.006;
use strict;
use warnings FATAL => 'all';
use POSIX qw/ceil/;
use Bit::Vector;
use Digest::MurmurHash qw(murmur_hash);
use Carp;
use Data::Dumper;
use Storable;
use Exporter();

our @EXPORT = qw(new add contains is_full get_slice_vectors_for_key);
our @ISA    = qw(Exporter);
our $VERSION = '0.01';
  
use constant SERIALIZED_FILE => '/var/tmp/simple_bloom_serialized.txt';

sub new {
    my($class, $fresh_instance, $initial_capacity, $error_rate) = @_;
 

    return _new_from_file() if((-e SERIALIZED_FILE) and (!-z SERIALIZED_FILE) and (!$fresh_instance));
    
    $initial_capacity = $initial_capacity || 1000;
    $error_rate = $error_rate || 0.05;
    
    
    my($num_slices, $bits_per_slice);
    $num_slices =    ceil(log(1/ $error_rate)/log(2));
    
    $bits_per_slice = ceil(
            ($initial_capacity * abs(log($error_rate))) /
            ($num_slices * (log(2) ** 2))
            );
            
    my $bit_vector = Bit::Vector->new($num_slices*$bits_per_slice);
    my $self = bless {
    	    INITIAL_CAPACITY => $initial_capacity,
    	    ERROR_RATE       => $error_rate,
            SLICES           => $num_slices,
            BITS_PER_SLICE   => $bits_per_slice,
            BIT_VECTOR       => $bit_vector,
            COUNT_OF_ELEMENTS=> 0,
            FRESH_INSTANCE   => $fresh_instance             
    	}, $class;
    
    $self;
}

sub _new_from_file {
    croak "can't call me, I am private class method" if(scalar(@_));
    croak "Bloom File doesn't exist" unless -e SERIALIZED_FILE;
    croak "Bloom File empty" if -z SERIALIZED_FILE;
    
    return retrieve(SERIALIZED_FILE);    
}


sub get_slice_vectors_for_key {
	my($self, $key) = @_;
    my ($slices, $bits_per_slice, $result);
    $slices = $self->{SLICES};
    $bits_per_slice = $self->{BITS_PER_SLICE};
    # From "Less Hashing same performance" paper, using a 
    # linear combination of hash functions (minimally two)
    # would get us the same performance without decreasing the
    # quality i.e. without increasing hash collisions
    my $hash_one = murmur_hash($key); 
    my $hash_two = murmur_hash($hash_one . $key);

    map { 
    	    $result->[$_] = abs((($hash_one + $_) * $hash_two) % $bits_per_slice)  
    	    
    	} 0 .. ($slices-1);
    
    
    return $result;	   

}

sub add {
	my ($self, $key) = @_;

	if ($self->is_full()){
        carp "BloomFilter full";
        # if called from a SBF, add should be called
        # again after increasing the filter resident capacity
        return 0; 
    }
    my $offset = 0;
    foreach my $bits (@{$self->get_slice_vectors_for_key($key)}) {
        $self->{BIT_VECTOR}->Bit_On($offset+$bits);
    	$offset += $self->{BITS_PER_SLICE}; 
        $self->{COUNT_OF_ELEMENTS}++;
    }

    return 1;
         
}

sub contains {
	my ($self, $key) = @_;
	my $offset = 0;
    
    foreach my $bits (@{$self->get_slice_vectors_for_key($key)}) {
    	return 0 unless ($self->{BIT_VECTOR}->contains($offset+$bits));
    	$offset += $self->{BITS_PER_SLICE}; 
    }
    
    return 1;
}


sub is_full {
	my ($self) = @_;
	my $return_status =
	($self->{COUNT_OF_ELEMENTS} < $self->{INITIAL_CAPACITY}) ? 0 : 1;
    
    return $return_status;	
}

sub DESTROY {
    my($self) = @_;
    # Fresh instances don't need to be backedup
    store $self, SERIALIZED_FILE unless($self->{FRESH_INSTANCE});
}

1;
=head1 NAME

Bloom::Simple

=head1 VERSION

Version 0.01

=cut



=head1 SYNOPSIS

    use Bloom::Simple;

    my $foo = Bloom::Simple->new();
    ...

=head1 AUTHOR

Subhojit Banerjee, C<< <subhojit20 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bloom-scalable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bloom-Scalable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bloom::Simple


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

# End of Bloom::Simple
