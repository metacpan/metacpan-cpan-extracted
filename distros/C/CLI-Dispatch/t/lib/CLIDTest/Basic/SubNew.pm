package CLIDTest::Basic::SubNew;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub new {
  my $class = shift;
  my %opt = (
    path => '/var/tmp/',
  );
  bless \%opt, $class;
}

sub run {
  my $self = shift;
  my $path = $self->{path} || "destroyed";
  return $path;
}

1;

__END__

=head1 NAME

CLIDTest::Basic::SubNew- new subroutine test

=head1 DESCRIPTION

test with new
