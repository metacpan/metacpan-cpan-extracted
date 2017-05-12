package DBIx::Class::InflateColumn::Serializer::Role::HashContentAccessor::TestSchema::Result::JSONTable;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::Serializer");

__PACKAGE__->table("json_table");

__PACKAGE__->add_columns(
	"id",
	{
		data_type         => "integer",
		is_auto_increment => 1,
		is_nullable       => 0,
		sequence          => "property_table_id_seq",
	},
	"properties1",
	{ data_type => "text", is_nullable => 1, serializer_class => "JSON" },
	"properties2",
	{ data_type => "text", is_nullable => 1, serializer_class => "JSON" },
);

__PACKAGE__->set_primary_key("id");

with 'DBIx::Class::InflateColumn::Serializer::Role::HashContentAccessor' => {
	column => 'properties1',
	name   => 'property1',
};

with 'DBIx::Class::InflateColumn::Serializer::Role::HashContentAccessor' => {
	column => 'properties2',
	name   => 'property2',
};


__PACKAGE__->meta->make_immutable;
1;
