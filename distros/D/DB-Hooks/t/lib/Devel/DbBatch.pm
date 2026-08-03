package Devel::DbBatch;

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
	return   if DB::state( 'init' );
	return;
	DB::say '--> '. shift;
}

sub on_return {
	return   if DB::state( 'init' );
	return;
	DB::say '<-- '. shift;
}

sub on_binteract {
	my( $source, $f, $l ) =  @_;
	# return   if $off;

	printf $DB::OUT "%s:%04s  %s\n" ,$f ,$l ,$source;
}

sub on_interact { get_command( 'interact' )->( @_ ) };

use DB::Utils qw/ call return interact binteract /; # subscribe in given order

set_command 'list.conf' =>  sub {
	$DB::Commands::lines_before =  3;
	$DB::Commands::lines_after  =  3;
};

set_command 'list.conf2' =>  sub {
	$DB::Commands::lines_before =  3;
	$DB::Commands::lines_after  =  2;
};


1;
