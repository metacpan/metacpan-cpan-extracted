package Bot::ChatBots::Weak;
use strict;
use warnings;
{ our $VERSION = '0.008'; }

use Scalar::Util qw< weaken >;

sub clone {
   my $self = shift;
   return ref($self)->new($self);
}

sub get {
   my ($self, $key) = @_;
   return $self->{$key};
}

sub get_multiple {
   my $self = shift;
   return @{$self}{@_};
}

sub new {
   my $package = shift;
   my $self = bless {}, $package;
   return $self->set(@_);
}

sub set {
   my $self = shift;
   my @args = (@_ && ref($_[0])) ? %{$_[0]} : @_;
   while (@args) {
      my ($key, $value) = splice @args, 0, 2;
      $self->{$key} = $value;
      weaken($self->{$key}) if ref $value;
   }
   return $self;
} ## end sub set

sub TO_JSON { return undef }

1;
