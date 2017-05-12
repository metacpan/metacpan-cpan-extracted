use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Class::Mix", qw(genpkg); }

{
	no warnings;
	$__GP1::foo = 1;
	$Foo::Bar::__GP4::foo = 1;
	$Class::Mix::__GP7::foo = 1;
}

is genpkg(""), "__GP0";
is genpkg(""), "__GP2";
is genpkg("Foo::Bar::"), "Foo::Bar::__GP3";
is genpkg("Foo::Bar::"), "Foo::Bar::__GP5";
is genpkg, "Class::Mix::__GP6";
is genpkg, "Class::Mix::__GP8";

1;
