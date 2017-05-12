use strict;
use warnings;

package App::autotest::Test::Runner;
$App::autotest::Test::Runner::VERSION = '0.006';
# ABSTRACT: runs tests

use Moose;
use TAP::Harness;
use App::autotest::Test::Runner::Result;

has harness => (
  is      => 'rw',
  isa     => 'TAP::Harness',
  default => sub { _default_harness() }
);

has result => (
  is  => 'rw',
  isa => 'App::autotest::Test::Runner::Result'
);

sub run {
  my ( $self, @tests ) = @_;

  my $harness_result = $self->harness->runtests(@tests);
  my $result =
    App::autotest::Test::Runner::Result->new( harness_result => $harness_result );
  $self->result($result);
}

sub had_failures {
  my ($self)=@_;

  return $self->result->has_failures;
}


sub _default_harness {
    my $args = {
        verbosity => -3,
        lib       => [ 'lib', 'blib/lib', 'blib/arch' ],
    };
    return TAP::Harness->new($args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::autotest::Test::Runner - runs tests

=head1 VERSION

version 0.006

=head1 INTERNAL METHODS

=head1 AUTHOR

Gregor Goldbach <glauschwuffel@nomaden.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gregor Goldbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
