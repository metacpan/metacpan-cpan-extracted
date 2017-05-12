use Test::More tests => 4;

use DPKG::Parse::Status;
use DPKG::Parse::Packages;
use DPKG::Parse::Available;
use DPKG::Parse::Entry;

my $status = DPKG::Parse::Status->new('filename' => './data/status');
my $available = DPKG::Parse::Available->new('filename' => './data/available');
my $packages = DPKG::Parse::Packages->new('filename' => './data/Packages');

my $data = <<EOH;
Package: 3dchess
Priority: optional
Section: games
Installed-Size: 152
Maintainer: Stephen Stafford <bagpuss\@debian.org>
Architecture: i386
Version: 0.8.1-11
Depends: libc6 (>= 2.3.2.ds1-4), xaw3dg (>= 1.5+E-1), xlibs (>> 4.1.0)
Filename: pool/main/3/3dchess/3dchess_0.8.1-11_i386.deb
Size: 33116
MD5sum: 7248665d99d529342a5cd050a9128ff6
Description: 3D chess for X11
 3 dimensional Chess game for X11R6.  There are three boards, stacked
 vertically; 96 pieces of which most are the traditional chess pieces with
 just a couple of additions; 26 possible directions in which to move.  The
 AI isn't wonderful, but provides a challenging enough game to all but the
 most highly skilled players.
EOH
my $entry = DPKG::Parse::Entry->new('data' => $data);

isa_ok($status, "DPKG::Parse::Status");
isa_ok($available, "DPKG::Parse::Available");
isa_ok($packages, "DPKG::Parse::Packages");
isa_ok($entry, "DPKG::Parse::Entry");

