# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Acme::MetaSyntactic::soviet -- NATO codenames for Soviet-designed equipment
#     Copyright (C) 2008, 2012, 2016, 2021 Jean Forget
#
#     See the license in the embedded documentation below.
#
package Acme::MetaSyntactic::soviet;

use warnings;
use strict;

use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '0.06';

my $data = { default => 'electronic' };
my ($category2, $category3);
my %seen;

_load_data_from_pod();

__PACKAGE__->init($data);

sub _load_data_from_pod {

  while (<DATA>) {
    if (/^=head2\s+(.*)/) {
      _flush_category();
      $category2 = lc($1);
      $category3 = '';
    }
    elsif (/^=head3\s+(.*)/) {
      _flush_category();
      $category3 = lc($1);
    }
    elsif (/=item\s+(.*?)\s*$/) {
      my $name = $1;
      $name =~ s/\s+/_/g;
      $name =~ s/_+/_/g;
      $seen{$name} = 1;
    }
    elsif (/^=head1/) {
      last;
    }
  }
  _flush_category();
}

sub _flush_category {
  if ($category2 and %seen) {
    $data->{names}{$category2}{$category3} = join ' ', sort keys %seen;
  }
  %seen = ();
}

38;
# Why 38? Hint: s/r$/t/

=encoding utf8

=head1 NAME

Acme::MetaSyntactic::soviet -- NATO codenames for Soviet-designed equipment

=head1 DESCRIPTION

Some codenames  given by  NATO to Soviet-designed  aircraft, missiles,
submarines,   radars  and  other   electronic  systems.   The  various
categories and sub-categories are

=over 4

=item *

electronic

=item *

electronic/radars

=item *

electronic/misc

=item *

vehicles

=item *

vehicles/aircraft

=item *

vehicles/helicopters

=item *

vehicles/missiles

=item *

vehicles/submarines

=item *

vehicles/error

=back

The default category is 'electronic'.

=head1 VERSION

This  is  version 0.06,  the  Fresco  version,  released on  the  49th
anniversary  of the  dogfight between  a  MiG-17 Fresco  flown by  ace
Colonel Tomb and a F-4 Phantom flown by soon-to-be-aces Cunningham and
Driscoll

=head1 SYNOPSIS

    use Acme::MetaSyntactic;

    my $meta = Acme::MetaSyntactic->new( 'soviet' );

    print $meta->name();          # return a single name
    my @names = $meta->name( 4 ); # return 4 distinct names (if possible)

If you want some category other than 'electronic', the second line should
read:

    my $meta = Acme::MetaSyntactic->new( 'soviet', category => 'vehicle/aircraft' );

If C<meta>  from L<Acme::MetaSyntactic> is  installed, you can  use it
from the command line:

    meta soviet

    meta soviet/vehicles/submarines

=head1 CONTRIBUTOR

Jean Forget

=head1 SOURCES

Note: I  have used only  sources published  I<before> the fall  of the
Soviet Union. Therefore, the module  name is C<A::MS::soviet>, with no
"ex-"  prefix. For  each  entry,  the sources  are  listed, with  page
numbers  for  most  books.  The   games  use  data  cards,  which  are
unnumbered.

Some sources, especially early  sources, may contain some errors. Some
equipment  may appear with  faulty intelligence  reports which  give a
wrong  code or  description.  And  a later  intelligence  report would
correct it.  The best  example is the  Backfire, first given  the code
"Tu-26" and then the code "Tu-22M".

=head2 Main Sources

These sources  contain extensive lists  or extensive tables  of soviet
equipment.

=over 4

=item *

I<Pat-Led-1>
written by J-J Patry and P. Lederer
published by Editions Presse & Recherche
abbreviated as I<PL>.

=item *

I<Jane's World Aircraft Recognition Handbook>
written by Derek Wood
published by Janes in 1987
(ISBN 0-7106-0343-6)
abbreviated as I<JWARH>.

=item *

I<Air Superiority>
designed by J.D. Webster
and published by GDW in 1987
(ISBN 0-943580-19-6) see
L<https://boardgamegeek.com/boardgame/3613/air-superiority>
abbreviated as I<ASu>.

=item *

I<Air Strike>
designed by J.D. Webster
and published by GDW in 1987
(ISBN 0-943580-30-7), see
L<https://boardgamegeek.com/boardgameexpansion/3614/air-strike>
abbreviated as I<ASt>.

=item *

I<Desert Falcons>
designed by J.D. Webster
and published by GDW in 1988
(ISBN 0-943580-97-8), see
L<https://boardgamegeek.com/boardgame/8474/desert-falcons>
abbreviated as I<DF>.

=item *

I<Les Flottes de Combat 1968>
written by H. Le Masson
published by Editions Maritimes et Outre-Mer
(no ISBN)
abbreviated as I<LFDC>.

=item *

I<Flottes de Combat 1990>
written by B. Prézelin
published by Editions Maritimes et Outre-Mer
(ISBN 2.7373.0485.7)
abbreviated as I<FDC>.

Note: these  last two  books are actually  the same book,  updated and
published every  other year.  You can notice  that the title  has been
shortened between the 1968 issue and the 1990 issue (FDC vs. LFDC).

=item *

I<Air Wars and Aircraft>
written by Victor Flintham
published by Arms and Armour in 1989
(ISBN 0-85368-779-X)
abbreviated as I<AWA>.

=item *

I<Air War>
designed by David Isby
published in 1977 by SPI and then in 1983 by TSR
(no ISBN), see
L<https://boardgamegeek.com/boardgame/1629/air-war-modern-tactical-air-combat>
abbreviated as I<SPIAW>.

=item *

I<How to Make War>
written by James F. Dunigan
published by Quill in 1988
(ISBN 0-668-07979-2)
abbreviated as I<HTMW>.

=item *

I<Science et Vie> special issue I<Aviation 77>
published by Excelsior Publications SA in May 1977
abbreviated as I<S&V>.

=item *

