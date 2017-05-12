package CLIDTest::Error::WithArgs;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub run {
  my $self = shift;

  return join '', @_;
}

die "intentionally";

1;

__END__

=head1 NAME

CLIDTest::Error::WithArgs - args test

=head1 DESCRIPTION

test with args
