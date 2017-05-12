#
#   DB::Ent test suite
#   Copyright (C) 2001-2003 Erick Calder
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

use warnings;
use strict;
use Test::Simple tests => 14;

use vars qw/$ef $ok $ar $al/;

use DB::Ent;
ok(1, "use DB::Ent");

$ef = DB::Ent->new(dbn => "test", debug => $ENV{DEBUG});
ok(defined $ef && $ef->isa('DB::Ent')
	, "entity factory instantiated"
	) || die $!;

my $usr = (getpwuid($>))[0];
ok($ef->cs() eq "mysql://$usr\@localhost/test",
    "connection string verified"
    );

$ok = $ef->init(DROP => 1);
ok($ok, "schema created") || die $!;

$ar = $ef->mk(artist => "Björk");
ok(defined $ar && $ar->isa("DB::Ent")
    , "entity created"
    );

my $url = "http://www.bjork.com";
$ok = $ar->attr(www => $url);
ok($ok, "attribute set");
ok($url eq $ar->attrs("www"), "attribute verified");
$ar->rmattr();
ok(!$ar->attrs("www"), "attribute removed");

$al = $ar->mksub(album => "Homogenic");
ok(defined $al && $al->isa("DB::Ent")
    , "sub-entity created"
    );

$al = $ef->mk(album => "Post");
$ok = $al->rel($ar);
ok(defined $al && $ok, "relative established");

my @rels = $ar->rels();
$ok = $rels[0]->{nm} eq "Homogenic" && $rels[1]->{nm} eq "Post";
ok($ok, "relatives verified");

my $ent = $ef->ent("Post");
ok($ent->{nm} eq "Post", "entity retrieved");

$ok = $al->rm();
ok($ef->ent("Post") == 0, "entity removed");

ok(1, "done");
