package Data::Embed::File;

# ABSTRACT: embed arbitrary data in a file

use strict;
use warnings;
use English qw< -no_match_vars >;
use IO::Slice;
use Fcntl qw< :seek >;
use Log::Log4perl::Tiny qw< :easy >;
use Scalar::Util qw< refaddr blessed >;

our $VERSION = '0.32'; # make indexer happy

sub new {
   my $package = shift;
   my $self = {(scalar(@_) && ref($_[0])) ? %{$_[0]} : @_};
   for my $feature (qw< offset length >) {
      LOGCROAK "$package new(): missing required field $feature"
        unless defined($self->{$feature})
        && $self->{$feature} =~ m{\A\d+\z}mxs;
   }
   LOGDIE "$package new(): either filename or fh are required"
     unless defined($self->{fh}) || defined($self->{filename});
   return bless $self, $package;
} ## end sub new

sub fh {
   my $self = shift;
   if (!exists $self->{slicefh}) {
      my %args = map { $_ => $self->{$_} }
        grep { defined $self->{$_} } qw< fh filename offset length >;
      $self->{slicefh} = IO::Slice->new(%args);
   }
   return $self->{slicefh};
} ## end sub fh

sub contents {
   my $self    = shift;
   my $fh      = $self->fh();
   my $current = tell $fh;
   seek $fh, 0, SEEK_SET;

   local $/ = wantarray() ? $/ : undef;
   my @retval = <$fh>;
   seek $fh, $current, SEEK_SET;
   return @retval if wantarray();
   return $retval[0];
} ## end sub contents

sub name { return shift->{name}; }

sub _dname {
   my $name = shift->{name};
   return $name if defined $name;
   return '';
}

sub is_same_as {
   my ($self, $other) = @_;
   return unless blessed($other);
   return unless $other->isa('Data::Embed::File');

   # quick wins
   return unless $self->{offset} == $other->{offset};
   return unless $self->{length} == $other->{length};

   # names must be the same
   return unless $self->_dname() eq $other->_dname();

   # check data sources
   if (defined $self->{fh}) {
      return unless defined $other->{fh};
      return refaddr($self->{fh}) eq refaddr($other->{fh});
   }
   elsif (defined $self->{filename}) {
      return unless defined $other->{filename};    # paranoid...
      if (ref $self->{filename}) {
         return unless ref $other->{filename};
         return refaddr($self->{filename}) eq refaddr($other->{filename});
      }
      return $self->{filename} eq $other->{filename};
   } ## end elsif (defined $self->{filename...})
   else {                                          # paranoid!
      return;
   }

   return 1;                                       # you made it!
} ## end sub is_same_as

1;
