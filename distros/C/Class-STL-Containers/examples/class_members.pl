#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use stl;

{
	package MyPack;
	use Class::STL::ClassMembers (
			qw(msg_text msg_type),
			Class::STL::ClassMembers::DataMember->new(
				name => 'on', validate => '^(input|output)$', default => 'input'),
			Class::STL::ClassMembers::DataMember->new(
				name => 'display_target', default => 'STDERR'),
			Class::STL::ClassMembers::DataMember->new(
				name => 'count', validate => '^\d+$', default => '100'),
			Class::STL::ClassMembers::DataMember->new(
				name => 'comment', validate => '^\w+$', default => 'hello'),
			Class::STL::ClassMembers::FunctionMember::New->new(),
			Class::STL::ClassMembers::FunctionMember::Disable->new(qw(somfunc)),
	); 
}

print ">>>$0>>>>:\n";

my $p = MyPack->new();
print "\$p->member_print():", $p->members_print(), "\n";

print "\$p->count(25);\n";
$p->count(25);
print "\$p->member_print():", $p->members_print(), "\n";

print "\$p->comment(\$p->comment() . 'world');\n";
$p->comment($p->comment() . 'world');
print "\$p->member_print(\"\\n\"):\n", $p->members_print("\n"), "\n";
