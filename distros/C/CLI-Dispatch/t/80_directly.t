use strict;
use warnings;
use lib 't/lib';
use Test::Classy;

load_tests_from 'CLIDTestClass::Directly';
run_tests;

exit;

package #
  CLIDTest::Directly::DumpMe;

use base qw( CLI::Dispatch::Command );

sub options {qw( option=s )}

sub run {
  my ($self, @args) = @_;

  my $text;
  if ( @args ) {
    $text = join '', @args;
  }
  elsif ( $self->option('option') ) {
    $text = $self->option('option');
  }
  else {
    $text = 'no args';
  }

  return $text;
}

1;

__END__

=head1 NAME

CLIDTest::Directly::DumpMe - dump me

=head1 DESCRIPTION

single command test
