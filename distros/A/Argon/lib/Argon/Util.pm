package Argon::Util;
# ABSTRACT: Utilities used in Argon classes
$Argon::Util::VERSION = '0.18';

use strict;
use warnings;
use Carp;
use AnyEvent;
use Scalar::Util qw(weaken);
use Argon::Log;


use parent 'Exporter';

our @EXPORT_OK = (
  qw(K param interval),
);


sub K ($$;@) {
  my $name = shift;
  my $self = shift;
  my @args = @_;

  my $method = $self->can($name);

  unless ($method) {
    croak "method $name not found";
  }

  weaken $self;
  weaken $method;

  sub { $method->($self, @args, @_) };
}


sub param ($\%;$) {
  my $key   = shift;
  my $param = shift;
  if (!exists $param->{$key} || !defined $param->{$key}) {
    if (@_ == 0) {
      croak "expected parameter '$key'";
    }
    else {
      my $default = shift;
      return (ref $default && ref $default eq 'CODE')
        ? $default->()
        : $default;
    }
  }
  else {
    return $param->{$key};
  }
}


sub interval (;$) {
  my $intvl = shift || 1;
  my $count = 0;

  return sub {
    my $reset = shift;

    if ($reset) {
      $count = 0;
      return;
    }

    my $inc = log($intvl * ($count + 1));
    ++$count;

    return $intvl + $inc;
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Argon::Util - Utilities used in Argon classes

=head1 VERSION

version 0.18

=head1 DESCRIPTION

Utility functions used in Argon classes.

=head1 EXPORTS

No subroutines are exported by default.

=head1 SUBROUTINES

=head2 K

Creates a callback function that calls a method on an object instance with
arbitrary arguments while preventing circular references from closing over the
method or object instance itself.

  my $callback = K('method_name', $self, $arg1, $arg2, ...);

=head2 param

Extracts a parameter from an argument hash.

  sub thing{
    my ($self, %param) = @_;
    my $foo = param 'foo', %param, 'default'; # equivalent: $param{foo} // 'default';
    my $bar = param 'bar', %param;            # equivalent: $param{bar} // croak "expected parameter 'bar'";
  }

=head2 interval

Returns a code ref that, when called, returns an increasing interval value to
simplify performing a task using a logarithmic backoff. When the code ref is
called with an argument (a truthy one), the backoff will reset back to the
original argument.

  my $intvl = interval 5;

  until (some_task_succeeds()) {
    sleep $intvl->();
  }

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
