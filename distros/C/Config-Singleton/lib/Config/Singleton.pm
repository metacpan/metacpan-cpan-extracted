use 5.006;
use warnings;
use strict;
package Config::Singleton;
# ABSTRACT: one place for your app's configuration
$Config::Singleton::VERSION = '0.005';
use Cwd ();
use File::Basename ();
use File::HomeDir ();
use File::Spec ();
use YAML::XS ();

use Sub::Exporter -setup => {
  groups => [ setup => \'_build_config_methods' ],
};

#pod =head1 SYNOPSIS
#pod
#pod   package YourApplication::Config;
#pod
#pod   use Config::Singleton -setup => {
#pod     filename => 'something.yaml',
#pod     template => {
#pod       foo => undef,
#pod       bar => 1024,
#pod       qux => [ 1, 2, 3],
#pod     },
#pod   };
#pod
#pod Elsewhere...
#pod
#pod   use YourApplication::Config 'my_instance_config.yml';
#pod
#pod   my $foo = YourApplication::Config->foo;
#pod
#pod =head1 DESCRIPTION
#pod
#pod Config::Singleton provides a base class for access to configuration data for
#pod your app. The basic implementation stores its configuration in YAML in a text
#pod file found in all the usual places. By default, Config::Singleton looks for
#pod myapp.yml, but an alternate filename may be passed when using the module.
#pod
#pod This module was derived from L<Rubric::Config|Rubric::Config>.
#pod
#pod =head1 USING APP::CONFIG
#pod
#pod The L</SYNOPSIS> section, above, demonstrates an example of almost every
#pod feature of Config::Singleton  It's a very simple module with a very small
#pod interface.
#pod
#pod It is not a base class.  It is a utility for setting up a class that stores
#pod loaded configuration data.  You just need to C<use> the module like this:
#pod
#pod   package Your::Config;
#pod
#pod   use Config::Singleton -setup => {
#pod     filename => 'your_program.yaml',
#pod     template => {
#pod       username => undef,
#pod       hostname => undef,
#pod       logfile  => undef,
#pod       facility => 'local1',
#pod       path     => [ qw(/var/spool /tmp/jobs) ],
#pod     },
#pod   };
#pod
#pod When another module uses Your::Config, F<your_program.yaml> will be loaded and
#pod its contents will be merged over the defaults given by the C<template>
#pod argument.  Each entry in the template hashref becomes a method on
#pod YourProgram::Config, which returns either the value from the config file or the
#pod value from the template, if no entry exists in the config file.
#pod
#pod So, assuming that F<your_program.yaml> looks like this:
#pod
#pod   ---
#pod   username: rjbs
#pod   hostname: fulfill.example.com
#pod
#pod   path:
#pod     - /var/spool/jobs
#pod     - /home/rjbs/spool/jobs
#pod
#pod Then these are the results of method calls on Your::Config:
#pod
#pod   Your::Config->username; # 'rjbs'
#pod
#pod   Your::Config->logfile;  # undef
#pod
#pod   Your::Config->facility; # 'local0'
#pod
#pod   Your::Config->path;     # qw(/var/spool/jobs  /home/rjbs/spool/jobs)
#pod
#pod =head2 Specifying a Config File
#pod
#pod Config::Singleton finds a config file via a series of DWIM-my steps that are
#pod probably
#pod more complicated to explain than they are to understand.
#pod
#pod The F<filename> argument given when using Config::Singleton is the name of the
#pod file that will, by default, be loaded to find configuration.  It may be
#pod absolute or relative.  If not given, it's computed as follows:  the "module
#pod base name" is made by dropping the last part of the class name, if it's
#pod multi-part, and double colons become underscores.  In other words
#pod "Your::Thing::Config" becomes "Your_Thing."  If the environment variable
#pod YOUR_THING_CONFIG_FILE is set, that will be used as the default.  If not,
#pod F<your_thing.yaml> will be used.
#pod
#pod The named file will be the source of configuration for the global (class
#pod method) configuration.  It can be overridden, however, when using the config
#pod module.  For example, after using the following code:
#pod
#pod   use Your::Thing::Config 'special.yaml';
#pod
#pod ...the default name will have been replaced with F<special.yaml>.  If the
#pod previous default file has already been loaded, this will throw an exception.
#pod Using the module without specifying a filename will defer loading of the
#pod configuration file until it's needed.  To force it to be loaded without setting
#pod an explicit filename, pass C<-load> as the filename.  (All names beginning
#pod with a dash are reserved.)
#pod
#pod If the filename is relative, the configuration file is found by looking for the
#pod file name in the following paths (F<LOC> is the location of the program being
#pod run, found via C<$0>):
#pod
#pod   ./
#pod   ../
#pod   LOC/
#pod   LOC/../etc/
#pod   ~/
#pod   /etc/
#pod
#pod You can change the paths checked by providing a F<path> argument, as an
#pod arrayref, in the setup arguments.
#pod
#pod =head2 Alternate Configuration Objects
#pod
#pod Although it's generally preferable to begin your program by forcing the loading
#pod of a configuration file and then using the global configuration, it's possible
#pod to have multiple Your::Thing::Config configurations loaded by instantiating
#pod objects of that class, like this:
#pod
#pod   my $config_obj = Your::Thing::Config->new($filename);
#pod
#pod The named file is found via the same path resolution (if it's relative) as
#pod described above.
#pod
#pod =head1 METHODS
#pod
#pod Config::Singleton doesn't actually have any real public methods of its own.
#pod Its methods are all private, and serve to power its C<import> routine.  These
#pod will probably be exposed in the future to allow for subclassing of
#pod Config::Singleton, but in the meantime, don't rely on them.
#pod
#pod =cut

