#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::Visitor::Callback;

sub newcb { Data::Visitor::Callback->new( @_ ) }
ok( !newcb()->ignore_return_values, "ignore_return_values defaults to false" );
is( newcb( ignore_return_values => 1 )->ignore_return_values, 1, "but can be set as initial param" );

{
	my $data = {
		action => 'original'
	};

	my $callbacks = {
		value => sub {
			my( $visitor, $data ) = @_;
# program gets to here and $data eq 'original'
			return 'modified';
		}
	};

	my $v = Data::Visitor::Callback->new( %$callbacks );

	is_deeply( $v->visit($data), { modified => "modified" } );
}

done_testing;
