package CPAN::Index::Loader;

=pod

=head1 NAME

CPAN::Index::Loader - Populates the CPAN index SQLite database

=head1 DESCRIPTION

This package implements all the functionality required to download
the CPAN index data, parse it, and populate the SQLite database
file.

Because it involves loading a number of otherwise unneeded modules,
this package is B<not> loaded by default with the rest of
L<CPAN::Index>, but may be loaded on-demand if needed.

=head1 METHODS

=cut

use strict;
use Carp           ();
use IO::File       ();
use IO::Zlib       ();
use Params::Util   qw{ _INSTANCE _HANDLE };
use Email::Address ();
use CPAN::Cache    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $loader = CPAN::Index::Loader->new(
      remote_uri => 'http://search.cpan.org/CPAN',
      local_dir  => '/tmp/cpanindex',
      );

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Create the cache object
	unless ( $self->cache ) {
		my @params = ();
		$self->{cache} = CPAN::Cache->new(
			remote_uri => delete($self->{remote_uri}),
			local_dir  => delete($self->{local_dir}),
			trace      => $self->{trace},
			verbose    => $self->{verbose},
			);
	}

	$self;
}

=pod

=head2 cache

The C<cache> accessor returns a L<CPAN::Cache> object that represents the
CPAN cache.

=cut

sub cache {
	$_[0]->{cache};
}

=pod

=head2 remote_uri

The C<remote_uri> accessor return a L<URI> object for the location of the
CPAN mirror.

=cut

sub remote_uri {
	$_[0]->cache->remote_uri;
}

=pod

=head2 local_dir

The C<local_dir> accessor returns the filesystem path for the root directory
of the local CPAN file cache.

=cut

sub local_dir {
	$_[0]->cache->local_dir;
}

=pod

=head2 local_file

  my $path = $loader->local_file('01mailrc.txt.gz');

The C<local_file> method takes the name of a file in the CPAN and returns
the local path to the file.

Returns a path string, or throws an exception on error.

=cut

sub local_file {
	$_[0]->cache->file($_[1])->path;
}

=pod

=head2 local_handle

  my $path = $loader->local_handle('01mailrc.txt.gz');

The C<local_handle> method takes the name of a file in the CPAN and returns
an L<IO::Handle> to the file.

Returns an L<IO::Handle>, most likely an L<IO::Handle>, or throws an
exception on error.

=cut

sub local_handle {
	my $self = shift;
	my $file = $self->local_file(shift);
	$file =~ /\.gz$/
		? IO::Zlib->new( $file, 'rb' ) # [r]ead [b]inary file
		: IO::File->new( $file );
}





#####################################################################
# Main Methods

=pod

=head2 load_index

The C<load_index> takes a single param of the schema to load, locates
the three main index files based on the C<local_dir> path, and then
loads the index from those files.

Returns the total number of records added.

=cut

sub load_index {
	my $self    = shift;
	my $schema  = shift;
	my $created = 0;

	# Load the files
	$created += $self->load_authors(
		$schema,
		$self->local_handle('authors/01mailrc.txt') ||
		$self->local_handle('authors/01mailrc.txt.gz'),
		);
	$created += $self->load_packages(
		$schema,
		$self->local_handle('modules/02packages.details.txt') ||
		$self->local_handle('modules/02packages.details.txt.gz'),
		);

	# Return the total
	$created;
}





#####################################################################
# Parsing Methods

=pod

=head2 load_authors

  CPAN::Index::Loader->load_authors( $schema, $handle );

The C<load_authors> method populates the C<package> table from the CPAN
F<01mailrc.txt.gz> file.

The C<author> table in the SQLite database should already be empty
B<before> this method is called.

Returns the number of authors added to the database, or throws an
exception on error.

=cut

