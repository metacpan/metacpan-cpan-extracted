use Test::More tests => 14;

use DPKG::Parse::Entry;

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

isa_ok($entry, "DPKG::Parse::Entry");
is($entry->package, "3dchess", "Package is 3dchess");
$entry->package("bobo");
is($entry->package, "bobo", "Package is bobo");
$entry->package("3dchess");
is($entry->priority, "optional", "Priority is optional");
is($entry->section, "games", "Section is games");
is($entry->installed_size, "152", "Installed-Size is 151");
is($entry->maintainer, "Stephen Stafford <bagpuss\@debian.org>", "Who is the Maintainer?");
is($entry->architecture, "i386", "Architecture is i386");
is($entry->version, "0.8.1-11", "Version is 0.8.1-11");
is($entry->depends, "libc6 (>= 2.3.2.ds1-4), xaw3dg (>= 1.5+E-1), xlibs (>> 4.1.0)", "Depends value");
is($entry->filename, "pool/main/3/3dchess/3dchess_0.8.1-11_i386.deb", "Filename is correct");
is($entry->size, 33116, "Size is 33116");
is($entry->md5sum, '7248665d99d529342a5cd050a9128ff6', "MD5sum is correct");
is($entry->description, "3D chess for X11
3 dimensional Chess game for X11R6.  There are three boards, stacked
vertically; 96 pieces of which most are the traditional chess pieces with
just a couple of additions; 26 possible directions in which to move.  The
AI isn't wonderful, but provides a challenging enough game to all but the
most highly skilled players.
", "Description is correct");



