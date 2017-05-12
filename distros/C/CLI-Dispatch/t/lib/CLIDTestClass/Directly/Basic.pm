package CLIDTestClass::Directly::Basic;

use strict;
use warnings;
use Test::Classy::Base;
use Try::Tiny;

sub no_args : Test {
  my $class = shift;

  my $ret = $class->dispatch();

  ok $ret eq 'no args', $class->message("dispatch succeeded: $ret");
}

sub with_args : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( one two three ));

  ok $ret eq 'onetwothree', $class->message("dispatch succeeded: $ret");
}

sub with_options : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( --option=hello ));

  ok $ret eq 'hello', $class->message("dispatch succeeded: $ret");
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  my $ret;
  try   { $ret = CLIDTest::Directly::DumpMe->run_directly }
  catch { $ret = $_ || 'Obscure error' };

  return $ret;
}

no warnings 'redefine';

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
