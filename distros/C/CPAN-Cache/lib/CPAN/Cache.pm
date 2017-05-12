package CPAN::Cache;

=pod

=head1 NAME

CPAN::Cache - Abstract locally-cached logical subset of a CPAN mirror

=head1 DESCRIPTION

There have been any number of scripts and modules written that contain
as part of their functionality some form of locally stored partial
mirror of the CPAN dataset.

B<CPAN::Cache> does the same thing, except that in addition it has the
feature that the downloading and storage of CPAN data is B<all> that it
does, so it should not introduce any additional dependencies or bloat,
and should be much easier to reuse that existing modules, which generally
are more task-specific.

The intent is that this module will be usable by everything that is in the
business of pulling modules from CPAN, storing them locally, and doing
something with them.

In this way, it really does little other than mirror data from a remote
URI, except that B<CPAN::Cache> also provides some additional
intelligence about which files are and are not static (will never change)
which aren't, and is typed specifically as a mirror of CPAN, instead of
any other sort of mirror.

By building this module as a seperate distribution, it is hoped we can
improve seperation of concerns in the CPAN-related modules and ensure
cleaner, smaller, and more robust tools that interact with the CPAN
in the most correct ways.

=head1 METHODS

=cut

use 5.005;
use strict;
use Carp          ();
use File::Spec    ();
use File::Path    ();
use File::HomeDir ();
use URI::ToDisk   ();
use Params::Util  '_INSTANCE';
use LWP::Simple   ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $cache = CPAN::Cache->new(
      remote_uri => 'http://search.cpan.org/CPAN/',
      local_dir  => '/tmp/cpan',
      );

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply boolean flags cleanly
	$self->{verbose}  = !! $self->{verbose};
	$self->{readonly} = !! $self->{readonly};

	# More thorough checking for the 
	my $uri  = $self->{remote_uri}
	           || 'http://search.cpan.org/CPAN/';
	my $path = $self->{local_dir}
	           || File::Spec->catdir(
			File::HomeDir->my_data, '.perl', 'CPAN-Cache'
			);

	# Strip superfluous trailing slashes
	$path =~ s/\/+$//;
	$uri  =~ s/\/+$//;

	# Create the mirror_local path if needed
	-e $path or File::Path::mkpath($path);
	-d $path or Carp::croak("mirror_local: Path '$path' is not a directory");
	-w $path or Carp::croak("mirror_local: No write permissions to path '$path'");

	# Create the mirror object and save the updated values
	$self->{_mirror} = URI::ToDisk->new( $path => $uri )
		or Carp::croak("Unexpected error creating HTML::Location object");

	$self;
}

=pod

=head2 remote_uri

The C<remote_uri> accessor returns a L<URI> object for the remote CPAN
repository.

=cut

sub remote_uri {
	$_[0]->{_mirror}->URI;
}

=pod

=head2 local_dir

The C<local_dir> accessor returns the filesystem path for the root
root directory of the CPAN cache.

=cut

sub local_dir {
	$_[0]->{_mirror}->path;
}

# Undocumented until it is usable
sub trace {
	$_[0]->{trace};
}

# Undocumented until it is usable
sub verbose {
	$_[0]->{verbose};
}

# Undocumented until it is usable
sub readonly {
	$_[0]->{readonly};
}





#####################################################################
# Interface Methods

=pod

=head2 file path/to/file.txt

The C<file> method takes the path of a file within the
repository, and returns a L<URI::ToDisk> object representing
it's location on both the server, and on the local filesystem.

Paths should B<always> be provided in unix/web format, B<not> the
local filesystem's format.

Returns a L<HTML::ToDisk> or throws an exception if passed a
bad path.

=cut

sub file {
	my $self = shift;
	my $path = $self->_path(shift);

	# Split into parts and find the location for it.
	$self->{_mirror}->catfile( split /\//, $path );
}

=pod

=head2 get path/to/file.txt

The C<get> method takes the path of a file within the
repository, and fetches it from the remote repository, storing
it at the appropriate local path.

Paths should B<always> be provided in unix/web format, not the local
filesystem's format.

Returns the L<URI::ToDisk> for the file if retrieved successfully,
false false if the file does not exist within the repository, or throws
an exception on error.

=cut

sub get {
	my $self = shift;
	my $file = $self->file(shift);

	# Check local dir exists
	my $dir = File::Basename::dirname($file->path);
	-d $dir or File::Path::mkpath($dir);

	# Fetch the file from the server
	my $rc = LWP::Simple::getstore( $file->uri, $file->path );
	if ( LWP::Simple::is_success($rc) ) {
		return $file;
	} elsif ( $rc == LWP::Simple::RC_NOT_FOUND ) {
		return undef;
	} else {
		Carp::croak("$rc error retrieving " . $file->uri);
	}
}

=pod

=head2 mirror path/to/file.txt

The C<mirror> method takes the path of a file within the
repository, and mirrors it from the remote repository, storing
it at the appropriate local path.

Using this method if preferable for items like indexs for which
want to ensure you have the current version, but do not want to
freshly download each time.

Paths should B<always> be provided in unix/web format, not the local
filesystem's format.

Returns the L<URI::ToDisk> for the file if mirrored successfully,
false if the file did not exist in the repository, or throws an
exception on error.

=cut

sub mirror {
	my $self = shift;
	my $path = $self->_path(shift);
	my $file = $self->file($path);

	# If any only if a path is "stable" and the file already exists,
	# it is guarenteed not to change, and we don't have to do the
	# mirroring operation.
	if ( $self->_static($path) and -f $file->path ) {
		return $file;
	}

	# Check local dir exists
	my $dir = File::Basename::dirname($file->path);
	-d $dir or File::Path::mkpath($dir);

	# Fetch the file from the server
	my $rc = LWP::Simple::mirror( $file->uri => $file->path );
	if ( LWP::Simple::is_success($rc) ) {
		return $file;
	} elsif ( $rc == LWP::Simple::RC_NOT_MODIFIED ) {
		return $file;
	} elsif ( $rc == LWP::Simple::RC_NOT_FOUND ) {
		return '';
	} else {
		Carp::croak("HTTP $rc error mirroring " . $file->uri);
	}
}

=pod

=head2 static

The C<static> method determines whether a given path within CPAN is
able to change or not.

In the CPAN, some files such as index files and checksum can change,
while other files such as the tarball files will be static, and once
committed to the repository will never be changed (altough they may
be deleted).

In a caching scenario, this means that if the file exists locally, we
will never need to return to the server to check for a new version,
we enables additional optimisations for CPAN-related algorithms.

Returns true if the file will never change, false if not, or throws
an exception on error.

=cut

sub static {
	my $self = shift;
	my $path = $self->_path(shift);

	# All checksum files will change
	if ( $path =~ m~/CHECKSUMS$~ ) {
		return '';
	}

	# The .readme files can apparently be changed
	if ( $path =~ m~.readme$~ ) {
		return '';
	}

	# The authors directory is otherwise immutable
	if ( $path =~ m~^authors/~ ) {
		return 1;
	}

	# The safe option is to default to false for the rest
	return '';
}





#####################################################################
# Support Methods

# Validate a CPAN file path
sub _path {
	my $self = shift;
	my $path = shift or Carp::croak("No CPAN path provided");

	# Strip any leading slash
	$path =~ s(^\/)();

	$path;
}

1;

=pod

=head1 TO DO

- Write a proper test suite, not just a compile test
  (even though this was taken from working JSAN code)

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Cache>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<CPAN::Index>, L<CPAN::Mini>, L<DBIx::Class>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