I<Aircraft Armament>
(or I<The Illustrated Encyclopedia of Aircraft Armament>)
written by Bill Gunston
published by Salamande Books Ltd. in 1987
(ISBN 0-86101-314-X)
abbreviated as I<IEAA>.

=back

=head2 Minor Sources

These  sources  mention some  NATO  codes  for  soviet equipment,  but
without trying to give an exhaustive list of some category or other.

=over 4

=item *

I<Rolling Thunder>
designed by Steve Weiss
published by Group Three Games in 1985
(no ISBN), see
L<https://boardgamegeek.com/boardgame/6228/rolling-thunder>
abbreviated as I<RT>.

=item *

I<Fox Two>
by Randy Cunningham with Jeff Ethell
published by Warner Books in 1984
ISBN 0-446-35458-9
abbreviated as I<F2>.

=item *

I<The Hunt for Red October>
by Tom Clancy,
first published by Naval Institute Press in 1984
published by Fontana in 1987
ISBN 0-00-617276-8
abbreviated at I<THFRO>.

=item *

I<Red Storm Rising>
by Tom Clancy,
first published by G.P. Putnam's Sons in 1986,
published by Berkley International Edition in 1987
ISBN 0-425-10242-4
abbreviated as I<RSR>.

=item *

I<Helicopter Aces>
by James W Bradin,
published by Avon Books in 1990,
ISBN 0-380-75847-4,
abbreviated as I<HA>.

=item *

I<Bullseye One Reactor> written by  Dan McKinnon published by House of
Hits  Publishing  in 1987  and  by  Airlife  Publishing Ltd  in  1988,
abbreviated  as   I<B1R>.  For  the   ISBN,  I  am  puzzled.   On  the
administrative page at  the beginning of the book, there  is a sticker
with number 1 85310 033 1 and on  the flap of the book cover, the ISBN
is 1 85310 032 3. Take your pick.

=item *

I<Air Warfare in the Missile Age> by Lon O. Nordeen, Jr., published by
the Smithsonian  Institution in 1985  and by  Air and Armour  Press in
1985, ISBN 0-85368-751-X, abbreviated as I<AWMA>.

=back

=head1 SOVIET EQUIPMENT

=cut

__DATA__

=head2 ELECTRONIC

The codenames for electronic devices are composed of two words. As you
can notice, similar  devices share one word and  differ with the other
word, e.g. Scan Fix and Scan Odd.  You may find in other sources these
codenames aggregated as a single word, e.g. Barlock.

=head3 RADARS

=over 4

=item Ball End

Navigation radar, FDC 758.

=item Bar Lock

Warning radar, PL 124, mentioned in RT.

=item Bass Tilt

Gun control radar, FDC 760.

=item Bee Hind

Radar mounted on Badger and Bear, FDC 760.

=item Big Fred

Battlefield surveillance radar, PL 97.

=item Big Net

Early warning radar, FDC 758.

=item Big Nose

Radar on Tu-28P, IEAA 157.

=item Big Screen

Early warning radar, FDC 759.

=item Cake Stand

Target tracking radar, FDC 759.

=item Cross Bird

Early warning radar, FDC 758.

=item Cross Sword

Target tracking radar, FDC 759.

=item Dog Ear

2S6 and SA-9 Gaskin warning and acquisition radar, PL 104, 116, 122.

=item Don Kay

Navigation radar, FDC 758.

=item Down Beat

Radar mounted on Backfire, FDC 760. Mentionned in RSR.

=item Drum Tilt

Gun control radar, FDC 759.

=item Egg Cup

Gun control radar, FDC 759.

=item Eye Bowl

Target tracking radar, FDC 759.

=item Fan Song

Guidance radar for SA-2 missiles, mentioned in RT and AWMA.

=item Fire Dome

SA-11 Gadfly fire control radar, PL 114.

=item Flap Lid

SA-10 Grumble fire control radar, PL 115.

=item Flat Face

Warning and acquisition radar, PL 123.

=item Fox Fire

Radar on MiG-25, DF, IEAA 157, 158. Mentionned in RSR.

=item Front Dome

Gadfly fire control radar, FDC 759.

=item Front Door

Target tracking radar, FDC 759.

=item Front Piece

Submarine mounted radar, FDC 759.

=item Gun Dish

ZSU-23-4 fire control radar, PL 105, mentioned in RT and AWMA.

=item Half Cup

Infrared warning, FDC 760.

=item Hawk Screech

Gun control radar, FDC 759.

=item Head Lights

Target tracking radar, FDC 759.

=item Head Net

Early warning radar, FDC 758.

=item High Fix

Radar on MiG-21F and Su-17/22, ASu, DF.

=item High Lark

Radar on MiG-23M and MiG-23MF, ASu, DF, IEAA 159. Mentioned in RSR.

=item High Sieve

Early warning radar, FDC 758.

=item Hot Shot

Surveillance, acquisition and tracking radar, PL 104.

=item Jay Bird

Radar on MiG-21MF and MiG-21bis, ASu and AWMA.

=item Kite Screech

Gun control radar, FDC 759.

=item Land Roll

SA-13 Gopher and SA-8 Gecko fire control radar, PL 113, 117.

=item Long Track

SA-6 Gainful and SA-4 Ganef warning and acquisition radar, PL 118, 119, 121.

=item Low Blow

Radar used by SA-3 Goa, mentioned in AWMA.

=item Muff Cob

Gun control radar, FDC 759.

=item Owl Screech

Gun control radar, FDC 759.

=item Palm Frond

Naigation radar, FDC 758.

=item Pat Hand

SA-4 Ganef acquisition and tracking radar, PL 119.

=item Peel Cone

Early warning and target designation radar, FDC 759.

=item Peel Group

Target tracking radar, FDC 759.

=item Plank Shave

Early warning and target designation radar, FDC 759.

=item Plate Steer

Early warning radar, FDC 759.

=item Pop Group

Target tracking radar, FDC 759.

=item Pork Through

