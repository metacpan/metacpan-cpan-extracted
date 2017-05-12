
@list = qw(a b c); 
$hash = {a => 1, b => 2, c => 3}; 

# a=1, b=2, c=3

print join( ' AND ', 
   map { 
     join('', $_, '=', "'", $hash->{$_}, "'")
   }
   @list), "\n"; 

      



