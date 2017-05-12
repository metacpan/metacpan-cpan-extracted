package CLIDTestClass::Sub::SubHelp;

use strict;
use warnings;
use Test::Classy::Base;
use CLI::Dispatch;
use File::Spec;
use Try::Tiny;

sub list : Tests(5) {
  my $class = shift;

  $class->_command_list(qw( cmd ));
}

sub list_with_help_command : Tests(5) {
  my $class = shift;

  $class->_command_list(qw( cmd help ));
}

sub help_of_missing_file : Tests(5) {
  my $class = shift;

  $class->_command_list(qw( cmd help nothing ));
}

sub unknown_command : Tests(5) {
  my $class = shift;

  $class->_command_list(qw( cmd unknown_command ));
}

sub pod_with_help_command : Tests(2) {
  my $class = shift;

  $class->_pod(qw( cmd help simple_sub ));
}

sub pod_with_help_option : Tests(2) : Skip("doesn't work for a subcommand") {
  my $class = shift;

  # NOTE: this is recognized to show pod of Cmd, not of SimpleSub.
  $class->_pod(qw( cmd simple_sub --help ));
}

sub _command_list {
  my $class = shift;

  my $ret = $class->dispatch(@_);

  my %map = (
    help    => 'help\s+-',
    install => 'install\s+- how to install',
    simple  => 'simple_sub\s+- alternative text for simple subcommand',
    args    => 'with_args_sub\s+- args test',
    options => 'with_options_sub\s+- option test',
  );

  foreach my $key ( keys %map ) {
    like $ret => qr/$map{$key}/, $class->message("has $key");
  }
}

sub _pod {
  my $class = shift;

  my $ret = $class->dispatch(@_);

  ok $ret =~ /simple manual/, $class->message('has description');
  ok $ret !~ /alternative text for simple subcommand/, $class->message('brief description is removed');
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  open my $null, '>', File::Spec->devnull;
  my $stdout = select($null);

  my $ret;
  try   { $ret = CLI::Dispatch->run('CLIDTest::Sub') }
  catch { $ret = $_ || 'Obscure error' };

  select($stdout);

  return $ret;
}

1;
