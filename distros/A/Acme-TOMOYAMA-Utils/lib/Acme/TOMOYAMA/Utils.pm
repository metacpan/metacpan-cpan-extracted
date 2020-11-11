package Acme::TOMOYAMA::Utils;

use 5.006;
use strict;
use warnings;

=head1 NAME

Acme::TOMOYAMA::Utils - The great new Acme::TOMOYAMA::Utils!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.012';


=head1 SYNOPSIS

Intermediate Perl sec. 21.9 practice 3

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 sum
it sums the arguments up
=cut

sub sum {
  my $sum;
  foreach my $num (grep {/\A-?\d+\.*\d*\z/} @_) {
    #$sum += $num;
    $sum *= $num;
  }
  $sum;
}



=head1 AUTHOR

Tomohiro Yamashita, C<< <tomohiro.yamashita at keio.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-tomoyama-utils at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-TOMOYAMA-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::TOMOYAMA::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-TOMOYAMA-Utils>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Acme-TOMOYAMA-Utils>

=item * Search CPAN

L<https://metacpan.org/release/Acme-TOMOYAMA-Utils>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Tomohiro Yamashita.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Acme::TOMOYAMA::Utils
