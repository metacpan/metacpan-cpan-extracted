package Data::Embed::Writer;

use strict;
use warnings;
use English qw< -no_match_vars >;
use Data::Embed::Reader;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;
use Data::Embed::Util qw< :constants escape >;
use Fcntl qw< :seek >;
use Scalar::Util qw< refaddr >;

our $VERSION = '0.32'; # make indexer happy

sub __output_for_new {
   my $self    = shift;
   my $package = ref $self;
   my $output  = $self->{output} = $self->{args}{output};
   $self->{output_same_as_input} = 0;    # by default

   # The simple stuff: not present/defined, or the classical "-" string
   if ((!defined($output)) || (!length($output)) || ($output eq '-')) {
      DEBUG $package, "::__output_for_new(): output to STDOUT";
      open my $fh, '>&', \*STDOUT
        or LOGCROAK "dup(): $OS_ERROR";
      binmode $fh
        or LOGCROAK "binmode(\\*STDOUT): $OS_ERROR";
      $self->{output_name} = '<STDOUT>';
      $self->{output_fh}   = $fh;
      $self->{output_type} = 'filehandle';
      return $self;
   } ## end if ((!defined($output)...))

   my $oref = ref $output;
   if (!$oref) {    # filename
      DEBUG $package, '::__output:for_new(): output to a file';
      $self->{output_type} = 'file';
      $self->{output_name} = $output;

      # same file as input? If yes, do not clobber
      if (($self->{input_type} eq 'file') && ($output eq $self->{input})) {
         open my $fh, '+<', $output
           or LOGCROAK "open('$output'): $OS_ERROR";
         binmode $fh
           or LOGCROAK "binmode('$output'): $OS_ERROR";
         $self->{output_fh}            = $fh;
         $self->{output_same_as_input} = 1;
         return $self;
      } ## end if (($self->{input_type...}))

      open my $fh, '>', $output
        or LOGCROAK "open('$output'): $OS_ERROR";
      binmode $fh
        or LOGCROAK "binmode('$output'): $OS_ERROR";
      $self->{output_fh} = $fh;
      return $self;
   } ## end if (!$oref)

   if ($oref eq 'SCALAR') {    # reference to a scalar, similar to filename
      DEBUG $package, '::__output:for_new(): output to a scalar ref';
      $self->{output_type} = 'scalar-ref';
      $self->{output_name} = "{$output}";

      # same file as input? If yes, do not clobber
      if (  ($self->{input_type} eq 'scalar-ref')
         && (refaddr($output) eq refaddr($self->{input})))
      {
         open my $fh, '+<', $output
           or LOGCROAK "open('$output'): $OS_ERROR";
         binmode $fh
           or LOGCROAK "binmode('$output'): $OS_ERROR";
         $self->{output_fh}            = $fh;
         $self->{output_same_as_input} = 1;
         return $self;
      } ## end if (($self->{input_type...}))

      open my $fh, '>', $output
        or LOGCROAK "open('$output'): $OS_ERROR";
      binmode $fh
        or LOGCROAK "binmode('$output'): $OS_ERROR";
      $self->{output_fh} = $fh;
      return $self;
   } ## end if ($oref eq 'SCALAR')

   # Otherwise, we will have to assume that it is a filehandle
   $self->{output_name}          = '<HANDLE>';
   $self->{output_fh}            = $output;
   $self->{output_type}          = 'filehandle';
   $self->{output_same_as_input} = ($self->{input_type} eq 'filehandle')
     && (refaddr($output) eq refaddr($self->{input_fh}));
   return $self;
} ## end sub __output_for_new

