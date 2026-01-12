package Acme::MetaSyntactic::linux;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.037';

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

2026-01-12 - v1.037

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.056.

=item *

2021-04-30 - v1.036

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.055.

=item *

2019-10-28 - v1.035

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.054.

=item *

2019-07-29 - v1.034

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.053.

=item *

2018-10-29 - v1.033

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.052.

=item *

2017-11-13 - v1.032

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.051.

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
Accessible_Coconut
AcorOS
AcreetionOS
Adelie
Aeon
AerynOS
AgarimOS
Alien_OS
AlmaLinux
Alpine
ALT
AlterOS
AnduinOS
antiX
AnuBitux
AOSC
Arch
ArchBANG
Archcraft
Archman
Archriot
arcOS
Arkane
Armbian
Artix
Asahi
Asmi
Astra
Athena
ATZ_Linux
Aurora
AUSTRUMI
AV_Linux
AxOS
BackBox
Batocera
Bazzite
Bedrock
Berry
Berserk_Arch
Besgnulinux
Bicom
BigLinux
Blade
blendOS
Bluefin
BlueOnyx
Bluestar
Bodhi
BOSS
Br_OS
BRGV_OS
BSDRP
BunsenLabs
CachyOS
CAINE
Calam
Calculate
Canaima
Catbird
CentOS
Chimera
ChromeOS
Circle
Clear_NDR
Clonezilla
CloudLinux
Commodore
CROWZ
Crunchbangplusplus
CRUX
CuerdOS
d77void
Damn_Small
Daphile
DAT
Debian
Debian_Edu
DebLight
deepin
DEKUVE
DESERT
Devuan
DietPi
Ditana
Dr_Parted
DragonFly
DragonOS
Drauger
Dynebolic
DynFi
EasyOS
Edubuntu
ELEGANCE
elementary
Elive
ElysiaOS
Emmabuntus
EN_OS
EndeavourOS
Endless
Escuelas
EterTICs
Exe
Exherbo
Expirion
ExTiX
Exton
extrox
Fatdog64
Fedora
Feren
Finnix
Flatcar
Flora
Fluxuan
FreeBSD
FreedomBox
Freeduc
Freeloader
FuguIta
FunOS
FUSS
FydeOS
gabeeOSLinux
Garuda
Gentoo
GhostBSD
GLF
GNOME_OS
Gnoppix
Gnuinos
GoboLinux
Gooroom
GParted
GrapheneOS
Green
Grml
GuideOS
Guix_System
GXDE
HackerOS
Haiku
HamoniKR
HardenedBSD
HeliumOS
Huayra
HydraPWK
Hyperbola
iDeal
iodeOS
IPFire
Kali
Kamarada
KANOTIX
KaOS
KDE_Linux
KDE_neon
Kicksecure
Kiro
Kodachi
KolibriOS
Kubuntu
Kumander
Kwort
LainOS
Lakka
LangitKetujuh
LazyLinux
Lernstick
LFS
LibraZiK
LibreELEC
Lingmo
Linux_Schools
LinuxCNC
LinuxConsole
Linuxfx
LinuxHub
Lite
Live_Raizo
Liya
LliureX
Loc_OS
Luberri
Lubuntu
LxPup
Mabox
Macaroni
Maemo_Leste
Mageia
MagOS
mAid
MakuluLinux
Manjaro
Mauna
MAX
Melawy
MidnightBSD
Milis
MiniOS
Mint
MIRACLE
Mobian
MocaccinoOS
MODICIA
MODOS
Murena
MX_Linux
nakeDeb
NebiOS
Nemesis
Neptune
NetBSD
NethSecurity
NethServer
Netrunner
NexentaStor
Nitrux
NixOS
Nobara
Noid
NomadBSD
NST
NuTyX
Nyarch
Obarun
ObsidianOS
Omarchy
OmegaLinux
OmniOS
OpenBSD
openEuler
OpenIndiana
openKylin
openmamba
OpenMandriva
OpenMediaVault
openSUSE
OPNsense
Oracle
Oreon
OSINT_VM
OSMC
OsoLinux
OviOS
PakOS
paldo
Parabola
Parch
Pardus
Parrot
Parted_Magic
PCLinuxOS
Pearl
pearOS
PelicanHPC
Pentoo
Peppermint
Peropesis
pfSense
PikaOS
Pisi
Plamo
Planeta_Tecno
PLD
Plop
Pop_OS
Porteus
Porteus_Kiosk
PorteuX
postmarketOS
Predator_OS
PrimTux
Proxmox
Puppy
Q4OS
Qlustar
Quarkos
Qubes
Quirinux
RasPiOS
RDS
ReactOS
RebeccaBlackOS
RebornOS
Recalbox
Red_Hat
RED_OS
Redcore
Redox
Refracta
RefreshOS
Regata
RELIANOID
Rescuezilla
Rhino
RISC
rlxos
Rockstor
Rocky
ROSA
RSS
Runtu
Salix
Sculpt
SDesk
Secure_K
secureblue
Security_Onion
Serbian
Shanios
Shebang
Side
siduction
Skudonet
Skywave
Slackel
Slackware
Slimbook_OS
Slint
SliTaz
SmartOS
SME_Server
Smoothwall
Snal
Solaris
Solus
SolydXK
Soplos
SparkyLinux
spirit_OS
StartOS
SteamOS
StormOS
StratOS
Super_Grub2
SUSE
Synex
SysLinuxOS
SystemRescue
T2_Linux
Tails
Talos
TeaLinux
Thinstation
TileOS
Tiny_Core
TobbeOS
Tribblix
Trisquel
TROMjaro
TrueNAS
Tsurugi
TTOS
TurnKey
TUXEDO
Twister
UBLinux
UBOS
UBports
Ubuntu
Ubuntu_Budgie
Ubuntu_Cinnamon
Ubuntu_Kylin
Ubuntu_MATE
Ubuntu_Pack
Ubuntu_Studio
Ubuntu_Sway
Ubuntu_Unity
Ufficio_Zero
Ultimate
Ultramarine
umbrelOS
Uncom
Univention
Unraid
UOS
VailuxOS
Vanilla
Vendefoul
Venom
Ventoy
Vinari
Vincent
Vine
Vipnix
Vitalinux
Void
Volumio
Voyager
VyOS
wattOS
Whonix
Wifislax
WM_Live
XCP_ng
Xebian
XeroLinux
XigmaNAS
Ximper
XIVA_Studio
Xray_OS
Xubuntu
YunoHost
Zenned
Zentyal
Zenwalk
Zephix
ZimaOS
Zorin
