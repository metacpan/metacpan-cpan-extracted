package CLIDTest::Basic::WithOptions;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub options {qw( hello target|t=s )}

sub run {
  my ($self, @args) = @_;

  my $hello = $self->option('hello') ? 'hello' : 'goodbye';

  return join ' ', $hello, $self->option('target');
}

1;

__END__

=head1 NAME

CLIDTest::Basic::WithOptions - option test

=head1 DESCRIPTION

test with options