# Initialize all the methods for our new class.
# this is a Sub::Exporter group generator
sub _build_config_methods {
  my ($self, $name, $arg) = @_;

  # XXX: validate $arg here -- rjbs

  # This is the set of subs we're going to install in config classes.
  my %sub = (
    $self->_build_default_filename_methods($arg),
    $self->_build_default_object_methods($arg),
    _template  => sub { $arg->{template} },
    _config    => sub { shift->_self->{config} },
    import     => $self->_build_import($arg),
    new        => $self->_build_new($arg),
  );

  for my $attr (keys %{ $arg->{template} }) {
    Carp::croak "can't use reserved name $attr as config entry"
      if exists $sub{ $attr };

    $sub{ $attr } = sub {
      my $value = shift->_self->_config->{$attr};
      return @$value if (ref $value || q{}) eq 'ARRAY'; # XXX: use _ARRAYLIKE
      return $value;
    };
  }

  return \%sub;
}

## METHODS THAT BUILD METHODS TO INSTALL

sub _build_new {
  my ($app_config, $arg) = @_;

  sub {
    my ($class, $filename) = @_;

    my $self = bless { } => $class;

    $self->{basename} = $filename || $class->default_filename;

    $filename = $app_config->_find_file_in_path(
      $self->{basename},
      $arg->{path},
    );

    $self->{filename} = $filename;

    $self->{config} = $app_config->_merge_data(
      $self->_template,
      $app_config->_load_file(
        $app_config->_find_file_in_path(
          $self->{filename},
          $arg->{path},
        ),
      ),
    );

    return $self;
  };
}

sub _build_default_filename_methods {
  my ($app_config, $arg) = @_;

  my $set_default;

  my $get_default_filename = sub {
    my ($self) = @_;
    return $set_default ||= $arg->{filename}
                        ||  $app_config->_default_filename_for_class($self);
  };

  my $set_default_filename = sub {
    my ($class, $filename) = @_;
    Carp::croak "can't change default filename, config already loaded!"
      if  $set_default
      and $set_default ne $filename;
    $set_default = $filename;
  };

  return (
    _get_default_filename => $get_default_filename,
    _set_default_filename => $set_default_filename,
  );
}

