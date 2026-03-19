package CPAN::MetaPackager::Create;

use 5.36.0;
use parent 'CPAN::MetaPackager::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Types::Standard qw/Object Str/;

our $VERSION = '1.00';

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;
	$self -> logger -> info('Creating all tables');

	my($method);
	my($result);

	for my $table_name (@{$self -> table_names})
	{
		$method = "create_${table_name}_table";

		$result = $self -> $method;

		$self -> logger -> debug("Created table '$table_name'");
	}

	$self -> logger -> info('Created all tables');
	$self -> logger -> info('-' x 50);

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of create_all_tables.

# --------------------------------------------------
# In the log table:
# o action	=> 'add', 'delete', 'export', 'import', 'update'.
# o context	=> 'flower', etc.
# o key		=> Either 0 or a primary key associated with the context.
# o name	=> The name of the thing.
# o note	=> Any text. May contain other primary keys, e.g. when garden also has a property.
# o outcome	=> 'Success' or 'Error'.

sub create_log_table
{
	my($self)        = @_;
	my($table_name)  = 'log';
	my($engine)      = $self -> engine;
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id			$primary_key,
action		text not null,
context		text not null,
file_name	text not null,
key			integer not null,
name		text not null,
note		text not null,
outcome		text not null,
timestamp	text $time_option not null default current_timestamp
) strict $engine
SQL

	return $result;

}	# End of create_log_table.

# --------------------------------------------------

sub create_packages_table
{
	my($self)        = @_;
	my($table_name)  = 'packages';
	my($engine)      = $self -> engine;
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id		$primary_key,
author	text not null,
name	text not null,
version	text not null
) strict $engine
SQL

	return $result;

}	# End of create_packages_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;
	$self -> logger -> info('Dropping all tables');

	for my $table_name (reverse @{$self -> table_names})
	{
		$self -> creator -> drop_table($table_name);

		$self -> logger -> debug("Dropped table '$table_name'");
	}

	$self -> logger -> info('Dropped all tables');
	$self -> logger -> info('-' x 50);

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of drop_all_tables.

# -----------------------------------------------

1;

=pod

=head1 NAME

CPAN::MetaPackager::Create - Manage the cpan.metapackager.sqlite database

=head1 Instructions

See POD in MetaPackager.pm.

=head1 Author

Ron Savage I<E<lt>ron@savage.net.auE<gt>>.

My homepage: L<https://savage.net.au/>.

=head1 License

Perl 5.

=head1 Copyright

Copyright (c) 2026, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
