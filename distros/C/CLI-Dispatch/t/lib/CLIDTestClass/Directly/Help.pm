package CLIDTestClass::Directly::Help;

use strict;
use warnings;
use Test::Classy::Base;
use File::Spec;
use Try::Tiny;

sub help_command : Test {
  my $class = shift;

  my $ret = $class->dispatch(qw( help ));

  ok $ret eq 'help', $class->message('help command is ignored');
}

sub help_option : Tests(2) {
  my $class = shift;

  my $ret = $class->dispatch(qw( --help ));

  ok $ret =~ /single command test/, $class->message('has description');
  ok $ret !~ /help me/, $class->message('name section is removed');
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  open my $null, '>', File::Spec->devnull;
  my $stdout = select($null);

  my $ret;
  try   { $ret = CLIDTest::Directly::HelpMe->run_directly }
  catch { $ret = $_ || 'Obscure error' };

  select($stdout);

  return $ret;
}

no warnings 'redefine';

package #
  CLIDTest::Directly::HelpMe;

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

CLIDTest::Directly::HelpMe - help me

=head1 DESCRIPTION

single command test
