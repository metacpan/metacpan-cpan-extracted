package Acme::GLOINBG::Utils;

use 5.006;
use strict;
use warnings;

=head1 NAME

Acme::GLOINBG::Utils - Utilities module for GLOINBG projects

=head1 VERSION

Version 0.06 Exercise 7, Fix the required modules in Build.PL

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

Utilities module

    use Acme::GLOINBG::Utils;

    my $foo = Acme::GLOINBG::Utils->new();
    ...

=head1 EXPORT

Functions that can be exported:
   sum

=head1 SUBROUTINES/METHODS

=head2 sum( LIST )

Numerically sums the argument list and returns the result.

=cut

sub sum {
  no warnings 'numeric';
  my $sum;
  foreach ( @_ ) { $sum += $_ }
  return $sum;
}

=head1 AUTHOR

Georgi Kolarov, C<< <gkolarov1970 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-gloinbg-utils at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-GLOINBG-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::GLOINBG::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-GLOINBG-Utils>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Acme-GLOINBG-Utils>

=item * Search CPAN

L<https://metacpan.org/release/Acme-GLOINBG-Utils>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Georgi Kolarov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Acme::GLOINBG::Utils
