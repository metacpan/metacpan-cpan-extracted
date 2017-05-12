package CPAN::Mini::Visit;

=pod

=head1 NAME

CPAN::Mini::Visit - A generalised API version of David Golden's visitcpan

=head1 SYNOPSIS

  CPAN::Mini::Visit->new(
      minicpan => '/minicpan',
      acme     => 0,
      author   => 'ADAMK',
      warnings => 1,
      random   => 1,
      callback => sub {
          print "# counter: $_[0]->{counter}\n";
          print "# archive: $_[0]->{archive}\n";
          print "# tempdir: $_[0]->{tempdir}\n";
          print "# dist:    $_[0]->{dist}\n";
          print "# author:  $_[0]->{author}\n";
      }
  )->run;
  
  # counter: 1234
  # archive: /minicpan/authors/id/A/AD/ADAMK/Config-Tiny-1.00.tar.gz
  # tempdir: /tmp/1a4YRmFAJ3/Config-Tiny-1.00
  # dist:    ADAMK/Config-Tiny-1.00.tar.gz
  # author:  ADAMK

=head1 DESCRIPTION

L<CPAN::Mini::Extract> has been relatively successful at allowing processes
to run across the contents (or a subset of the contents) of an entire
L<minicpan> checkout.

However it has become evident that while it is useful (and theoretically
optimal from a processing point of view) to maintain an expanded minicpan
checkout the sheer size of an expanded minicpan is such that it becomes
an undo burdon to manage, move, copy or even delete a directory tree with
hundreds of thousands of file totalling in the high single gigabytes in size.

Annoyed by this, David Golden created L<visitcpan> which takes an alternative
approach of sequentially expanding the tarball of each distribution into a
temporary directory, do the processing on that distribution, and then delete
the temporary directory before moving on to the next directory.

This method results in a longer computation time, but with the benefit of
dramatically reduced system overhead, greater adaptability, and allow for
easy ad-hoc computations.

This improvement in flexibility turns out to be worth the extra computation
time in almost all cases.

B<CPAN::Mini::Visit> is a simplified and generalised API-based version of 
David Golden's L<visitcpan> script.

It implements only the process of discovering, iterating and expanding
archives, before handing off control to an arbitrary callback function
provided to the constructor.

=cut

use 5.008;
use strict;
use warnings;
use Carp                   ();
use File::Spec        0.80 ();
use File::Temp        0.21 ();
use File::pushd       1.00 ();
use File::chmod       0.31 ();
use File::Find::Rule  0.27 ();
use Archive::Extract  0.32 ();
use CPAN::Mini       0.576 ();
use Params::Util      1.00 ();

our $VERSION = '1.15';
# $VERSION = eval $VERSION;

use Object::Tiny 1.06 qw{
	minicpan
	authors
	callback
	acme
	author
	ignore
	random
	warnings
	prefer_bin
};

=pod

=head2 new

Takes a variety of parameters and creates a new visitor object.

The C<minicpan> param should be the root directory of a L<CPAN::Mini>
download.

The C<callback> param should be a C<CODE> reference that will be called
for each visit. The first parameter passed to the callback will be a C<HASH>
reference containing the tarball location in the C<archive> key, the location
of the temporary directory in the C<tempdir> key, the canonical CPAN
distribution name in the C<dist> key, and the author id in the C<author> key.

The C<acme> param (true by default) can be set to false to exclude any
distributions that contain the string "Acme", allowing the visit to ignore
any of the joke modules.

The C<author> param can be provided to limit the visit to only the modules
owned by a specific author.

The C<random> param will cause the archives to be processed in random order
if enabled. If not, the archives will be processed in alphabetical order.

The C<warnings> param will turn on L<Archive::Extract> warnings if enabled,
or disable warnings otherwise.

The C<prefer_bin> param will tell L<Archive::Extract> to use binary extract
instead of CPAN module extract wherever possible. By default, it will use
module-based extract.

Returns a B<CPAN::Mini::Visit> object, or throws an exception on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Normalise
	$self->{random}     = $self->random     ? 1 : 0;
	$self->{prefer_bin} = $self->prefer_bin ? 1 : 0;
	$self->{warnings}   = 0 unless $self->{warnings};

	# Check params
	unless (
		Params::Util::_HASH($self->minicpan)
		or (
			defined Params::Util::_STRING($self->minicpan)
			and
			-d $self->minicpan
		)
	) {
		Carp::croak("Missing or invalid 'minicpan' param");
	}
	unless ( Params::Util::_CODELIKE($self->callback) ) {
		Carp::croak("Missing or invalid 'callback' param");
	}
	if ( defined $self->ignore ) {
		unless ( Params::Util::_ARRAYLIKE($self->ignore) ) {
			Carp::croak("Invalid 'ignore' param");
		}
		# Clone the array so we can prepend more things
		$self->{ignore} = [ @{ $self->ignore } ];
	} else {
		$self->{ignore} = [];
	}

	# Apply the optional author setting
	my $author = Params::Util::_STRING($self->author);
	if ( defined $author ) {
		unshift @{$self->ignore}, sub {
			$_[0]->{author} ne $author;
		};
	}

	# Clean and apply the acme setting
	$self->{acme} = 1 unless defined $self->{acme};
	$self->{acme} = !! $self->{acme};
	unless ( $self->{acme} ) {
		unshift @{$self->ignore}, qr/\bAcme\b/;
	}

	# Derive the authors directory
	$self->{authors} = File::Spec->catdir( $self->_minicpan, 'authors', 'id' );
	unless ( -d $self->authors ) {
		Carp::croak("Authors directory '$self->{authors}' does not exist");
	}

	return $self;
}

