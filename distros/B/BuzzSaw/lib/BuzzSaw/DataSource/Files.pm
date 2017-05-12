package BuzzSaw::DataSource::Files; # -*-perl-*-
use strict;
use warnings;

# $Id: Files.pm.in 22433 2013-01-25 12:02:00Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 22433 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/DataSource/Files.pm.in $
# $Date: 2013-01-25 12:02:00 +0000 (Fri, 25 Jan 2013) $

our $VERSION = '0.12.0';

use BuzzSaw::Types qw(BuzzSawDataSourceFilesNamesList);

use Cwd ();
use English qw(-no_match_vars);
use File::Find::Rule ();
use IO::File ();
use List::Util ();

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(ArrayRef Bool FileHandle Int Maybe Str);

with 'BuzzSaw::DataSource';

has 'directories' => (
    traits   => ['Array'],
    isa      => ArrayRef[Str],
    is       => 'ro',
    required => 1,
    default  => sub { [ q{.} ] },
    handles  => {
        list_directories  => 'elements',
        count_directories => 'count',
    },
);

has 'names' => (
    traits   => ['Array'],
    isa      => BuzzSawDataSourceFilesNamesList,
    is       => 'ro',
    coerce   => 1,
    required => 1,
    default  => sub { [] },
    handles  => {
        list_names  => 'elements',
        count_names => 'count',
        has_names   => 'count',
    },
);

has 'size_limit' => (
    isa       => 'Str',
    is        => 'ro',
    predicate => 'has_size_limit',
);

has 'recursive' => (
    isa     => Bool,
    is      => 'ro',
    default => 1,
);

has 'order_by' => (
    isa       => enum(['random','size_asc','size_desc','name_asc','name_desc']),
    is        => 'ro',
    default   => 'random',
);

has 'files' => (
    traits   => ['Array'],
    isa      => ArrayRef[Str],
    is       => 'ro',
    writer   => '_set_files',
    builder  => '_find_files',
    lazy     => 1,
    handles  => {
        list_files   => 'elements',
        count_files  => 'count',
        get_filename => 'get',
    },
);

has '_current_fileidx' => (
    isa      => Maybe[Int],
    is       => 'rw',
    init_arg => undef,
    default  => sub { -1 },
);

has '_current_digest' => (
    isa      => Maybe[Str],
    is       => 'rw',
    init_arg => undef,
);

