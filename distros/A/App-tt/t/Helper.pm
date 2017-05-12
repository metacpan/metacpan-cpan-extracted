package t::Helper;
use strict;
use warnings;
use File::Basename;
use File::Spec;
use File::Path ();
use Test::More;

$ENV{TIMETRACKER_HOME} ||= File::Spec->catdir('t', '.TimeTracker-' . basename($0));
File::Path::remove_tree($ENV{TIMETRACKER_HOME}) if -d $ENV{TIMETRACKER_HOME};

sub _out {
  my $tt = shift;
  my $str = sprintf shift, @_;
  diag "$str" if $ENV{APP_TT_DEBUG} and $str =~ /\S/;
  $main::out .= "$str\n";
}

sub tt {
  my $path = File::Spec->catfile(qw(script tt));
  plan skip_all => "Cannot find $path" unless -f $path;
  my $script = do $path || die $@;
  my $class = ref $script;
  no strict 'refs';
  no warnings 'redefine';
  *{"$class\::_diag"} = \&_out;
  *{"$class\::_say"}  = \&_out;
  return $script;
}

sub import {
  my $class  = shift;
  my $caller = caller;

  $main::out = '';
  strict->import;
  warnings->import;
  eval "package $caller;use Test::More;1" or die $@;
}

1;
