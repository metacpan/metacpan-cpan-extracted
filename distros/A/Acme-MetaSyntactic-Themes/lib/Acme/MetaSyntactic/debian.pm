package Acme::MetaSyntactic::debian;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.006';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::debian - The debian theme

=head1 DESCRIPTION

This theme lists all the Debian codenames. So far they have been
characters taken from the movie I<Toy Story> by Pixar.

Source: L<https://www.debian.org/doc/manuals/debian-faq/ftparchives.en.html#codenames>.

=head1 CONTRIBUTOR

Philippe Bruhat (Book).

=head1 CHANGES

=over 4

=item *

2026-01-12 - v1.006

Added C<trixie> to the list of Debiam codenames.
Published in Acme-MetaSyntactic-Themes version 1.055.

=item *

2021-04-30 - v1.005

Updated the link to the Debian documentation about codenames.
Published in Acme-MetaSyntactic-Themes version 1.055.

=item *

2019-07-29 - v1.004

Added C<bullseye> and C<bookworm> to the list of Debiam codenames.
Published in Acme-MetaSyntactic-Themes version 1.053.

=item *

2018-10-29 - v1.003

Added C<buster> to the list of Debian codenames.
Published in Acme-MetaSyntactic-Themes version 1.052.

=item *

2015-06-08 - v1.002

Added C<stretch> to the list of Debian codenames.
Published in Acme-MetaSyntactic-Themes version 1.046.

=item *

2013-06-17 - v1.001

Added C<jessie> to the list of Debian codenames.
Published in Acme-MetaSyntactic-Themes version 1.033.

=item *

2012-05-07 - v1.000

Updated with the new Debian versions since 2007, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-05-02

Introduced in Acme-MetaSyntactic version 0.20.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
buzz rex bo
hamm slink potato
woody sarge etch
lenny squeeze wheezy
jessie stretch buster
bullseye bookworm trixie
sid
