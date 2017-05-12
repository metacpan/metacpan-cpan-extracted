package CLIDTest::Basic::WithArgs;

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

CLIDTest::Basic::WithArgs - args test

=head1 DESCRIPTION

test with args
