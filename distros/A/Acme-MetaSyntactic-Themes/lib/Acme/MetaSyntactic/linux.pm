package Acme::MetaSyntactic::linux;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.031';

our %Remote = (
    source  => 'http://distrowatch.com/',
    extract => sub {
        my @forms = $_[0] =~ m{<select [^>]+>(.*?)</select>}gs;
        return
            map {
                s/\@/_at_/g; s/\+/_plus_/g;
                s/^0/Zero/; s/^2/Two/; s/^3/Three/; s/^4/Four/;
                s/^_|_$//g;  s/_+/_/g;
                $_
                }
            map { Acme::MetaSyntactic::RemoteList::tr_nonword($_) }
            map { Acme::MetaSyntactic::RemoteList::tr_accent($_) }
            map { Acme::MetaSyntactic::RemoteList::tr_utf8_basic($_) }
            $forms[0] =~ m!<option value=".*?">([^<]+?)</option>!g;
    }
);

__PACKAGE__->init();

1;

=head1 NAME

Acme::MetaSyntactic::linux - The Linux theme

=head1 DESCRIPTION

This theme contains the lists all the known and less
known Linux distributions, as maintained by DistroWatch on
L<http://distrowatch.com/stats.php>.

Note that the distribution list also contains the *BSD projects.

=head1 CONTRIBUTOR

Philippe Bruhat (BooK).

=head1 CHANGES

=over 4

=item *

2017-06-12 - v1.031

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.050.

=item *

2016-03-21 - v1.030

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.049.

=item *

2015-10-19 - v1.029

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.048.

=item *

2015-08-10 - v1.028

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.047.

=item *

2015-06-08 - v1.027

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.046.

=item *

2015-02-02 - v1.026

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.045.

=item *

2015-01-05 - v1.025

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.044.

=item *

2014-10-13 - v1.024

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.043.

=item *

2014-09-15 - v1.023

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.042.

=item *

2014-08-18 - v1.022

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.041.

=item *

2014-06-16 - v1.021

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.040.

=item *

2014-04-07 - v1.020

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.039.

=item *

2013-12-09 - v1.019

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.038.

=item *

2013-10-14 - v1.018

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.037.

=item *

2013-09-16 - v1.017

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.036.

=item *

2013-07-29 - v1.016

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.035.

=item *

2013-07-22 - v1.015

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.034.

=item *

2013-06-17 - v1.014

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.033.

=item *

2013-06-03 - v1.013

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.032.

=item *

2013-03-25 - v1.012

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.031.

=item *

2013-02-18 - v1.011

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.030.

=item *

2013-01-14 - v1.010

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.029.

=item *

2012-11-19 - v1.009

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.028.

=item *

2012-10-29 - v1.008

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.025.

=item *

2012-10-22 - v1.007

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.024.

=item *

2012-10-01 - v1.006

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.021.

=item *

2012-09-10 - v1.005

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.018.

=item *

2012-08-27 - v1.004

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.016.

=item *

2012-07-23 - v1.003

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.011.

=item *

2012-06-25 - v1.002

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.007.

=item *

2012-05-28 - v1.001

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.003.

=item *

2012-05-07 - v1.000

Updated with new extraction code and changes since November 2006, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-11-06

Updated from the source web site in Acme-MetaSyntactic version 0.99.

=item *

2006-10-30

Updated from the source web site in Acme-MetaSyntactic version 0.98.

=item *

2006-10-23

Updated from the source web site in Acme-MetaSyntactic version 0.97.

=item *

2006-10-09

Introduced in Acme-MetaSyntactic version 0.95.

=back

=head1 DEDICATION

This module is dedicated to the Linux kernel for its fifteenth
anniversary. Linux was first published on the C<comp.archives> newsgroup
on October 5, 1991.
See L<http://groups.google.com/group/comp.archives/msg/13a145b453f89094>

