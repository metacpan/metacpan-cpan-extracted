#!/usr/bin/perl

use strict;
use warnings;

use Alzabo::Display::SWF;# qw/my_conf.yml/;

my $name = $ARGV[0] || die "Supply an Alzabo schema name!";

my $s = Alzabo::Display::SWF->create( $name );
$s->save("$name.swf");
my ($x, $y) = $s->dim;

open HTML, ">$name.html" or die;
print HTML <<END;
<html>
<head>
<title>$name :: Data Model</title>
</head>
<body>
<p>
<EMBED type="application/x-shockwave-flash" src="$name.swf"
       width="100%" height="@{[ int(141*$y/$x) ]}%"/>
</p>
</body>
</html>
END
close HTML
;
