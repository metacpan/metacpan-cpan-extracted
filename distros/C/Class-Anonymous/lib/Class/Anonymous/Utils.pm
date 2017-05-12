package Class::Anonymous::Utils;

use strict;
use warnings;

use Carp;
use Exporter 'import';

our @EXPORT_OK = qw/method before after around/;

our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

sub method {
  croak "'method' requires a name and a callback" unless @_ == 2;
  my ($name, $cb) = @_;
  $Class::Anonymous::CURRENT->($name => $cb);
}

sub before {
  croak "'before' requires a name and a callback" unless @_ == 2;
  my ($name, $cb) = @_;
  my $old = $Class::Anonymous::CURRENT->($name);
  croak "$name is not a method of the object" unless $old;
  my $new = sub {
    my $self = shift;
    my $want = wantarray;
    if ($want) {
      ()   = $self->$cb(@_);
      return $self->$old(@_);
    } elsif (defined $want) {
      scalar $self->$cb(@_);
      return $self->$old(@_);
    } else {
      $self->$cb(@_);
      $self->$old(@_);
    }
  };
  $Class::Anonymous::CURRENT->($name => $new);
}

sub after {
  croak "'after' requires a name and a callback" unless @_ == 2;
  my ($name, $cb) = @_;
  my $old = $Class::Anonymous::CURRENT->($name);
  croak "$name is not a method of the object" unless $old;
  my $new = sub {
    my $self = shift;
    my $want = wantarray;
    if ($want) {
      my @ret = $self->$old(@_);
      ()      = $self->$cb(@_);
      return @ret;
    } elsif (defined $want) {
      my $ret = $self->$old(@_);
      scalar    $self->$cb(@_);
      return $ret;
    } else {
      $self->$old(@_);
      $self->$cb(@_);
    }
  };
  $Class::Anonymous::CURRENT->($name => $new);
}

sub around {
  croak "'around' requires a name and a callback" unless @_ == 2;
  my ($name, $cb) = @_;
  my $old = $Class::Anonymous::CURRENT->($name);
  croak "$name is not a method of the object" unless $old;
  $Class::Anonymous::CURRENT->($name => sub { $cb->($old, @_) });
}

1;

