package CPAN::Mini::Extract;

=pod

=head1 NAME

CPAN::Mini::Extract - Create CPAN::Mini mirrors with the archives extracted

=head1 SYNOPSIS

  # Create a CPAN extractor
  my $cpan = CPAN::Mini::Extract->new(
      remote         => 'http://mirrors.kernel.org/cpan/',
      local          => '/home/adam/.minicpan',
      trace          => 1,
      extract        => '/home/adam/.cpanextracted',
      extract_filter => sub { /\.pm$/ and ! /\b(inc|t)\b/ },
      extract_check  => 1,
  );
  
  # Run the minicpan process
  my $changes = $cpan->run;

=head1 DESCRIPTION

C<CPAN::Mini::Extract> provides a base for implementing systems that
download "all" of CPAN, extract the dists and then process the files
within.

It provides the same syncronisation functionality as L<CPAN::Mini> except
that it also maintains a parallel directory tree that contains a directory
located at an identical path to each archive file, with a controllable
subset of the files in the archive extracted below.

=head2 How does it work

C<CPAN::Mini::Extract> starts with a L<CPAN::Mini> local mirror, which it
will optionally update before each run. Once the L<CPAN::Mini> directory
is current, it will scan both directory trees, extracting any new archives
and removing any extracted archives no longer in the minicpan mirror.

=head1 EXTENDING

This class is relatively straight forward, but may evolve over time.

If you wish to write an extension, please stay in contact with the
maintainer while doing so.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp                         ();
use File::Basename               ();
use File::Path                   ();
use File::Spec              0.80 ();
use File::Remove            0.34 ();
use List::Util              1.15 ();
use File::HomeDir           0.88 ();
use File::Temp              0.21 ();
use URI                     1.37 ();
use URI::file                    ();
use IO::File                1.14 ();
use IO::Uncompress::Gunzip 2.017 ();
use Archive::Tar            1.22 ();
use Params::Util            1.00 ();
use LWP::Online             0.03 ();
use File::Find::Rule        0.30 ();
use CPAN::Mini          1.111004 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.23';
	@ISA     = 'CPAN::Mini';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> constructor is used to create and configure a new CPAN
Processor. It takes a set of named params something like the following.

  # Create a CPAN processor
  my $Object = CPAN::Mini::Extract->new(
      # The normal CPAN::Mini params
      remote         => 'ftp://cpan.pair.com/pub/CPAN/',
      local          => '/home/adam/.minicpan',
      trace          => 1,
      
      # Additional params
      extract        => '/home/adam/explosion',
      extract_filter => sub { /\.pm$/ and ! /\b(inc|t)\b/ },
      extract_check  => 1,
      );

=over

=item minicpan args

C<CPAN::Mini::Extract> inherits from L<CPAN::Mini>, so all of the arguments
that can be used with L<CPAN::Mini> will also work with
C<CPAN::Mini::Extract>.

Please note that C<CPAN::Mini::Extract> applies some additional defaults
beyond the normal ones, like turning C<skip_perl> on.

=item offline

Although useless with L<CPAN::Mini> itself, the C<offline> flag will
cause the CPAN synchronisation step to be skipped, and only any
extraction tasks to be done. (False by default)

=item extract

Provides the directory (which must exist and be writable, or be creatable)
that the tarball dists should be extracted to.

=item extract_filter

C<CPAN::Mini::Extract> allows you to specify a filter controlling which
types of files are extracted from the Archive. Please note that ONLY
normal files are ever considered for extraction from an archive, with
any directories needed created automatically.

Although by default C<CPAN::Mini::Extract> only extract files of type .pm,
.t and .pl from the archives, you can add a list of additional things you
do not want to be extracted.

The filter should be provided as a subroutine reference. This sub will
be called with $_ set to the path of the file. The subroutine should
return true if the file is to be extracted, or false if not.

  # Extract all .pm files, except those in an include directory
  extract_filter => sub { /\.pm$/ and ! /\binc\b/ },

=item extract_check

The main extraction process is done as each new archive is downloaded,
but occasionally in a process this long-running something may go wrong
and you can end up with archives not extracted.

In addition, sometimes the processing of the extracted archives is
destructive and will result in them being deleted each run.

Once the mirror update has been completed, the C<extract_check> keyword
forces the processor to go back over every tarball in the mirror and
double check that it has a corrosponding extracted directory.

=item extract_force

For cases in which the filter has been changed, the C<extract_flush>
boolean flag can be used to forcefully delete and re-extract every
extracted directory.

=back

Returns a new C<CPAN::Mini::Extract> object, or dies on error.

=cut