Battlefield surveillance radar and artillery support, PL 97.

=item Pot Head

Warning radar, FDC 759.

=item Pot Drum

Warning radar, FDC 759.

=item Puff Ball

Radar mounted on Badger and Bear, FDC 760.

=item Scan Fix

Ranging radar on MiG-15P and MiG-17P, DF.

=item Scan Odd

Radar on MiG-19P, DF.

=item Scan Three

Radar on Yak-25, IEAA 157.

=item Scoop Pair

Target tracking radar, FDC 759.

=item Side Net

Aircraft altitude acquisition radar, PL 124.

=item Skip Spin

Radar on  Su-15, ASu, DF, and  on Yak-28P and Su-11  according to IEAA
157.

=item Sky Watch

Early warning radar, FDC 759.

=item Slim Net

Early warning radar, FDC 758.

=item Small Fred

Battlefield surveillance radar, PL 98.

=item Small Yawn

Counter-battery radar, PL 98.

=item Snoop Pair

Submarine mounted radar, FDC 759.

=item Snoop Plate

Submarine mounted radar, FDC 759.

=item Snoop Slab

Submarine mounted radar, FDC 759.

=item Snoop Tray

Submarine mounted radar, FDC 759.

=item Spin Scan

Radar on MiG-21MF, ASu and AWMA.

=item Spin Trough

Navigation radar, FDC 758.

=item Spoon Rest

Warning and acquisition radar, PL 123.

=item Square Tie

Early warning and target designation radar, FDC 759.

=item Straight Flush

SA-6 Gainful surveillance and tracking radar, PL 118, 120, B1R 134, AWMA.

=item Strut Curve

Early warning radar, FDC 758.

=item Strut Pair

Early warning and target designation radar, FDC 758, 759.

=item Sun Visor

Gun control radar, FDC 759.

=item Tall Mike

Radar mounted on some variants of the BRM reco vehicle, PL 11.

=item Thin Skin

SA-6 Gainful aircraft altitude acquisition radar, PL 118, 121.

=item Top Dome

Target tracking radar, FDC 759.

=item Top Knot

Target tracking radar, FDC 759.

=item Top Pair

Early warning radar, FDC 758.

=item Top Plate

Early warning radar, FDC 759.

=item Top Sail

Early warning radar, FDC 759.

=item Top Steer

Early warning radar, FDC 759.

=item Top Trough

Early warning radar, FDC 758.

=item Trap Door

Target tracking radar, FDC 759.

=item Two Spots

Aircraft acquisition radar, PL 122.

=back

=head3 MISC

This category lists some electronic devices other than radars: sonars,
ECM devices, etc.

=over 4

=item Band Stand

Data transmission system, FDC 759.

=item Bell Bash

Electronic warfare, FDC 760.

=item Bell Clout

Electronic warfare, FDC 760.

=item Bell Shroud

Electronic warfare, FDC 760.

=item Bell Squat

Electronic warfare, FDC 760.

=item Bell Thumb

Electronic warfare, FDC 760.

=item Big Ball

Satellite communication, FDC 760.

=item Big Bulge

Satellite communication, FDC 760. Mentioned several times in RSR.

=item Brick Group

Submarine ECM, FDC 760.

=item Brick Pulp

Submarine ECM, FDC 760.

=item Brick Spit

Submarine ECM, FDC 760.

=item Bull Horn

Hull mounted sonar, FDC 760.

=item Bull Nose

Hull mounted sonar, FDC 760.

=item Cage Bare

Transmission equipment, FDC 760.

=item Cage Cone

Transmission equipment, FDC 760.

=item Cage Pot

Electronic warfare, FDC 760.

=item Cage Stalk

Transmission equipment, FDC 760.

=item Code Eye

Submarine ECM, FDC 760.

=item Elk Tail

Towed sonar, FDC 760.

=item Fish Bowl

Satellite communication, FDC 760.

=item Grid Crane

Electronic warfare, FDC 760.

=item High Pole

IFF equipemnt, FDC 760.

=item Horse Jaw

Hull mounted sonar, FDC 760. Mentionned in RSR.

=item Horse Tail

Towed sonar, FDC 760.

=item Light Bulb

Satellite communication, FDC 760.

=item Low Ball

Satellite communication, FDC 760.

=item Mare Tail

Towed sonar, FDC 760.

=item Moose Jaw

Hull mounted sonar, FDC 760.

=item Pert Spring

Satellite communication, FDC 760.

=item Park Lamp

Submarine ECM, FDC 760.

=item Plinth Net

Data transmission system, FDC 759.

=item Pop Art

Transmission equipment, FDC 760.

=item Punch Bowl

Satellite communication, FDC 760.

=item Rum Tub

Electronic warfare, FDC 760.

=item Salt Pot

IFF equipemnt, FDC 760.

=item Site Crane

Electronic warfare, FDC 760.

=item Sprat Star

Electronic warfare, FDC 760.

=item Square Head

IFF equipemnt, FDC 760.

=item Squid Ram

Sonar mounted on submarines, FDC 760.

=item Shark Gill

Sonar mounted on submarines, FDC 760.

=item Shark Teeth

Sonar mounted on submarines, FDC 760.

=item Side Globe

Electronic warfare, FDC 760.

=item Squeeze Box

Infrared warning, FDC 760.

=item Stop Light

Submarine ECM, FDC 760.

=item Straight Key

Transmission equipment, FDC 760.

=item Tee Plinth

Infrared warning, FDC 760.

=item Tin Man

Infrared warning, FDC 760.

=item Top Hat

Electronic warfare, FDC 760.

=item Vee Bars

Transmission equipment, FDC 760.

=item Vee Cone

Transmission equipment, FDC 760.

=item Vee Tube

Transmission equipment, FDC 760.

=item Watch Dog

Electronic warfare, FDC 760.

=back

=head2 VEHICLES

This  category lists  flying and  naval vehicles.  These  vehicles are
submarines, planes, helicopter or missiles.

