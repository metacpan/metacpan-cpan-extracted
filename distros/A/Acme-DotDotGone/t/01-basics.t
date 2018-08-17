use Test::More;
use lib 'lib';

my $package = q|
use Acme::DotDotGone dot;
my $end = 'the world is ending';
print $end;
1;
|;

my $var = 'testing.pl';
open(FH, '>', $var)
    or die "Can't open memory file: $!\n";
print FH $package;
close FH;

qx(perl testing.pl);

open(FH, '<', $var)
    or die "Can't open memory file: $!\n";
my $file = do{ local $/, <FH> };
close FH;

is ($file, 'use Acme::DotDotGone;
.. . .. .. . .. .. . .. . . .. .. .. .. . . . . . . .. . . . . .. . . .. . . .. . .. . . .. .. . . .. .. .. . .. .. . . . .. . . .. .. . . . . . . .. . . .. . .. .. .. .. . . . . . . . .. . . .. .. .. . . .. . . . . .. . .. .. .. . . . . .. . .. .. . .. . .. . . .. .. . . . . . . .. . . .. .. .. . .. .. .. . .. .. .. .. . .. .. . . .. . . .. .. .. . . . .. .. . .. .. . . . .. . . .. .. . . . . . . .. . . .. . . .. . .. .. . .. .. . . .. .. .. . . . . . . .. . . .. . .. . . .. .. . . .. .. .. . .. .. . . . .. . . .. .. . .. . . .. . .. .. . . .. .. .. . .. .. . .. .. .. . . .. .. . .. .. .. . . .. . . .. .. . .. .. .. . . . .. . .. . . . . . . . . .. .. .. . . .. . . .. .. .. . .. . . .. . .. .. . . .. .. .. . .. .. . . . .. . .. .. .. . . . . . . .. . . . . .. . . .. . . .. . .. . . .. .. . . .. .. .. . .. .. . . . .. . . .. .. . .. .. . .. .. .. . . . .. . .. . . . . .. . . . .. .. . . .. .. . .. .. .. . . . .. . .. . . . .');

qx(perl testing.pl);

$file =~ s/DotDotGone;/DotDotGone panic;/;

open(FH, '>', $var)
    or die "Can't open memory file: $!\n";
print FH $file;
close FH;

qx(perl testing.pl);

open(FH, '<', $var)
    or die "Can't open memory file: $!\n";
$file = do{ local $/, <FH> };
close FH;

is($file, 'use Acme::DotDotGone;
my $end = \'the world is ending\';
print $end;
1;
');

unlink($var);

done_testing();
