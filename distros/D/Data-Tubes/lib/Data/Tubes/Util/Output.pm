package Data::Tubes::Util::Output;
use strict;
use warnings;
use English qw< -no_match_vars >;
use 5.010;
use File::Path qw< make_path >;
use File::Basename qw< dirname >;
our $VERSION = '0.740';

use Log::Log4perl::Tiny qw< :easy :dead_if_first >;
use Mo qw< default >;
has binmode => (default => ':raw');
has footer  => ();
has header  => ();
has interlude => ();
has output    => (default => \*STDOUT);
has policy    => (default => undef);
has track     => (
   default => sub {
      return {
         files       => 0,
         records     => 0,
         chars_file  => 0,
         chars_total => 0,
      };
   }
);

sub open {
   my ($self, $hint) = @_;

   # reset some tracking parameters
   my $track = $self->track();
   $track->{files}++;
   $track->{records}    = 0;
   $track->{chars_file} = 0;

   # get new filehandle
   my ($fh, $fh_releaser) =
     @{$track}{qw< current_fh current_fh_releaser>} = $self->get_fh($hint);

   # do header handling
   $self->_print($fh, $self->header(), $track);

   return $fh;
} ## end sub open

sub __open_file {
   my ($filename, $binmode) = @_;

   # ensure its directory exists
   make_path(dirname($filename), {error => \my $errors});
   if (@$errors) {
      my ($error) = values %{$errors->[0]};
      LOGCONFESS "make_path() for '$filename': $error";
   }

   # can open the file, at last
   CORE::open my $fh, '>', $filename
     or LOGCONFESS "open('$filename'): $OS_ERROR";
   binmode $fh, $binmode;

   return $fh;
} ## end sub __open_file

sub get_fh {
   my ($self, $handle) = @_;
   $handle //= $self->output();

   # define a default releaser, but not for GLOBs as they have their own
   # life outside of here
   my $releaser = ref($handle) eq 'GLOB' ? undef : sub {
      CORE::close $_[0] or LOGCONFESS "close(): $OS_ERROR";
      return undef;
   };

   # if $handle is a factory, treat it as such
   if (ref($handle) eq 'CODE') {
      my @items = $handle->($self);
      $handle = shift @items;

      # override the $releaser if and only if the factory instructed to
      # do so. Otherwise, the default one will be kept.
      $releaser = shift @items if @items;
   } ## end if (ref($handle) eq 'CODE')

   # now, we either have a filehandle, or a filename
   return ($handle, $releaser) if ref($handle) eq 'GLOB';
   return (__open_file($handle, $self->binmode()), $releaser);
} ## end sub get_fh

sub release_fh {
   my ($self, $fh) = @_;
   my $track = $self->track();
   if (my $releaser = delete $track->{current_fh_releaser}) {
      $releaser->($fh);
   }
   delete $track->{current_fh};
   return undef;
} ## end sub release_fh

sub close {
   my ($self, $fh, $track) = @_;

   # do footer handling
   $self->_print($fh, $self->footer(), $track);

   # call close, prepare $fh for other possible records
   return $self->release_fh($fh);
} ## end sub close

sub just_close {
   my $self  = shift;
   my $track = $self->track();
   my $fh    = $track->{current_fh} or return;
   $self->close($fh, $track);
   return;
} ## end sub just_close

sub print {
   my $self = shift;

   my $iterator  = ref($_[0]) && $_[0];
   my $checker   = $self->checker();
   my $track     = $self->track();
   my $fh        = $track->{current_fh};
   my $interlude = $self->interlude();

   while ('necessary') {
      my $record = $iterator ? $iterator->() : shift(@_);
      last unless defined $record;

      # get filehandle if needed
      $fh ||= $self->open();

      # print interlude if we have previous records, increase count
      $self->_print($fh, $interlude, $track)
        if $track->{records};

      # print record
      $self->_print($fh, $record, $track);

      # increment number of records, for next print
      $track->{records}++;

      # do checks if activated
      $fh = $self->close($fh, $track)
        if $checker && (!$checker->($self));
   } ## end while ('necessary')

   return;
} ## end sub print

sub _print {
   my ($self, $fh, $data, $track) = @_;
   return unless defined $data;
   $data = $data->($self) if ref $data;

   # do print data
   ref($fh) or LOGCONFESS("$fh is not a reference");
   print {$fh} $data or LOGCONFESS "print(): $OS_ERROR";

   # update trackers
   my $new_chars = length($data);
   $track->{chars_file}  += $new_chars;
   $track->{chars_total} += $new_chars;

   return $new_chars;
} ## end sub _print

sub default_check {
   my $self = shift;

   my $policy = $self->policy()
     or return 1;    # no policy, always fine
   my $track = $self->track();
   if (my $mr = $policy->{records_threshold}) {
      return 0 if $track->{records} >= $mr;
   }
   if (my $cpf = $policy->{characters_threshold}) {
      return 0 if $track->{chars_file} >= $cpf;
   }
   return 1;
} ## end sub default_check

sub checker {
   my $self = shift;

   # allow for overriding tout-court
   if (my $method = $self->can('check')) {
      return $method;    # will eventually be called in the right way
   }

   # if no policy is set, there's no reason to do checks
   my $policy = $self->policy() or return;

   # at this point, let's use the default_check, whatever it is
   return $self->can('default_check');
} ## end sub checker

sub DESTROY { shift->just_close() }

sub writer {
   my $package = shift;
   my $self    = $package->new(@_);
   return sub { return $self->print(@_) };
}

1;
