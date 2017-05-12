package Acme::kevinz;

use 5.006;
use strict;
use warnings;

=head1 NAME

Acme::kevinz - The great new Acme::kevinz!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Acme::kevinz;

    my $foo = Acme::kevinz->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 sum

Returns the sum of numbers.

=cut

sub sum {
my $sum;
foreach (@_) {
  $sum += $_;
}
return $sum;
}

=head1 AUTHOR

E. Kevin Zembower, C<< <kzembower at verizon.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-kevinz at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-kevinz>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::kevinz


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-kevinz>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-kevinz>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-kevinz>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-kevinz/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 E. Kevin Zembower.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Acme::kevinz
