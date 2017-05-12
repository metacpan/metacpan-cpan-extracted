package Data::Embed::Reader;

use strict;
use warnings;
use English qw< -no_match_vars >;
use Fcntl qw< :seek >;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;
use Storable qw< dclone >;
use Data::Embed::File;
use Data::Embed::Util qw< :constants unescape >;

our $VERSION = '0.32'; # make indexer happy

sub new {
   my $package = shift;
   my $input   = shift;

   # Undocumented, keep additional parameters around...
   my %args = (scalar(@_) && ref($_[0])) ? %{$_[0]} : @_;
   my $self = bless {args => \%args}, $package;

   # If a GLOB, just assign a default filename for logs and set
   # binary mode :raw
   if (ref($input) eq 'GLOB') {
      DEBUG $package, ': input is a GLOB';
      $self->{filename} = '<GLOB>';
      binmode $input, ":raw"
        or LOGCROAK "binmode() to ':raw' failed";
      $self->{fh} = $input;
   } ## end if (ref($input) eq 'GLOB')
   else {    # otherwise... it's a filename
      DEBUG $package,
        ': input is a file or other thing that can be open-ed';
      $self->{filename} = $input;
      open $self->{fh}, '<', $input
        or LOGCROAK "open('$input'): $OS_ERROR";
      binmode $self->{fh}, ':raw';
   } ## end else [ if (ref($input) eq 'GLOB')]

   return $self;
} ## end sub new

sub files {
   my $files = shift->_ensure_index()->{files};
   return wantarray() ? @$files : $files;
}

sub prefix {
   return shift->_ensure_index()->{_prefix};
}

sub reset {
   my $self = shift;
   delete $self->{$_} for qw< files index >;
   return $self;
}

######## PRIVATE METHODS ##############################################

# Get the index of the embedded files as a L<Data::Embed::File> object.
# You should normally not need this index, because it is parsed
sub _index { return shift->_ensure_index()->{_index}; }

sub _ensure_index {
   my $self = shift;

   # rebuild cache if not in place
   if (!exists $self->{files}) {
      my $index = $self->_load_index()
        || {
         _prefix => Data::Embed::File->new(
            fh       => $self->{fh},
            filename => $self->{filename},
            name     => 'Data::Embed prefix data',
            offset   => 0,
            length   => scalar(__size($self->{fh})),
         ),
         files  => [],
         _index => Data::Embed::File->new(
            fh       => $self->{fh},
            filename => $self->{filename},
            name     => 'Data::Embed index',
            length   => 0,
            offset   => scalar(__size($self->{fh})),
         ),
        };
      %$self = (%$self, %$index);
   } ## end if (!exists $self->{files...})

   # return a reference to $self, for easy chaining
   return $self;
} ## end sub _ensure_index

sub _load_index {
   my $self = shift;

   # read the index section from the end of the file, or bail out
   defined(my $index_text = $self->_read_index())
     or return;
   my $index_length = length($index_text);

   # trim to isolate the data in the section
   my $terminator_length = length TERMINATOR();
   substr $index_text, 0, length(STARTER()), '';
   substr $index_text, -$terminator_length, $terminator_length, '';
   DEBUG "index contents is '$index_text'";

   # iterate over the index that has been read. Each line in this
   # index is assumed to contain a pair length/name
   my $data_length = 0;
   my ($fh, $filename) = @{$self}{qw< fh filename >};
   my @files = map {
      my ($length, $name) = m{\A \s* (\d+) \s+ (\S*) \s*\z}mxs
        or LOGCROAK "index line is not compliant: >$_<";
      $name = Data::Embed::Util::unescape($name);

      # the offset at which "this" file lives is equal to the length
      # of all data considered so far
      my $offset = $data_length;

      # the addition of this file increases the data length with the
      # size of the section, plus two bytes for separating newlines
      $data_length += $length + 2;
      {
         fh       => $fh,
         filename => $filename,
         name     => $name,
         length   => $length,
         offset   => $offset,     # to be adjusted further
      };
   } split /\n+/, $index_text;

   # Now we established the full length of the data section, so it's
   # possible to adjust all offsets for all files (remember that the
   # files are assumed to be at the end of the embedding file)
   my $full_length       = __size($fh);
   my $offset_correction = $full_length - $index_length - $data_length;
   for my $file (@files) {
      $file =
        Data::Embed::File->new(%$file,
         offset => ($file->{offset} + $offset_correction),);
   }

   # return the files in the index and the index itself, all as
   # Data::Embed::File objects for consistency
   return {
      _prefix => Data::Embed::File->new(
         fh       => $fh,
         filename => $filename,
         name     => 'Data::Embed prefix data',
         length   => $offset_correction,
         offset   => 0,
      ),
      files  => \@files,
      _index => Data::Embed::File->new(
         fh       => $fh,
         filename => $filename,
         name     => 'Data::Embed index',
         length   => $index_length,
         offset   => $data_length + $offset_correction,
      ),
   };
} ## end sub _load_index

