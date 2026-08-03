package Devel::DbContext;

use strict;
use warnings;

use parent 'DB::Hooks';

use DB::Commands qw/ set_command get_command run /;
# Commands should be available immediately. This is important when
# we are debugging at CT: when DB is in process of loading
BEGIN {
	set_command next_command =>  \&get_next;
}


our $commands;
sub import {
	( my $class, $commands ) =  ( shift, shift );

	$commands =~ s/^\$(.)//s;
	my $endline =  $1 // ';';
	$commands =  [ split $endline, $commands ];

	$class->SUPER::import( @_ );
}


sub get_next {
	return shift @$commands;
}

sub on_call {
	eval {1/0}
}

sub on_return {
	eval {1/0}
}
sub on_load {
	$_ = 'broken';
}

sub on_interact { get_command( 'interact' )->( @_ ) };

use DB::Utils qw/ call return load interact /; # subscribe in given order


1;
