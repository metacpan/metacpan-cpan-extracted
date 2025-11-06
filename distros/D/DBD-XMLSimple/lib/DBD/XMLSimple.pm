package DBD::XMLSimple;

use warnings;
use strict;

=head1 NAME

DBD::XMLSimple - Access XML data via the DBI interface

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

Reads XML and makes it available via DBI.

Sadly, DBD::AnyData doesn't work with the latest DBI,
and DBD::AnyData2 isn't out yet, so I am writing this pending the publication of DBD::AnyData2.

DBD-XMLSimple doesn't yet expect to support complex XML data, so that's why
it's not called DBD-XML.

The XML file needs to have a <table> containing the entry/entries.

    use FindBin qw($Bin);
    use DBI;

    my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');

    $dbh->func('person', 'XML', "$Bin/../data/person.xml", 'xmlsimple_import');

    my $sth = $dbh->prepare('SELECT * FROM person');

Input data will be something like this:

    <?xml version="1.0" encoding="US-ASCII"?>
    <table>
	<row id="1">
	    <name>Nigel Horne</name>
	    <email>njh@nigelhorne.com</email>
	</row>
	<row id="2">
	    <name>A N Other</name>
	    <email>nobody@example.com</email>
	</row>
    </table>

If a leaf appears twice,
it will be concatenated.

    <?xml version="1.0" encoding="US-ASCII"?>
    <table>
	<row id="1">
	    <name>Nigel Horne</name>
	    <email>njh@nigelhorne.com</email>
	    <email>nhorne@pause.org</email>
	</row>
    </table>

    $sth = $dbh->prepare('Select email FROM person');
    $sth->execute();
    $sth->dump_results();

    Gives the output "njh@nigelhorne.com,nhorne@pause.org"
=cut

=head1 SUBROUTINES/METHODS

=head2 driver

No routines in this module should be called directly by the application.

=cut

use base qw(DBI::DBD::SqlEngine);

use vars qw($VERSION $drh $methods_already_installed);

our $VERSION = '0.08';
our $drh = undef;
our $methods_already_installed = 0;

sub driver
{
	return $drh if $drh;

	# my($class, $attr) = @_;
	my $class = $_[0];

	# $class .= '::dr';
	# $drh = DBI::_new_drh($class, {
	# $drh = DBI::_new_drh("$class::dr", {
	$drh = $class->SUPER::driver({
		'Name' => 'XMLSimple',
		'Version' => $VERSION,
		'Attribution' => 'DBD::XMLSimple by Nigel Horne',
	});

	if($drh) {
		$class .= '::db';
		# DBI->setup_driver($class);
		$class->install_method('xmlsimple_import') unless $drh->{methods_installed}++;
	}

	return $drh;
}

sub CLONE
{
	undef $drh;
}

package DBD::XMLSimple::dr;

use vars qw($imp_data_size);

$imp_data_size = 0;

sub disconnect_all
{
	shift->{tables} = {};
}

sub DESTROY
{
	shift->{tables} = {};
}

# Database handle
package DBD::XMLSimple::db;

use base qw(DBI::DBD::SqlEngine::db);

use vars qw($imp_data_size);

$DBD::XMLSimple::db::imp_data_size = 0;

sub xmlsimple_import
{
	# my($dbh, $table_name, $format, $filename, $flags) = @_;
	my($dbh, $table_name, $format, $filename) = @_;

	die if($format ne 'XML');

	# $dbh->{tables} ||= {};
	$dbh->{tables}{$table_name} = { filename => $filename, rows => [], col_names => [] };
}

package DBD::XMLSimple::st;

use strict;
use warnings;

use base qw(DBI::DBD::SqlEngine::st);

use vars qw($imp_data_size);

$DBD::XMLSimple::st::imp_data_size = 0;

# Statement handle
package DBD::XMLSimple::Statement;
use base qw(DBI::DBD::SqlEngine::Statement);

use strict;
use warnings;
use XML::Twig;
use Carp;

