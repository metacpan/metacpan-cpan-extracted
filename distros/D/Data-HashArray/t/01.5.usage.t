use utf8;
use strict;

use Test::More tests=>32;

use_ok('Data::HashArray');
use Data::HashArray;


my $a = Data::HashArray->new(
					  {code=>'FR', name=>'France', size=>'medium'},
					  {code=>'TR', name=>'Turkey', size=>'medium'},
					  {code=>'US', name=>'United States', size=>'large'}
					  );

my $expected;

# ACCESS					  
$expected = 'United States'; 
is($a->[2]->{name}, $expected, 'Subscript access [2]');

$expected = 'France'; 
is($a->[0]->{name}, $expected, 'Subscript access [0]');

$expected = 'France'; 
is($a->{name}, $expected, 'OVERLOADED hash access.');

# HASHING over fields 
my $h;

# HASH on 'code'    
$h = $a->hash('code');  		# One level hash (returns a hash of a HashArray of hashes)

foreach my $country (@$a) {
	my $code  	= $country->{code};
	my $name 	= $country->{name};
	my $size	= $country->{size};
	  
	is($h->{$code}->{code}, $code, "Hashed keying on 'code'. Check 'code' on key '$code'");
	is($h->{$code}->{name}, $name, "Hashed keying on 'code'. Check 'name' on key '$code'");
	is($h->{$code}->{size}, $size, "Hashed keying on 'code'. Check 'size' on key '$code'");
}	

# HASH on 'code' with a CODE reference.   
$h = $a->hash( sub {shift->{code};});			# One level hash (returns a hash of a HashArray of hashes)
foreach my $country (@$a) {
	my $code  	= $country->{code};
	my $name 	= $country->{name};
	my $size	= $country->{size};
	  
	is($h->{$code}->{code}, $code, "CODE-REF. Hashed keying on 'code'. Check 'code' on key '$code'");
	is($h->{$code}->{name}, $name, "CODE-REF. Hashed keying on 'code'. Check 'name' on key '$code'");
	is($h->{$code}->{size}, $size, "CODE-REF. Hashed keying on 'code'. Check 'size' on key '$code'");
}	

# HASH on 'size, code'    
$h = $a->hash('size', 'code');	# Two level hash (returns a hash of a hash of a HashArray  of hashes)

foreach my $country (@$a) {
	my $code  	= $country->{code};
	my $name 	= $country->{name};
	my $size	= $country->{size};
	
	is($h->{$size}->{$code}->{code}, $code, "Hashed keying on 'size, code'. Check 'code' on key '$code'");
	is($h->{$size}->{$code}->{name}, $name, "Hashed keying on 'size, code'. Check 'name' on key '$code'");
	is($h->{$size}->{$code}->{size}, $size, "Hashed keying on 'size, code'. Check 'size' on key '$code'");
}	


#	print STDERR "\nTest OVER baby!\n";			
ok(1);	# survived everything
  

1;

