#!/usr/bin/perl -I. -w

use Cisco::Reconfig;
use Test;
use Carp qw(verbose);
use Scalar::Util qw(weaken);

use strict;

my $debugdump = 0;

if ($debugdump) {
	$Cisco::Reconfig::nonext = 1;
}

BEGIN { plan test => 6 };

sub wok
{
	my ($a, $b) = @_;
	require File::Slurp;
	import File::Slurp;
	write_file('x', $a);
	write_file('y', $b);
	return ok($a,$b);
}

my $config = readconfig(\*DATA);

if ($debugdump) {
	require File::Slurp;
	require Data::Dumper;
	import File::Slurp;
	import Data::Dumper;
	$Data::Dumper::Sortkeys = 1;
	$Data::Dumper::Sortkeys = 1;
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Indent = 1;
	$Data::Dumper::Indent = 1;
	write_file("dumped", Dumper($config));
	exit(0);
}

ok(defined $config);

# -----------------------------------------------------------------
{

my $x = $config->get('banner motd');
#undef $config;
#use Data::Dumper;
#print Dumper($x);
#exit(0);
ok($x->subs->text, <<'END');
                                       _      _     ___ ____
 _ __ ___   ___ ___ ___  _ __ _ __ ___ (_) ___| | __/ _ \___ \       ___ ___
| '_ ` _ \ / __/ __/ _ \| '__| '_ ` _ \| |/ __| |/ / | | |__) |____ / __/ _ \
| | | | | | (_| (_| (_) | |  | | | | | | | (__|   <| |_| / __/_____| (_|  __/
|_| |_| |_|\___\___\___/|_|  |_| |_| |_|_|\___|_|\_\\___/_____|     \___\___|


This system and data is the property of blah blah
blah...
^C
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('banner testa');
ok($x->subs->text, <<END);

   A device

^C
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('banner testb');
ok($x->subs->text, <<END);

   A device^C
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('banner testc');
ok($x->text, <<END);
banner testc ^C A device ^C
END

}
# -----------------------------------------------------------------
{

my $x = $config->get('service');
ok($x->text, <<END);
service tcp-small-servers
END

}
# -----------------------------------------------------------------


__DATA__
!
! Last configuration change at 20:38:42 PDT Mon Jun 26 2000C
! NVRAM config last updated at 20:38:49 PDT Mon Jun 26 2000C
!
service tcp-small-servers
banner exec ^C
 
                XXXXX XXXXX Network Gateway
 
   This is a restricted network node.  Do NOT use this node if
   you do not work for UMMC Network Services.  Thank you.
 
^C
!
banner motd ^C
                                       _      _     ___ ____
 _ __ ___   ___ ___ ___  _ __ _ __ ___ (_) ___| | __/ _ \___ \       ___ ___
| '_ ` _ \ / __/ __/ _ \| '__| '_ ` _ \| |/ __| |/ / | | |__) |____ / __/ _ \
| | | | | | (_| (_| (_) | |  | | | | | | | (__|   <| |_| / __/_____| (_|  __/
|_| |_| |_|\___\___\___/|_|  |_| |_| |_|_|\___|_|\_\\___/_____|     \___\___|


This system and data is the property of blah blah
blah...
^C
!
!
hostname humble
!
banner testa ^CCCCCC

   A device

^C
banner testb ^C

   A device^C
banner testc ^C A device ^C
!username stat password <removed>

