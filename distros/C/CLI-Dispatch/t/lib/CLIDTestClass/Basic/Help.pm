package CLIDTestClass::Basic::Help;

use strict;
use warnings;
use Test::Classy::Base;
use CLI::Dispatch;
use File::Spec;
use Try::Tiny;

sub list : Tests(4) {
  my $class = shift;

  $class->_command_list;
}

sub list_with_help_command : Tests(4) {
  my $class = shift;

  $class->_command_list(qw( help ));
}

sub pod_with_help_command : Tests(2) {
  my $class = shift;

  $class->_pod(qw( help simple ));
}

sub pod_with_help_option : Tests(2) {
  my $class = shift;

  $class->_pod(qw( simple --help ));
}

sub help_option_only : Tests(2) {
  my $class = shift;

  my $ret = $class->dispatch(qw( --help ));

  ok $ret =~ /SYNOPSIS/, $class->message('has synopsis');
  ok $ret !~ /CLI::Dispatch::Help -/, $class->message('name section is removed');
}

sub _command_list {
  my $class = shift;

  my $ret = $class->dispatch(@_);

  my %map = (
    help    => 'help\s+-',
    simple  => 'simple\s+- simple test',
    args    => 'with_args\s+- args test',
    options => 'with_options\s+- option test',
  );

  foreach my $key ( keys %map ) {
    like $ret => qr/$map{$key}/, $class->message("has $key");
  }
}

sub _pod {
  my $class = shift;

  my $ret = $class->dispatch(@_);

  ok $ret =~ /simple dispatch test/, $class->message('has description');
  ok $ret !~ /simple test/, $class->message('brief description is removed');
}

sub dispatch {
  my $class = shift;

  local @ARGV = @_;

  open my $null, '>', File::Spec->devnull;
  my $stdout = select($null);

  my $ret;
  try   { $ret = CLI::Dispatch->run('CLIDTest::Basic') }
  catch { $ret = $_ || 'Obscure error' };

  select($stdout);

  return $ret;
}

1;