sub new {
	my $class = shift;

	# Use the CPAN::Mini settings as defaults, and add any
	# additional explicit params.
	my %config = ( CPAN::Mini->read_config, @_ );

	# Unless provided auto-detect offline mode
	unless ( defined $config{offline} ) {
		$config{offline} = LWP::Online::offline();
	}

	# Fake a remote URI if CPAN::Mini can't handle offline mode
	my %fake = ();
	if ( $config{offline} and $CPAN::Mini::VERSION < 0.570 ) {
		my $tempdir   = File::Temp::tempdir();
		my $tempuri   = URI::file->new( $tempdir )->as_string;
		$fake{remote} = $tempuri;
	}

	# Use a default local path if none provided
	unless ( defined $config{local} ) {
		my $local = File::Spec->catdir(
			File::HomeDir->my_data, 'minicpan',
		);
	}

	# Call our superclass to create the object
	my $self = $class->SUPER::new( %config, %fake );

	# Check the extract param
	$self->{extract} or Carp::croak(
		"Did not provide an 'extract' path"
		);
	if ( -e $self->{extract} ) {
		unless ( -d _ and -w _ ) {
			Carp::croak(
				"The 'extract' path is not a writable directory"
				);
		}
	} else {
		File::Path::mkpath( $self->{extract}, $self->{trace}, $self->{dirmode} )
			or Carp::croak("The 'extract' path could not be created");
	}

	# Set defaults and apply rules
	unless ( defined $self->{extract_check} ) {
		$self->{extract_check} = 1;
	}
	if ( $self->{extract_force} ) {
		$self->{extract_check} = 1;
	}

	# Compile file_filters if needed
	$self->_compile_filter('extract_filter');

	# We'll need a temp directory for expansions
	$self->{tempdir} = File::Temp::tempdir( CLEANUP => 1 );

	$self;
}





#####################################################################
# Main Methods

=pod

=head2 run

The C<run> methods starts the main process, updating the minicpan mirror
and extracted version, and then launching the PPI Processor to process the
files in the source directory.

Returns the number of changes made to the local minicpan and extracted
directories, or dies on error.

=cut

sub run {
	my $self = shift;

	# Prepare to start
	local $| = 1;
	my $changes;
	$self->{added}   = {};
	$self->{cleaned} = {};

	# If we want to force re-expansion,
	# remove all current expansion dirs.
	if ( $self->{extract_force} ) {
		$self->log("Flushing all expansion directories (extract_force enabled)\n");
		my $authors_dir = File::Spec->catfile( $self->{extract}, 'authors' );
		if ( -e $authors_dir ) {
			$self->log("Removing $authors_dir...");
			File::Remove::remove( \1, $authors_dir ) or Carp::croak(
				"Failed to remove previous expansion directory '$authors_dir'"
				);
			$self->log(" removed\n");
		}
	}

	# Update the CPAN::Mini local mirror
	if ( $self->{offline} and $CPAN::Mini::VERSION < 0.570 ) {
		$self->log("Skipping minicpan update (offline mode enabled)\n");
	} else {
		$self->log("Updating minicpan local mirror...\n");
		$self->update_mirror;
	}

	$changes ||= 0;
	if ( $self->{extract_check} or $self->{extract_force} ) {
		# Expansion checking is enabled, and we didn't do a normal
		# forced check, so find the full list of files to check.
		$self->log("Tarball expansion checking enabled\n");
		my @files = File::Find::Rule->new
					    ->name('*.tar.gz')
					    ->file
					    ->relative
					    ->in( $self->{local} );

		# Filter to just those we need to extract
		$self->log("Checking " . scalar(@files) . " tarballs\n");
		@files = grep { ! -d File::Spec->catfile( $self->{extract}, $_ ) } @files;
		if ( @files ) {
			$self->log("Scheduling " . scalar(@files) . " tarballs for expansion\n");
		} else {
			$self->log("No tarballs need to be extracted\n");
		}

		# Expand each of the tarballs
		foreach my $file ( sort @files ) {
			$self->mirror_extract( $file );
			$changes++;
		}
	}

	$self->log("Completed minicpan extraction\n");
	$changes;
}





#####################################################################
# CPAN::Mini Methods

# Track what we have added
sub mirror_file {
	my $self = shift;
	my $file = shift;

	# Do the normal stuff
	my $rv = $self->SUPER::mirror_file($file, @_);

	# Expand the tarball if needed
	unless ( -d File::Spec->catfile( $self->{extract}, $file ) ) {
		$self->{current_file} = $file;
		$self->mirror_extract( $file ) or return undef;
		delete $self->{current_file};
	}

	$self->{added}->{$file} = 1;
	delete $self->{current_file};
	$rv;
}

sub mirror_extract {
	my ($self, $file) = @_;

	# Don't try to extract anything other than normal tarballs for now.
	return 1 unless $file =~ /\.t(ar\.)?gz$/;

	# Extract the new file to the matching directory in
	# the processor source directory.
	my $local_file  = File::Spec->catfile( $self->{local}, $file   );
	my $extract_dir = File::Spec->catfile( $self->{extract}, $file );

	# Do the actual extraction
	$self->_extract_archive( $local_file, $extract_dir );
}

# Also remove any processing directory.
# And track what we have removed.
sub clean_file {
	my $self = shift;
	my $file = shift; # Absolute path

	# Convert to relative path, and clear the expansion directory
	my $relative = File::Spec->abs2rel( $file, $self->{local} );
	$self->clean_extract( $relative );

	# We are doing this in the reverse order to when we created it.
	my $rv = $self->SUPER::clean_file($file, @_);

	$self->{cleaned}->{$file} = 1;
	$rv;
}

