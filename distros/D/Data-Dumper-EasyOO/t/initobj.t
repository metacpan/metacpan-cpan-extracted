#!perl
use strict;
use Test::More tests => 16;
use vars qw($AR $HR @ARGold @HRGold);
require 't/Testdata.pm';
# share imported pkgs via myvars to other pkgs in file
my ($ar,$hr) = ($AR, $HR);
my @argold = @ARGold;
my @hrgold = @HRGold;


use vars q($odd);
my ($mdd, %style); # cant declare inside use

BEGIN { %style = (indent=>1, terse=>1); }

# 2 imports, each inits an object
use Data::Dumper::EasyOO;

Data::Dumper::EasyOO->import(%style, init => \$mdd);
Data::Dumper::EasyOO->import(%style, init => \$odd);

is($mdd->($AR), $ARGold[1][1], "use-time init of my var");
is($odd->($HR), $HRGold[1][1], "use-time init of pkg var");

pass "test copy constructor";
my $ndd = $mdd->new;
$ndd->Indent(2);

is($ndd->($AR), $ARGold[1][2], "cpd obj w indent=>2");
is($ndd->($HR), $HRGold[1][2], "cpd obj w indent=>2");

#$ndd->(copied => \%INC);

SKIP: {
    eval "use Test::Warn";
    skip "these tests need Test::Warn", 4 if $@;
    pass "test (init => \$var) where \$var is already defined";

    my $code = q{ use Data::Dumper::EasyOO (init => \$odd) };
    #print "code: $code, with $odd\n";


  TODO: {
      local $TODO = "withut this todo block, test fails ?!?";
      # eval "use re 'debug'";
      warnings_like
	  ( sub { eval "$code" },
	    [ qr/init arg must be a ref to a (scalar) variable/,
	      qr/wont construct a new EzDD object into non-undef variable/, ],
	    'Auto-Construct only into variable w/o a defined value');
      # eval "no re 'debug'";
  };

    $odd = undef;
    eval "$code";
    isa_ok ($odd, 'Data::Dumper::EasyOO', 're-construct after undeffing var.');

    # test void-context call on obj w/o autoprint
    $odd = Data::Dumper::EasyOO->new();
    $odd->Set(autoprint => undef);
    warning_like( sub { $odd->(\%INC) },
		  qr/called in void context, without autoprint defined/,
		  "carps on void context call to obj w/o autoprint on");
}

SKIP: {
    eval "use Config";
    skip "these tests need Test::Warn", 1 
	unless $Config::Config{useperlio};

    # strcat in eval's arg to prevent compile-time parse, 
    # which would cause 5.5.3 to barf on 3 arg open
    eval "".q{
    	my $buf;
	open (my $fh, '>', \$buf);
	$odd->Set(autoprint => $fh);
	$odd->(odd => \%INC);

	like ($buf, qr/PerlIO/,
	      "autoprint => \$fh works on use-time init'd obj");
    };
    warn $@ if $@;
}


package MultiInit;
*is = \&Test::More::is;

# multiple object inits/auto-constructs
my ($ez1, $ez2, $ez3);
use Data::Dumper::EasyOO ( init		=> \$ez1,
			   indent	=> 1,
			   init		=> \$ez2,
			   terse	=> 1,
			   init		=> \$ez3,
			   indent	=> 2);

is($ez1->($ar), $argold[0][2], "init => \$ez1 prints as expected");
is($ez1->($hr), $hrgold[0][2], "init => \$ez1 prints as expected");

is($ez2->($ar), $argold[0][1], "init => \$ez2 prints as expected");
is($ez2->($hr), $hrgold[0][1], "init => \$ez2 prints as expected");

is($ez3->($ar), $argold[1][1], "init => \$ez3 prints as expected");
is($ez3->($hr), $hrgold[1][1], "init => \$ez3 prints as expected");

