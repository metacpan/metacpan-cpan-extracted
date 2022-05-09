# -*- mode: cperl; mode: follow; -*-
#

package App::Regather::Plugin;

=head1 NAME

App::Regather::Plugin - plugin (module) loader

=head1 DESCRIPTION

This module provides implementation of arbitrary plugin (module)
loader.

=cut

use strict;
use warnings;
use diagnostics;
use feature 'state';

use Carp;
use File::Basename;
use File::Spec;

=head1 CONSTRUCTOR

=head2 new($class, ...)

A command object fabric.  Looks for a perl module for B<$class>, loads
it and returns an instance of that class.  Surplus arguments (B<...>)
are passed as parameters to the underlying class constructor.

Input data for plugin is a hash:

      cf           reference to Config class object
      force        force all actions done on start
      log          reference to Logg class object
      obj          reference to Net::LDAP object
      out_file_old ... looks like it is not needed any more ...
      prog         program name and version
      rdn          RDN of a LDAP object event relates to
      s            service
      st           syncrepl state
      ts_fmt       timestamp format
      v            verbosity

Each plugin should provide two methods

ldap_sync_add_modify and ldap_sync_delete

=cut

sub new {
  my ($class, $command, @args) = @_;
  croak __PACKAGE__ . ': command not supplied' unless $command;
  my $modname = __PACKAGE__ . '::' . $command;
  my $modpath = $modname;
  $modpath =~ s{::}{/}g;
  $modpath .= '.pm';
  my $cmd = eval { require $modpath; $modname->new(@args) };
  if ( $@ ) {
    if ($@ =~ /Can't locate $modpath/) {
      die __PACKAGE__ . ": unknown command: $command\n"
    }
    croak __PACKAGE__ . ': ERROR: ' . $@;
  }
  return $cmd;
}

=head2 names

Returns hash of plugins available, where key is a plugin name and the
value is path to plugin file.

For each plugin an attempt is made to load it, to ensure the module is
usable.

=cut

sub names {
  my $self = shift;
  my @classpath = split(/::/, $self);
  state $return //= {
    map { $_->[0] => $_->[1] }
    map {
      my $name     = basename($_);
      my $filename = File::Spec->catfile(@classpath, $name);
      if (exists($INC{$filename})) {
	()
      } else {
	eval { require $filename; };
	$name =~ s/\.pm$//;
	$@ ? () : [$name, $_];
      }
    }
    sort map { glob File::Spec->catfile($_, @classpath,	'*.pm') } @INC
  };

  return %$return;
}

######################################################################

1;
