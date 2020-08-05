use strict;
use warnings;

use Test::More;

BEGIN {
  plan skip_all => 'these tests require Data::Alias or fixes to use core aliasing' if "$]" >= '5.031002';
}

use Test::Needs 'Data::Alias';

use Scalar::Util qw(isweak weaken);

use Data::Visitor;

{
	my $ref = { };
	$ref->{foo} = $ref;
	weaken($ref->{foo});

	ok( isweak($ref->{foo}), "foo is weak" );

	my $v = Data::Visitor->new( weaken => 1 );

	my $copy = $v->visit($ref);

	is_deeply( $copy, $ref, "copy is equal" );

	ok( isweak($copy->{foo}), 'copy is weak' );
}

{
	my $ref = { foo => { } };
	$ref->{bar} = $ref->{foo};
	weaken($ref->{foo});

	ok(  isweak($ref->{foo}), "foo is weak" );
	ok( !isweak($ref->{bar}), "bar is not weak" );

	my $v = Data::Visitor->new( weaken => 1 );

	my $copy = $v->visit($ref);

	local $TODO = "can't tell apart different refs without making hash/array elems seen as scalar refs";
	ok( isweak($copy->{foo}), 'copy is weak' );
	is_deeply( $copy, $ref, "copy is equal" );
	ok( ref $copy->{bar} && !isweak($copy->{bar}), 'but not in bar' );
}

done_testing;
