package Acme::BOATES;

use 5.006;
use strict;
use warnings;

=head1 NAME

Acme::BOATES - The great new Acme::BOATES!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Acme::BOATES;

    my $foo = Acme::BOATES->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 sum( LIST_OF_NUMBERS )

Returns the sum of the numbers

=cut

sub sum {
    my $sum = 0;
    foreach( @_ ) { $sum += $_ }
    return $sum;
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Brian Oates, C<< <boates at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-boates at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-BOATES>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::BOATES


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-BOATES>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-BOATES>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-BOATES>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-BOATES/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Oates.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Acme::BOATES
