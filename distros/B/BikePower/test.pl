# -*- perl -*-

BEGIN { $^W = 1; $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}

use BikePower;
use BikePower::HTML;

$loaded = 1;
print "ok 1\n";

$o = new BikePower
  '-no-ini' => 1,
  '-no-default' => 1,
  'V_incr' => 2,
  'C_a' => '0.9',
  'A_c' => '0.4925155 (upright)',
  'Wm' => 19,
  'E' => '0.249',
  'G' => '0',
  'H' => '0',
  'first_C' => 500,
  'C_incr' => 100,
  'A1' => '0',
  'R' => '0.0066 (26 x 1.375)',
  'T_a' => 20,
  'T' => '0.95',
  'first_P' => 50,
  'given' => 'v',
  'Wc' => 68,
  'BM_rate' => '1.4',
  'P_incr' => 50,
  'cross_wind' => '0',
  'first_V' => 16,
  'N_entry' => 10
;

if (!$o->isa('BikePower')) {
    print "not ";
}
print "ok 2\n";

my $v1 = 30/3.6;
$o->velocity($v1); # supply velocity in m/s
if ($o->velocity != $v1) {
    print "not ";
}
print "ok 3\n";

# XXX maybe rounding errors are possible?!? check it on other machines!

$ok = 4;

my $power0 = 200;
my $v0     = 29.3;

for my $i (0 .. 1) {
    $o->velocity($v1);
    $o->given('v');
    if ($i == 0) {
	$o->calc;
    } else {
	$o->calc_slow;
    }

    if (int($o->power) != 212) { # Watts
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    if (int($o->{'_out'}{'P'}) != 212) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    $o->given('P');
    $o->power($power0);

    if ($i == 0) {
	$o->calc;
    } else {
	$o->calc_slow;
    }

    if (sprintf("%.1f", $o->velocity*3.6) ne $v0) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";

    if (sprintf("%.1f", $o->{'_out'}{V}) ne $v0) {
	print "not ";
    }
    print "ok " . ($ok++) . "\n";
}

eval q{
    use Tk;
    use BikePower::Tk;
    $top = new MainWindow;
    $t = $o->tk_interface($top);
    $top->update;
    $top->destroy;
    print "ok " . ($ok++) . "\n";
};
if ($@) {
    print "ok " . ($ok++) . "# skip\n";
}

BikePower::HTML::code();
print "ok " . ($ok++) . "\n";

use CGI;
my $cgi = new CGI {};
$ENV{COOKIE} = "BikePower=frontalarea=0.6566873:transeff=0.95:rollfriction=0.004:weightcyclist=67:weightmachine=12";
my $o = BikePower::HTML::new_from_cookie($cgi);
print "not " if (!$o->isa('BikePower'));
print "ok " . ($ok++) . "\n";

print "not " if $o->T ne 0.95;
print "ok " . ($ok++) . "\n";

print "not " if $o->weight_machine ne 12;
print "ok " . ($ok++) . "\n";

my $clone = $o->clone;
print "not " if !$clone->isa('BikePower');
print "ok " . ($ok++) . "\n";

my $clone2 = clone BikePower $o;
print "not " if !$clone2->isa('BikePower');
print "ok " . ($ok++) . "\n";

print "not " if $o->weight_machine ne $clone->weight_machine;
print "ok " . ($ok++) . "\n";

print "not " if $o->weight_machine ne $clone2->weight_machine;
print "ok " . ($ok++) . "\n";

$o->given('P');
$clone->given('P');
$o->power($power0);
$clone->power($power0);
$o->calc;
$clone->calc;
if ($o->velocity ne $clone->velocity) {
    print "not ";
}
print "ok " . ($ok++) . "\n";