sub open_table($$$$$)
{
	my ($self, $data, $tname) = @_;
	my $dbh = $data->{Database};

	# Determine the table name
	$tname ||= (keys %{$dbh->{tables}})[0];	# fallback to first registered table
	my $table_info = $dbh->{tables}{$tname}
		or croak "No XML file registered for table '$tname'";

	my $source = $table_info->{filename};

	my $twig = XML::Twig->new();

	if(ref($source) eq 'ARRAY') {
		$twig->parse(join('', @{$source}));
	} else {
		$twig->parsefile($source);
	}

	my $root = $twig->root;
	my @records = $root->children();

	carp 'No rows found under <table>' if !@records;

	my @rows;
	my %colnames_seen;

	# First pass — discover columns across all rows
	for my $record (@records) {
		for my $leaf ($record->children) {
			$colnames_seen{$leaf->name()}++;
		}
		# Also include 'id'
		if (defined(my $id = $record->att('id'))) {
			$colnames_seen{id}++;
		}
	}

	my @col_names = sort keys %colnames_seen;
	if (!@col_names) {
		carp "Empty table, creating dummy column '_dummy'";
		@col_names = ('_dummy');
	}
	my %col_nums = map { $col_names[$_] => $_ } 0..$#col_names;

	# Second pass — save row values
	for my $record (@records) {
		my %row;

		# Include id if present
		if (defined(my $id = $record->att('id'))) {
			$row{id} = $id;
		}

		for my $leaf ($record->children) {
			my $key = $leaf->name;
			if (defined $row{$key}) {
				$row{$key} .= ',' . $leaf->field();
			} else {
				$row{$key} = $leaf->field();
			}
		}

		# Now produce array in canonical column order
		push @rows, [ map { $row{$_} } @col_names ];
	}

	$data->{rows} = \@rows;

	# Store table metadata
	$data->{col_names} = \@col_names;
	$data->{col_nums}  = \%col_nums;
	$data->{row_count} = scalar @rows;

	return DBD::XMLSimple::Table->new($data, $data);
}

# Table handle
package DBD::XMLSimple::Table;
use base qw(DBI::DBD::SqlEngine::Table);

use strict;
use warnings;

sub new
{
	my($class, $data, $attr, $flags) = @_;

	$attr->{table} = $data;
	$attr->{readonly} = 1;
	$attr->{cursor} = 0;

	$attr->{rows} = $data->{rows};
	$attr->{col_nums} = $data->{col_nums};

	my $rc = $class->SUPER::new($data, $attr, $flags);

	$rc->{col_names} = $attr->{col_names};

	return $rc;
}

sub fetch_row($$)
{
	my($self, $data) = @_;

	if($self->{'cursor'} >= $data->{'row_count'}) {
		return undef;
	}

	$self->{row} = $self->{rows}[ $self->{cursor}++ ];
	return $self->{row};
}

sub seek($$$$)
{
	my($self, $data, $pos, $whence) = @_;

	print "seek $pos $whence, not yet implemented\n";
}

sub complete_table_name($$$$)
{
	my($self, $meta, $file, $respect_case, $file_is_table) = @_;
}

sub open_data
{
	# my($className, $meta, $attrs, $flags) = @_;
}

sub bootstrap_table_meta
{
	my($class, $dbh, $meta, $table, @other) = @_;

	$class->SUPER::bootstrap_table_meta($dbh, $meta, $table, @other);

	$meta->{table} = $table;

	$meta->{sql_data_source} ||= __PACKAGE__;
}

sub get_table_meta($$$$;$)
{
	my($class, $dbh, $table, $file_is_table, $respect_case) = @_;

	my $meta = $class->SUPER::get_table_meta($dbh, $table, $respect_case, $file_is_table);

	$table = $meta->{table};

	return unless $table;

	return($table, $meta);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * Test coverage report: L<https://nigelhorne.github.io/DBD-XMLSimple/coverage/>

=item * L<DBD::AnyData>, which was also used as a template for this module.

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/DBD-XMLSimple>

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc DBD::XMLSimple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBD-XMLSimple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBD-XMLSimple>

=item * Search CPAN

L<http://search.cpan.org/dist/DBD-XMLSimple/>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2016-2025 Nigel Horne.

This program is released under the following licence: GPL

=cut

1; # End of DBD::XMLSimple
