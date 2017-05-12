package Acme::MetaSyntactic::jabberwocky;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';

=head1 NAME

Acme::MetaSyntactic::jabberwocky - Jabberwocky

=head1 DESCRIPTION

Words from the famous poem by Lewis Carroll.

=head1 POEM

Source: L<http://en.wikisource.org/wiki/Jabberwocky>.

=cut

# include the poem in the documentation

{
    my %seen;
    __PACKAGE__->init(
        {   names => join ' ',
            grep { !$seen{$_}++ }
                map {
                /^(?:J(?:abberwock|ubjub)|Bandersnatch|Tumtum)$/ ? $_ : lc
                }
                map  { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
                map  { (/([-\w]*\w)/g) }
                grep { !/=pod/ }
                split /\n/ => <<'=cut' } );

=pod

    'Twas brillig, and the slithy toves
    Did gyre and gimble in the wabe;
    All mimsy were the borogoves,
    And the mome raths outgrabe.

    'Beware the Jabberwock, my son!
    The jaws that bite, the claws that catch!
    Beware the Jubjub bird, and shun
    The frumious Bandersnatch!'

    He took his vorpal sword in hand:
    Long time the manxome foe he sought--
    So rested he by the Tumtum tree,
    And stood awhile in thought.

    And as in uffish thought he stood,
    The Jabberwock, with eyes of flame,
    Came whiffling through the tulgey wood,
    And burbled as it came!

    One, two! One, two! And through and through
    The vorpal blade went snicker-snack!
    He left it dead, and with its head
    He went galumphing back.

    'And has thou slain the Jabberwock?
    Come to my arms, my beamish boy!
    O frabjous day! Callooh! Callay!'
    He chortled in his joy.

    'Twas brillig, and the slithy toves
    Did gyre and gimble in the wabe;
    All mimsy were the borogoves,
    And the mome raths outgrabe.

=cut

}

1;

=head1 OTHER PERLISH VERSIONS

Some perlmonks have tried their hand on this classic too:

=over 4

=item *

L<http://perlmonks.org/?node_id=29907> by wombat,

=item *

L<http://perlmonks.org/?node_id=111157> by andreychek,

=item *

L<http://perlmonks.org/?node_id=195873> by RMGir.

=back

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-09-25

Introduced in Acme-MetaSyntactic version 0.93.

=item *

2005-10-24

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>,

=cut