=head3 SUBMARINES

=over 4

=item Akula

Nuclear-powered attack submarine (SSN), FDC 790, HTMW 224+253.

=item Alfa

Nuclear-powered  attack submarine  (SSN), FDC  789, HTMW  253. Spelled
"Alpha"  in HTMW 284.  A prominent  character of  THFRO, appears  in a
crucial part of RSR.

=item Beluga

Attack submarine (SS), FDC 794.

=item Bravo

Auxiliary / rescue submarine (SST), FDC 798.

=item Charlie I

Nuclear-powered aerodynamic missile submarine (SSGN), FDC 785, HTMW 224. Mentioned in THFRO and RSR.

=item Charlie II

Nuclear-powered aerodynamic missile submarine (SSGN), FDC 785, HTMW 224+253. Mentioned in THFRO.

=item Delta I

Nuclear-powered ballistic missile submarine (SSBN), FDC 781, HTMW 224. Mentioned (without number) in THFRO and RSR.

=item Delta II

Nuclear-powered ballistic missile submarine (SSBN), FDC 781, HTMW 224.

=item Delta III

Nuclear-powered ballistic missile submarine (SSBN), FDC 780, HTMW 224.

=item Delta IV

Nuclear-powered ballistic missile submarine (SSBN), FDC 780, HTMW 224.

=item Echo

Nuclear-powered attack submarine (SSN), FDC 793. Mentioned in HTMW 224 as Echo I. Mentioned in THFRO and RSR.

=item Echo II

Nuclear-powered  aerodynamic  missile  submarine (SSGN),  FDC  786  or
nuclear-powered auxiliary / rescue submarine (SSAN), FDC 797.

=item Echo II Mod

Nuclear-powered aerodynamic missile submarine (SSGN), FDC 786.

=item Echo III

Nuclear-powered attack submarine (SSN), HTMW 224.

=item Fox Trot

Attack submarine (SS), FDC 795, HTMW 224. Mentioned iun RSR.

=item Golf II

Ballistic missile submarine (SSB), FDC 783, HTMW 224. Mentioned (without number) in THFRO.

=item Golf II Mod

Command submarine (SSQ), FDC 798.

=item Hotel II

Nuclear-powered command submarine (SSQN), FDC 798.

=item Hotel III

Nuclear-powered ballistic missile submarine (SSBN), FDC 782, HTMW 224.

=item India

Auxiliary / rescue submarine (SSA), FDC 797.

=item Juliett

Aerodynamic missile submarine (SSG), FDC 788, HTMW 224. Mentioned in RSR.

=item Juliett Mod

Aerodynamic missile submarine (SSG), FDC 788.

=item Kilo

Attack submarine (SS), FDC 794, HTMW 253.

=item Lima

Auxiliary / rescue submarine (SSA), FDC 797.

=item Mike

Submarine, unspecified category, HTMW 224+253. Mentioned in RSR.

=item Mir

Tracked rescue submarine, FDC 798.

=item November

Nuclear-powered attack submarine (SSN), FDC 793, HTMW 224. Mentioned in THFRO and RSR.

=item Oscar I

Nuclear-powered aerodynamic missile submarine (SSGN), FDC 784, HTMW 253. Mentioned (without number) in THFRO and RSR.

=item Oscar II

Nuclear-powered aerodynamic missile submarine (SSGN), FDC 783.

=item Papa

Nuclear-powered aerodynamic missile submarine (SSGN), FDC 785, HTMW 224. Mentioned in RSR.

=item Romeo

Attack submarine (SS), FDC 796, HTMW 224.

=item Sierra

Nuclear-powered attack submarine (SSN), FDC 790, HTMW 224+253.

=item Tango

Attack submarine (SS), FDC 795, HTMW 224+253. Mentioned in THFRO and a prominent character of RSR.

=item Typhoon

Nuclear-powered ballistic missile submarine (SSBN), FDC 779, HTMW 224. A prominent character of THFRO.

=item Uniform

Nuclear-powered auxiliary / rescue submarine (SSAN), FDC 797.

=item Victor I

Nuclear-powered attack submarine (SSN), FDC 793, HTMW 224. Mentioned in THFRO and a prominent character of RSR.

=item Victor II

Nuclear-powered attack submarine (SSN), FDC 792, HTMW 224. Mentioned in THFRO.

=item Victor III

Nuclear-powered attack submarine (SSN), FDC 791, HTMW 224+253.

=item Whiskey

Attack submarine (SS), FDC 796, HTMW 224.

=item X Ray

Nuclear-powered auxiliary / rescue submarine (SSAN), FDC 798.

=item Yankee I

Nuclear-powered  ballistic  missile   submarine  (SSBN),  FDC  782  or
nuclear-powered attack  submarine (SSN),  FDC 794.  Also  mentioned in
HTMW 224+253 without precisions.   Mentioned (without number) in THFRO
and RSR.

=item Yankee II

Nuclear-powered ballistic missile submarine (SSBN), FDC 781.

=item Yankee Notch

Nuclear-powered aerodynamic missile submarine (SSGN), FDC 787.

=item Zulu IV

Auxiliary / rescue submarine (SSA), FDC 797.

=item Zulu V

Auxiliary / rescue submarine (SSA), FDC 797.

=back

=head3 AIRCRAFT

=over 4

=item Backfin

Yak aircraft, number unknown, AWA 392.

=item Backfire

Tu-22M / Tu-26  variable geometry bomber, JWARH 37, 189,  FDC 775, AWA
392, SPIAW,  HTMW 165+267+436, S&V 92,  IEAA 47, 92, 109,  110, 111. A
very prominent character in RSR.

=item Badger

Tu-16  bomber,  JWARH  37,  93,  LFDC 368,  FDC  774,  AWA  392,  HTMW
165+267+436, AWMA, IEAA 36, 96, 110. A prominent character in RSR.

=item Bank

Light bomber based on the B-25 Mitchell or maybe lend-lease B-25, AWA 392.

