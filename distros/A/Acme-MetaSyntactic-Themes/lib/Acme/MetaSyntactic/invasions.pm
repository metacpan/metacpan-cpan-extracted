package Acme::MetaSyntactic::invasions;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.001';

=head1 NAME

Acme::MetaSyntactic::invasions - The naval and airborne invasions theme

=head1 DESCRIPTION

This list gives some codenames for naval invasions, paradrops and
operations with both a naval invasion component and an airborne
component during World War II. The list includes some operations which
were planned but not executed.

Sources, among others:

=over 4

=item *

the I<Codeword Dictionnary>,
Paul Adkins, Motorbooks International
(ISBN 0-7603-00368-1)

=item *

I<Strategy & Tactics> #160, May 1993

=back

=cut

{
    my %seen;
    __PACKAGE__->init(
        {   names => join ' ',
            grep    { !$seen{$_}++ }
                map { s/_+/_/g; $_ }
                map { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
                map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
                map { /^=item\s+(.*?)\s*$/ ? $1 : () }
                split /\n/ => <<'=cut'} );

=pod

=over 4

=item Al

Diversionary invasion of the Aleutians, in support of the invasion of Midway. Executed on 7th June 1942.

=item Anvil

Invasion of the South of France, near Toulon and Marseille. Executed as "Dragoon" on 15th August 1944.

=item Avalanche

Invasion on Salerno, executed on 9 September 1943.

=item Barracuda

Invasion of the Naples region, also known as Gangway or Mustang. Planned but never executed.

=item Baytown

Diversionary invasion of Calabria near Reggio Calabria, executed on 3rd September 1943,
in support of Avalanche and Slapstick.

=item Brimstone

Invasion of Sardinia. Planned but never executed.

=item Buttress

Invasion of Calabria near Cetrano, Almantea and Pizzo. Planned but never executed.

=item Coronet

Invasion of Honshu, in the Tokyo Plain. Planned for December 1945 or March 1946, but
the war ended before.

=item Detachment

Invasion of Iwo Jima. Executed on 19th February 1945.

=item Dragoon

Invasion of the South of France, near Toulon. Executed on 15th August 1944. Also known
as "Anvil".

=item Eclipse

Paradrop on Berlin. Planned but never executed.

=item Firebrand

Invasion of Corsica. Planned but never executed.

=item Flintlock

Invasion of Kwajalein. Executed on 31st January 1944.

=item Gangway

Invasion of the Naples region, also known as Barracuda or Mustang. Planned but never executed.

=item Giant_I

Paradrop on Caserta, Capua and the Volturno river, in support of Avalanche. Planned but
never executed.

=item Giant_II

Paradrop on Rome. Planned but never executed.

=item Goblet

Invasion of Calabria near Crotone. Planned but never executed.

=item Gruener_Pfeil

German invasion of Jersey and Guernsey. Executed on 1st July 1940. The islands were
occupied until 8th May 1945.

=item Herkules

German airborne invasion of Malta. Planned but never executed.

=item Husky

Invasion of Sicily, executed on 10th July 1943.

=item Iceberg

Invasion of Okinawa. Executed on 1st April 1945.

=item Ikarus

German invasion of Iceland. Planned but never executed.

=item Jubilee

Probing invasion of Dieppe. Executed on 19th August 1942.

=item Leopard

German invasion of the Greek island Leros. Executed on 12th November 1943.

=item Market_Garden

Joint airborne + armored invasion of the Netherlands. Executed on 7th September 1944.

=item Menace

Invasion of Dakar by British and Free French troops. Attempted on 23rd September 1940.

=item Merkur

German paradrop on Crete. Executed on 20th May 1941.

=item Mi

Japanese invasion of Midway. Attempted on 3rd June 1942.

=item Mo

Japanese plan including operation Al and operation Mi.

=item Musket

Invasion of Southern Italy. Planned but never executed.

=item Mustang

Invasion of the Naples region, also known as Barracuda or Gangway. Planned but never executed.

=item Oboe

A series of landings by American and Australian troops on Borneo and neighbour
islands. Executed between May 1945 and July 1945.

=item Olympic

Invasion of Kyushu. Planned for 1st November 1945, but the war ended before this date.

=item Overlord

Invasion of Normandy. Executed on 6th June 1944.

=item Roundhammer

Invasion of Northern France. The plan was proposed but never adopted.

=item Roundup

Invasion of Northern France in 1943. Planned but never executed.

=item Seeloewe

German invasion of Great Britain. Planned for September 1940, but never executed.

=item Shingle

Invasion on Anzio, executed on 22nd January 1944.

=item Shoestring

Invasion of Guadalcanal. Executed on 7th August 1942. Its official name is "Watchtower".

=item Slapstick

Invasion on the Gulf of Taranto, executed on 9th September 1943.

=item Sledgehammer

Invasion of Western Europe. Considered in 1942 but never planned.

=item Torch

Invasion of North Africa. Executed on 8th November 1942.

=item Varsity

Paradrop across the Rhine. Executed on 23rd March 1945.

=item Victor

Series of amphibious landings on the Philippine Islands. Executed in 1945.

=item Watchtower

Invasion of Guadalcanal. Executed on 7th August 1942. Nicknamed as "Shoestring".

=back

=cut

}

# Ending a module with 0 is wrong. Ending it with 1 is correct, but boring.
# So why not ending it with a few verses from Paul Verlaine?
q{
Les sanglots longs
des violons
de l'automne
Blessent mon coeur
D'une langeur
Monotone
};

__END__

=head1 CONTRIBUTOR

Jean Forget

=head1 CHANGES

=over 4

=item *

2015-02-02 - v1.001

Include names from I<Strategy & Tactics> #160.

Use the "POD inside here-doc" trick to give some historical tidbits about the various names.

Published in Acme-MetaSyntactic-Themes v1.045.

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-09-18

Introduced in Acme-MetaSyntactic version 0.92,
on the 62nd anniversary of Market-Garden.

=item *

2006-06-14

Submitted by Jean Forget.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut
