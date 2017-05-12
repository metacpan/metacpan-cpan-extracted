use strict;
use warnings;

use lib("t");

use Test::More tests=>3;
use File::Copy;

use_ok('Apache::Voodoo::Loader::Static') || BAIL_OUT($@);

my $path = $INC{'Apache/Voodoo/Loader/Static.pm'};
$path =~ s:(blib/)?lib/Apache/Voodoo/Loader/Static.pm:t:;

#
# make sure the .pm is the original ones.
#
$path .= "/app_newstyle";
copy("$path/C/a/controller.pm.orig","$path/C/a/controller.pm") || die "can't reset controller.pm: $!";

isa_ok(
	Apache::Voodoo::Loader::Static->new('app_newstyle::C::a::controller'),
	"app_newstyle::C::a::controller"
);

isa_ok(
	Apache::Voodoo::Loader::Static->new('app_newstyle::C::this::module::does::not::exist'),
	"Apache::Voodoo::Zombie"
);
