
use strict;
use warnings;
use Test::More tests => 4;

use Data::Bool qw(true false is_bool to_bool);

TODO: {
    local $TODO = 'Unexplained mismatch';
    is( \&true,  \&Data::Bool::true );
    is( \&false, \&Data::Bool::false );
}
is( \&is_bool, \&Data::Bool::is_bool );
is( \&to_bool, \&Data::Bool::to_bool );
