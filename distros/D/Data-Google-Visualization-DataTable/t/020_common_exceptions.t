#!/usr/bin/perl

use strict;
use warnings;
use Data::Google::Visualization::DataTable;
use Test::More;
use Scalar::Util qw(weaken);

BEGIN {
	eval "use Test::Exception";
	plan skip_all => "Test::Exception needed for these tests" if $@;
}

plan tests => 8;

# Add a column, add a row, then add another column
{
	my $datatable = Data::Google::Visualization::DataTable->new();
	$datatable->add_columns({ id => 'foo', label => "bar", type => 'string' });
	$datatable->add_rows([1]);
	throws_ok
		{ $datatable->add_columns }
		qr/You can't add columns once you've added rows/,
		"Adding columns after rows caught";
}

# Adding bad columns
{
	my $datatable = Data::Google::Visualization::DataTable->new();
	throws_ok
		{ $datatable->add_columns( {} ) }
		qr/Every column must have a 'type'/,
		"Adding columns without a type caught";
	throws_ok
		{ $datatable->add_columns( { type => 'foo' } ) }
		qr/Unknown column type/,
		"Adding columns with an unknown type caught";
}

# Bad label, ID, pattern
{
	my $datatable = Data::Google::Visualization::DataTable->new();
	for my $key (qw(label pattern id)) {
		throws_ok
			{ $datatable->add_columns( { type => 'string', $key => [] } ) }
			qr/'$key' needs to be a simple string/,
			"Adding a reference for '$key' caught";
	}
}

# Nonsense column p
{
	my $datatable = Data::Google::Visualization::DataTable->new();
	my $circular = [];
	push(@$circular, $circular);
	weaken $circular;

	throws_ok
		{ $datatable->add_columns( { type => 'string', p => $circular } ) }
		qr/Serializing 'p' failed/,
		"Unserializable p caught";
}

# Catch non-unique columns
{
	my $datatable = Data::Google::Visualization::DataTable->new();
	$datatable->add_columns({ id => 'foo', label => "bar", type => 'string' });
	throws_ok
		{ 	$datatable->add_columns({ id => 'foo', label => "baz", type => 'string' }) }
		qr/We already have a column with the id/,
		"Duplicate column ID caught";
}