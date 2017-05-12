#!/usr/bin/perl -w
use strict;

use Test::More tests => 7;
use Data::Phrasebook;

my @empty = ();

# load up the default dict
my $book = Data::Phrasebook->new(class  => 'Plain',
                                 loader => 'Text',
								 );

{
	my @dicts = $book->dicts();
	is( scalar(@dicts), 0 );

	@dicts = $book->dicts('blah');
	is( scalar(@dicts), 0 );
}

$book->file('t/phrases');

{
	eval { $book->keywords('t/phrases','welsh.txt'); };
	like( $@, qr/not accessible/ );

	eval { $book->keywords('blah','english.txt'); };
	like( $@, qr/not accessible/ );
}

{
	eval { $book->keywords(undef,'welsh.txt'); };
	like( $@, qr/not accessible/ );

	eval { $book->keywords('t/phrases',undef); };
	like( $@, qr/not accessible/ );

	eval { $book->keywords('blah',undef); };
	like( $@, qr/not accessible/ );
}

