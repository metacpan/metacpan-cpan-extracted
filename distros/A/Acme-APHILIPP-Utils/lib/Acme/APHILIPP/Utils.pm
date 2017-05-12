package Acme::APHILIPP::Utils;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(sum);

=head1 NAME

Acme::APHILIPP::Utils - Test module that sums

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

    use Acme::APHILIPP::Utils;

    my $sum = sum(1, 2, 3);
    print "$sum\n"; # 6

=head1 EXPORT

A list of functions that can be exported.

sum()

=head1 SUBROUTINES/METHODS

=head2 sum

Returns the sum of the numbers passed to it, ignoring arguments
that don't look like numbers.

=cut

sub sum {
    my $sum;
    foreach my $num ( grep { /\A-?\d+\.*\d*\z/ } @_ ) {
        $sum += $num;
    }
    $sum;
}

=head1 AUTHOR

Andre Philipp, C<< <aphilipp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-aphilipp-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-APHILIPP-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::APHILIPP::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-APHILIPP-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-APHILIPP-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-APHILIPP-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-APHILIPP-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Andre Philipp.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>


=cut

1; # End of Acme::APHILIPP::Utils
