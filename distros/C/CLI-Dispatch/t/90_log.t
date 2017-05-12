use strict;
use warnings;
use lib 't/lib';
use Test::Classy;

load_tests_from 'CLIDTestClass::Log';
run_tests;

exit;

package #
  CLIDTest::Log::DumpMe;

use base qw( CLI::Dispatch::Command );

sub run {
  my ($self, @args) = @_;

  $self->log(debug => 'debug');
  $self->log(info  => 'info');
  $self->log(warn  => 'warn');
  $self->log(error => 'error');

  return 'ok';
}

1;

__END__

=head1 NAME

CLIDTest::Log::DumpMe - log me

=head1 DESCRIPTION

single command test