sub load_authors {
	my $self   = shift;
	my $schema = _INSTANCE(shift, 'DBIx::Class::Schema')
		or Carp::croak("Did not provide a DBIx::Class::Schema param");
	my $handle = _HANDLE(shift)
		or Carp::croak("Did not provide a file handle param");

	# Wrap the actual method in a DBIx::Class transaction
	my $created = 0;
	
	my $rs = eval {
		$schema->txn_do( sub {
			$created = $self->_load_authors( $schema, $handle );
		} );
	};
	if ( $@ =~ /Rollback failed/ ) {
		Carp::croak("Rollback failed, database may be corrupt");
	} elsif ( $@ ) {
		Carp::croak("Database error while loading authors: $@");
	}

	$created;	
}
	
sub _load_authors {
	my ($self, $schema, $handle) = @_;

	# Every email address should be different, so disable
	# Email::Address caching so we don't waste a bunch of memory.
	local $Email::Address::NOCACHE = 1;

	# Process the author records
	my $created = 0;
	while ( my $line = $handle->getline ) {
		# Parse the line
		unless ( $line =~ /^alias\s+(\S+)\s+\"(.+)\"[\012\015]+$/ ) {
			Carp::croak("Invalid 01mailrc.txt.gz line '$line'");
		}
		my $id    = $1;
		my $email = $2;

		# Parse the full email address to seperate the parts
		my @found = Email::Address->parse($email);
		unless ( @found ) {
			# Invalid email or something that Email::Address can't handle.
			# Use a default name and address for now.
			@found = Email::Address->parse( "$id <$id\@cpan.org>" );
		}

		# Some CPAN users have multiple addresses, for example
		# A. PREM ANAND <prem_and@rediffmail.com,prem@ncbs.res.in>
		# When this happens, we'll just take the first one.

		# Create the record
		$schema->resultset('Author')->create( {
			id    => $id,
			name  => $found[0]->name,
			email => $found[0]->address,
			} );
		$created++;

		# Debugging
		#if ( $Test::More::VERSION ) {
		#	Test::More::diag("$created...");
		#}
	}

	$created;
}

=pod

=head2 load_packages

  CPAN::Index::Loader->load_packages( $schema, $handle );

The C<load_packages> method populates the C<package> table from the CPAN
F<02packages.details.txt.gz> file.

The C<package> table in the SQLite database should already be empty
B<before> this method is called.

Returns the number of packages added to the database, or throws an
exception on error.

=cut

sub load_packages {
	my $self   = shift;
	my $schema = _INSTANCE(shift, 'DBIx::Class::Schema')
		or Carp::croak("Did not provide a DBIx::Class::Schema param");
	my $handle = _HANDLE(shift)
		or Carp::croak("Did not provide a file handle param");

	# Advance past the header, to the first blank line
	while ( my $line = $handle->getline ) {
		last if $line !~ /[^\s\012\015]/;
	}

	# Wrap the database method in a DBIx::Class transaction
	my $created;
	my $rs = eval {
		$schema->txn_do( sub {
			$created = $self->_load_packages( $schema, $handle );
		} );
	};
	if ( $@ =~ /Rollback failed/ ) {
		Carp::croak("Rollback failed, database may be corrupt");
	} elsif ( $@ ) {
		Carp::croak("Database error while loading packages: $@");
	}

	$created;
}

sub _load_packages {
	my ($self, $schema, $handle) = @_;

	# Process the author records
	my $created = 0;
	while ( my $line = $handle->getline ) {
		unless ( $line =~ /^(\S+)\s+(\S+)\s+(.+?)[\012\015]+$/ ) {
			Carp::croak("Invalid 02packages.details.txt.gz line '$line'");
		}
		my $name    = $1;
		my $version = $2 eq 'undef' ? undef : $2;
		my $path    = $3;

		# Create the record
		$schema->resultset('Package')->create( {
			name    => $name,
			version => $version,
			path    => $path,
			} );
		$created++;

		# Debugging
		#if ( $Test::More::VERSION ) {
		#	Test::More::diag("$created...");
		#}
	}

	$created;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Index>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>cpan@ali.asE<gt>

Parts based on various modules by Leon Brocard E<lt>acme@cpan.orgE<gt>

=head1 SEE ALSO

Related: L<CPAN::Index>, L<CPAN>

Based on: L<Parse::CPAN::Authors>, L<Parse::CPAN::Packages>

=head1 COPYRIGHT

Copyright (c) 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
