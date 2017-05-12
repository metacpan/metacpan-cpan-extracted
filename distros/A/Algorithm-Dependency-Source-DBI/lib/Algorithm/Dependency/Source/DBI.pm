package Algorithm::Dependency::Source::DBI;

=pod

=head1 NAME

Algorithm::Dependency::Source::DBI - Database source for Algorithm::Dependency

=head1 SYNOPSIS

  use DBI;
  use Algorithm::Dependency;
  use Algorithm::Dependency::Source::DBI;
  
  # Load the data from a database
  my $data_source = Algorithm::Dependency::Source::DBI->new(
      dbh            => DBI->connect('dbi:SQLite:sqlite.db'),
      select_ids     => 'select name from stuff',
      select_depends => 'select from, to from m2m_deps',
  );
  
  # Create the dependency object, and indicate the items that are already
  # selected/installed/etc in the database
  my $dep = Algorithm::Dependency->new(
      source   => $data_source,
      selected => [ 'This', 'That' ]
  ) or die 'Failed to set up dependency algorithm';
  
  # For the item 'Foo', find out the other things we also have to select.
  # This WON'T include the item we selected, 'Foo'.
  my $also = $dep->depends( 'Foo' );
  print $also
  	? "By selecting 'Foo', you are also selecting the following items: "
  		. join( ', ', @$also )
  	: "Nothing else to select for 'Foo'";
  
  # Find out the order we need to act on the items in.
  # This WILL include the item we selected, 'Foo'.
  my $schedule = $dep->schedule( 'Foo' );

=head1 DESCRIPTION

The L<Algorithm::Dependency> module has shown itself to be quite reliable
over a long period of time, as well as relatively easy to setup and use.

However, recently there has been an increasing use of things like
L<DBD::SQLite> to store and distribute structured data.

L<Algorithm::Dependency::Source::DBI> extends L<Algorithm::Dependency>
by providing a simple way to create dependency objects that pull their
data from a database directly.

=head1 METHODS

=cut

use 5.005;
use strict;
use Params::Util qw{  _STRING _ARRAY _INSTANCE };
use Algorithm::Dependency::Item   ();
use Algorithm::Dependency::Source ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.06';
	@ISA     = 'Algorithm::Dependency::Source';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $simple = Algorithm::Dependency::Source::DBI->new(
      dbh            => $dbi_db_handle,
      select_ids     => 'select name from stuff',
      select_depends => 'select from, to from m2m_deps',
  );
  
  my $complex = Algorithm::Dependency::Source::DBI->new(
      dbh            => $dbi_db_handle,
      select_ids     => [ 'select name from stuff where foo = ?',         'bar' ],
      select_depends => [ 'select from, to from m2m_deps where from = ?', 'bar' ],
  );

The C<new> constructor takes three named named params.

The C<dbh> param should be a standard L<DBI> database connection.

The C<select_ids> param is either a complete SQL string, or a reference to
an C<ARRAY> containing a SQL string with placeholders and matching
variables.

When executed on the database, it should return a single column containing
the complete set of all item identifiers.

The C<select_depends> param is either a complete SQL string, or a reference
to an C<ARRAY> containing a SQL string with placeholders and matching
variables.

When executed on the database, it should return two columns containing
the complete set of all dependencies, where identifiers in the first-column
depends on identifiers in the second-column.

Returns a new L<Algorithm::Dependency::Source::DBI> object, or dies on
error.

=cut

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Apply defaults
	if ( _STRING($self->{select_ids}) ) {
		$self->{select_ids} = [ $self->{select_ids} ];
	}
	if ( _STRING($self->{select_depends}) ) {
		$self->{select_depends} = [ $self->{select_depends} ];
	}

	# Check params
	unless ( _INSTANCE($self->dbh, 'DBI::db') ) {
		Carp::croak("The dbh param is not a DBI database handle");
	}
	unless ( _ARRAY($self->select_ids) and _STRING($self->select_ids->[0]) ) {
		Carp::croak("Missing or invalid select_ids param");
	}
	unless ( _ARRAY($self->select_depends) and _STRING($self->select_depends->[0]) ) {
		Carp::croak("Did not provide the select_depends query");
	}

	return $self;
}

=pod

=head2 dbh

The C<dbh> accessor returns the database handle provided to the constructor.

=cut

sub dbh {
	$_[0]->{dbh};
}

=pod

=head2 select_ids

The C<select_ids> accessor returns the SQL statement provided to the
constructor. If a raw string was provided, it will be returned as a
reference to an C<ARRAY> containing the SQL string and no params.

=cut

sub select_ids {
	$_[0]->{select_ids};
}

=pod

=head2 select_depends

The C<select_depends> accessor returns the SQL statement provided to
the constructor. If a raw string was provided, it will be returned as
a reference to an C<ARRAY> containing the SQL string and no params.

=cut

sub select_depends {
	$_[0]->{select_depends};
}





#####################################################################
# Main Functionality

sub _load_item_list {
	my $self = shift;

	# Get the list of ids
	my $ids  = $self->dbh->selectcol_arrayref(
		$self->select_ids->[0],
		{}, # No options
		@{$self->select_ids}[1..-1],
		);
	my %hash = map { $_ => [ ] } @$ids;

	# Get the list of links
	my $depends = $self->dbh->selectall_arrayref(
		$self->select_depends->[0],
		{}, # No options
		@{$self->select_depends}[1..-1],
		);
	foreach my $depend ( @$depends ) {
		next unless $hash{$depend->[0]};
		next unless $hash{$depend->[1]};
		push @{$hash{$depend->[0]}}, $depend->[1];
	}

	# Now convert to items
	my @items = map {
		Algorithm::Dependency::Item->new( $_, @{$hash{$_}} )
		or return undef;
		} keys %hash;

	\@items;
}

1;

=pod

=head1 SUPPORT

To file a bug against this module, use the CPAN bug tracking system

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Dependency-Source-DBI>

For other comments, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Algorithm::Dependency>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
