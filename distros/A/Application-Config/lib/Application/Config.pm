package Application::Config;

use strict;
use warnings;

use Config::Tiny;
use File::HomeDir;

our $VERSION = '0.5';
our $CONFIG  = {};
our $FILE    = {};

sub import {
  my $class   = shift;
  my $cfgfile = shift;
  my $pkg     = shift;
  
  if (!$pkg) {
    ($pkg, undef, undef) = caller();
  }
  
  if (!$cfgfile) {
    my $cfgpkg = substr($pkg, rindex($pkg, ':') + 1);
    $cfgfile = lc($cfgpkg) . ".conf" ;
  }
  
  {
    no strict;

    *{$pkg."::config"} = sub {
      return $CONFIG{$pkg} if $CONFIG{$pkg};
      my @paths = (
        File::Spec->catfile( File::HomeDir->my_home, ".$cfgfile" ),
        ".$cfgfile",
        "./etc/$cfgfile",
        "/etc/$cfgfile"
      );
      foreach my $path (@paths) {
        if (-e $path) {
          $FILE{$pkg} = $path;
          return $CONFIG{$pkg} = Config::Tiny->read( $path );
        }
      }
      return {};
    };    

    *{$pkg.'::configfile'} = sub {
      return $FILE{$pkg};
    };
    
    *{$pkg."::pkgconfig"} = sub {
      my ($package, $filename, $line) = caller;
      return $pkg->config->{$package} || {};
    };
  }
  
}

=head1 NAME

  Application::Config - configuration for applications that makes less work
  
=head1 SYNOPSIS

  package Foo;
  
  use Application::Config;
  
  package Some::Other::Package;
  
  my $config = Foo->config;
  
=head1 DESCRIPTION

I find myself writing methods that fetch a config file for an application from
disk and return it all the time.  I come from the small-tools loosely joined school of thought,
which means I'm writing little applications all the time. This really sucks.  Application::Config solves that problem
for me.  It might solve it for you.  Who knows.

=head1 USAGE

When Application::Config is imported into a package it creates a two class
methods for the package.  The first, config, returns a Config::Tiny object
for the entire config file.  The second, pkgconfig, returns a hash reference
that contains the part of the config file relevent to the calling package. For
example the config file:

  foo=bar
  baz=bash
  
  [My::Test::Class]
  foo=baz

Would result in the config method returning a data structure that looks
something like:

  {
    '_' => {
      'foo' => 'bar',
      'baz' => 'bash'
    }
    'My::Test::Class' => {
      'foo' => 'baz'
    }
  }

Calling pkgconfig from the My::Test::Class package would return only the
structure under the C<My::Test::Class> key.

=head1 WHERE ARE THE CONFIG FILES ON DISK?

Application config looks, in this order, for a config file:

=over 4

=item ~/.<filename>

=item ./.<filename>

=item ./etc/<filename>

=item /etc/<filename>

=back

The actual filename varies based on the name of the package requiring the
Application::Config module.  For example the code:

  package MyPackage;
  
  use Application::Config;
  
would look for the filename mypackage.conf (or .mypackage.conf in the first
instance).

  package Another::MyPackage;
  
  use Application::Config;
  
Would look for the same config file.  This can be altered by providing an
argument to the Application::Config require line:

  package Another::MyPackage;
  
  use Application::Config 'myconfigfile.conf';
  
=head1 INSTALLING THE METHODS INTO ANOTHER PACKAGE 
 
All three of these uses would install the C<config> and C<pkgconfig> methods
into the requiring package.  If you'd like the methods to be installed
somewhere else, you can simply add a second argument to the require line that
is the package to install the methods in.

=head1 SEE ALSO

L<Config::Tiny>

=head1 AUTHOR

James A. Duncan <james@reasonablysmart.com>

Contributions from Scott McWhirter <smcwhirter |AT| joyent {DOT} com>

=head1 LICENSE

This module is released under the MIT license

=cut
