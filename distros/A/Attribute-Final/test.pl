use Test::More tests => 3;
BEGIN { use_ok("Attribute::Final");};

package Beverage::Hot; 
sub serve :final { } 
 
package Tea; 
use base 'Beverage::Hot'; 
 

eval "
sub Tea::serve { # Compile-time error. 
} 
";

package main;
is_deeply(\%Attribute::Final::marked, {"Beverage::Hot" => ["serve"]});
eval { Attribute::Final->check; };
like($@, qr/Cannot override final method Beverage::Hot::serve /, 
    "Check failed after method overriden");
