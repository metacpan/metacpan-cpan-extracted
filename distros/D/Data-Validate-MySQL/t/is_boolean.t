#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 261;
BEGIN { use_ok('Data::Validate::MySQL', qw(is_boolean)) };

#########################

# valid tests
my @good = ();
for(0..128){
	push(@good, $_ * -1);
}
for(1..127){
	push(@good, $_);
}
foreach my $value (@good){
	ok(defined(is_boolean($value)), "valid boolean: $value");
}

# invalid tests
my @bad = (
	-129,
	'abc',
	255,
	''
);
foreach my $value (@bad){
	ok(!defined(is_boolean($value)), "invalid boolean: $value");
}