=item Bark

Il-2, AWA 392.

=item Bat

Tu-2, AWA 392.

=item Beagle

Il-28 bomber, JWARH 37, 216, LFDC 368, AWA 392, IEAA 36, 140.

=item Bear

Tu-95 bomber or Tu-142 bomber (Bear F and H), JWARH 37, 121, LFDC 368,
FDC  774, AWA  392,  HTMW 165+436,  IEAA 109,  111,  140. A  prominent
character in RSR.

=item Beast

Il-10, AWA 392.

=item Bison

M-4 bomber, JWARH 37, 94, AWA 392, HTMW 436, IEAA 183.

=item Blackjack

Tu supersonic bomber, JWARH 37, AWA 392, HTMW 165+436, IEAA 111.

=item Blinder

Tu-22 bomber, JWARH 37, 132, LFDC 368, FDC 774, AWA 392, HTMW 165+436,
S&V 91, IEAA 47, 109, 157, B1R 31. Mentioned in RSR.

=item Blowlamp

Il-54, AWA 392.

=item Bob

Il-4, AWA 392.

=item Boot

Tu-91, AWA 392.

=item Bosun

Tu-14, AWA 392.

=item Bounder

M-? (number unknown), AWA 392 or Tu-?, LFDC 368.

=item Box

Attack aircraft based on the A-20 Havoc or maybe lend-lease A-20, AWA 392.

=item Brawny

Il-40, AWA 392.

=item Brassard

Yak-25, AWA 392.

=item Brewer

Yak-28 strike / attack aircraft, JWARH 37, 99, AWA 392.

=item Buck

Pe-2, AWA 392.

=item Bull

Tu-4 Heavy bomber based on the B-29, AWA 392.

=item Cab

Li-2 transport aircraft, based on the C-47, JWARH 37.

=item Camber

Il-86 transport aircraft, JWARH 37, 114, AWA 392.

=item Camel

Tu-104 transport aircraft, JWARH 37, AWA 392.

=item Camp

An-8 transport aircraft, JWARH 37, AWA 392.

=item Candid

Il-76 transport aircraft, PL 218, JWARH 37, 118, AWA 392. Mentioned in RSR.

=item Careless

Tu-154 transport aircraft, JWARH 37, 134, AWA 392, S&V 51.

=item Cash

An-28 transport aircraft, PL 221, JWARH 37, 306, AWA 392.

=item Cart

Tu-70, AWA 392.

=item Cat

An-10 transport aircraft, JWARH 37, AWA 392.

=item Charger

Tu-144 supersonic airliner, JWARH 37, S&V 50.

=item Clam

Ilyushin aircraft, number unknown, AWA 392.

=item Clank

An-30 transport aircraft, JWARH 37, 28, AWA 392.

=item Classic

Il-62 airliner, JWARH 37, 138, AWA 392, S&V 49.

=item Cleat

Tu-114 transport aircraft, JWARH 37, AWA 392.

=item Cline

An-32 transport aircraft, PL 220, JWARH 37, 288, AWA 392.

=item Clobber

Yak-42 airliner, JWARH 37, 139, AWA 392.

=item Clod

An-14 transport aircraft, JWARH 37, 305, AWA 392.

=item Coach

Il-12 transport aircraft, JWARH 37, AWA 392.

=item Coaler

An-72/74 transport aircraft, PL 221, JWARH 37, AWA 392.

=item Cock

An-22 transport aircraft, PL 219, JWARH 37, 329, AWA 392.

=item Codling

Yak-40 transport aircraft, JWARH 37, 160, AWA 392.

=item Coke

An-24 transport aircraft, JWARH 37, 286, AWA 392.

=item Colt

An-2 WW-2 vintage biplane transport  aircraft, JWARH 37, 469, AWA 392,
AWMA.

=item Condor

An-124 transport aircraft, PL 218, JWARH 37, AWA 392.

=item Cooker

Tu-110, AWA 392.

=item Cookpot

Tu-124 transport aircraft, JWARH 37.

=item Coot

Il-18 / Il-20 airliner, JWARH 38, 315, AWA 392.

=item Cork

Yak-16, AWA 392.

=item Crate

Il-14 airliner, JWARH 38, 228, AWA 392.

=item Creek

Yak-12 transport aircraft, JWARH 38, AWA 392.

=item Crow

Yak-10, AWA 392.

=item Crusty

Tu-134 transport aircraft, JWARH 38, 133, AWA 392, S&V 50.

=item Cub

An-12 transport aircraft, PL 219, JWARH 38, 327, AWA 392.

=item Cuff

Be-30 transport aircraft, JWARH 38.

=item Curl

An-26 transport aircraft, PL 220, JWARH 38, 286, AWA 392.

=item Fagot

MiG-15bis, JWARH 38, DF, AWA 392, SPIAW, AWMA.

=item Fang

La-11 fighter, AWA 392.

=item Fantail

La-15 fighter, AWA 392.

=item Fargo

MiG-9 fighter, AWA 392.

=item Farmer

MiG-19 fighter, PL 213, JWARH 38, 56, DF, AWA 392, SPIAW, AWMA.

=item Feather

Yak-17 fighter, AWA 392.

=item Fencer

Su-24 variable  geometry strike fighter,  PL 211, JWARH 38,  187, ASt,
AWA 392, HTMW 165, AWMA, IEAA 111. Or Su-19 according to SPIAW and S&V
92.

=item Fiddler

Tu-28 and Tu-118 fighters, PL 223, JWARH 38, 75, AWA 392, IEAA 157.

=item Fin

La-7 fighter, AWA 392.

=item Firebar

Yak-28 fighter, PL 222, JWARH 38, 98, AWA 392.

=item Fishbed

MiG-21 fighter, PL  211, JWARH 38, 177, ASu, DF,  AWA 392, SPIAW, HTMW
165, S&V 91, AWMA.

=item Fishpot

Su-9/Su-11 fighter, PL 222, JWARH 38, 176, AWA 392.