# Remove a processing directory
sub clean_extract {
	my ($self, $file) = @_;

	# Remove the source directory, if it exists
	my $source_path = File::Spec->catfile( $self->{extract}, $file );
	if ( -e $source_path ) {
		File::Remove::remove( \1, $source_path ) or Carp::carp(
			"Cannot remove $source_path $!"
			);
	}

	1;
}





#####################################################################
# Support Methods and Error Handling

# Compile a set of filters
sub _compile_filter {
	my $self = shift;
	my $name = shift;

	# Shortcut for "no filters"
	return 1 unless $self->{$name};

	# If the filter is already a code ref, shortcut
	return 1 if Params::Util::_CODELIKE($self->{$name});

	# Allow a single Regexp object for the filter
	if ( Params::Util::_INSTANCE($self->{$name}, 'Regexp') ) {
		$self->{$name} = [ $self->{$name} ];
	}

	# Check for bad cases
	Params::Util::_ARRAY0($self->{$name}) or Carp::croak(
		"$name is not an ARRAY reference"
		);
	unless ( @{$self->{$name}} ) {
		delete $self->{$name};
		return 1;
	}

	# Check we only got Regexp objects
	my @filters = @{$self->{$name}};
	if ( scalar grep { ! Params::Util::_INSTANCE($_, 'Regexp') } @filters ) {
		return $self->_error("$name can only contains Regexp filters");
	}

	# Build the anonymous sub
	$self->{$name} = sub {
		foreach my $regexp ( @filters ) {
			return 1 if $_ =~ $regexp;
		}
		return '';
	};

	1;
}

# Encapsulate the actual extraction mechanism
sub _extract_archive {
	my ($self, $gz, $to) = @_;

	# Do a one-shot separate decompression because for some reason
	# the default on-the-fly decompression is horridly memory
	# innefficientm, allocating and freeing massive blocks of memory
	# for every single block that gets read in.
	my $archive = $self->_extract_gz( $gz );

	# IO::Zlib::tell will cause problems and Archive::Tar
	# tries to use it by default, so invoke it with a
	# file handle to MAKE it do the right thing.
	my $io = IO::File->new( $archive, "r" )
		or die "Failed to open $archive";

	# Some hints to Archive::Tar to make it behave to make it
	# work better on Win32, and to ignore the ownership crap
	# that we don't care about.
	local $Archive::Tar::WARN  = 0;
	local $Archive::Tar::CHOWN = 0;
	local $Archive::Tar::CHMOD = 0;

	# Load the archive
	my $tar = eval {
		Archive::Tar->new( $io );
	};
	if ( $@ or ! $tar ) {
		return $self->_tar_error("Loading of $archive failed");
	}

	# Get the complete list of files
	my @files = eval {
		$tar->list_files( [ 'name', 'size' ] )
	};
	return $self->_tar_error("Loading of $archive failed") if $@;

	# Filter to get just the ones we want
	@files = map { $_->{name} } grep { $_->{size} } @files;
	if ( $self->{extract_filter} ) {
		@files = grep &{$self->{extract_filter}}, @files;
	}

	# Iterate and extract each file
	File::Path::mkpath( $to, $self->{trace}, $self->{dirmode} );
	foreach my $wanted ( sort @files ) {
		# Where to extract to
		my $to_file = File::Spec->catfile( $to, $wanted );
		my $to_dir  = File::Basename::dirname( $to_file );
		File::Path::mkpath( $to_dir, $self->{trace}, $self->{dirmode} );
		$self->log("write $to_file\n");

		my $rv;
		SCOPE: {
			$rv = eval {
				$tar->extract_file( $wanted, $to_file );
			};
		}
		if ( $@ or ! $rv ) {
			# There was an error during the extraction
			$self->_tar_error( " ... failed" );
			if ( -e $to_file ) {
				# Remove any partial file left behind
				File::Remove::remove( $to_file );
			}
			return 1;
		}
	}

	# Clean up
	$tar->clear;
	undef $tar;
	$io->close;
	File::Remove::remove( $archive );

	return 1;
}

# Extract a gz-compressed file to a temp file
my $counter = 0;
sub _extract_gz {
	my $self = shift;
	my $gz   = shift;
	my $tar  = ++$counter . '.tar';
	my $file = File::Spec->catfile(
		$self->{tempdir}, $tar,
	);
	IO::Uncompress::Gunzip::gunzip( $gz => $file )
		or die "Failed to uncompress $gz";
	return $file;
}

sub _tar_error {
	my $self = shift;

	# Get and clean up the message
	my $message = shift;
	if ( ! $message and $self->{current_file} ) {
		$message = "Expansion of $self->{current_file} failed";
	}
	if ( ! $message ) {
		$message = "Expansion of file failed";
	}
	$message .= " (Archive::Tar warning)" if $@ =~ /Archive::Tar warning/;
	$message .= "\n";

	$self->log($message);
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Mini-Extract>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<CPAN::Mini>

=head1 COPYRIGHT

Funding provided by The Perl Foundation.

Copyright 2005 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
