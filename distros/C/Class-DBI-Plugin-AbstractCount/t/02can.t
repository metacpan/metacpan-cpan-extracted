#!/usr/bin/perl -I. -w
use strict;

use Test::More tests => 2;

sub set_sql
{
	my ( $class, $name, $sql ) = @_;
	no strict 'refs';
	*{ "$class\::sql_$name" } =
		sub
		{ };
}

use Class::DBI::Plugin::AbstractCount;
can_ok( 'main', qw( count_search_where ) );
can_ok( 'main', qw( sql_count_search_where ) );

__END__
