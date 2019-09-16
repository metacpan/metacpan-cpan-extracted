# This module provides various helper function used throughout the program.

package App::PTP::Util;

use 5.022;
use strict;
use warnings;

# More or less the same as List::Util::uniqstr (or List::Util::uniq). Provided
# here because the List::Util function is not available in 5.22 by default.
sub uniqstr {
  my ($content, $markers) = @_;
  for my $i (0 .. $#$content - 1) {
    if ($content->[$i] eq $content->[$i+1]) {
      undef $content->[$i];
      undef $markers->[$i];
    }
  }
  @$content = grep { defined } @$content;
  @$markers = grep { defined } @$markers;
}

# Globally delete duplicate lines even if they are not contiguous. Keep the
# first occurence of each string.
sub globaluniqstr  {
  my ($content, $markers) = @_;
  my %seen;
  for my $i (0 .. $#$content) {
    if ($seen{$content->[$i]}++) {
      undef $content->[$i];
      undef $markers->[$i];
    }
  }
  @$content = grep { defined } @$content;
  @$markers = grep { defined } @$markers;
}

{
  # A simple way to make a scalar be read-only.
  package App::PTP::Util::ReadOnlyVar;
  sub TIESCALAR {
    my ($class, $value) = @_;
    return bless \$value, $class;
  }
  sub FETCH {
    my ($self) = @_;
    return $$self;
  }
  # Does nothing. We could warn_or_die, but it does not play well with the fact
  # that we are inside the safe.
  sub STORE {}
  # Secret hidden methods for our usage only. These methods can't be used
  # through the tie-ed variable, but only through the object returned by the
  # call to tie.
  sub set {
    my ($self, $value) = @_;
    $$self = $value;
  }
  sub get {
    my ($self, $value) = @_;
    return $$self;
  }
  sub inc {
    my ($self) = @_;
    ++$$self;
  }
}

{
  # A simple way to make a scalar be an alias of another one (but does not allow
  # to store undef in the variable as this is used to mark non-existant lines
  # in some function and this package is tied to the marker variable).
  package App::PTP::Util::AliasVar;
  sub TIESCALAR {
    my ($class) = @_;
    my $var;
    return bless \$var, $class;
  }
  sub FETCH {
    my ($self) = @_;
    return $$$self;
  }
  sub STORE {
    my ($self, $value) = @_;
    # This empty string is also the value that is set in do_perl when the marker
    # is undef (this is not the same as the default 0 that is put when the array
    # is built).
    $$$self = $value // '';
  }
  # Secret hidden methods for our usage only. These methods can't be used
  # through the tie-ed variable, but only through the object returned by the
  # call to tie.
  sub set {
    my ($self, $ref) = @_;
    $$self = $ref;
  }
}

{
  # A fake array that returns the marker at a given offset from the current
  # line (and refuses to store undef in the array).
  package App::PTP::Util::MarkersArray;
  our $NEGATIVE_INDICES = 1;
  sub TIEARRAY {
    my ($class, $markers, $n) = @_;
    my $this = [$markers, $n];
    return bless $this, $class;
  }
  sub FETCH {
    my ($self, $offset) = @_;
    my $index = ($$self->[1] - 1 + $offset);
    return 0 if $index < 0;
    return 0 if $index >= $self->FETCHSIZE();
    return $self->[0][$index];
  }
  sub FETCHSIZE {
    my ($self) = @_;
    return scalar(@App::PTP::Commands::markers);
  }
  sub STORE {
    my ($self, $offset, $value) = @_;
    my $index = ($$self->[1] - 1 + $offset);
    return $value if $index < 0;
    return $value if $index >= $self->FETCHSIZE();
    $self->[0][$index] = $value // '';  # make it more difficult to store undef
  }
  sub STORESIZE {}
}

1;