sub _build_default_object_methods {
  my ($app_config) = @_;

  my $default;

  my $_self = sub {
    my ($self) = @_;
    return $self if ref $self;
    return $default ||= $self->new($self->_get_default_filename);
  };

  return (
    _self           => $_self,
    _default_object => sub { $default },
  );
}

sub _build_import {
  my ($app_config, $arg) = @_;

  return sub {
    my ($class, $filename) = @_;

    Carp::confess sprintf('import called on %s object', ref $class)
      if ref $class;

    return unless defined $filename and length $filename;

    if ($filename =~ /^-/) {
      if ($filename eq '-load') {
        return $class->_self;
      }
      Carp::croak "unknown directive for $class: $filename";
    } else {
      $class->_set_default_filename($filename);
    }

    $class->_self;
  }
}

# METHODS FOR THINGS TO CALL ON APP::CONFIG

sub _default_filename_for_class {
  my ($app_config, $class) = @_;

  # remove final part (A::Config -> A)
  (my $module_base = $class) =~ s/::\w+\z//;

  $module_base =~ s/::/_/g;
  my $filename = $ENV{uc($module_base) . '_CONFIG_FILE'}
              || lc($module_base) . '.yaml';

  return $filename;
}

sub _load_file { YAML::XS::LoadFile($_[1]); }

sub _find_file_in_path {
  my ($self, $filename, $path) = @_;

  if (File::Spec->file_name_is_absolute( $filename )) {
    Carp::croak "config file $filename not found\n" unless -e $filename;
    return $filename;
  }

  $path = $self->_default_path unless defined $path;

  for my $dir (@$path) {
    my $this_file = File::Spec->catfile($dir, $filename);
    return $this_file if -e $this_file;
  };

  Carp::croak "config file $filename not found in path (@$path)\n";
}

sub _default_path {
  my $home = File::HomeDir->my_home;
  my $path = File::Basename::dirname(Cwd::realpath($0));

  return [
    q{},
    q{./},
    q{../},
    qq{$path/},
    qq{$path/../etc/},
    qq{$home/.},
    q{/etc/},
  ];
}

# In the future, using Clone here might be a good idea to avoid issues with
# stupid references.
sub _merge_data {
  my ($self, $template, $override) = @_;

  my $merged = {};

  for (keys %$template) {
    # Should we be preventing the config file's entry from having a different
    # data type than the template value?  -- rjbs, 2007-08-18
    $merged->{$_} = defined $override->{$_} ? $override->{$_} : $template->{$_};
  }

  return $merged;
}

#pod =head1 TODO
#pod
#pod =for :list
#pod * a ->new method to allow loading different configs
#pod * a way to tell Your::Config, with no explicit filename, to die unless a filename was specified by an earlier use
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod Ricardo SIGNES not only wrote the inspiration for this in Rubric::Config, but
#pod he also basically wrote the majority of the implementation here, and even
#pod provided extensions of what he knew I wanted it to do, even when I said I
#pod didn't need that yet. In the end it ended up being extremely elegant, which I
#pod can say without being boastful, because he wrote the elegant bits.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Singleton - one place for your app's configuration

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  package YourApplication::Config;

  use Config::Singleton -setup => {
    filename => 'something.yaml',
    template => {
      foo => undef,
      bar => 1024,
      qux => [ 1, 2, 3],
    },
  };

Elsewhere...

  use YourApplication::Config 'my_instance_config.yml';

  my $foo = YourApplication::Config->foo;

=head1 DESCRIPTION

Config::Singleton provides a base class for access to configuration data for
your app. The basic implementation stores its configuration in YAML in a text
file found in all the usual places. By default, Config::Singleton looks for
myapp.yml, but an alternate filename may be passed when using the module.

This module was derived from L<Rubric::Config|Rubric::Config>.

=head1 USING APP::CONFIG

