package Acme::Globule;
BEGIN {
  $Acme::Globule::DIST = 'Acme-Globule';
}
BEGIN {
  $Acme::Globule::VERSION = '0.004';
}
# ABSTRACT: Extensible package-local way to override glob()
use warnings;
use strict;

# a quick dance to get at the glob()/<> implementation that we replace with
# a wrapper
use File::Glob qw( csh_glob );
my $csh_glob = \&csh_glob;

use Module::Load;

# This is a hash mapping packages that use us to the Globule plugins they
# requested.
my %clients;

# This is a hash of plugins that have been pulled in so far, and maps to the
# name of the package that actually implements the plugin.
my %plugins;

sub import {
    my($self, @plugins) = @_;
    my($importer) = caller;

    foreach my $plugin (@plugins) {
        unless (defined $plugins{$plugin}) {
            my $pkgname = __PACKAGE__."::$plugin";
            load $pkgname;
            $plugins{$plugin} = $pkgname;
        }
    }

    $clients{$importer} =  \@plugins;
}

sub _new_csh_glob {
    my($pattern) = @_;
    my($caller) = caller;  # contains package of caller, or (eval) etc, but
    # will match an entry in %clients for any package
    # that imported us
    if (my $client = $clients{$caller}) {
        # The caller imported us, so we work through the plugins they requested
        foreach my $plugin (@$client) {
            # Try the pattern against each plugin in turn, until one returns a
            # true value. This is assumed to be an arrayref that contains the
            # result of the glob
            my $result = $plugins{$plugin}->globule($pattern);
            return @$result if $result;
        }
    }
    # Since no plugins matched (or the caller didn't import us), we fall
    # through to the original glob function
    goto &$csh_glob;
}

no warnings;              # we don't want "subroutine redefined" diagnostics
*File::Glob::csh_glob = \&_new_csh_glob;
*CORE::GLOBAL::glob = \&File::Glob::csh_glob;

1;


1;

__END__
=pod

=head1 NAME

Acme::Globule - Extensible package-local way to override glob()

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 # a simple plugin
 package Acme::Globule::Ping;

 sub globule {
   my($self, $pattern) = @_;
   # somebody did <ping> and so we want to return ('pong')
   return [ "pong" ] if $pattern eq 'ping';
   # they didn't ping, so pass
   return;
 }

 # a simple client
 package main;

 use Acme::Globule qw( Ping );

 # prints "pong'
 print <ping>;
 # prints the location of your home directory
 print <~>;

=head1 DESCRIPTION

This package extends glob (and thus <>) to return custom results. It has a
plugin mechanism and you define which plugins you wish to use on the import
line. Now when you call glob(), these plugins will be tried left-to-right
until one claims it, with a fall-through to the standard glob() function.

Each of your packages may use different plugins, and packages that do not
import Acme::Globule will get standard glob() behaviour.

=head1 Creating a plugin

To create a plugin, create a module Acme::Globule::* and provide a globule()
method. The globule method should return an array reference containing the
matches, or nothing if it wishes to decline and let the next plugin try it.

=head1 BUGS

Any code that uses this module is perverse and therefore contains at least
one bug.

This module globally hooks both File::Glob::csh_glob CORE::GLOBAL::glob, and
so using this module anywhere in a program will cause all uses of glob() to
suffer a slight performance hit even in other modules which do not use it.

glob() within an eval() will probably not do what you expect.

=head1 SEE ALSO

Acme::Globule::*, the plugins.

=head1 AUTHOR

Peter Corlett <abuse@cabal.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Corlett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