=item Fitter

Su-7  fighter  (Fitter A)  or  Su-17/20/22  variable geometry  fighter
(Fitter C, D and H) or Su-17 fighter (Fitter K), PL 212, JWARH 38, 57,
186, ASu, FDC 775, AWA 392, SPIAW, HTMW 165, B1R 31, AWMA, IEAA 156.

=item Flagon

Su-21 fighter aircraft, PL 222, IEAA  157. Or Su-15 fighter, JWARH 38,
175, ASu, DF, AWA 392, SPIAW, HTMW 165, S&V 92.

=item Flanker

Su-27 fighter, PL 208, JWARH 38, 88, ASu, AWA 392, HTMW 165, IEAA 160.
Mentioned in RSR.

=item Flashlight

Yak-25 and Yak-27 fighters, AWA 392.

=item Flogger

MiG-23 variable geometry fighter (Flogger  A and G) or MiG-27 variable
geometry fighter (Flogger  D and J), PL 210, JWARH  38, 184, 185, ASu,
ASt, DF,  AWA 392, SPIAW,  HTMW 165, S&V 92,  B1R 31, 130,  AWMA, IEAA
156, 158. Mentioned in RSR.

=item Flora

Yak-23 fighter, AWA 392.

=item Forger

Yak-38 VSTOL  fighter, PL 214,  JWARH 38, 64,  FDC 775, AWA  392, HTMW
165, S&V 156, IEAA 111, 159. Mentioned in THFRO.

=item Foxbat

MiG-25 interceptor,  PL 223, 224,  JWARH 38,  85, DF, AWA  392, SPIAW,
HTMW 165, S&V 91, AWMA, IEAA 157, 158. Mentioned in RSR.

=item Foxhound

MiG-31 interceptor, PL 224, JWARH 38, 86, ASu, AWA 392, HTMW 165, IEAA
160.

=item Frank

Yak-9 fighter, AWA 392.

=item Fred

Lend-lease P-63 fighter, AWA 392.

=item Fresco

MiG-17 fighter, PL 213, JWARH 38, 55, DF, AWA 392, SPIAW, AWMA.

=item Fritz

La-9 fighter, AWA 392.

=item Frogfoot

Su-25 attack aircraft, PL 209, JWARH  38, 212, ASt, AWA 392, HTMW 165,
IEAA 134.

=item Fulcrum

MiG-29 fighter,  PL 208, JWARH  38, 87, ASu,  AWA 392, HTMW  165, IEAA
159. Mentioned in RSR.

=item Madge

Be-6 flying boat, JWARH 38, LFDC 368, AWA 392.

=item Maestro

Yak-28U trainer version of Firebar and Brewer, JWARH 38, AWA 392.

=item Magnet

Yak-17U, AWA 392.

=item Magnum

Yak-30 aircraft, JWARH 38.

=item Maiden

Su-11U variant of Fishpot, JWARH 38, AWA 392.

=item Mail

Be-12 amphibian aircraft,  JWARH 39, 460, FDC 775, AWA  392, HTMW 267.
IEAA 140 and AWA 392 give also the M-12 designation.

=item Mainstay

Airborne radar aircraft, JWARH 39, AWA 392, HTMW 267. Mentioned in RSR.

=item Mandrake

Reconnaissance aircraft, JWARH 39, AWA 392.

=item Mangrove

Yak-27 reconnaissance aircraft, JWARH 39, AWA 392.

=item Mantis

Yak-32 trainer, JWARH 39.

=item Mare

Yak-14, AWA 392.

=item Mark

Yak-7U, AWA 392.

=item Mascot

Il-28U trainer, JWARH 39, AWA 392.

=item Max

Yak-18 trainer, JWARH 39, 360, AWA 392.

=item May

Il-38 maritime  reconnaissance aircraft, JWARH  39, 316, FDC  775, AWA
392, HTMW 267, IEAA 140. Mentioned in RSR.

=item Maya

L-29, AWA 392.

=item Midas

Il-76FR, AWA 392.

=item Midget

MiG-15UTI trainer aircraft, JWARH 39, 54, AWA 392.

=item Mink

Yak UT-2, AWA 392.

=item Mole

Be-8, AWA 392.

=item Mongol

MiG-21U trainer aircraft, JWARH 39, AWA 392.

=item Moose

Yak-18P trainer aircraft, JWARH 39, 360, AWA 392.

=item Mop

Lend-lease PBY Catalina, AWA 392.

=item Moss

Tu-126 airborne early  warning aircraft, JWARH 39, 122,  AWA 392, HTMW
267, AWMA.

=item Mote

Be-2, AWA 392.

=item Moujik

Su-7U trainer aircraft, JWARH 39, AWA 392.

=item Mug

Be-4, AWA 392.

=item Mule

Po-2 utility aircraft, JWARH 39, AWA 392.

=back

=head3 HELICOPTERS

=over 4

=item Hake

Mi-10 heavy transport helicopter, AWA 392.  This is not a typo in AWA,
because there are  two lines with Mi-10: Hake and  Harke. On the other
hand, it may be a copy-paste mishap.

=item Halo

Mi-26 heavy transport helicopter, PL 201, JWARH 38, 538, AWA 392, HTMW 163.

=item Hare

Mi-1 / Mi-3 light helicopter, JWARH 38, 509, AWA 392.

=item Harke

Mi-10 heavy transport helicopter, PL 202, JWARH 38, 539, AWA 392, S&V 122.

=item Harp

Ka-20 ASW helicopter, LFDC 368.

=item Havoc

Mi-28 attack helicopter, PL 198, JWARH 38, AWA 392, HTMW 163. Mentioned in HA.

=item Haze

Mi-14 naval  helicopter, JWARH 38,  529, FDC  775, AWA 392,  HTMW 267,
IEAA 140.

=item Helix

Ka-27 or Ka-32 naval transport  and support medium helicopter, PL 201,
JWARH 38, 542, FDC 775, AWA  392, HTMW 163+267, IEAA 140. Mentioned in
RSR.

