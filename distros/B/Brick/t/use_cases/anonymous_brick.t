#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

=head1 NAME

Anonymous Brick use case

=head1 SYNOPSIS

=cut

my $class = 'Brick';
use_ok( $class );

my $brick = $class->new();
isa_ok( $brick, $class );

my $bucket = $class->bucket_class->new;

=head1 DESCRIPTION

I don't always need a named nethods to compose functions, as long as I
know the name I gave it when I created it.

First, I need to create a brick that doesn't live in a named
subroutine. I can do that with C<add_to_bucket>. I name it C<FooSub>,
and that's how I'll get to it later. I'll make sure the I get the
right one by declaring that the name is unique.

=cut

my $unnamed_sub = $bucket->add_to_bucket( {
	name        => "FooSub",
	unique      => 1,
	description => "This is a brick that isn't attached to a sub name",
	code        => sub {
		$_[0]->{number} == 3 ? 1 : die {
			handler => 'FooSub',
			message => "Number wasn't 3",
			}
		},
	} );

isa_ok( $unnamed_sub, ref sub {} );

=pod

Later on, I want to use C<FooSub> in a composition, but I'm in some different
scope and I can't use the return value from C<add_to_bucket>. I make sure
I call C<get_brick_by_name> in list context, and since it's a unique name
I know that I'll only get a single code reference back.

=cut

my( $foo_sub ) = $bucket->get_brick_by_name( 'FooSub' );
is( $foo_sub, $unnamed_sub, "I get the same sub back" );

=pod

Now that I have my code reference for C<FooSub>, I can use it in a
composition (or even inside another subroutine).

=cut

my $composed = $bucket->__compose_satisfy_all( $foo_sub );
isa_ok( $composed, ref sub {} );

=pod

I might even use this in a named subroutine if I know that I've
already created the unnamed version. C<bar_sub> is like any
other brick:

=cut

sub Brick::Bucket::_bar_sub
	{
	my( $bucket, $setup ) = @_;

	my( $foo_sub ) = $bucket->get_brick_by_name( 'FooSub' );
	isa_ok( $foo_sub, ref sub {} );

	my $this_sub = $bucket->add_to_bucket( {
		name        => "_bar_sub",
		unique      => 1,
		description => "This is a brick I made in _bar_sub",
		code        => sub {
			$_[0]->{number} == 3 ? 1 : die {
				handler => 'FooSub',
				message => "Number wasn't 3",
				}
			},
		} );
	isa_ok( $this_sub, ref sub {} );

	my $composed = $bucket->__compose_satisfy_all(
		$foo_sub,
		$this_sub,
		);
	}

my $bar_sub = $bucket->_bar_sub;
isa_ok( $composed, ref sub {} );

