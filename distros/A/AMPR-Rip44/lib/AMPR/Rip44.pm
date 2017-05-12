package AMPR::Rip44;

use warnings;
use strict;

=head1 NAME

AMPR::Rip44 - A naive custom RIPv2 daemon

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

A naive custom RIPv2 daemon to receive RIP updates from the
44/8 ampr.org routing service, and insert them in the
Linux routing table.

=head1 SUBROUTINES/METHODS

=head2 fill_local_ifs

Figure out local interface IP addresses so that routes to them can be ignored

=cut

sub fill_local_ifs() {

}

=head2 mask2prefix

Convert a netmask (in integer form) to the corresponding prefix length,
and validate it too. This is a bit ugly, optimizations are welcome.

=cut

sub mask2prefix ($) {
	my($mask) = @_; # integer

}



=head1 AUTHOR

Heikki Hannikainen, OH7LZB, C<< <hessu at hes.iki.fi> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ampr-rip44 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AMPR-Rip44>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AMPR::Rip44


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AMPR-Rip44>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AMPR-Rip44>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AMPR-Rip44>

=item * Search CPAN

L<http://search.cpan.org/dist/AMPR-Rip44/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Heikki Hannikainen, OH7LZB.

This program is released under the following license: EVVKTVH / ICCLEIYSIUYA


=cut

1; # End of AMPR::Rip44
