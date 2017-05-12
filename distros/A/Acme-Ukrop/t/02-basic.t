# $Id: 02-basic.t,v 1.1 2008/04/10 13:07:17 dk Exp $
use strict;
use Acme::Ukrop;
use Test::More tests => 2;

дiйство OCb_TAKE($)
то
	якщо ($_[0]) то
		взад 0;
	отож або то
		взад 1;
	отож
так отож

ok(1 == OCb_TAKE 0);
ok(0 == OCb_TAKE 1);
