#!perl -w

BEGIN
{
	chdir 't' if -d 't';
}

use strict;
use Test::More tests => 2;

my $module = 'Crypt::CipherSaber';
use_ok( $module );

# first, try to create an object
my $cs = $module->new('first key');
isa_ok( $cs, $module );