sub __size {
   my $fh   = shift;
   my $size = -s $fh;
   if (!defined $size) {
      DEBUG "getting size via seek";
      my $current = tell $fh;
      seek $fh, 0, SEEK_END;
      $size = tell $fh;
      DEBUG "size: $size";
      seek $fh, $current, SEEK_SET;
   } ## end if (!defined $size)
   return $size;
} ## end sub __size

# read the last section of the file, looking for the index
sub _read_index {
   my $self = shift;
   my ($fh, $filename) = @{$self}{qw< fh filename >};
   DEBUG "_read_index(): fh[$fh] filename[$filename]";
   my $full_length = __size($fh);    # length of the whole stream/file

   # look for TERMINATOR at the very end of the file
   my $terminator = TERMINATOR;

   # is there enough data?
   my $terminator_length = length $terminator;
   return unless $full_length > $terminator_length;

   # read exactly that number of bytes from the end of the file
   # and compare with the TERMINATOR
   my $ending = $self->_read(($terminator_length) x 2);
   return unless $ending eq $terminator;
   DEBUG "found terminator";

   # TERMINATOR is in place, this is promising. Now let's look for
   # STARTER going backwards in the file
   my $starter  = STARTER;
   my $readable = $full_length - $terminator_length;
   my $chunk_size = 80;     # we'll read this number of bytes per time
   my $starter_position;    # this will tell us where the STARTER begins
   while ($readable) {      # loop until there's stuff to read backwards

      # how many bytes to read? $chunk_size if possible, what remains
      # otherwise
      my $n = ($readable > $chunk_size) ? $chunk_size : $readable;
      my $chunk = $self->_read($n, $n + length $ending);

      # we're reading backwards, so the new $chunk as to be pre-pended
      $ending = $chunk . $ending;
      TRACE sub { "ENDING: >$ending<" };

      # Look for the STARTER. We have to work on the full $ending
      # instead of the shorter last $chunk because the STARTER might
      # have been split across two reads
      $starter_position = CORE::index $ending, $starter;

      # finding the STARTER is a good exit condition
      last if $starter_position >= 0;

      # otherwise note that we already read some bytes and go on
      $readable -= $n;
   } ## end while ($readable)

   # if $starter_position is not valid (i.e. -1) then we did not find
   # the STARTER and we exit with a failure (not an exception, the whole
   # thing might not be in place at all, although the presence of the
   # TERMINATOR is suspect anyway...)
   return unless $starter_position >= 0;
   DEBUG "found starter";

   # trim the available buffer $ending to isolate the index and return it
   substr $ending, 0, $starter_position, '';
   return $ending;
} ## end sub _read_index

# read data from the underlying stream, using offsets from the end
# of the stream
sub _read {
   my $self = shift;
   my @args = my ($count, $offset_from_end) = @_;
   my ($fh, $filename) = @{$self}{qw< fh filename >};
   DEBUG
     sub { my $args = join ', ', @args; "_read($args) [file: $filename]" };

   LOGDIE '_read(): offset from end cannot be less than count'
     if $offset_from_end < $count;
   DEBUG "seeking $offset_from_end to the end";
   seek $fh, -$offset_from_end, SEEK_END
     or LOGCROAK "seek('$filename'): $OS_ERROR";

   my $buffer = '';
   while ($count) {
      my $chunk;
      defined(my $nread = read $fh, $chunk, $count)
        or LOGCROAK "read('$filename'): $OS_ERROR";
      TRACE sub { "read $nread bytes, '$chunk'" };
      DEBUG "read $nread out of $count bytes needed";
      LOGCROAK "unexpectedly reached end of file"
        unless $nread;
      $buffer .= $chunk;
      $count -= $nread;
   } ## end while ($count)
   return $buffer;
} ## end sub _read

1;
