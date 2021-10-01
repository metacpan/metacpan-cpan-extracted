#!/usr/bin/perl -w

use strict;

use Test::More;
BEGIN { require "./t/utils.pl" }

use vars qw(@SPEC_METHODS @MODULES);
my @SPEC_METHODS = qw(AUTOLOAD DESTROY CLONE);
my @MODULES = qw(DBIx::SearchBuilder DBIx::SearchBuilder::Record);

if( not eval { require Devel::Symdump } ) {
	plan skip_all => 'Devel::Symdump is not installed';
} elsif( not eval { require capitalization } ) {
	plan skip_all => 'capitalization pragma is not installed';
} else {
	plan tests => scalar @MODULES;
}

foreach my $mod( @MODULES ) {
	eval "require $mod";
	my $dump = Devel::Symdump->new($mod);
	my @methods = ();
	foreach my $method (map { s/^\Q$mod\E:://; $_ } $dump->functions) {
		push @methods, $method;
		
		my $nocap = nocap( $method );
		push @methods, $nocap if $nocap ne $method;
	}
	can_ok( $mod, @methods );
}

sub nocap
{
	my $method = shift;
	return $method if grep( { $_ eq $method } @SPEC_METHODS );
	$method =~ s/(?<=[a-z])([A-Z]+)/"_" . lc($1)/eg;
	return lc($method);
}

