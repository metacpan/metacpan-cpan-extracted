#!/usr/bin/perl -w
use strict;
use vars qw( $class );

use Test::More tests => 13;

# ------------------------------------------------------------------------

BEGIN {
    $class = 'Data::Phrasebook';
    use_ok $class;
}

my $file = 't/01phrases.txt';
my %trail = (
	1 => 0,
	2 => 0,
	3 => 11,
	4 => 29,
);

# ------------------------------------------------------------------------

{
    my $obj = $class->new;
    isa_ok( $obj => "${class}::Plain", 'Bare new' );
    is( $obj->debug => 0 , 'Set/get debug works');
}

{
    my $obj = $class->new( file => $file, debug => 4 );
    isa_ok( $obj => "${class}::Plain", 'New with file' );
    is( $obj->debug => 4 , 'Set/get debug works');

    {
        my $str = $obj->fetch( 'foo', {
                my => "Iain's",
                place => 'locale',
            });
    }

    {
        $obj->delimiters( qr{ :(\w+) }x );

        my $str = $obj->fetch( 'bar', {
                my => "Bob's",
                place => 'whatever',
            });
    }

	for(1..4) {
		my @log = $obj->retrieve($_);
		is(scalar(@log),$trail{$_});
	}

	$obj->clear();
	{
		my @log = $obj->retrieve(4);
		is(scalar(@log),$trail{1});
		@log = $obj->retrieve();
		is(scalar(@log),$trail{1});

		my $items = $obj->store();
		is($items,undef);
		$items = $obj->store(5,'hello');
		is($items,undef);
	}
}

