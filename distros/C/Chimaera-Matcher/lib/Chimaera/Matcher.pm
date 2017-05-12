package Chimaera::Matcher;

use 5.006;
use strict;
use warnings;
use Error;

=head1 NAME

Chimaera::Matcher - An object to look for Chimaeric (Bovine) MHC sequences

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

An object to check for possible chimaeric sequences in MHC sequencing studies.

Example usage....

    use Chimaera::Matcher;

    my $foo = Chimaera::Matcher->new( 'haplotype1' => $haplotype1, 'haplotype2' => $haplotype2);
    
    if ($foo->possible_chimaera($test_seq)) {
    	printf("Could be a chimaera\n");
    }
    else {
    	printf("Not a chimaera\n");
    }
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Given a pair of sequence strings, construct a Matcher that we can use
to test a series of possible chimaeric sequences against.

Two named sequence arguments must be supplied, keyed as 'haplotype1' and 'haplotype2'. Both must be the same length as each other and non-empty.

Tests are all case-insensitive.

=cut

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
	my $self     = {@_};
	bless( $self, $class );
	foreach my $index ( 1, 2 ) {
		my $haplo = "haplotype${index}";
		throw Error::Simple( "No haplotype${haplo}" )
		  unless defined( $self->{$haplo} );
	}
	my $len = length($self->{'haplotype1'});
	throw Error::Simple( "Haplotypes differ in length" )
		unless ( $len == length($self->{'haplotype2'}));

	throw Error::Simple( "Haplotypes are empty" )
		unless ( $len > 0);
		
	$self->{'haplotype1'} = uc($self->{'haplotype1'});
	$self->{'haplotype2'} = uc($self->{'haplotype2'});
	
	if ( $self->{'haplotype1'} eq $self->{'haplotype2'}) {
		print "Identical\n";
		throw Error::Simple( "Haplotypes are identical" );
	}

	my $matcher = {};
	for (my $i = 0; $i < $len; $i++) {
		my $base = {};
		$base->{substr($self->{'haplotype1'}, $i, 1 )} += 1;
		$base->{substr($self->{'haplotype2'}, $i, 1 )} -= 1;
		
		$matcher->{$i} = $base;
	}
	$self->{'matcher'} = $matcher;
	$self->{'length'} = $len;
	
	return $self;
}

=head2 possible_chimaera

Pass in a sequence to be tested as a possible chimaera. The sequence must be the same
length as the haplotype arguments supplied in the constructor. If the test sequence has
a base that was not seen in either of the haplotypes supplied, then it cannot be a 
chimaera of the two. If the test sequence switches from one haplotype to the other more
than once, then this cannot be a chimaera.

If the test sequence is identical to one or other of the input haplotypes then it also
cannot be defined as a chimaera.

=cut

sub possible_chimaera {
	my $self = shift;
	my $candidate = shift;
	
	$candidate = uc($candidate);
	
	my %to_string = ( 0 => "", -1 => "A", 1 => "B");
	
	if ( length($candidate) != $self->{'length'} ) {
		return 0;
	}
	
	my $coded_string = "";
	for (my $i = 0; $i < $self->{'length'}; $i++) {
		my $base = substr($candidate, $i, 1);
		if (defined($self->{'matcher'}{$i}{$base})) {
			$coded_string .= $to_string{$self->{'matcher'}{$i}{$base}};
		}
		else {
			return 0;
		}
	}
	if ($coded_string =~ m/^(A+B+|B+A+)$/) {
		return 1;
	}
	return 0;	
}

=head1 AUTHOR

"Andy Law", C<< <"andy.law at roslin.ed.ac.uk"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chimaera at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chimaera>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Chimaera::Matcher


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chimaera>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Chimaera>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Chimaera>

=item * Search CPAN

L<http://search.cpan.org/dist/Chimaera/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 The Roslin Institute.

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

1;    # End of Chimaera::Matcher
