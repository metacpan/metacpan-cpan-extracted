use strict;

use warnings;

use Test::More qw(no_plan);

BEGIN
{ 
	$|++;

	use_ok( 'Data::Type', qw(_ +DB +Bio +Perl +Perl6) ); 
}

use Data::Dumper;

#diag( Data::Dumper->Dump( [ \%Data::Type::_alias ] ) );

ok( STD_BOOL(), 'STD_BOOL exported');

ok( DB_VARCHAR(), 'DB_VARCHAR exported');

ok( BIO_DNA(), 'STD_DNA exported');

__END__

ok( Data::Type::STD_BOOL(), 'STD_BOOL exported');

ok( Data::Type::DB_VARCHAR(), 'DB_VARCHAR exported');

ok( Data::Type::BIO_DNA(), 'STD_DNA exported');
