#!perl
use strict;
use Test::More;
eval "use Test::Warn";
plan skip_all =>
    "Test::Warn needed to test that warnings are properly issued"
    if $@;

plan tests => 10;

sub warning_is (&$;$);		# prototypes needed cuz eval delays
sub warning_like (&$;$);	# the protos provided by pkg

use_ok qw(Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "good object");
isa_ok ($ddez, 'CODE', "good object");

#print $ddez->([1,2,3]);

pass "test for disallowed methods";

# traditional form (not the one doc'd in Test::Warn)
# is needed here, cuz the eval delays the prototype.

warning_is { $ddez->poop(1) } 'illegal method <poop>',
	     "got expected warning";

warning_like { $ddez->Set(Indent=>1,poop=>1) }
	      qr/illegal method <(Indent|poop)>/,
              "detected illegal method 'poop'";

warnings_like ( sub { $ddez->Set(doodoo=>1,poop=>1) },
		[ qr/illegal method <doodoo>/,
		  qr/illegal method <poop>/ ],
		"detected illegal methods 'doodoo' and 'poop'");

warnings_are ( sub { $ddez->Set(gormless=>1,poop=>1) },
		[ 'illegal method <gormless>',
		  'illegal method <poop>' ],
	       "detected illegal methods 'gormless' and 'poop'");


warning_like ( sub { Data::Dumper::EasyOO->import( bogus => 2 ) }, 
	       qr/unknown print-style: bogus/,
	       "detected import of unknown print-style");

# set autoprint to illegal value (not checked till used, maybe later)
$ddez->Set(autoprint => 'gormless');

# then invoke
TODO: {
    $TODO = "sort out difference between carped warning and warning";

warnings_like ( sub { $ddez->(bush => 'gormless') },
		[ qr/illegal autoprint value/,
		  qr/Argument "gormless" isn\'t numeric/,
		  ],
		"detected bad autoprint value");
}
