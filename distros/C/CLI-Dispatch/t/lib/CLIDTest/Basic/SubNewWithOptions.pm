package CLIDTest::Basic::SubNewWithOptions;

use strict;
use warnings;
use base qw( CLI::Dispatch::Command );

sub options {qw( path|p=s )}

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

CLIDTest::Basic::SubNewWithOptions- new subroutine option test

=head1 DESCRIPTION

test with new and options
