package Acme::GRYLLIDA::Utils;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(sum);


=head1 NAME

Acme::GRYLLIDA::Utils - The great new Acme::GRYLLIDA::Utils! A test module.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

contains a sum() function to add numbers, and a test for that function.


    use Acme::GRYLLIDA::Utils;

    my $foo = sum(1, 2);
    print "$foo\n"; # 3
    
    my $foo = sum(2, 2, "a");
    print "$foo\n"; # 4

=head1 EXPORT

A list of functions that can be exported. 

sum()


=head1 SUBROUTINES/METHODS

=head2 sum

This function returns a sum of its arguments. Non-number arguments are ignored. No arguments returns undef.

=cut

sub sum {
  my $sum;
  foreach my $num ( grep {/\A-?\d+\.*\d*\z/ } @_ ) {
    $sum += $num;
  }
  $sum;
}


=head1 AUTHOR

Gryllida, C<< <Gryllida at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-gryllida-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-GRYLLIDA-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::GRYLLIDA::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-GRYLLIDA-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-GRYLLIDA-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-GRYLLIDA-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-GRYLLIDA-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gryllida.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Acme::GRYLLIDA::Utils
