package Acme::MetaSyntactic::errno;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA     = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.003';

use Errno ();

__PACKAGE__->init(
    {   default => 'PERL',
        names   => {
            POSIX => join( ' ', @{ $Errno::EXPORT_TAGS{POSIX} } ),
            PERL  => join( ' ', keys %! ),
        },
    }
);

1;

=head1 NAME

Acme::MetaSyntactic::errno - The errno theme

=head1 DESCRIPTION

The name of all errors known to Perl via the system F<errno.h>.

The official POSIX error list is available at
L<http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/errno.h.html>.

=head1 CONTRIBUTOR

Philippe Bruhat (BooK)

=head1 CHANGES

=over 4

=item *

2013-05-13 - v1.003

New release without any code change. (Just a F<Changes> change.)

=item *

2012-07-23 - v1.002

Fix in the documentation CHANGES section.

=item *

2012-07-13 - v1.001

Added a LICENSE section, to please CPANTS.

=item *

2012-06-21 - v1.000

Published as part of the Booking.com Hackathon.

=back

=head1 SEE ALSO

L<Errno>,
L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