has '_current_fh' => (
    isa      => Maybe[FileHandle],
    is       => 'rw',
    init_arg => undef,
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub BUILD {
  my ($self) = @_;

  # Always check the names list for emptiness first, the count_files
  # method triggers the files builder method so it's never going to be
  # empty if names have been specified.

  if ( $self->count_names == 0 && $self->count_files == 0 ) {
    $self->log->logdie('You must specify either a set of files or a set of names to find');
  }

  return;
}

sub _find_files {
    my ($self) = @_;

    my $finder = File::Find::Rule->new();
    $finder->file;     # Only interested in files
    $finder->nonempty; # No point examining empty files

    if ( $self->has_size_limit && $self->size_limit ) {
      $finder->size($self->size_limit);
    }

    my @rules = map { File::Find::Rule->name( $_ ) } $self->list_names;

    $finder->any(@rules);

    if ( !$self->recursive ) {
        $finder->maxdepth(1);
    }

    my $iter = $finder->start($self->list_directories);

    my %files;
    while ( defined( my $file = $iter->match ) ) {
      # converts relative to absolute path, resolves symbolic links
      $file = Cwd::abs_path($file);

      $files{$file} = 1;
    }

    # Typically we randomise the order of the list so that multiple
    # processes will pass through the files in different orders which
    # should make the process more efficient. We also support sorting
    # by name and size in ascending or descending order. The size
    # sorting can be handy if you really do need to leave the biggest
    # files until last.

    my @files;
    my $order_by = $self->order_by;
    if ( $order_by =~ m/^size_(asc|desc)$/ ) {

        my $sorter;
        if ( $1 eq 'asc' ) {
            $sorter = sub { $a->[1] <=> $b->[1] }; 
        } else {
            $sorter = sub { $b->[1] <=> $a->[1] }; 
        }

        # Schwartzian transform for efficient sorting
        @files = map  { $_->[0] }
                 sort $sorter
                 map  { [ $_, (stat($_))[7] ] } keys %files;

    } elsif ( $order_by =~ m/^name_(asc|desc)$/ ) {

        if ( $1 eq 'asc' ) {
            @files = sort { $a cmp $b } keys %files;
        } else {
            @files = sort { $b cmp $a } keys %files;
        }

    } else {
        @files = List::Util::shuffle( keys %files );
    }

    if ( $self->log->is_debug ) {
      my $count = scalar @files;
      $self->log->debug("Found $count log files");
    }

    return \@files;
}

sub reset {
  my ($self) = @_;

  if ( $self->log->is_debug ) {
    $self->log->debug('Resetting data source');
  }

  $self->_current_fileidx(-1);
  $self->_current_fh(undef);
  $self->_current_digest(undef);

  if ( $self->has_names ) {
    $self->_set_files( $self->_find_files );
  }

  return;
}

sub next_entry {
    my ($self) = @_;

    my $fh = $self->_current_fh // $self->_next_fh;

    # Ensure we do not attempt to get a line from an empty file
    while ( defined $fh && $fh->eof ) {
        $fh = $self->_next_fh;
    }

    if ( !defined $fh ) {
        return;
    }

    chomp ( my $line = $fh->getline );

    return $line;
}

sub _next_fh {
    my ($self) = @_;

    my $current_fh = $self->_current_fh;
    if ( defined $current_fh ) {
        my $current_file   = $self->_current_filename;
        my $current_digest = $self->_current_digest;
        $self->db->register_log( $current_file, $current_digest );

        $self->db->end_transaction();

        $self->db->end_processing($current_file);

        $current_fh->close;
    }

    my $file = $self->_next_free_filename;

    # This ensures that if a file has disappeared or become
    # unopenable in anyway we just move on. Much better to do this
    # than fail out right in the middle of a long run.

    my $new_fh;
    while ( defined $file && !defined $new_fh ) {
      if ( $self->log->is_debug ) {
        my $cur   = $self->_current_fileidx + 1;
        my $total = $self->count_files;
        $self->log->debug("Opening $file ($cur/$total)");
      }

      $new_fh = eval {

        my $fh;
        if ( $file =~ m/\.gz$/ ) {
          require IO::Uncompress::Gunzip;
          $fh = IO::Uncompress::Gunzip->new($file)
            or $self->log->logdie("Could not open $file: $IO::Uncompress::Gunzip::GunzipError");
        } elsif ( $file =~ m/\.bz2$/ ) {
          require IO::Uncompress::Bunzip2;
          $fh = IO::Uncompress::Bunzip2->new($file)
            or $self->log->logdie("Could not open $file: $IO::Uncompress::Bunzip2::Bunzip2Error");
        } else {
          $fh = IO::File->new( $file, 'r' )
            or $self->log->logdie("Could not open $file: $OS_ERROR");
        }
        return $fh;
      };

      if ( $EVAL_ERROR || !defined $new_fh ) {
        $self->log->error($EVAL_ERROR) if $EVAL_ERROR;

        # just move onto the next available file
        $file = $self->_next_free_filename;
      }

    }

    $self->_current_fh($new_fh);

    if ( defined $new_fh ) {
      $self->db->begin_transaction();
    }

    return $new_fh;
}

sub _current_filename {
    my ($self) = @_;

    my $filename;
    my $cur_fileidx = $self->_current_fileidx;
    if ( defined $cur_fileidx && $cur_fileidx >= 0 ) {
        $filename = $self->get_filename($cur_fileidx);
    }

    return $filename;
}

sub _next_free_filename {
  my ($self) = @_;

  # Register that the file is being processed. There is locking here
  # to avoid multiple processes taking on the same file. Keep going
  # until we find the next free file (or give up if the list is
  # exhausted).

  my ( $file, $digest ) = $self->_next_filename;

  my $can_start = 0;
  while ( defined $file && !$can_start ) {
      $can_start = $self->db->start_processing( $file, $digest,
                                                       $self->readall );

    if ( !$can_start ) {
      ( $file, $digest ) = $self->_next_filename;
    }

  }

  return $file;
}

sub _next_filename {
    my ($self) = @_;

    my $file_count = $self->count_files;

    my ( $next_filename, $next_digest );

    my $cur_fileidx = $self->_current_fileidx;

    while ( defined $cur_fileidx && !defined $next_filename ) {

      if ( $cur_fileidx + 1 < $file_count ) {
        $cur_fileidx  = $cur_fileidx + 1;
      } else {
        $cur_fileidx = undef;
      }
      $self->_current_fileidx($cur_fileidx);

      $next_filename = $self->_current_filename;

      if ( defined $next_filename ) {

        $next_digest = eval { $self->checksum_file($next_filename) };

        if ( $EVAL_ERROR || !defined $next_digest ) {
          $self->log->error("Failed to calculate digest for $next_filename: $EVAL_ERROR");
          $next_filename = undef;
          $next_digest   = undef;
        }

      }

    }

    # store digest for retrieval at end of processing run when we
    # store it into the database to show that the file is done.

    $self->_current_digest($next_digest);

    return ( $next_filename, $next_digest );
}

1;
__END__

=head1 NAME

BuzzSaw::DataSource::Files - A BuzzSaw data source for a set of files.

=head1 VERSION

This documentation refers to BuzzSaw::DataSource::Files version 0.12.0

=head1 SYNOPSIS

  use BuzzSaw::DataSource::Files;

  my $source = BuzzSaw::DataSource::Files->new(
                       parser      => "RFC3339",
                       names       => ["*.log"],
                       directories => ["/var/log"],
                       recursive   => 0 );

  $source->reset();

  while ( defined ( my $entry = $source->next_entry ) ) {
    ...
  }

=head1 DESCRIPTION

This module provides a class which implements the BuzzSaw data source
API. It can be used to search a large directory tree to find all log
files with names which match specified patterns. The list of files
will be walked and each line of each file will be returned in a
continuous stream until the end is reached. This module considers each
line to represent a separate log entry, no attempts are made to handle
multi-line log entries.

This module can seamlessly handle a mixture of files compressed with
either of gzip or bzip2 alongside standard plain-text files.

The module records each file once it has been completely parsed so
that on the next run it can be ignored if it has not been altered.

The module uses locking so that multiple processes can run
concurrently on the same set of log files without any problems
associated with conflicting access requirements.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

The following attributes are inherited from the
L<DataSource::DataSource> role which is implemented by this class. See
the documentation for that role for full details.

=over

=item db

The L<BuzzSaw::DB> object.

=item parser

The L<BuzzSaw::Parser> object.

=item readall

This is a boolean value which controls whether or not the contents of
all files should be examined. If this is set to false (the default)
then this class will not re-read files which have previously been
examined and have not since been altered.

=back

The following attributes are specific to this class.

=over

=item files

If you wish to parse a set of specifically named log files then you
can set this attribute to be a reference to an array of absolute
filenames. More typically you will not know all the potential file
names and will want to trawl for all log files which match some
pattern within an entire directory. In that case you should ignore
this attribute and use the C<names> and C<directories> attributes
described below, this attribute will then be automatically populated
by doing a filesystem search using the L<File::Find::Rule>
module. There is no default value. Note that you MUST specify either a
set of names or a set of files when the files data source object is
created.

=item names

This takes a list of strings and references to Perl regular
expressions. Strings are considered to be simple POSIX-style file
matches (e.g. C<*.log>). If you need anything more complex then use
the full power of Perl regular expressions
(e.g. C<qr/^.*\.log(-\d+)?$/>). A file will be included in the final
list if ANY pattern matches, the rules are OR-ed not AND-ed
together. You can specify as many patterns as you like and can mix the
use of both styles. There is no default value. Note that you MUST
specify either a set of names or a set of files when the files data
source object is created.

=item directories

This is a reference to a list of directories which should be searched
when the names attribute has been specified and the files attribute
has not been specified. The default value is a single-element list
containing C<.> (i.e. the current directory).

=item recursive

This is a boolean value which controls whether or not to search
recursively through the specified directories looking for matching log
files. The default is true.

=item order_by

This is a string which controls the sequence in which the list of
files found will be parsed. The supported options are: C<random>,
C<name_asc>, C<name_desc>, C<size_asc>, C<size_desc>, the default is
C<random>.

Typically you will want to randomise the order of the list so that
multiple processes will pass through the files in different orders
which should make the process more efficient. The size sorting can be
very useful if you really do need to leave the biggest files until
last (or get them done first).

=item size_limit

This is a string which is used to set limits on the size (in bytes) of
the files which will be parsed. The format follows the semantics
supported by the L<Number::Compare> module, for example "<100M" or
"<200K". If this is not set or is set to C<0> (zero) all files will be
parsed.

=back

=head1 SUBROUTINES/METHODS

The class provides implementations of the two methods required by the
L<BuzzSaw::DataSource> role.

=over

=item $source->reset

This resets all internal iterators which are used to track the current
location in the currently open file. It also forces a rescan of the
file system if the C<names> attribute has been specified. You probably
want to call this just before you start working through the list of
entries.

=item $entry = $source->next_entry

This method works through the set of files as a single continuous
stream. Whenever the end-of-file is reached in one file the next is
opened until the complete set of data is exhausted. When the end of
the stream is reached an C<undef> value will be returned, if an error
occurs this method will die. The sequence in which files are parsed is
controlled by the C<order_by> attribute.

Note that this module can handle files which are compressed using gzip
(if the file name suffix is C<.gz>) or bzip2 (if the file name suffix
is C<.bz2>).

=head1 DEPENDENCIES

This module is powered by L<Moose>, it also requires L<MooseX::Types>,
L<MooseX::Log::Log4perl> and L<MooseX::SimpleConfig>.

It also needs L<File::Find::Rule>.

=head1 SEE ALSO

L<BuzzSaw>, L<BuzzSaw::DataSource>, L<DataSource::Importer>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
