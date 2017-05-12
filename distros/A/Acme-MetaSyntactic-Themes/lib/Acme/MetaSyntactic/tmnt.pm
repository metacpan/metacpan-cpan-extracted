package Acme::MetaSyntactic::tmnt;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.001';
__PACKAGE__->init();

our %Remote = (
    source  => ['http://www.ninjaturtles.com/html/profiles.htm',
                'http://www.ninjaturtles.com/html/profiles02.htm'],
    extract => sub {
        return
            map { s/\W+/_/g; $_ }
            map { split /\s+&amp;\s+/ }
            $_ [0] =~ m{<a href="/html/profile?\d+.htm">([^<]+)</a>}g
    }
);

1;

=head1 NAME

Acme::MetaSyntactic::tmnt - The Teenage Mutant Ninja Turtles theme

=head1 DESCRIPTION

The Teenage Mutant Ninja Turtles are a comic series created in 1984 
by Kevin Eastman and Peter Laird. They have been published as comic
books, television series, and movies.

The official web of Mirage Studios has a lot of information about
the TMNT, see L<http://www.ninjaturtles.com/>.

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

=item *

2012-05-07

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-01-30

Made updatable in Acme-MetaSyntactic version 0.59.

=item *

2006-01-23

Introduced in Acme-MetaSyntactic version 0.58.

=item *

2005-10-26

Submitted by Abigail.

=back

Source URL and list updated in v1.001, published in Acme-MetaSyntactic-Theme
1.002, on May 21, 2012.

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Donatello Leonardo Michelangelo Raphael Master_Splinter April_O_Neil
Casey_Jones The_Shredder Hun Foot_Soldier Krang Bebop Rocksteady
Rat_King Leatherhead Slash Mondo_Gecko Ray_Fillet Wingnut Screwloose
Merdude Tattoo Wyrm Dreadmon Jagwar Dragon_Lord Venus_de_Milo
