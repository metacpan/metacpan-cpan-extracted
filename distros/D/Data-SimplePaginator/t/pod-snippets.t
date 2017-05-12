#!/usr/bin/perl -w
use Test::More;
eval "use Pod::Snippets 0.14";
plan skip_all => "Pod::Snippets 0.14 required for testing POD snippets" if $@;

# find the module
my @locations = (
	'lib/Data/SimplePaginator.pm', # when running perl t/pod-snippets.t
	'../lib/Data/SimplePaginator.pm', # when running perl pod-snippets.t
	map { "$_/Data/SimplePaginator.pm" } @INC, # for anywhere else
);
my @found = grep { -e $_ } @locations;
my $module = shift @found;

plan skip_all => "Cannot find Data::SimplePaginator for testing POD snippets" unless defined $module;
plan tests => 1;

require $module;
my $snips = load Pod::Snippets($module);
my $result = eval $snips->as_code; 
"$@" ? fail($@) : pass;
