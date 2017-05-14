# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;

BEGIN { plan tests => 2 };

use Data::Dumper;

use Class::Maker;

ok(1); # If we made it this far, we're ok.

#########################
# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

Class::Maker::class 'TestMe',
{
	public =>
	{
		string => [qw( one two three four )],
	}
};

	my $tm = TestMe->new;

	$tm->one( 1 );
	$tm->two( 2 );
	$tm->three( 3 );
	$tm->four( 4 );

	print "FIRST: \n";

	my $clone = $tm->new( two => '666' );

	print Dumper [ $tm, $clone ];

	$Class::Maker::Basic::Fields::DEBUG = 1;

{
	package Role;

	Class::Maker::class
	{
		public =>
		{
			string => [qw( anything )],
		},
	};
}

{
	package Human::Role;

	our @ISA = qw( Role );

	Class::Maker::class
	{
		public =>
		{
			string => [qw( name desc purpose )],
		},

		default =>
		{
			name => 'Role Name',

			desc => 'Role Descrition',
		},
	};

	sub anew : method
	{
		my $this = shift;

		return $this->new( name => $_[0] );
	}
}

{
	package Human::Role::Simple;

	@ISA = qw(Human::Role);

	sub new : method
	{
		my $this = shift;

		return $this->SUPER::new( name => $_[0] );
	}
}

	our $myrole = Human::Role->new( name => 'dba', desc => 'Database Administrator' );

	print Dumper $myrole;

	$Class::Maker::DEBUG = 0;

	our $role = Human::Role->anew( 'dba' );

	our $role_simple = Human::Role::Simple->new( 'admin' );

	my $all = Class::Maker::Reflection::find( 'main' => 'Human::Role' );

	print Dumper $all, $role;

	print "--" x 40, "\n";

	print Dumper 'Human::Role reflex', Class::Maker::Reflection::reflect( 'Human::Role' );

	#print Dumper 'Human::Role::Simple reflex', map { reflect( $_ ) } @{ *{ 'Human::Role::Simple::ISA' }{ARRAY} };

	$Class::Maker::Reflection::DEEP = 1;

	print "--" x 40, "\n";

	print Dumper 'Human::Role::Simple reflex', Class::Maker::Reflection::reflect( 'Human::Role::Simple' );
	
	print Dumper Class::Maker::Reflection::reflect( 'Human::Role::Simple' )->parents; 

	#class User => qw/Human/, qw( string<name firstname title> date<birthday> email<email> array<friends> hash<synonymes> );




package Class::Maker::Test;

Class::Maker::class '.TestMe',
{
	public =>
	{
		string => [qw( one two three four )],
	}
};

package main;

	$_ = Class::Maker::Test::TestMe->new( one => '1' );

	print Dumper $_;

ok( $_->one eq '1' );