Linux was announced on C<comp.os.minix> on August 25, 1991.
See L<http://groups.google.com/group/comp.os.minix/msg/b813d52cbc5a044b>

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
ThreeCX
FourMLinux
Absolute
AbulEdu
Alpine
ALT
Android_x86
Antergos
antiX
APODIO
Arch
ArchBang
Arya
Asianux
AsteriskNOW
Audiophile
AUSTRUMI
AV_Linux
BackBox
Baruwa
Berry
Bicom
Bio_Linux
BitKey
Black_Lab
BlackArch
blackPanther
BlankOn
BlueOnyx
Bluestar
Bodhi
BOSS
BSDRP
BunsenLabs
CAINE
Calculate
Canaima
CentOS
Chakra
ChaletOS
Chapeau
Clear
ClearOS
Clonezilla
CloudReady
Connochaet
Container
CRUX
Debian
Debian_Edu
deepin
DEFT
Devil
Devuan
DragonFly
DRBL
DuZeru
EasyNAS
Edubuntu
Elastix
elementary
Elive
Emmabuntus
Endian
Endless
Exe
Exherbo
ExTiX
Fatdog64
Fedora
feren
Fermi
Finnix
FreeBSD
FreeNAS
FreePBX
Frugalware
FuguIta
Funtoo
Gecko
Gentoo
GhostBSD
gNewSense
GoboLinux
GParted
Greenie
Grml
GuixSD
Haiku
IPFire
Kaiana
Kali
KANOTIX
KaOS
Karoshi
KDE_neon
Keysoft
KNOPPIX
Kodachi
KolibriOS
Korora
Kubuntu
Kwort
KXStudio
Lakka
Leeenux
LFS
LibreELEC
LinHES
LinuxBBQ
LinuxConsole
Linuxfx
Lite
Live_Raizo
LliureX
Lubuntu
Lunar
LuninuX
LXLE
Mageia
MakuluLinux
Mangaka
Manjaro
Maui
MAX
Metamorphose
MidnightBSD
Minimal
MiniNo
MINIX
Mint
MirOS
MorpheusArch
MX_Linux
Nanolinux
NAS4Free
Neptune
NetBSD
NethServer
Netrunner
NexentaStor
NixOS
NST
NuTyX
OB2D
OBRevenge
OLPC
Omoikane
OpenBSD
OpenELEC
OpenIndiana
OpenLX
OpenMandriva
OpenMediaVault
openSUSE
Openwall
OPNsense
Oracle
OSGeo
OSMC
Overclockix
OviOS
paldo
Parabola
Parrot
Parsix
Parted_Magic
PCLinuxOS
Peach_OSI
Pearl
PelicanHPC
Pentoo
Peppermint
pfSense
Pinguy
Pisi
Plamo
PLD
Plop
Point
PoliArch
Porteus
Porteus_Kiosk
PrimTux
Proxmox
Puppy
Q4OS
Qubes
Quirky
RancherOS
Raspbian
RaspBSD
ReactOS
RebeccaBlackOS
Rebellin
Red_Hat
Refracta
RemixOS
REMnux
Rescatux
Resulinux
RISC
Robolinux
Rocks_Cluster
Rockstor
ROSA
Runtu
Sabayon
SalentOS
Salix
Scientific
Securepoint
SELKS
Semplice
Shark
siduction
Simplicity
Slackel
Slackware
SliTaz
SmartOS
SME_Server
Smoothwall
SMS
Solus
SolydXK
Sonar
Sophos
Source_Mage
SparkyLinux
Springdale
SteamOS
Stella
StressLinux
Subgraph
SuliX
Super_Grub2
SUSE
SwagArch
Swecha
Swift
SystemRescue
T2
Tails
TalkingArch
Tanglu
TENS
Thinstation
Tiny_Core
ToOpPy
ToriOS
Toutou
Trisquel
TrueOS
TurnKey
tuxtrans
UberStudent
Ubuntu
Ubuntu_Budgie
Ubuntu_DP
Ubuntu_GNOME
Ubuntu_Kylin
Ubuntu_MATE
Ubuntu_Studio
UHU_Linux
Ulteo
Ultimate
Univention
Untangle
URIX
Uruk
UTUTO
Vector
Vine
Vinux
Void
Volumio
VortexBox
Voyager
VyOS
wattOS
Webconverger
Whonix
Wifislax
WM_Live
XStreamOS
Xubuntu
Zentyal
Zenwalk
Zeroshell
Zorin
