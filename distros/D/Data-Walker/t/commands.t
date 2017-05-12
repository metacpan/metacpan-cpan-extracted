
my ($last_test,$loaded);

######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';

BEGIN { $last_test = 79; $| = 1; print "1..$last_test\n"; }
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

$s->{b}->{u} =  $s->{b};                     # recursive
$s->{b}->{v} = { v => {}, b => $s->{b} };    # recursive
$s->{b}->{v}->{v} = $s->{b}->{v};            # recursive

$s->{b}->{v}->{w} = "";                           
$s->{b}->{v}->{w} = \$s->{b}->{v}->{w};      # self-reference

bless $s, Data::Walker;

$w->walk($s);

#------------------------------------------------------
# Test chdir and prompt generation, and set function
# 
$want = "/->{b}> ";          test q($w->cd("/b");     $w->walker_getprompt);
$want = "/->{a}> ";          test q($w->cd("../a");   $w->walker_getprompt);
$want = "";                  test q($w->set("warning",0));
$want = "/->{a}> ";          test q($w->cd("../c");   $w->walker_getprompt);
$want = "/->{a}> ";          test q($w->cd("/d");     $w->walker_getprompt);
$want = "/->{e}->ref> ";     test q($w->cd("/e");     $w->walker_getprompt);

# Test reference loops of various kinds
#
$want = "";                  test q($w->set("warning",1));
$want = "/->{b}> ";          test q($w->cd("/b");     $w->walker_getprompt);
$want = "/->{b}-1-->{u}-1-> ";
                             test q($w->cd("u");      $w->walker_getprompt);
$want = "/->{b}-1-->{u}-1-->{v}> ";
                             test q($w->cd("v");      $w->walker_getprompt);
$want = "/->{b}-1-->{u}-1-->{v}-2-->{v}-2-> ";
                             test q($w->cd("v");      $w->walker_getprompt);
$want = "/->{b}-1-->{v}-2-->{b}-1-->{v}-2-> ";
                             test q( 
                                $w->cd("/b/v/b/v");
                                $w->walker_getprompt
                             );
# Test self-reference
#
$want = "";                  test q($w->set("warning",0));
$want = "/->{b}->{v}> ";     test q($w->cd("/b/v");   $w->walker_getprompt);
$want = "/->{b}->{v}->{w}> ";
                             test q($w->cd("w");      $w->walker_getprompt);
$want = "/->{b}->{v}->{w}-1-->ref-1-> ";
                             test q($w->cd("ref");    $w->walker_getprompt);
$want = "/->{b}->{v}> ";
                             test q($w->cd("..");     $w->walker_getprompt);


#------------------------------------------------------
# Test chdir'ing through references and nonexistant directories
# 
$want = "/->{a}> ";         test q(
                                 $w->cd("/a"); 
                                 $w->cd("/f"); 
                                 $w->walker_getprompt
                             );

$want = "";                  test q($w->set("warning",0));
$want = "";                  test q($w->set("skipdoublerefs",0));

$want = "/->{e}> ";          test q($w->cd("/e");     $w->walker_getprompt);
$want = "/->{e}->ref> ";     test q($w->cd("ref");    $w->walker_getprompt);
$want = "/->{e}> ";          test q($w->cd("..");     $w->walker_getprompt);
$want = "/->{e}> ";          test q($w->cd("reference");  $w->walker_getprompt);
$want = "/->{e}->ref> ";     test q($w->cd("/e/ref"); $w->walker_getprompt);
$want = "";                  test q($w->set("skipdoublerefs",1));
$want = "/> ";               test q($w->cd("..");     $w->walker_getprompt);


#------------------------------------------------------
# ls on a HASH
#
$want = "15";                test q($w->lscol1width(15));
$want = "25";                test q($w->lscol2width(25));
$want =  "" ;                test q($w->cd("/"));

$want = join "\t", qw(a b c d e f);
$want .= "\t";
                             test q($w->ls);

$want = join "\t", qw(.. . a b c d e f);
$want .= "\t";
                             test q($w->la);
                             test q($w->ls("-a"));

$want =<<EOM;
..              Data::Walker=HASH         \\(6\\)
.               Data::Walker=HASH         \\(6\\)
a               ARRAY                     \\(3\\)
b               HASH                      \\(6\\)
c               CODE                      
d               scalar                    80
e               REF->ARRAY                \\(2\\)
f               SCALAR                    80
EOM
chomp($want);
                             test q($w->lal);
                             test q($w->all);
                             test q($w->lla);
                             test q($w->ls("al"));
                             test q($w->ls("la"));
                             test q($w->ls("-al"));
                             test q($w->ls("-la"));
$want =<<EOM;
a               ARRAY                     \\(3\\)
b               HASH                      \\(6\\)
c               CODE                      
d               scalar                    80
e               REF->ARRAY                \\(2\\)
f               SCALAR                    80
EOM
chomp($want);
                             test q($w->ll);
                             test q($w->ls("-l"));
                             test q($w->ls("l"));

#------------------------------------------------------
# ls on an ARRAY
#
$w->cd("/a");

$want = join "\t", qw(scalar scalar scalar);
$want .= "\t";
                             test q($w->ls);

$want = join "\t", qw(.. . scalar scalar scalar);
$want .= "\t";
                             test q($w->la);
                             test q($w->la);
                             test q($w->ls("-a"));

$w->lscol1width(15);
$w->lscol2width(25);

$want =<<EOM;
..              Data::Walker=HASH         \\(6\\)
.               ARRAY                     \\(3\\)
0               scalar                    10
1               scalar                    20
2               scalar                    'thirty'
EOM
chomp($want);
                             test q($w->lal);
                             test q($w->all);
                             test q($w->lla);
                             test q($w->ls("al"));
                             test q($w->ls("la"));
                             test q($w->ls("-al"));
                             test q($w->ls("-la"));

$want =<<EOM;
0               scalar                    10
1               scalar                    20
2               scalar                    'thirty'
EOM
chomp($want);
                             test q($w->ll);
                             test q($w->ls("-l"));
                             test q($w->ls("l"));

#------------------------------------------------------
# print, type, cat
#
$w->cd("/");

$want = "ARRAY$id";          test q($w->print("a"));
$want = "ARRAY$id";          test q($w->type("a"));
$want = "ARRAY$id";          test q($w->cat("a"));

$want = "HASH$id";           test q($w->print("b"));
$want = "HASH$id";           test q($w->type("b"));
$want = "HASH$id";           test q($w->cat("b"));

$want = "CODE$id";           test q($w->print("c"));
$want = "CODE$id";           test q($w->type("c"));
$want = "CODE$id";           test q($w->cat("c"));

$want = "80";                test q($w->print("d"));
$want = "80";                test q($w->type("d"));
$want = "80";                test q($w->cat("d"));

if($perl_version >= 5.008) {

	$want = "REF$id";         test q($w->print("e"));
	$want = "REF$id";         test q($w->type("e"));
	$want = "REF$id";         test q($w->cat("e"));

} else {

	$want = "SCALAR$id";      test q($w->print("e"));
	$want = "SCALAR$id";      test q($w->type("e"));
	$want = "SCALAR$id";      test q($w->cat("e"));
}

$w->cd("/a");

$want = "20";                test q($w->print(1));
$want = "20";                test q($w->type(1));
$want = "20";                test q($w->cat(1));

$want = "thirty";            test q($w->print(2));
$want = "thirty";            test q($w->type(2));
$want = "thirty";            test q($w->cat(2));


