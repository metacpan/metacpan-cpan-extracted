
package AutoCode::Friendship;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
use AutoCode::AccessorMaker(
    '$'=>['peer_string'],
    '@'=>[qw(peer extra)], 
    _initialize=>undef
);
#use AutoCode::Initializer('@'=>[qw(peer extra)]);

1;

