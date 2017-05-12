#!/usr/bin/perl -w 

use strict;
use warnings;

use Data::Pageset::Variable;

use Test::More tests => 16;

#------------------------------------------------------------------------------
# setup stuff
#------------------------------------------------------------------------------

my @list = ( 1 .. 100 );
my $args = { total_entries              => scalar @list, 
	variable_entries_per_page  => { 1 => 30, 2 => 20, 4 => 23, },
	entries_per_page           => 10,
};

#------------------------------------------------------------------------------
# new
#------------------------------------------------------------------------------

{
	local $args->{variable_entries_per_page} = [ 1 .. 10 ];
	eval { Data::Pageset::Variable->new($args) };
	like $@, qr/hashref/, 
	"Can't make a Data::Pageset::Variable unless entries_per_page is a hashref";
}

{
	local $args->{entries_per_page};
	eval { Data::Pageset::Variable->new($args) };
	like $@, qr/supplied/, 
	"Can't make a Data::Pageset::Variable unless we tell it the default entries_per_page";
}

{
	isa_ok(Data::Pageset::Variable->new($args) => 'Data::Pageset::Variable');
}

#------------------------------------------------------------------------------
# behaves like Data::Pageset with no variable_entries_per_page
#------------------------------------------------------------------------------

{
	my $args = { total_entries => scalar @list, entries_per_page   => 10 };
	isa_ok my $dp = Data::Pageset::Variable->new($args) => 'Data::Pageset::Variable';
	is $dp->first => 1, "first on first page (no variable_entries_per_page";
	is $dp->last => 10, "last on first page (no variable_entries_per_page"; 
}

#------------------------------------------------------------------------------
# entries on the page
#------------------------------------------------------------------------------

{
# page 1
	local $args->{current_page} = 1;
	my $dp = Data::Pageset::Variable->new($args);
	is $dp->first => 1, "first on first page";
	is $dp->last => 30, "last on first page";
}

{
# page 2
	local $args->{current_page} = 2;
	my $dp = Data::Pageset::Variable->new($args);
	is $dp->first => 31, "first on second page";
	is $dp->last => 50, "last on second page";
}

{
# page 3
	local $args->{current_page} = 3;
	my $dp = Data::Pageset::Variable->new($args);
	is $dp->first => 51, "first on third page";
	is $dp->last => 60, "last on third page";
}

{
# page 4
	local $args->{current_page} = 4;
	my $dp = Data::Pageset::Variable->new($args);
	is $dp->first => 61, "first on fourth page";
	is $dp->last => 83, "last on fourth page";
}

{
# ridiculously large page
	local $args->{current_page} = 300;
	my $dp = Data::Pageset::Variable->new($args);
	is $dp->first => 94, "first on last page";
	is $dp->last => 100, "last on last page";
}



