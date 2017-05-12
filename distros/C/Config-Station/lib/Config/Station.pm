package Config::Station;
$Config::Station::VERSION = '0.002001';
# ABSTRACT: Load configs from files and the environment

use Moo;
use warnings NONFATAL => 'all';

use JSON::MaybeXS;
use IO::All;
use Try::Tiny;
use Module::Runtime 'use_module';

has _debug => (
   is => 'ro',
   init_arg => undef,
   lazy => 1,
   default => sub {
      my $self = shift;

      exists $ENV{'DEBUG_' . $self->_env_key}
         ? $ENV{'DEBUG_' . $self->_env_key}
         : $self->__debug
   },
);

has __debug => (
   is => 'ro',
   init_arg => 'debug',
);

has _env_key => (
   is => 'ro',
   init_arg => 'env_key',
   required => 1,
);

has _location => (
   is => 'ro',
   init_arg => undef,
   lazy => 1,
   default => sub {
      my $self = shift;

      my $path = $ENV{'FILE_' . $self->_env_key} ||
         $self->__location;

      warn "No path specified to load config from\n"
         if !$path && $self->_debug;

      return $path
   },
);

has __location => (
   is => 'ro',
   init_arg => 'location',
);

has _config_class => (
   is => 'ro',
   init_arg => 'config_class',
   required => 1,
);

has _decode_via => (
   is => 'ro',
   init_arg => 'decode_via',
   lazy => 1,
   builder => sub { \&decode_json },
);

has _encode_via => (
   is => 'ro',
   init_arg => 'encode_via',
   lazy => 1,
   builder => sub { \&encode_json },
);

sub _io { io->file(shift->_location) }

sub _debug_log {
   my ($self, $line, $ret) = @_;

   if ($self->_debug) {
      if (my @keys = keys %$ret) {
         warn "CONFIGSTATION FROM $line:\n";
         warn "  $_: $ret->{$_}\n" for @keys;
      } else {
         warn "CONFIGSTATION FROM $line: EMPTY\n";
      }
   }

   $ret
}

sub _read_config_from_file {
   my $self = shift;

   my $ret = try {
      $self->_debug_log(FILE => $self->_decode_via->($self->_io->all));
   } catch {
      if ($self->_debug) {
         warn "CONFIGSTATION FROM FILE: $_\n"
      }
      {}
   };

}

sub _read_config_from_env {
   my $self = shift;

   my $k_re = '^' . quotemeta($self->_env_key) . '_(.+)';

   my $ret = +{
      map {; m/$k_re/; lc $1 => $ENV{$self->_env_key . "_$1"} }
      grep m/$k_re/,
      keys %ENV
   };

   $self->_debug_log(ENV => $ret);
}

sub _read_config {
   my $self = shift;

   {
      %{$self->_read_config_from_file},
      %{$self->_read_config_from_env},
   }
}

sub load {
   my $self = shift;

   use_module($self->_config_class)->new($self->_read_config)
}

# eat my data
sub store {
   my ($self, $obj) = @_;

   $self->_io->print($self->_encode_via->($obj->serialize))
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Station - Load configs from files and the environment

=head1 VERSION

version 0.002001

=head1 SYNOPSIS

Define your config class:

 package MyApp::Config;

 use Moo;

 has www_port => (
   is => 'ro',
   required => 1,
 );

 has static_path => (
   is => 'ro',
   default => 'view/static',
 );

 1;

And elsewhere you load it up:

 my $station = Config::Station->new(
   config_class => 'MyApp::Config',
   env_key      => 'MYAPP',
   location     => '.config.json',
 );

 my $config = $station->load;

=head1 DESCRIPTION

This config loader offers a couple of major features that make it compelling
for the user:

=over

=item 1. Object based configuration

This is a huge deal.  This means that you can trivially set defaults, add
validation, and an other number of cool things.  On top of that this means that
unless you do something silly, your configuration has clearly defined fields,
instead of being a shapeless hash.

=item 2. Environment based overriding

Presumably many users of this module will be loading their config from a file.
That's fine and normal, but baked into the module is and an environment based
config solution.  This allows the user to change, for example, a port, by just
running the application as follows:

 MYAPP_WWW_PORT=8080 perl bin/myapp.pl

=back

=head1 ATTRIBUTES

 my $station = Config::Station->new( env_key => 'MYAPP' )

=head2 env_key

The C<env_key> is a required attribute which affects everything about this
module.

C<env_key> affects two classes of values:

=head3 Meta Configuration

These values use the C<env_key> as a suffix, and are documented further down.

=head3 Normal Configuration

These values use the C<env_key> as a prefix for env vars that override
configuration keys.  To be clear, if you specify an C<env_key> of C<FOO>, an env
var of C<FOO_BAR=BAZ> will pass C<< bar => 'BAZ' >> to the constructor of
L</config_class>.

=head2 config_class

The C<config_class> is a required attribute which determines the class that
will be used when loading the configuration.  The config class absolutely must
have a C<new> method which takes a hash.  What it returns is up to you.

If you care to, you can define a C<serialize> method on the object which
supports the L</store> method, but I suspect that is likely not a typical use
case.

=head2 debug

Debugging is critical feature of this module.  If you set this attribute
directly, or indirectly by setting the env var C<'DEBUG_' . $env_key>, you will
get some handy debugging output C<warn>ed.  It looks like this:

 CONFIGSTATION FROM FILE:
   name: herp
 CONFIGSTATION FROM ENV:
   id: 1
   name: wins

If the file can't be loaded or parsed, for some reason, instead of listing
key-value pairs, the output for the file will be:

 CONFIGSTATION FROM FILE: $exception

Note that failure to load or deserialize the file is not considered an error.
If you want to enforce that data is set do that by making your object
constructor more strict.

=head2 location

The location can be set directly, or indirectly by setting the env var
C<'FILE_' . $env_key>.  As noted above, it is neither required to be set or
parseable at all.

=head2 decode_via

 my $station = Config::Station->new( ..., decode_via => sub { \&YAML::Load );

A code reference which can inflate a string into a hash reference.  Default uses
JSON.

=head2 encode_via

 my $station = Config::Station->new( ..., encode_via => sub { \&YAML::Dump );

A code reference which can deflate a hash reference into a string.  Default uses
JSON.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
