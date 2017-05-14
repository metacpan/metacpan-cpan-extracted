use Test::More qw(no_plan);

use strict;

use warnings;

use Class::Maker;

use Class::Maker::Types::Array;

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

sub li
{
	my $title = shift;

	$title = 'Array '.$title;

	print "\n" x 3, $title, "\n", "=" x length( $title ), "\n", @_ , "\n";
}

	my $m =  Class::Maker::Types::Array->new( array => [qw(x x)] );

	my $m1 =  Class::Maker::Types::Array->new( array => [qw(B B)] );

	is( $m->intersection( $m1 )->totext, "[]" );

	my $m2 =  Class::Maker::Types::Array->new( array => [qw(A B)] );

	is( $m->intersection( $m2 )->totext, "[]" );






my @set = (
	   Class::Maker::Types::Array->new( array => [qw(A B)] ),
	   Class::Maker::Types::Array->new( array => [qw(B)] ),
	   Class::Maker::Types::Array->new( array => [qw(B A)] ),
	  );

	is( $set[0]->diff( $set[1] )->totext, "[A]" );
	is( $set[2]->diff( $set[1] )->totext, "[A]" );









	my $a = Class::Maker::Types::Array->new( array => [1..70] );

	my $b = Class::Maker::Types::Array->new( array => [50..100, 60] );

	li( "A", $a->totext );

	li( "B", $b->totext );

	li( "B UNIQUE", $b->unique->sort->totext );

	li( "PICK 2", $a->pick( 2 )->totext );

	li( "PICK 3", $a->pick( 3 )->totext );

	li( "UNION", $b->union( $a )->sort->totext );

	li( "DIFF", $b->diff( $a )->sort->totext );

	li( "INTERSECTION", $b->intersection( $a )->sort->totext );

	my $c = Class::Maker::Types::Array->new( array => [50..100] );

	my $d = Class::Maker::Types::Array->new( array => [50..100] );

	li( "C", $c->totext );

	li( "D", $d->totext );

	li( "C eq D", $c->eq( $d ) ? 'yes' : 'no' );

	li( "C eq A", $c->eq( $a ) ? 'yes' : 'no' );

	li( "RAND C", $c->rand->totext );

	li( "RAND and SORT C", $c->rand->sort->totext );

ok(2);

use IO::Extended qw(:all);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

Class::Maker::class 'Person',
{
    public =>
    {
            scalar => [qw( name age )],
    },

    private =>
    {
    		scalar => [qw( internal )],
    },
};

sub Person::hello : method
{
	my $this = shift;

	$this->_internal( 2123 );

	printf "Here is %s and i am %d years old.\n",  $this->name, $this->age;
};

sub Person::regexp_test_method : method
{
	my $this = shift;

return join ', ', @_;
}


  my $set = Class::Maker::Types::Array->new( array => [] );

ok $set;

	our @names = qw(Jo James John Janna Jessi Silver Platinum Triton);

  $set->push( Person->new( name => $_ ) ) for @names;

use Data::Dumper;

print Dumper $set;

###

is scalar $set->get_where( name => 'Jo' )->get, 1;

my ($ga) = $set->get_where( name => 'Jo' )->get;

is $ga->name, 'Jo';

#### REGEXP method

is scalar $set->get_where_regexp( name => qr/Jo/ )->get, 2;

is scalar $set->get_where_regexp( name => qr/J/ )->get, 5;

#### REGEXP method with args

is scalar $set->get_where_regexp( [qw(name)] => qr/Jo/ )->get, 2;

  # regexp_test_method returns its arguments (here always alpha), thats why we expect all objects to be selected
is scalar $set->get_where_regexp( [qw(regexp_test_method alpha)] => qr/alpha/ )->get, scalar @names;

###

is scalar $set->get_where_sref( sub { $_[1]->name eq 'Silver' } )->get, 1;

is scalar $set->get_where_sref( sub { $_[1]->name eq 'Silver' || $_[1]->name eq 'Triton' } )->get, 2;

ok(3);


###

	my $seq = Class::Maker::Types::Array->new( array => [1..100] );

	li( "SEQ 1..100 divided by 2", $seq->div( 2 )->totext );

ok(1);

	li( "SEQ 1..100 divided by 2 and scale_unit() method", $seq->div(2)->scale_unit->totext );

ok(1);

	my $array_like_hash = Class::Maker::Types::Array->new( array => [1..4], keys => [qw( alpha beta gamma delta )] );
	
	li( "array as_hash tested", Data::Dump::dump $array_like_hash->as_hash );
	
	li( "->warp( 3, 2, 1, 0 ) test: BEFORE", Data::Dump::dump $array_like_hash );

	li( "->warp( 3, 2, 1, 0 ) test: AFTER", Data::Dump::dump $array_like_hash->warp( 3, 2, 1, 0 ) );


	my $array_a = Class::Maker::Types::Array->new( array => [1..4] );

	my $array_b = Class::Maker::Types::Array->new( array => [1..4] );

	li( '$this->div_by_array_obj( $that ), all should be 1', Data::Dump::dump $array_a->div_by_array_obj( $array_b ) );