sub __input_for_new {
   my $self    = shift;
   my $package = ref $self;
   my $input   = $self->{input} = $self->{args}{input};

   # if not defined, it just does not exist
   if (!defined($input)) {
      DEBUG $package, "::__input_for_new(): no input";
      $self->{input_name} = '*undef*';
      $self->{input_fh}   = undef;
      $self->{input_type} = 'undef';
      return $self;
   } ## end if (!defined($input))

   # the classical "-" string
   if ($input eq '-') {
      DEBUG $package, "::__input_for_new(): input from STDIN";
      open my $fh, '<&', \*STDIN
        or LOGCROAK "dup(): $OS_ERROR";
      binmode $fh
        or LOGCROAK "binmode(\\*STDIN): $OS_ERROR";
      $self->{input_name} = '<STDIN>';
      $self->{input_fh}   = $fh;
      $self->{input_type} = 'filehandle';
      return $self;
   } ## end if ($input eq '-')

   my $iref = ref $input;
   if (!$iref) {    # filename
      DEBUG $package, '::__input:for_new(): input from file';
      open my $fh, '<', $input
        or LOGCROAK "open('$input'): $OS_ERROR";
      binmode $fh
        or LOGCROAK "binmode('$input'): $OS_ERROR";
      $self->{input_name} = $input;
      $self->{input_fh}   = $fh;
      $self->{input_type} = 'file';
      return $self;
   } ## end if (!$iref)

   if ($iref eq 'SCALAR') {    # reference to a scalar, similar to filename
      DEBUG $package, '::__input:for_new(): input from a scalar ref';
      open my $fh, '<', $input
        or LOGCROAK "open('$input'): $OS_ERROR";
      binmode $fh
        or LOGCROAK "binmode('$input'): $OS_ERROR";
      $self->{input_name} = "{$input}";
      $self->{input_fh}   = $fh;
      $self->{input_type} = 'scalar-ref';
      return $self;
   } ## end if ($iref eq 'SCALAR')

   # Otherwise, we will have to assume that it is a filehandle
   $self->{input_name} = '<HANDLE>';
   $self->{input_fh}   = $input;
   $self->{input_type} = 'filehandle';
   return $self;
} ## end sub __input_for_new

sub _transfer_input {
   my $self = shift;
   if (!$self->{input_transferred}) {

      # if there is an input, transfer to the output if it is the case
      if ($self->{input_fh}) {
         if ($self->{output_same_as_input})
         {    # don't copy, assume seekable input
            my $reader = Data::Embed::Reader->new($self->{input_fh});
            my $ifile = $reader->_index();    # private method called
            my @index = $ifile->contents();
            shift @index;                     # eliminate STARTER
            pop @index;                       # eliminate TERMINATOR
            $self->{index} = \@index;    # initialize previous index
                                         # put out handle in right position
            seek $self->{output_fh}, $ifile->{offset}, SEEK_SET;
         } ## end if ($self->{output_same_as_input...})
         else {
            my $starter    = STARTER;
            my $terminator = TERMINATOR;
            my (@index, $index_completed);
            my $ifh = $self->{input_fh};
            my $ofh = $self->{output_fh};
          INPUT:
            while (<$ifh>) {
               if (!@index) {
                  if ($_ eq $starter) {
                     push @index, $_;
                     next INPUT;
                  }
                  else {
                     print {$ofh} $_;
                  }
               } ## end if (!@index)
               elsif (!$index_completed) {    # accumulating index
                  if (m{\A \s* (\d+) \s+ (\S*) \s*\z}mxs) {
                     push @index, $_;
                  }
                  elsif ($_ eq $terminator) {
                     push @index, $_;
                     $index_completed = 1;
                  }
                  else {    # not a valid index, flush accumulated lines
                     print {$ofh} @index;
                     @index           = ();
                     $index_completed = undef;    # paranoid
                  }
               } ## end elsif (!$index_completed)
               else
               {    # accumulating and index completed, but other stuff...
                  print {$ofh} @index;    # flush and reset
                  @index           = ();
                  $index_completed = undef;
               } ## end else [ if (!@index) ]
            } ## end INPUT: while (<$ifh>)
            shift @index;                 # eliminate STARTER
            pop @index;                   # eliminate TERMINATOR
            $self->{index} = \@index;     # initialize previous index
         } ## end else [ if ($self->{output_same_as_input...})]
      } ## end if ($self->{input_fh})
      $self->{input_transferred} = 1;
   } ## end if (!$self->{input_transferred...})
   return $self;
} ## end sub _transfer_input

