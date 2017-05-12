package Coro::Generator;

=head1 NAME

Coro::Generator - Create generators using Coro

=head1 SYNOPSIS

  use 5.10.0; # This module does NOT require 5.10, but 'say' does
  use strict;
  use Coro::Generator;

  my $even = generator {
    my $x = 0;
    while(1) {
      $x++; $x++;
      yield $x;
    }
  };

  for my $i (1..10) {
    say $even->();
  }

=head1 DESCRIPTION

In the words of wikipedia, generators look like functions but act like
iterators.

=head2 EXPORT

generator, yield

=cut

use strict;
use Coro;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(generator yield);
our $VERSION = '0.02';

our @yieldstack;
our $retval;
our @params;

sub generator (&) {
  my $code = shift;
  my $prev = new Coro::State;
  my $coro = Coro::State->new(sub {
    yield();
    $code->(@params) while 1;
  });
  push @yieldstack, [$coro, $prev];
  $prev->transfer($coro);
  return sub {
    @params = @_;
    push @yieldstack, [$coro, $prev];
    $prev->transfer($coro);
    return $retval;
  };
}

sub yield {
  $retval = shift;
  my ($coro, $prev) = @{pop @yieldstack};
  $coro->transfer($prev);
  return wantarray ? @params : $params[0];
}

=head1 SEE ALSO

L<Coro>

=head1 AUTHOR

Brock Wilcox, E<lt>awwaiid@thelackthereof.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Brock Wilcox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

