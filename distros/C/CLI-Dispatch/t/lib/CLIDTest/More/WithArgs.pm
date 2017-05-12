package CLIDTest::More::WithArgs;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub run {
  my $self = shift;

  return join '', @_;
}

1;

__END__

=head1 NAME

CLIDTest::More::WithArgs - args test

=head1 DESCRIPTION

test with args