sub new {
   my $package = shift;
   my %args = (scalar(@_) && ref($_[0])) ? %{$_[0]} : @_;
   $args{transfer_input} = 1 unless exists $args{transfer_input};

   # Undocumented, keep additional parameters around...
   my $self = bless {args => \%args}, $package;

   # first of all, resolve the input
   $self->__input_for_new();

   # then the output (might depend on the input)
   $self->__output_for_new();

   $self->_transfer_input() if $args{transfer_input};

   return $self;
} ## end sub new

sub add {
   my $self = shift;
   my %args = (scalar(@_) && ref($_[0])) ? %{$_[0]} : @_;

   $self->_add($_)
     for (defined($args{inputs}) ? @{$args{inputs}} : (\%args));

   return $self;
} ## end sub add

sub _add {
   my ($self, $args) = @_;

   # DWIM!
   if (defined $args->{input}) {
      if ($args->{input} eq '-') {
         open my $fh, '<&', \*STDIN
           or LOGCROAK "dup(): $OS_ERROR";
         binmode $fh
           or LOGCROAK "binmode(\\*STDIN): $OS_ERROR";
         $args->{fh} = $fh;
      } ## end if ($args->{input} eq ...)
      else {
         my $ref = ref $args->{input};
         if ((!$ref) || ($ref eq 'SCALAR')) {
            $args->{filename} = $args->{input};
         }
         else {
            $args->{fh} = $args->{input};
         }
      } ## end else [ if ($args->{input} eq ...)]
   } ## end if (defined $args->{input...})

   if (defined $args->{fh}) {
      return $self->add_fh(@{$args}{qw< name fh >});
   }
   elsif (defined $args->{filename}) {
      return $self->add_file(@{$args}{qw< name filename >});
   }
   elsif (defined $args->{data}) {
      return $self->add_data(@{$args}{qw< name data >});
   }

   LOGCROAK "add() needs some input";
   return;    # unreached
} ## end sub _add

sub add_file {
   my ($self, $name, $filename) = @_;
   $name = '' unless defined $name;
   my $print_name =
     (ref($filename) eq 'SCALAR') ? 'internal data' : $filename;
   DEBUG "add_file(): $name => $filename";

   # To make it work with references to scalars in perl pre-5.14
   # we split open() and binmode()
   open my $fh, '<', $filename
     or LOGCROAK "open('$print_name'): $OS_ERROR";
   binmode $fh
     or LOGCROAK "binmode('$print_name') failed";

   return $self->add_fh($name, $fh);
} ## end sub add_file

sub add_data {
   my ($self, $name) = @_;
   return $self->add_file($name, \$_[2]);
}

sub add_fh {
   my ($self, $name, $input_fh) = @_;

   my $output_fh   = $self->{output_fh};
   my $data_length = 0;                    # go!
   while (!eof $input_fh) {
      my $buffer;
      defined(my $nread = read $input_fh, $buffer, 4096)
        or LOGCROAK "read(): $OS_ERROR";
      last unless $nread;                  # safe side?
      print {$output_fh} $buffer
        or LOGCROAK "print(): $OS_ERROR";
      $data_length += $nread;
   } ## end while (!eof $input_fh)

   # Add separator, not really needed but might come handy for
   # peeking into the file
   print {$output_fh} "\n\n"
     or LOGCROAK "print(): $OS_ERROR";

   $name = '' unless defined $name;
   push @{$self->{index}}, sprintf "%d %s\n", $data_length, escape($name);

   return $self;
} ## end sub add_fh

sub write_index {
   my $self = shift;
   my ($output_fh, $index) = @{$self}{qw< output_fh index >};
   print {$output_fh} STARTER, @$index, TERMINATOR
     or LOGCROAK "print(): $OS_ERROR";
   delete $self->{$_} for qw< output_fh index >;
   return;
} ## end sub write_index

sub DESTROY {
   my $self = shift;
   $self->write_index() if exists $self->{output_fh};
   return;
}

1;
