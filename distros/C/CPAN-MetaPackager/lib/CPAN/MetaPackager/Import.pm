package CPAN::MetaPackager::Import;

use 5.36.0;
use boolean;
use parent 'CPAN::MetaPackager::Database';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().
use DateTime::Tiny;

use File::Spec;
use File::Slurper 'read_lines';

use Moo;

use Types::Standard qw/Str/;

has packages_path =>
(
	default		=> sub{return '/tmp/02packages.details.txt'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

our $VERSION = '1.00';

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;
	$self -> logger -> info('Populating all tables');

	$self -> populate_packages_table;

	$self -> logger -> info('Populated all tables');
	$self -> logger -> info('-' x 50);

	# Return 0 for OK and 1 for error.

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_packages_table
{
	my($self)		= @_;
	my($path)		= File::Spec -> catfile($self -> home_path, $self -> packages_path);
	my($table_name)	= 'packages';

	$self -> get_table_column_names(true, $table_name); # Populates $self -> column_names.

	my($packages) = $self -> read_packages_file;

	my($author);
	my(%count);
	my($distro);
	my(@fields);
	my($package);
	my($record);
	my($version);

	$count{package}	= 0;
	$count{total}	= 0;

	for my $line (@$packages)
	{
		$count{total}++;

		next if ($count{total} <= 9);

		$count{package}++;

		($package, $version, $distro)	= split(/\s+/, $line);
		@fields							= split('/', $distro);
		$author							= $fields[2];

		$self -> insert_hashref
		(
			$table_name,
			{
				id		=> $count{package},
				author	=> $author,
				name	=> $package,
				version	=> $version,
			}
		);

		say "Stored $count{package} records into '$table_name'" if ($count{package} % 10000 == 0);
	}

	my($pad)			= $self -> pad; # For temporary use, during import.
	$$pad{$table_name}	= $self -> read_table($table_name);
	my($packages_count)	= $#{$$pad{$table_name} } + 1;

	$self -> logger -> info("Finished populate_packages_table(). Stored $count{package} records into table '$table_name'");

}	# End of populate_packages_table.

# --------------------------------------------------

sub read_packages_file
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($file_name)	= $self -> packages_path;
	my(@packages)	= read_lines($file_name, 'UTF-8');

	$self -> logger -> info("$file_name: record count: @{[$#packages + 1]}. Includes 9 header records");

	return \@packages;

} # End of read_packages_file.

# --------------------------------------------------

1;

=pod

=head1 NAME

CPAN::MetaPackager::Import - Manage the cpan.metapackager.sqlite database

=head1 Instructions

See POD in MetaPackager.pm.

==head1 Author

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
