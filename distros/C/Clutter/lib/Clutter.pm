package Clutter;
{
  $Clutter::VERSION = '1.110';
}

use strict;
use warnings;
use Carp qw/croak/;
use Cairo::GObject;
use Glib::Object::Introspection;
use Exporter;

our @ISA = qw(Exporter);

my $_CLUTTER_BASENAME = 'Clutter';
my $_CLUTTER_VERSION = '1.0';
my $_CLUTTER_PACKAGE = 'Clutter';

sub import {
  my $class = shift;

  Glib::Object::Introspection->setup (
    basename => $_CLUTTER_BASENAME,
    version => $_CLUTTER_VERSION,
    package => $_CLUTTER_PACKAGE,
  );
}

# - Overrides --------------------------------------------------------------- #

sub Clutter::CHECK_VERSION {
  return not defined Clutter::check_version(@_ == 4 ? @_[1..3] : @_);
}

sub Clutter::check_version {
  Glib::Object::Introspection->invoke ($_CLUTTER_BASENAME, undef, 'check_version',
                                       @_ == 4 ? @_[1..3] : @_);
}

sub Clutter::init {
  my $rest = Glib::Object::Introspection->invoke (
               $_CLUTTER_BASENAME, undef, 'init',
               [$0, @ARGV]);
  @ARGV = @{$rest}[1 .. $#$rest]; # remove $0
  return;
}

sub Clutter::main {
  # Ignore any arguments passed in.
  Glib::Object::Introspection->invoke ($_CLUTTER_BASENAME, undef, 'main');
}

sub Clutter::main_quit {
  # Ignore any arguments passed in.
  Glib::Object::Introspection->invoke ($_CLUTTER_BASENAME, undef, 'main_quit');
}

sub Gtk3::Builder::add_from_string {
  my ($builder, $string) = @_;
  return Glib::Object::Introspection->invoke (
    $_CLUTTER_BASENAME, 'Script', 'add_from_string',
    $builder, $string, length $string);
}

# Copied from Gtk2.pm
sub Clutter::Script::connect_signals {
  my $builder = shift;
  my $user_data = shift;

  my $do_connect = sub {
    my ($object,
        $signal_name,
        $user_data,
        $connect_object,
        $flags,
        $handler) = @_;
    my $func = ($flags & 'after') ? 'signal_connect_after' : 'signal_connect';
    # we get connect_object when we're supposed to call
    # signal_connect_object, which ensures that the data (an object)
    # lives as long as the signal is connected.  the bindings take
    # care of that for us in all cases, so we only have signal_connect.
    # if we get a connect_object, just use that instead of user_data.
    $object->$func($signal_name => $handler,
                   $connect_object ? $connect_object : $user_data);
  };

  # $builder->connect_signals ($user_data)
  # $builder->connect_signals ($user_data, $package)
  if ($#_ <= 0) {
    my $package = shift;
    $package = caller unless defined $package;

    $builder->connect_signals_full(sub {
      my ($builder,
          $object,
          $signal_name,
          $handler_name,
          $connect_object,
          $flags) = @_;

      no strict qw/refs/;

      my $handler = $handler_name;
      if (ref $package) {
        $handler = sub { $package->$handler_name(@_) };
      } else {
        if ($package && $handler !~ /::/) {
          $handler = $package.'::'.$handler_name;
        }
      }

      $do_connect->($object, $signal_name, $user_data, $connect_object,
                    $flags, $handler);
    });
  }

  # $builder->connect_signals ($user_data, %handlers)
  else {
    my %handlers = @_;

    $builder->connect_signals_full(sub {
      my ($builder,
          $object,
          $signal_name,
          $handler_name,
          $connect_object,
          $flags) = @_;

      return unless exists $handlers{$handler_name};

      $do_connect->($object, $signal_name, $user_data, $connect_object,
                    $flags, $handlers{$handler_name});
    });
  }
}

1;

__END__

# - Docs -------------------------------------------------------------------- #

=head1 NAME

Clutter - Perl interface to the 1.x series of the Clutter toolkit

=head1 SYNOPSIS

  use Clutter;

  die unless Clutter::init() eq 'success';

  Clutter::main;

=head1 ABSTRACT

Perl bindings to the 1.x series of the Clutter toolkit. This module allows you
to write dynamic, compelling, graphical user interfaces in a Perlish and
object-oriented way, freeing you from the casting and memory management in C,
yet remaining very close in spirit to original API.

=head1 DESCRIPTION

FIXME

=head1 SEE ALSO

=over

=item L<Glib>

=item L<Glib::Object::Introspection>

=back

=head1 AUTHORS

=encoding utf8

=over

=item Emmanuele Bassi <ebassi@gnome.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 by Emmanuele Bassi <ebassi@gnome.org>

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

=cut
