#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Will it get past something that returns undef?
{
my $undef_sub = sub { return };
my $pass_sub  = sub { 1 };

{
my $sub = $bucket->__compose_pass_or_skip( $undef_sub, $pass_sub );
isa_ok( $sub, ref sub {}, "__compose_pass_or_skip returns a hash ref" );

my $result = eval { $sub->({}) };
ok( $result, "Satisfied one" );
}

{
my $sub = $bucket->__compose_pass_or_skip( $undef_sub, $undef_sub );
isa_ok( $sub, ref sub {}, "__compose_pass_or_skip returns a hash ref" );

my $result = eval { $sub->({}) };
my $at = $@;
print STDERR Data::Dumper->Dump( [$at], [qw(at)] ) if $ENV{DEBUG};

TODO: {
	local $TODO = "Should this return undef?";

	ok( ! defined $at, "\$@ is undef" );
	}

	is( $result, 0, "Satisfied none" );
}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Will it get past something that returns die with a reference?
# It shouldn't
{
my $undef_sub = sub {
	die {
		message => "Validation error!",
		handler => "undef_sub"
		}
	};
my $pass_sub  = sub { 1 };

{
my $sub = $bucket->__compose_pass_or_skip( $undef_sub, $pass_sub );
isa_ok( $sub, ref sub {}, "__compose_pass_or_skip returns a hash ref" );

my $result = eval { $sub->({}) };
my $at = $@;
is( $result, undef, "Failed, as expected" );
isa_ok( $at, ref {}, "\$@ is a reference" );
ok( exists $at->{message}, "Key 'message' exists in die ref" );
ok( exists $at->{handler}, "Key 'handler' exists in die ref" );
}


}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Two selectors that will work with the right input data
{

my $cat_selector = sub {
	#print STDERR "\nRunning cat selector\n" if $ENV{DEBUG};
	return unless $_[0]->{animal} eq 'cat'; return 1
	};

my $dog_selector = sub {
	#print STDERR "\nRunning dog selector\n" if $ENV{DEBUG};
	return unless $_[0]->{animal} eq 'dog'; return 1
	};

my $sub = $bucket->__compose_pass_or_skip( $cat_selector, $dog_selector );
isa_ok( $sub, ref sub {}, "__compose_pass_or_skip returns a hash ref" );

foreach my $animal ( qw(dog cat dog) )
	{
	my $result = eval { $sub->( { animal => $animal } ) };
	#print STDERR Data::Dumper->Dump( [$result], [qw(result)] );
	ok( $result, "Animal '$animal' returned true" );
	}

foreach my $animal ( qw(llama camel) )
	{
	my $result = eval { $sub->( { animal => $animal } ) };
	my $at = $@;
	print STDERR Data::Dumper->Dump( [$at], [qw(at)] ) if $ENV{DEBUG};
	TODO: { local $TODO = "Error in return values";
	eval { isa_ok( $at, ref {}, "\$@" );
	ok( exists $at->{message}, "Key 'message' exists in die ref" );
	ok( exists $at->{handler}, "Key 'handler' exists in die ref" ); }; }
	}

}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Two selectors with sub conditions
{

my $cat_selector = sub {
	print STDERR "Running cat selector with $_[0]->{animal}\n" if $ENV{DEBUG};
	return unless $_[0]->{animal} eq 'cat'; print "Still here!\n"; return 1
	};

my $cat_sound = sub {
	print STDERR "Running cat sound with $_[0]->{animal}\n" if $ENV{DEBUG};
	die {
		message => "Cats don't go '$_[0]->{sound}'",
		handler => 'cat_sound',
		} unless $_[0]->{sound} eq 'meow';
	# print STDERR "Still here!\n";
	return 1
	};

my $cat_composed = $bucket->__compose_pass_or_stop( $cat_selector, $cat_sound );

my $dog_selector = sub {
	print STDERR "Running dog selector with $_[0]->{animal}\n" if $ENV{DEBUG};
	return unless $_[0]->{animal} eq 'dog'; return 1
	};

my $dog_sound = sub {
	print STDERR "Running dog sound with $_[0]->{animal}\n" if $ENV{DEBUG};
	die {
		message => "Dogs don't go '$_[0]->{sound}'",
		handler => 'dog_sound',
		} unless $_[0]->{sound} eq 'bark';
	return 1
	};

my $dog_composed = $bucket->__compose_pass_or_stop( $dog_selector, $dog_sound );

my $sub = $bucket->__compose_pass_or_skip( $cat_composed, $dog_composed );
isa_ok( $sub, ref sub {}, "__compose_pass_or_skip returns a hash ref" );

foreach my $animal ( qw(dog cat dog) )
	{
	print STDERR "\n-----------------\nTrying animal ==> $animal, sound => meow\n" if $ENV{DEBUG};
	my $result = eval { $sub->( { animal => $animal, sound => 'meow' } ) };
	#print STDERR Data::Dumper->Dump( [$result], [qw(result)] );
	is( !! $result, 'cat' eq $animal,
		"Animal '$animal' with 'meow' " .
			('cat' eq $animal ? "passed" : "failed")
			);
	}

}
