#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Visitor::Callback;

use Tie::RefHash;

my $h = {
	foo => {},
};

tie %{ $h->{foo} }, "Tie::RefHash";

$h->{bar}{gorch} = $h->{foo};

$h->{foo}{[1, 2, 3]} = "blart";

my $v = Data::Visitor::Callback->new( tied_as_objects => 1, object => "visit_ref" ); # deep clone the refhash tied

my $copy = $v->visit($h);

isnt( $copy, $h, "it's a copy" );
isnt( $copy->{foo}, $h->{foo}, "the tied hash is a copy, too" );
is( $copy->{foo}, $copy->{bar}{gorch}, "identity preserved" );
ok( tied %{ $copy->{foo} }, "the subhash is tied" );
isa_ok( tied(%{ $copy->{foo} }), 'Tie::RefHash', 'tied to correct class' );
isnt( tied(%{ $copy->{foo} }), tied(%{ $h->{foo} }), "tied is different" );
ok( ref( ( keys %{ $copy->{foo} } )[0] ), "the key is a ref" );
is_deeply([ keys %{ $copy->{foo} } ], [ keys %{ $h->{foo} } ], "keys eq deeply" );

my $v_no_tie = Data::Visitor::Callback->new( tied_as_objects => 0 );

my $no_tie_copy = $v_no_tie->visit($h);

ok( !tied(%{ $no_tie_copy->{foo} }), "not tied" );

sub Foo::AUTOLOAD { fail("tie interface must not be called") }
sub Foo::DESTROY {} # no fail

{
	foreach my $v (
		Data::Visitor::Callback->new( tied_as_objects => 1 ),
		Data::Visitor->new( tied_as_objects => 1 )
	) {
		my $x = bless {}, "Foo";

		use Tie::ToObject;

		tie my @array, 'Tie::ToObject' => $x;
		tie my %hash,  'Tie::ToObject' => $x;
		tie *handle,   'Tie::ToObject' => $x;
		tie my $scalar,'Tie::ToObject' => $x;

		{
			$v->visit(\@array);
			my $copy = $v->visit(\@array);
			is( ref($copy), "ARRAY", "tied array" );
			ok( tied(@$copy), "copy is tied" );
		}

		{
			$v->visit(\%hash);
			my $copy = $v->visit(\%hash);
			is( ref($copy), "HASH", "tied array" );
			ok( tied(%$copy), "copy is tied" );
		}

		{
			$v->visit(\$scalar);
			my $copy = $v->visit(\$scalar);
			is( ref($copy), "SCALAR", "tied array" );
			ok( tied($$copy), "copy is tied" );
		}
		{
			$v->visit(\*handle);
			my $copy = $v->visit(\*handle);
			is( ref($copy), "GLOB", "tied array" );
			ok( tied(*$copy), "copy is tied" );
		}
	}
}

done_testing;