=item Hen

Ka-15 light helicopter, JWARH 38, AWA 392.

=item Hind

Mi-24 / Mi-25 attack and transport  helicopter, PL 199, JWARH 38, 530,
AWA 392, HTMW 165, IEAA 134, 161, 182, 183. Mentioned in RSR and HA.

=item Hip

Mi-8 or Mi-17  medium transport and support helicopter,  PL 203, JWARH
38, 528, FDC 775,  AWA 392, HTMW 165, S&V 119,  IEAA 134. Mentioned in
RSR.

=item Hog

Ka-18 light helicopter, JWARH 38, AWA 392.

=item Hokum

Attack helicopter designed  by Kamov, PL 198, JWARH 38,  AWA 392, IEAA
161. Mentioned in HA.

=item Homer

Mi-12, AWA 392, S&V 122.

=item Hoodlum

Ka-26 light transport helicopter, PL 200, JWARH 38, 543, AWA 392, S&V 118.

=item Hook

Mi-6 heavy transport helicopter, PL 202, JWARH 38, 537, AWA 392, HTMW 165, S&V 119.

=item Hoplite

Mi-2 light  transport and support  helicopter, PL 204, JWARH  38, 513,
AWA 392, IEAA 134.

=item Hormone

Ka-25 naval helicopter, JWARH 38, 541, FDC 775, AWA 392, HTMW 163+267,
IEAA 140.

=item Horse

Yak-24, LFDC 368, AWA 392.

=item Hound

Mi-4  medium transport and support helicopter, PL 204, JWARH 38, 515, LFDC 368, AWA 392.

=back

=head3 MISSILES

This category lists Soviet missiles  with the NATO codename and the US
designation. The missiles' Soviet  designations were still a secret at
the time  of the  Soviet Union  collapse.  You will  note that  the US
designation is  different between  the ground-to-xxx variant  (no "N")
and the ship-to-xxx  variant (with a "N"), while  the NATO codename is
the same.

=over 4

=item Acrid

AA-6 air-to-air missile, PL 223, JWARH  30, DF, SPIAW, HTMW 174, AWMA,
IEAA 158.

=item Alamo

AA-10 air-to-air missile, PL 225, ASu, DF, HTMW 174, IEAA 160.

=item Alkali

AA-1 air-to-air missile, PL 213, SPIAW, AWMA.

=item Amos

AA-9 air-to-air missile, PL 224, ASu, HTMW 174, IEAA 158, 160.

=item Anab

AA-3 air-to-air  missile (soviet designation would  be RP-11 according
to IEAA), PL 222, JWARH 29, ASu, SPIAW, HTMW 174, IEAA 157, 160, 161.

=item Apex

AA-7 air-to-air  missile (or  R-23T and R-23R  according to  IEAA), PL
208, 210,  211, 224, JWARH 29,  ASu, SPIAW, HTMW 174,  AWMA, IEAA 158,
160.

=item Aphid

AA-8 air-to-air missile (or R-60 according to IEAA), PL 208, 210, 211,
214, 224, JWARH 29, ASu, SPIAW, HTMW 174, AWMA, IEAA 156, 159, 161.

=item Archer

AA-11 air-to-air missile, PL 225, IEAA 161.

=item Ash

AA-5 air-to-air missile, PL 223, JWARH 29, DF, IEAA 157, 158.

=item Atoll

AA-2 air-to-air  missile (K-13A or  SB-06 according to IEAA),  PL 210,
213, 222,  JWARH 30, DF,  SPIAW, HTMW 174,  AWMA, IEAA 156,  159, 161.
Mentioned in RT, F2 and THFRO.

=item Frog

Backcronym for "Free Rocket Over Ground", PL 96, AWMA.

=item Gadfly

SA-11 / SA-N-7 anti-aircraft missile, PL 114, FDC 755.

=item Gainful

SA-6 ground-to-air missile, PL 118, SPIAW, B1R 133, AWMA.

=item Ganef

SA-4 ground-to-air missile, PL 119.

=item Gaskin

SA-9 ground-to-air missile, PL 116.

=item Gecko

SA-8 / SA-N-4 anti-aircraft missile, PL 117, FDC 755, AWMA.

=item Gladiator

SA-12 ground-to-air missile, PL 114.

=item Goa

SA-3 / SA-N-1 anti-aircraft missile, LFDC 367, FDC 755, SPIAW, AWMA.

=item Goblet

SA-N-2 anti-aircraft missile, FDC 755.

=item Gopher

SA-13 ground-to-air missile, PL 113.

=item Grail

SA-7 / SA-N-5  anti-aircraft missile, FDC 755, SPIAW,  AWMA, IEAA 161.
RT gives a Russian name, I<Strela>.

=item Gremlin

SA-14 / SA-N-8 anti-aircraft missile, FDC 755.

=item Grumble

SA-10 / SA-N-6 anti-aircraft missile, PL 115, FDC 755.

=item Guideline

SA-2 / SNA-1 anti-aircraft missile, LFDC 367, SPIAW, AWMA.

=item Kangaroo

AS-3 air-to-ground missile,  HTMW 175, IEAA 109. Note:  JWARH 25 gives
the name  "Kangroo" (surely a typo  for kangaroo), and LFDC  367 gives
the name with a French spelling: "Kangourou".

=item Karen

AS-10 air-to-ground missile, PL 211, 226, FDC 756, IEAA 111.

=item Kedge

AS-14 air-to-ground missile, PL 211, 226, IEAA 111.

=item Kegler

Very brief entry in IEAA 111.

=item Kelt

AS-5 air-to-ground  missile, JWARH 25,  FDC 756, HTMW 174,  AWMA, IEAA
96, 110. Mentioned in RSR.

=item Kennel

AS-1 air-to-surface missile, LFDC 367.

=item Kent

AS-15 air-to-ground missile, FDC 756, IEAA 111.

