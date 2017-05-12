use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use DBIx::Class::Storage::Statistics;
use Test::DBIC::Schema::Connector;
use DCAUTSchema;
use Data::Dumper;

my $schema = test_dbic_schema_connect('DCAUTSchema');

my @queries;

{
	package LastQueryMagic;
	use strict;
	use base 'DBIx::Class::Storage::Statistics';

	sub query_start {
		my $self = shift;
		push @queries, {
			sql => shift,
			params => \@_,
		};
	}
}

$schema->storage->debug(1);
$schema->storage->debugobj(LastQueryMagic->new);

my $insert = $schema->resultset('DCAUT')->create({ id => 5 });
shift @queries; # ignore this query

$insert->update;

my $query = shift @queries;

is($query->{params}->[0],'\'5\'', "Checking for update try in last params");

done_testing;
