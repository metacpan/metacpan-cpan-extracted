package App::Plex::Archiver;

use strict;
use warnings;

# ABSTRACT: Archives movies (mp4, avi, mov, mkv) into a directory structure for the Plex Media server

use File::Basename;
use File::Copy qw( copy );
use File::Spec;
use File::Slurp;
use File::HomeDir;
use Carp qw( croak );
use Lingua::EN::Titlecase;
use IO::Prompter;
use Readonly;

use Exporter qw( import );
our @EXPORT_OK = qw( title_from_filename copy_file get_tmbd_api_key get_tmdb_info );

Readonly my $DEFAULT_TMDB_API_KEY_FILENAME => ".tmdb-api-key";

## Version string
our $VERSION = qq{0.01};

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub title_from_filename {
  my $filename = shift // '';

  return '' unless ($filename);

  # Strip the path and extension
  my ($basename, $path, undef) = fileparse($filename, qr/\.[^.]*$/);

  # The $basename now contains the filename without path or extension.
  # Example: "my_document-v1.0.txt" -> "my_document-v1.0"

  # Convert underscores and dash to spaces
  $basename =~ s/[_-]/ /g;

  return scalar(Lingua::EN::Titlecase->new($basename)->title());
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub copy_file {
  my ( $source, $destination, $delete_source ) = @_;

  croak "Source file '$source' does not exist"      unless -e $source;
  croak "Source '$source' is not a regular file"    unless -f $source;
  croak "Cannot read source file '$source'"         unless -r $source;
  croak "Destination directory is not writable"     unless -w dirname($destination);

  copy( $source, $destination )
    or croak "Failed to copy '$source' to '$destination': $!";

  if ($delete_source) {
    unlink $source
      or croak "Copied but failed to delete '$source': $!";
  }
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub get_tmbd_api_key {
  my $filename = shift // "";

  if ($filename) {
    if (!-f "$filename") {
      return "'$filename' does not exist, or is not a regular file";
    }

  return (undef, read_file($filename, chomp => 1,));
  }

  my @tried;
  for my $path ('.', File::HomeDir->my_home) {
    my $filename = File::Spec->catfile($path, $DEFAULT_TMDB_API_KEY_FILENAME);
    if (-f "$filename") {
      return (undef, read_file($filename, chomp => 1,));
    }
    push(@tried, $filename);
  }

  return sprintf("Could not locate TMDB API key file: '%s'", join("', '", @tried));
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
sub get_tmdb_info {
  my $tmdb  = shift;
  my $title = shift // "";
  my $debug = shift // 0;

  return unless ($tmdb && $title);

  my @responses = $tmdb->search(max_pages => 1)->movie($title);

  for my $response (@responses) {
    $response->{release_year} = $response->{release_date} // "";
    my @parts = split(/-/, $response->{release_year});
    $response->{release_year} = $parts[0] // "";
  }

  if ($debug) {
    my $idx = 1;
    for my $response (@responses) {
      printf( "%2d - [id: %s]:\t%s (%s)\n",
        $idx,
        $response->{id},
        $response->{title},
        $response->{release_year},
      );
      $idx++;
    }
  }

  my $menu = [];
  for my $movie (@responses) {
    push(@$menu, sprintf("\"%s\" (%s)", $movie->{title}, $movie->{release_year}));
  }
  if (scalar(@$menu)) {
    my $selected = prompt(
      "Matching titles ...",
      -menu => $menu,
      -number,
      "Your choice: "
    );

    my $idx = 0;
    while ($idx < scalar(@$menu)) {
      if ($selected eq $menu->[$idx]) {
        printf("returning id='%s', release_year='%s'\n", $responses[$idx]->{id}, $responses[$idx]->{release_year}) if ($debug);
        return ($responses[$idx]->{id}, $responses[$idx]->{release_year});
      }
      $idx++;
    }
  } else {
    printf("No matching titles found!\n");
  }

  return;
}

1;

__END__

=head1 NAME

App::Plex::Archiver - Core functionality for archiving Plex media files

=head1 SYNOPSIS

  use App::Plex::Archiver qw( title_from_filename copy_file get_tmbd_api_key get_tmdb_info );

  # Extract a title from a filename
  my $title = title_from_filename('/path/to/movie_file-2023.mp4');
  # Returns: "Movie File 2023"

  # Copy or move a file
  copy_file('/source/file.mp4', '/dest/file.mp4', 0);  # Copy
  copy_file('/source/file.mp4', '/dest/file.mp4', 1);  # Move

  # Get TMDB API key
  my ($error, $api_key) = get_tmbd_api_key();
  die $error if $error;

  # Search for movie information
  my $tmdb = TMDB->new(api_key => $api_key);
  my ($tmdb_id, $release_year) = get_tmdb_info($tmdb, "Movie Title", 1);

=head1 DESCRIPTION

App::Plex::Archiver provides core functionality for archiving media files into a
directory structure suitable for Plex Media Server. The module handles file operations,
filename processing, TMDB API integration, and user interaction for movie metadata
retrieval.

This module is designed to work with the plex-archiver command-line tool but can
be used independently for media file processing tasks.

=head1 EXPORTED FUNCTIONS

The following functions can be imported using the C<use> statement:

=head2 title_from_filename

  my $title = title_from_filename($filename);

Extracts a human-readable title from a filename by removing the path and extension,
converting underscores and dashes to spaces, and applying proper title case formatting.

=over 4

=item * B<Parameters>

=over 4

=item * C<$filename> - The full path or filename to process

=back

=item * B<Returns>

A properly formatted title string, or empty string if no filename provided

=item * B<Example>

  title_from_filename('/movies/the_dark_knight-2008.mp4')
  # Returns: "The Dark Knight 2008"

=back

=head2 copy_file

  copy_file($source, $destination, $delete_source);

Safely copies a file from source to destination with optional deletion of the source
file (move operation). Includes comprehensive error checking and validation.

=over 4

=item * B<Parameters>

=over 4

=item * C<$source> - Path to the source file

=item * C<$destination> - Path to the destination file

=item * C<$delete_source> - Boolean flag: if true, deletes source after successful copy

=back

=item * B<Returns>

Nothing on success. Dies with descriptive error message on failure.

=item * B<Validation>

=over 4

=item * Verifies source file exists and is readable

=item * Verifies destination directory is writable

=item * Ensures atomic operation (copy then delete for moves)

=back

=back

=head2 get_tmbd_api_key

  my ($error, $api_key) = get_tmbd_api_key($filename);

Retrieves the TMDB API key from a specified file or searches for it in default
locations (current directory and user home directory).

=over 4

=item * B<Parameters>

=over 4

=item * C<$filename> - Optional: specific file containing the API key

=back

=item * B<Returns>

A two-element list:

=over 4

=item * C<$error> - Error message string, or C<undef> on success

=item * C<$api_key> - The API key string, or C<undef> on error

=back

=item * B<Default Search Locations>

=over 4

=item * C<./.tmdb-api-key> (current directory)

=item * C<$HOME/.tmdb-api-key> (user home directory)

=back

=back

=head2 get_tmdb_info

  my ($tmdb_id, $release_year) = get_tmdb_info($tmdb, $title, $debug);

Searches TMDB for movie information and presents an interactive menu for the user
to select the correct match. Returns the TMDB ID and release year for the selected movie.

=over 4

=item * B<Parameters>

=over 4

=item * C<$tmdb> - TMDB object instance (from TMDB module)

=item * C<$title> - Movie title to search for

=item * C<$debug> - Optional: enable debug output (default: 0)

=back

=item * B<Returns>

A two-element list on success, or empty list if no selection made:

=over 4

=item * C<$tmdb_id> - TMDB movie ID

=item * C<$release_year> - Movie release year (extracted from release_date)

=back

=item * B<Interactive Features>

=over 4

=item * Presents numbered menu of search results

=item * Shows movie title and release year for each option

=item * Handles user selection via IO::Prompter

=back

=back

=head1 DEPENDENCIES

This module requires the following Perl modules:

=over 4

=item * L<File::Basename> - File path manipulation

=item * L<File::Copy> - File copying operations

=item * L<File::Spec> - Cross-platform file path operations

=item * L<File::Slurp> - Simple file reading

=item * L<File::HomeDir> - User home directory detection

=item * L<Carp> - Error handling

=item * L<Lingua::EN::Titlecase> - Title case formatting

=item * L<IO::Prompter> - Interactive user prompts

=item * L<Readonly> - Read-only variables

=item * L<TMDB> - The Movie Database API integration (external dependency)

=back

=head1 CONSTANTS

=head2 $DEFAULT_TMDB_API_KEY_FILENAME

The default filename to search for when looking for TMDB API key files.

  Default value: ".tmdb-api-key"

=head1 ERROR HANDLING

Functions in this module use different error handling strategies:

=over 4

=item * B<copy_file> - Dies with descriptive error messages using C<croak>

=item * B<get_tmbd_api_key> - Returns error message as first return value

=item * B<title_from_filename> - Returns empty string for invalid input

=item * B<get_tmdb_info> - Returns empty list when no selection is made

=back

=head1 EXAMPLES

=head2 Basic File Processing

  use App::Plex::Archiver qw( title_from_filename copy_file );

  my $source = '/downloads/movie_file_2023.mkv';
  my $title = title_from_filename($source);
  my $dest = "/plex/movies/$title/$title.mkv";

  # Create destination directory
  use File::Path qw( make_path );
  make_path(dirname($dest));

  # Copy file
  copy_file($source, $dest, 0);

=head2 TMDB Integration

  use App::Plex::Archiver qw( get_tmbd_api_key get_tmdb_info );
  use TMDB;

  # Get API key
  my ($error, $api_key) = get_tmbd_api_key();
  die "Failed to get API key: $error" if $error;

  # Initialize TMDB
  my $tmdb = TMDB->new(api_key => $api_key);

  # Search for movie
  my ($tmdb_id, $year) = get_tmdb_info($tmdb, "The Matrix", 1);
  if ($tmdb_id) {
      print "Found: TMDB ID $tmdb_id, Year $year\n";
  }

=head1 VERSION

Version 0.01

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

This module was created as part of the plex-archiver project.

=head1 SEE ALSO

=over 4

=item * L<plex-archiver> - Command-line tool that uses this module

=item * L<TMDB> - The Movie Database API module

=item * L<https://www.themoviedb.org/> - The Movie Database website

=back

=cut