=item Kerry

AS-7 air-to-ground missile, PL 209, 212,  214, 226, JWARH 27, FDC 756,
HTMW 175, IEAA 48, 110.

=item Kingfish

AS-6  air-to-ground  missile,  FDC  756, HTMW  174,  IEAA  110,  named
Kingfisher by JWARH 25. Mentioned in RSR.

=item Kipper

AS-2 air-to-ground  missile, JWARH  25, LFDC 367,  FDC 756,  HTMW 175,
IEAA 109.

=item Kitchen

AS-4 air-to-ground missile, LFDC 367, FDC 756, HTMW 175, IEAA 109.

=item Kyle

AS-9 air-to-ground missile, FDC 756.

=item Sagger

AT-3  Antiarmour missile  mounted  on BMP-1,  BMD-1, BVP-80A,  OT-64C,
BRDM-2 and BRDM. The Russian name is I<Malyutka> according to IEAA. PL
37, 38, 40, 49, 57, 59, 60, 227, HTMW 90, AWMA, IEAA 133, 134.

=item Sampson

SS-N-21 ship-launched cruise missile, FDC 755.

=item Sandbox

SS-N-12 anti-ship missile, FDC 755.

=item Sark

SS-N-5 ballistic missile, FDC 754.

=item Sawfly

SS-N-8 ballistic missile, FDC 754.

=item Scarab

SS-21, PL 95.

=item Scorpion

SS-NX-24 cruise missile, FDC 755.

=item Scud

SS1-C, PL 96, AWMA.

=item Serb

SS-N-6 ballistic missile, FDC 754.

=item Shaddock

SS-N-3 anti-ship missile, FDC 754.

=item Shipwreck

Aptly named SS-N-19 anti-ship missile, FDC 755.

=item Silex

SS-N-14 anti-submarine missile, FDC 757.

=item Siren

SS-N-9 anti-ship missile, FDC 755.

=item Skiff

SS-N-23 ballistic missile, FDC 754.

=item Snapper

Rocket used for mine clearing, PL 146.

=item Snipe

SS-N-17 ballistic missile, FDC 754.

=item Songster

AT-8 antiarmour missile mounted on T-80BV and T-64B tanks, PL 17, 19, HTMW 90.

=item Spandrel

AT-5 antiarmour missile mounted on BMP-2, BMD-2, BMP-30, BRDM-2, PL 35, 42, 48, 60, HTMW 90.

=item Spider

SS-23, PL 95.

=item Spigot

AT-4 antiarmour missile mounted on BMP-1, BMD-1, BMD-2, BMP-30, PL 37, 38, 41, 42, 48, HTMW 90.

=item Spiral

AT-6 antiarmour missile,  PL 227, HTMW 90, IEAA 111,  134 (which gives
both the code AT-6 and the alternate code AS-8).

=item Stallion

SS-N-16 anti-submarine missile, FDC 757.

=item Starbright

SS-N-7 anti-ship missile, FDC 755.

=item Starfish

SS-N-15 anti-submarine missile, FDC 757.

=item Stingray

SS-N-18 ballistic missile, FDC 754.

=item Sturgeon

SS-N-20 ballistic missile, FDC 754. THFRO gives it the name "Seahawk".

=item Styx

SS-N-2 anti-ship missile, LFDC 367, FDC 754, AWMA, IEAA 96, 110.

=item Sunburn

SS-N-22 anti-ship missile, FDC 755.

=item Swatter

AT-2 antiarmour missile, PL 227, IEAA 134.

=back

=head3 ERRORS

AWA gives a few designations  marked as wrong designations.  Here they
are, for the sake of completeness.

=over 4

=item Faceplate

MiG-21  fighter,  AWA  392.  Mentioned  in  IEAA  109  as  "the  Ye-2A
'Faceplate' by the Mikoyan bureau".

=item Flipper

MiG-23 fighter, AWA 392.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=cut

=head1 BUGS

Please   report  any   bugs   or  feature   requests   to  Github   at
C<https://github.com/jforget/Acme-MetaSyntactic-soviet/issues>,    and
create an issue or submit a pull request.

If you have no  feedback after a week or so, try to  reach me by email
at JFORGET  at cpan  dot org.  The notification  from Github  may have
failed to reach  me. In your message, please  mention the distribution
name in the subject, so my spam filter and me will easily dispatch the
email to the proper folder.

On the other hand, I may be on vacation. Do not be upset if the answer
arrives after one or  two months. Be upset only if  you do not receive
an answer to several emails over at least six months or one year.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::MetaSyntactic::soviet

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/pod/Acme::MetaSyntactic::soviet>

=item * GitHub

L<https://github.com/jforget/Acme-MetaSyntactic-soviet>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008,  2012, 2016,  2021 Jean  Forget, all  rights reserved.
This program is  free software; you can redistribute  it and/or modify
it under the  same terms as Perl itself: GNU  Public License version 1
or later and Perl Artistic License.

The full text of the license can be found in the F<LICENSE> file included
with this module or at
L<https://dev.perl.org/licenses/artistic.html>
and L<https://www.gnu.org/licenses/gpl-1.0.html>.

Here is the summary of GPL:

This program is  free software; you can redistribute  it and/or modify
it under the  terms of the GNU General Public  License as published by
the Free  Software Foundation; either  version 1, or (at  your option)
any later version.

This program  is distributed in the  hope that it will  be useful, but
WITHOUT   ANY  WARRANTY;   without  even   the  implied   warranty  of
MERCHANTABILITY  or FITNESS  FOR A  PARTICULAR PURPOSE.   See  the GNU
General Public License for more details.

You should  have received  a copy  of the  GNU General  Public License
along with this program; if not, see
L<https://www.gnu.org/licenses/gpl-1.0.html>   or  contact   the  Free
Software Foundation, Inc., L<https://www.fsf.org/>.

This program  is free software;  you can  redistribute it and  you can
modify it under the same terms as Perl itself.

=cut

