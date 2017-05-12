use Test::More tests => 5;

BEGIN { use_ok( 'Date::Namedays::Simple::Hungarian' ); }

my $object = Date::Namedays::Simple::Hungarian->new ();
isa_ok ($object, 'Date::Namedays::Simple::Hungarian');


eval {
	$object->processNames();	# this shall NOT die, processNames() are overriden in Hungarian.pm !
};

ok ( (not $@), "Implemented abstract method should not die.");

# One name
my ($Gizella) = $object->getNames(5,7);
ok ( ($Gizella eq 'Gizella'), "Check for a single name.");

# Two names
my (@names) = $object->getNames(12,2,2001);
ok ( ($names[0].$names[1] eq 'MelindaVivien'), "Check for two names with year.");
