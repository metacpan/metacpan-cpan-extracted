package Person;

use strict;
use vars qw(@ISA);
use IsamObjects;
use CIsam;
@ISA = qw(IsamObjects);

my $FIELDMAP =
{ 
	last_name 	=> [ 'CHARTYPE',	0,  21 ],
	first_name	=> [ 'CHARTYPE',	21, 21 ],
	phone		=> [ 'LONGTYPE',	42, 4 ],
	age		=> [ 'INTTYPE',		46, 2 ],
	net_worth	=> [ 'DOUBLETYPE',	48, 8 ],
	account_balance	=> [ 'FLOATTYPE',	56, 4 ]
};


my @index;
$index[0] = new Keydesc;
$index[0]->k_flags( &ISNODUPS );
$index[0]->k_nparts(  2 );
$index[0]->k_part( 0, [  0, 21, &CHARTYPE ] );
$index[0]->k_part( 1, [ 21, 21, &CHARTYPE ] ); 

$index[1] = new Keydesc;
$index[1]->k_flags( &ISNODUPS );
$index[1]->k_nparts(  2 );
$index[1]->k_part( 0, [ 21, 21, &CHARTYPE ] );
$index[1]->k_part( 1, [  0, 21, &CHARTYPE ] ); 

my $INDEXMAP =
{
	foo => $index[0],
	bar => $index[1]
};

sub LENGTH { 60 };
sub FIELDMAP { $FIELDMAP };
sub INDEXMAP { $INDEXMAP };

1;
__END__;
