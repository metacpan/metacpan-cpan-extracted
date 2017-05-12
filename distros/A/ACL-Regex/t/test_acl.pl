#!/usr/bin/perl
#use warnings;
use strict;
use lib( "../lib" );
use ACL::Regex;
use Data::Dumper;

my $accept_acl = ACL::Regex->new->
	generate_required( 'required.txt' )->
	parse_acl_from_file( { Filename => "acl.permit.txt" } );

my $reject_acl = ACL::Regex->new->
	generate_required( 'required.txt' )->
	parse_acl_from_file( { Filename => "acl.reject.txt" } );

my @actions;

# Read an action
while( <> ){
	chomp;
	push( @actions, $_ );
}

ACTION: for my $action ( @actions ){
	print "Action: $action\n";
	# Check against the reject
	my ($rc,$regex,$comment) = $reject_acl->match( $action );
	if( $rc ){
		print "\t! Rejected against $regex\n";
		print "\t: Reason: $comment\n";
		next ACTION;
	}
	($rc,$regex,$comment) = $accept_acl->match( $action );
	if( $rc ){
		print "\t* Accepted against $regex\n";
		print "\t: Reason: $comment\n";
		next ACTION;
	}

	print "\t? No ACLs matched\n";

}
