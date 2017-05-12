
package Vegetable;

package Potatoe ;
use AutoLoader ;
@ISA = ("Vegetable");
sub AUTOLOAD{} ;

package SuperObject ;
@ISA = ("Potatoe");

package SuperObjectWithAutoload ;
@ISA = ("Potatoe");
sub AUTOLOAD{} ;

package TiedHash;
use Tie::Hash;
@ISA = (Tie::StdHash);

package TiedArray;
use Tie::Array;
@ISA = ('Tie::StdArray');

package TiedScalar;
use Tie::Scalar;
@ISA = (Tie::StdScalar);

package TiedHandle; 
use Tie::Handle ;
our @ISA = 'Tie::StdHandle';

package main ;


use strict ;
use warnings ;
use Carp ;

use Data::TreeDumper ;
$Data::TreeDumper::Displayinheritance = 1 ;
$Data::TreeDumper::Displayautoload = 1 ;
$Data::TreeDumper::Displaytie = 1 ;
$Data::TreeDumper::Displayrootaddress = 1 ;

use Devel::Peek ;

tie my %tied_hash_object, "TiedHash" ;
%tied_hash_object = (m1 => 1) ;
bless \%tied_hash_object, 'SuperObject' ;

tie my $tied_scalar_object, "TiedScalar" ;
$tied_scalar_object = 7 ;
bless \$tied_scalar_object, 'SuperObject' ;

tie *FH, 'TiedHandle';
bless \*FH, 'SuperObject' ;

print DumpTree(\%tied_hash_object, '%tied_hash_object') ;
print DumpTree(\$tied_scalar_object, '$tied_scalar_object') ;
print DumpTree(\*FH, '*tied_handle') ;


#~ print Dump %tied_hash_object ;
