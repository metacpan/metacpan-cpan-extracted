
BEGIN 
{ 
	use Test::More qw(no_plan);
	
	$| = 0 
}

use strict; use warnings;

use Data::Type qw(+Bio);
use IO::Extended qw(:all);

ok( Data::Type::type_list() );

$_ = 'ATGC';

ok( Data::Type::dvalid BIO::DNA );
ok( Data::Type::is BIO::DNA );
ok( not Data::Type::isnt BIO::DNA );

$_ = 'HHHHH';

ok(not Data::Type::dvalid BIO::DNA);
ok(not Data::Type::is BIO::DNA);
ok(Data::Type::isnt BIO::DNA);