=pod

=head2 run

The C<run> method executes the visit process, taking no parameters and
returning true.

Because the object contains no state information, you may call the C<run>
method multiple times for a single visit object with no ill effects.

=cut

sub run {
	my $self = shift;

	# If we've been passed a HASH minicpan param,
	# do an update_mirror first, before the regular run.
	if ( Params::Util::_HASH($self->minicpan) ) {
		CPAN::Mini->update_mirror(%{$self->minicpan});
	}

	# Search for the files
	my $find  = File::Find::Rule->name('*.tar.gz', '*.tgz', '*.zip', '*.bz2')->file->relative;
	my @files = sort $find->in( $self->authors );

	# Randomise if applicable
	if ( $self->random ) {
		@files = sort { rand() <=> rand() } @files;
	}

	# Extract the archive
	my $counter = 0;
	foreach my $path ( @files ) {
		# Derive the main file properties
		my $archive = File::Spec->catfile( $self->authors, $path );
		my $dist    = $path;
		$dist =~ s|^[A-Z]/[A-Z][A-Z]/|| or die "Bad distpath for $path";
		unless ( $dist =~ /^([A-Z0-9-]+)/ ) {
			die "Bad author for $path";
		}
		my $author = "$1";

		# Apply the ignore filters
		my $skip = 0;
		foreach my $filter ( @{$self->ignore} ) {
			if ( defined Params::Util::_STRING($filter) ) {
				$filter = quotemeta $filter;
				$filter = qr/$filter/;
			}
			if ( Params::Util::_REGEX($filter) ) {
				$skip = 1 if $dist =~ $filter;
			} elsif ( Params::Util::_CODELIKE($filter) ) {
				$skip = 1 if $filter->( {
					counter => $counter,
					archive => $archive,
					dist    => $dist,
					author  => $author,
				} );
			} else {
				Carp::croak("Missing or invalid filter");
			}
		}
		next if $skip;

		# Explicitly ignore some damaging distributions
		# if we are using Perl extraction
		unless ( $self->prefer_bin ) {
			next if $dist =~ /\bHarvey-\d/;
			next if $dist =~ /\bText-SenseClusters\b/;
			next if $dist =~ /\bBio-Affymetrix\b/;
			next if $dist =~ /\bAlien-MeCab\b/;
		}

		# Extract the archive
		local $Archive::Extract::WARN       = !! ($self->warnings > 1);
		local $Archive::Extract::PREFER_BIN = $self->prefer_bin;
		my $extract = Archive::Extract->new( archive => $archive );
		my $tmpdir  = File::Temp->newdir;
		my $ok      = 0;
		SCOPE: {
			my $pushd1 = File::pushd::pushd( File::Spec->curdir );
			$ok = eval {
				$extract->extract( to => $tmpdir );
			};
		}
		if ( $@ or not $ok ) {
			if ( $self->warnings > 1 ) {
				warn("Failed to extract '$archive': $@");
			} elsif ( $self->warnings ) {
				print "  Failed: $dist\n";
			}
			next;
		}

		# If using bin tools, do an additional check for
		# damaged tarballs with non-executable directories (on unix)
		my $extracted = $extract->extract_path;
		unless ( -r $extracted and -x $extracted ) {
			# Handle special case where we have screwed up
			# permissions on the extract directory.
			# Just assume we have permissions for that.
			File::chmod::chmod( 0755, $extracted );
		}

		# Change into the directory
		my $pushd2 = File::pushd::pushd( $extracted );

		# Invoke the callback
		$self->callback->( {
			counter => ++$counter,
			archive => $archive,
			dist    => $dist,
			author  => $author,
			tempdir => $extracted,
		} );
	}

	return 1;
}





######################################################################
# Support Methods

sub _minicpan {
	my $self = shift;
	return Params::Util::_HASH($self->minicpan)
		? $self->minicpan->{local}
		: $self->minicpan;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Mini-Visit>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2009 - 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
