use Test::More;
use Data::Dumper;

use strict;

sub dumper { Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Deepcopy(1)->Dump }

use Array::Join::OO;

my @arr_a = (
    { id => 1, name => 'Alice' },
    { id => 2, name => 'Bob' },
    { id => 3, name => 'Carol' },
    { id => 25, name => 'Zelda' },
);
my @arr_b = (
    { uid => 1, email => 'alice@example.com' },
    { uid => 3, email => 'carol@example.com' },
    { uid => 4, email => 'daniel@example.com' },
    { uid => 6, email => 'frank@example.com' },
    { uid => 8, email => 'hanna@example.com' },
);

$\ = "\n"; $, = "\t";

ok (2 == scalar Array::Join::OO->new(
				\@arr_a,
				\@arr_b,
				{
				 on => [
					sub { $_->{id} },
					sub { $_->{uid} },
				       ],
				 type  => 'inner',
				 merge => [ 'a', 'b' ],
				}
			       )->join, "inner");


ok( 7 ==scalar Array::Join::OO->new(
				\@arr_a,
				\@arr_b,
				{
				 on => [
					sub { $_->{id} },
					sub { $_->{uid} },
				       ],
				 type  => 'outer',
				 merge => [ 'a', 'b' ],
				}
			       )->join, "outer");

ok(4 == scalar Array::Join::OO->new(
				    \@arr_a,
				    \@arr_b,
				    {
				     on => [
					    sub { $_->{id} },
					    sub { $_->{uid} },
					   ],
				     type  => 'left',
				     merge => [ 'a', 'b' ],
				    }
				   )->join, "left");


ok (5 == scalar scalar Array::Join::OO->new(
					    \@arr_a,
					    \@arr_b,
					    {
					     on => [
						    sub { $_->{id} },
						    sub { $_->{uid} },
						   ],
					     type  => 'right',
					     merge => [ 'a', 'b' ],
					    }
					   )->join, "right");

done_testing();
