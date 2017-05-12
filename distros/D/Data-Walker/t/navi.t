
my ($last_test,$loaded);

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';

BEGIN { $last_test = 28; $| = 1; print "1..$last_test\n"; }
END   { print "not ok 1  Can't load Data::Walker\n" unless $loaded; }

use Data::Walker;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $tcounter = 1;
my $want     = '';
my $id       = '\(0x.+\)';  # Regex to match the id of stringified refs

my $w        = new Data::Walker;
my $s        = {};

my $perl_version = $];


sub test {
	$tcounter++;

	my $string = shift;
	my $ret = eval $string;
	$ret = 'undef' if not defined $ret;

	if("$ret" =~ /^$want$/m) {

		print "ok $tcounter\n";

	} else {
		print "not ok $tcounter\n",
		"   -- '$string' returned '$ret'\n", 
		"   -- expected =~ /$want/\n"
	}
}


#------------------------------------------------------
# Our test data structure
#
$s = {
	a => [ 10, 20, "thirty" ],
	b => {
		"w" => "forty",
		"x" => "fifty",
		"y" => 60,
		"z" => \70,
	},
	c => sub { return "function"; },
	d => 80,
 	e => \[ "m", "n" ],
};
$s->{f}      = \$s->{d};
$s->{b}->{v} =  $s->{b};   #recursive

bless $s, Data::Walker;


#------------------------------------------------------
# Test basic formatting
#
$want = 'ARRAY';              test q($w->printref( $s->{a} )); 
$want = 'HASH';               test q($w->printref( $s->{b} ));
$want = 'CODE';               test q($w->printref( $s->{c} ));
$want = 'scalar';             test q($w->printref( $s->{d} ));
$want = 'Data::Walker=HASH';  test q($w->printref( $s      ));

#------------------------------------------------------
# Test ref-to-refs
#
$want = 'REF->ARRAY';         test q($w->printref(\$s->{a} ));
$want = 'REF->HASH';          test q($w->printref(\$s->{b} ));
$want = 'REF->CODE';          test q($w->printref(\$s->{c} ));
$want = 'SCALAR';             test q($w->printref(\$s->{d} ));
$want = 'REF->Data::Walker=HASH'; 
                              test q($w->printref(\$s      ));

#------------------------------------------------------
# Test formatting with ids
#
$w->showids(1);
#
$want = "ARRAY$id";              test q($w->printref( $s->{a} ));
$want = "HASH$id";               test q($w->printref( $s->{b} ));
$want = "CODE$id";               test q($w->printref( $s->{c} ));
$want = "Data::Walker=HASH$id";  test q($w->printref( $s      ));
$want = "REF$id->ARRAY$id";      test q($w->printref(\$s->{a} ));
$want = "SCALAR$id";             test q($w->printref(\$s->{d} ));
#
$w->showids(0);


#------------------------------------------------------
# Test walking up and down trees
# 
$w->warning(0);          # Hide Data::Walker warnings during tests
$w->{namepath} = ['/'];  # Set during CLI;  fudge it here
$w->{refpath} = [$s];    # Set during CLI;  fudge it here
#
$want = "ARRAY$id";              test q($w->down("a", $s->{a}));
$want = "Data::Walker=HASH$id";  test q($w->up() );
$want = "HASH$id";               test q($w->down("b", $s->{b}));
$want = "Data::Walker=HASH$id";  test q($w->up() );
$want = "undef";                 test q($w->down("c", $s->{c}));
$want = "Data::Walker=HASH$id";  test q($w->up() );
$want = "undef";                 test q($w->down("d", $s->{d}));


#------------------------------------------------------
# Test walking up and down trees with ref-to-refs
# 
$w->skipdoublerefs(1);
#
$want = "ARRAY$id";              test q($w->down("e", $s->{e}));
$want = "Data::Walker=HASH$id";  test q($w->up() );
#
$w->skipdoublerefs(0);
#
if($perl_version >= 5.008) {
	$want = "REF$id";             test q($w->down("e", $s->{e}));
} else {
	$want = "SCALAR$id";          test q($w->down("e", $s->{e}));
}
$want = "Data::Walker=HASH$id";  test q($w->up());


