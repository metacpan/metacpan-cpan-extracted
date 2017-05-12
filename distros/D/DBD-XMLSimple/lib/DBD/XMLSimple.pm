package DBD::XMLSimple;

use warnings;
use strict;

=head1 NAME

DBD::XMLSimple - Access XML data via the DBI interface

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

Reads XML and makes it available via DBI.

    use FindBin qw($Bin);
    use DBI;

    my $dbh = DBI->connect('dbi:XMLSimple(RaiseError => 1):');

    # To be replaced with xmls_import once the driver has been registered
    $dbh->func('person', 'XML', "$Bin/../data/person.xml", 'x_import');

    my $sth = $dbh->prepare("SELECT * FROM person");

Input data will be something like this:

    <?xml version="1.0" encoding="US-ASCII"?>
    <table>
	<row id="1">
	    <name>Nigel Horne</name>
	    <email>njh@bandsman.co.uk</email>
	</row>
	<row id="2">
	    <name>A N Other</name>
	    <email>nobody@example.com</email>
	</row>
    </table>
=cut

=head1 SUBROUTINES/METHODS

=head2 driver

No routines in this module should be called directly by the application.

=cut

use base qw(DBI::DBD::SqlEngine);

use vars qw($VERSION $drh $methods_already_installed);

our $VERSION = '0.05';
our $drh = undef;

sub driver
{
	return $drh if $drh;

	my($class, $attr) = @_;

	# $class .= '::dr';
	# $drh = DBI::_new_drh($class, {
	# $drh = DBI::_new_drh("$class::dr", {
	$drh = $class->SUPER::driver({
		'Name' => 'XML',
		'Version' => $VERSION,
		'Attribution' => 'DBD::XMLSimple by Nigel Horne',
	});

	if($drh) {
		unless($methods_already_installed++) {
			DBI->setup_driver(__PACKAGE__);
			DBD::XMLSimple::db->install_method('x_import');
		}
	}

	return $drh;
}

sub CLONE
{
	undef $drh;
}

package DBD::XMLSimple::dr;

use vars qw($imp_data_size);

sub disconnect_all
{
	shift->{tables} = {};
}

sub DESTROY
{
	shift->{tables} = {};
}

package DBD::XMLSimple::db;

use vars qw($imp_data_size);

$DBD::XMLSimple::db::imp_data_size = 0;
@DBD::XMLSimple::db::ISA = qw(DBI::DBD::SqlEngine::db);

sub x_import
{
	my($dbh, $table_name, $format, $file_name, $flags) = @_;

	die if($format ne 'XML');

	$dbh->{filename} = $file_name;
}

package DBD::XMLSimple::st;

use strict;
use warnings;

use vars qw($imp_data_size);

$DBD::XMLSimple::st::imp_data_size = 0;
@DBD::XMLSimple::st::ISA = qw(DBI::DBD::SqlEngine::st);

package DBD::XMLSimple::Statement;

use strict;
use warnings;
use XML::Twig;
use Carp;

@DBD::XMLSimple::Statement::ISA = qw(DBI::DBD::SqlEngine::Statement);

sub open_table($$$$$)
{
	my($self, $data, $tname, $createMode, $lockMode) = @_;
	my $dbh = $data->{Database};

	my $twig = XML::Twig->new();
	my $source = $dbh->{filename};
	if(ref($source) eq 'ARRAY') {
		$twig->parse(join('', @{$source}));
	} else {
		$twig->parsefile($source);
	}

	my $root = $twig->root;
	my %table;
	my $rows = 0;
	my %col_nums;
	my @col_names;
	foreach my $record($root->children()) {
		my %row;
		my $index = 0;
		foreach my $leaf($record->children) {
			my $key = $leaf->name();
			$row{$key} = $leaf->field();
			if(!exists($col_nums{$key})) {
				$col_nums{$key} = $index++;
				push @col_names, $key;
			}
		}
		$table{data}->{$record->att('id')} = \%row;
		$rows++;
	}

	carp "No data found to import" if($rows == 0);
	carp "Can't determine column names" if(scalar(@col_names) == 0);

	$data->{'rows'} = $rows;

	$table{'table_name'} = $tname;
	$table{'col_names'} = \@col_names;
	$table{'col_nums'} = \%col_nums;

	return DBD::XMLSimple::Table->new($data, \%table);
}

package DBD::XMLSimple::Table;

use strict;
use warnings;

@DBD::XMLSimple::Table::ISA = qw(DBI::DBD::SqlEngine::Table);

sub new
{
	my($class, $data, $attr, $flags) = @_;

	$attr->{table} = $data;
	$attr->{readonly} = 1;
	$attr->{cursor} = 0;

	my $rc = $class->SUPER::new($data, $attr, $flags);

	$rc->{col_names} = $attr->{col_names};
	$rc->{col_nums} = $attr->{col_nums};
	return $rc;
}

sub fetch_row($$)
{
	my($self, $data) = @_;

	if($self->{cursor} >= $data->{rows}) {
		return;
	}
	$self->{cursor}++;

	my @fields;
	foreach my $col(@{$self->{'col_names'}}) {
		push @fields, $self->{'data'}->{$self->{'cursor'}}->{$col};
	}
	$self->{row} = \@fields;

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

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Change x_import to xmls_import once it's been registered

=head1 SEE ALSO

L<DBD::AnyData>, which was also used as a template for this module.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBD::XMLSimple

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBD-XMLSimple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBD-XMLSimple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBD-XMLSimple>

=item * Search CPAN

L<http://search.cpan.org/dist/DBD-XMLSimple/>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2016 Nigel Horne.

This program is released under the following licence: GPL

=cut

1; # End of DBD::XMLSimple
