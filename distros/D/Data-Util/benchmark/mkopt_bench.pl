#!perl -w

use strict;
use Benchmark qw(:all);

use FindBin qw($Bin);
use lib $Bin;
use Common;

use Data::Util qw(:all);
use Data::OptList();

signeture 'Data::Util' => \&mkopt, 'Data::OptList' => \&Data::OptList::mkopt;

my @args = ([qw(foo bar), baz => []], "moniker", 0);

#use Test::More 'no_plan';
#is_deeply Data::Util::mkopt(@args), Data::OptList::mkopt(@args);

print "mkopt()\n";
print "no-unique, no-validation\n";
cmpthese -1 => {
	'OptList' => sub{
		for(1 .. 10){
			my $opt_ref = Data::OptList::mkopt(@args);
		}
	},
	'Util' => sub{
		for(1 .. 10){
			my $opt_ref = Data::Util::mkopt(@args);
		}
	},
	'inline' => sub{
		for(1 .. 10){
			my $opt_ref = [ (map{ [$_ => undef] } qw(foo bar) ), [baz => []] ];
		}
	},
};

@args = ([qw(foo bar), baz => []], "moniker", 1);
print "unique, no-validation\n";
cmpthese -1 => {
	'OptList' => sub{
		for(1 .. 10){
			my $opt_ref = Data::OptList::mkopt(@args);
		}
	},
	'Util' => sub{
		for(1 .. 10){
			my $opt_ref = Data::Util::mkopt(@args);
		}
	},
};

@args = ([qw(foo bar), baz => []], "moniker", 0, 'ARRAY');
print "no-unique, validation\n";
cmpthese -1 => {
	'OptList' => sub{
		for(1 .. 10){
			my $opt_ref = Data::OptList::mkopt(@args);
		}
	},
	'Util' => sub{
		for(1 .. 10){
			my $opt_ref = Data::Util::mkopt(@args);
		}
	},
};

@args = ([qw(foo bar), baz => []], "moniker", 1, 'ARRAY');
print "unique, validation\n";
cmpthese -1 => {
	'OptList' => sub{
		for(1 .. 10){
			my $opt_ref = Data::OptList::mkopt(@args);
		}
	},
	'Util' => sub{
		for(1 .. 10){
			my $opt_ref = Data::Util::mkopt(@args);
		}
	},
};

@args = ({foo => [], bar => [], baz => []}, "moniker", 0);
print "\nmkopt() from HASH ref\n";
cmpthese -1 => {
	'OptList' => sub{
		for(1 .. 10){
			my $opt_ref = Data::OptList::mkopt(@args);
		}
	},
	'Util' => sub{
		for(1 .. 10){
			my $opt_ref = Data::Util::mkopt(@args);
		}
	},
};


@args = ([qw(foo bar), baz => []]);
print "\nmkopt_hash()\n";
cmpthese -1 => {
	'OptList' => sub{
		for(1 .. 10){
			my $opt_ref = Data::OptList::mkopt_hash(@args);
		}
	},
	'Util' => sub{
		for(1 .. 10){
			my $opt_ref = Data::Util::mkopt_hash(@args);
		}
	},
	'inline' => sub{
		for(1 .. 10){
			my $opt_ref = { (map{ $_ => undef} qw(foo bar) ), baz => [] };
		}
	}
};

@args = ([qw(foo bar), baz => []], 'test', 'ARRAY');
print "mkopt_hash() with validation\n";
cmpthese -1 => {
	'OptList' => sub{
		for(1 .. 10){
			my $opt_ref = Data::OptList::mkopt_hash(@args);
		}
	},
	'Util' => sub{
		for(1 .. 10){
			my $opt_ref = Data::Util::mkopt_hash(@args);
		}
	},
	'inline' => sub{
		for(1 .. 10){
			my $opt_ref = { (map{ $_ => undef} qw(foo bar) ), baz => [] };
			while(my($k, $v) = each %{$opt_ref}){
				defined $v and array_ref($v);
			}
		}
	}
};
