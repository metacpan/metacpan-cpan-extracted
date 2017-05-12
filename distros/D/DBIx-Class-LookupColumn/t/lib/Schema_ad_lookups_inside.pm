package Schema_ad_lookups_inside;

use Moose;
#use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

use Data::Dumper;

__PACKAGE__->load_namespaces;


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

__PACKAGE__->load_components( qw/LookupColumn::Auto/ );

 my @tables = __PACKAGE__->sources; # get all table names 
 
 my @candidates =  grep { ! /Type$/ } @tables;  # tables that do NOT end with Type
 my @lookups =  grep {  /Type$/ } @tables;      # tables that DO end with Type == the Lookup Tables !

 __PACKAGE__->add_lookups(
	targets => \@candidates, 
	lookups => \@lookups,
	
	# function that will generate the relation names: here we build it from the Lookup Table
	relation_name_builder => sub{
		my ( $class, %args) = @_;
		$args{lookup} =~ /^(.+)Type$/; # remove the end (Type) from the Lookup table name
		lc( $1 );
	},
	# function that gives the name of the column that holds the definitions/values: here it is always 'name'
	lookup_field_name_builder => sub { 'name' } 
 );


1;