The L</SYNOPSIS> section, above, demonstrates an example of almost every
feature of Config::Singleton  It's a very simple module with a very small
interface.

It is not a base class.  It is a utility for setting up a class that stores
loaded configuration data.  You just need to C<use> the module like this:

  package Your::Config;

  use Config::Singleton -setup => {
    filename => 'your_program.yaml',
    template => {
      username => undef,
      hostname => undef,
      logfile  => undef,
      facility => 'local1',
      path     => [ qw(/var/spool /tmp/jobs) ],
    },
  };

When another module uses Your::Config, F<your_program.yaml> will be loaded and
its contents will be merged over the defaults given by the C<template>
argument.  Each entry in the template hashref becomes a method on
YourProgram::Config, which returns either the value from the config file or the
value from the template, if no entry exists in the config file.

So, assuming that F<your_program.yaml> looks like this:

  ---
  username: rjbs
  hostname: fulfill.example.com

  path:
    - /var/spool/jobs
    - /home/rjbs/spool/jobs

Then these are the results of method calls on Your::Config:

  Your::Config->username; # 'rjbs'

  Your::Config->logfile;  # undef

  Your::Config->facility; # 'local0'

  Your::Config->path;     # qw(/var/spool/jobs  /home/rjbs/spool/jobs)

=head2 Specifying a Config File

Config::Singleton finds a config file via a series of DWIM-my steps that are
probably
more complicated to explain than they are to understand.

The F<filename> argument given when using Config::Singleton is the name of the
file that will, by default, be loaded to find configuration.  It may be
absolute or relative.  If not given, it's computed as follows:  the "module
base name" is made by dropping the last part of the class name, if it's
multi-part, and double colons become underscores.  In other words
"Your::Thing::Config" becomes "Your_Thing."  If the environment variable
YOUR_THING_CONFIG_FILE is set, that will be used as the default.  If not,
F<your_thing.yaml> will be used.

The named file will be the source of configuration for the global (class
method) configuration.  It can be overridden, however, when using the config
module.  For example, after using the following code:

  use Your::Thing::Config 'special.yaml';

...the default name will have been replaced with F<special.yaml>.  If the
previous default file has already been loaded, this will throw an exception.
Using the module without specifying a filename will defer loading of the
configuration file until it's needed.  To force it to be loaded without setting
an explicit filename, pass C<-load> as the filename.  (All names beginning
with a dash are reserved.)

If the filename is relative, the configuration file is found by looking for the
file name in the following paths (F<LOC> is the location of the program being
run, found via C<$0>):

  ./
  ../
  LOC/
  LOC/../etc/
  ~/
  /etc/

You can change the paths checked by providing a F<path> argument, as an
arrayref, in the setup arguments.

=head2 Alternate Configuration Objects

Although it's generally preferable to begin your program by forcing the loading
of a configuration file and then using the global configuration, it's possible
to have multiple Your::Thing::Config configurations loaded by instantiating
objects of that class, like this:

  my $config_obj = Your::Thing::Config->new($filename);

The named file is found via the same path resolution (if it's relative) as
described above.

=head1 METHODS

Config::Singleton doesn't actually have any real public methods of its own.
Its methods are all private, and serve to power its C<import> routine.  These
will probably be exposed in the future to allow for subclassing of
Config::Singleton, but in the meantime, don't rely on them.

=head1 TODO

=over 4

=item *

a ->new method to allow loading different configs

=item *

a way to tell Your::Config, with no explicit filename, to die unless a filename was specified by an earlier use

=back

=head1 ACKNOWLEDGEMENTS

Ricardo SIGNES not only wrote the inspiration for this in Rubric::Config, but
he also basically wrote the majority of the implementation here, and even
provided extensions of what he knew I wanted it to do, even when I said I
didn't need that yet. In the end it ended up being extremely elegant, which I
can say without being boastful, because he wrote the elegant bits.

=head1 AUTHORS

=over 4

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

John Cappiello <jcap@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by John Cappiello.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
