use strict;
use warnings;

package App::autotest::Test::Runner::Result;
$App::autotest::Test::Runner::Result::VERSION = '0.006';
# ABSTRACT: represents the result of a test run

use Moose;

has harness_result => (
  is      => 'rw',
  isa     => 'TAP::Parser::Aggregator'
);

sub has_failures {
  my ($self)=@_;

  return $self->harness_result->failed > 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::autotest::Test::Runner::Result - represents the result of a test run

=head1 VERSION

version 0.006

=head1 AUTHOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
