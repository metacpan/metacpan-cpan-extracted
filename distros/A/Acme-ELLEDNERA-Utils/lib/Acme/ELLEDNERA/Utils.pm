package Acme::ELLEDNERA::Utils;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.04';

use Exporter qw(import);
our @EXPORT_OK = qw( sum shuffle );
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );


sub sum {
	my @valid_nums = grep { /\A-?\d+(?:\.\d+)?\z/ } @_;
	
	my $sum;
	for ( @valid_nums ) {
		$sum += $_;
	}
	
	$sum
}


sub shuffle {
	my @deck = @_;
	return unless @deck;
	
	my $i = @deck;
	while (--$i) {
		my $j = int rand ($i+1);
		@deck[$i, $j] = @deck[$j, $i];
	}
	
	@deck;
}

1; # End of Acme::ELLEDNERA::Utils

__END__

=head1 NAME

Acme::ELLEDNERA::Utils

Done for the sake of learning how to create modules :)

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

This module allows you to do addition and shuffle an array.

        use Acme::ELLEDNERA::Utils qw( sum shuffle );
        # or
        # use Acme::ELLEDNERA::Utils ":all";

        # addition
        $sum = sum(1, 2, 3);
        $sum = sum(1.2, 3.14159);
        $sum = sum( qw(t1 10 t2 5 6) ); # only performs 10+5+6 = 21

        # shuffling an array
        @ori_nums = (1, 3, 5, 7, 9, 11, 13, 15);
        @shuffled = shuffle(@ori_nums);

=head1 EXPORT

None by default

=head1 SUBROUTINES

=head2 sum( LIST )

Obtains the sum of a list of numbers. If no numbers are passed in, it will return C<undef>.
A mixture of numbers and non-numerics will work too. However, complex and scientific 
numbers are not supported.

The C<sum> subroutine in version 0.03 is broken

=head2 shuffle( LIST )

Shuffle a list of anything :) This subroutine uses the Fisher Yates Shuffle algorithm.
I just copied and pasted (most of) them from L<https://perldoc.perl.org/perlfaq4#How-do-I-shuffle-an-array-randomly?>

Unlike the original implementation, this subroutine takes in an actual array 
and returns a new shuffled one. It is the same one as in the of Intermediate 
Perl (2nd edition)

=head1 SEE ALSO

List::Util

=head1 AUTHOR

Raphael Jun Jie Jong, C<< <raphael.jongjj at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-ellednera-utils at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-ELLEDNERA-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::ELLEDNERA::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-ELLEDNERA-Utils>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Acme-ELLEDNERA-Utils>

=item * Search CPAN

L<https://metacpan.org/release/Acme-ELLEDNERA-Utils>

=back


=head1 ACKNOWLEDGEMENTS

Besiyata d'shmaya, Intermediate Perl 2nd Edition

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by  Raphael Jun Jie Jong.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
