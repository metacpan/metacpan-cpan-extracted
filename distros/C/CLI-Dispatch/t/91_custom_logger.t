use strict;
use warnings;
use lib 't/lib';
use Test::Classy;

load_tests_from 'CLIDTestClass::CustomLogger';
run_tests;

exit;

package #
  CLIDTest::CustomLogger::DumpMe;

use base qw( CLI::Dispatch::Command );

our $Logger;

sub log {
  my $self = shift;
  ($self->{verbose} || $self->{debug}) && $Logger && $Logger->log(@_);
}

sub run {
  my ($self, @args) = @_;

  if ($self->{debug}) {
    $Logger->set_level(stderr => { maxlevel => 'debug' });
  }

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
