package Beekeeper::Config;

use strict;
use warnings;

our $VERSION = '0.04';

use JSON::XS;
use Carp;

my %Cache;
my $Config_dir;


sub set_config_dir {
    my ($class, $dir) = @_;

    croak "Couldn't read config files from $dir: directory does not exist\n" unless ($dir && -d $dir);

    $Config_dir = $dir;
}

sub get_bus_config {
    my ($class, %args) = @_;

    my $bus_id = $args{'bus_id'};

    croak "bus_id was not specified" unless ($bus_id);

    my $config = $class->read_config_file( 'bus.config.json' );

    croak "Couldn't read config file bus.config.json: file not found\n" unless defined ($config);

    my %bus_cfg  = map { $_->{'bus_id'}  => $_ } @$config;

    return ($bus_id eq '*') ? \%bus_cfg : $bus_cfg{$bus_id};
}

sub get_pool_config {
    my ($class, %args) = @_;

    my $pool_id = $args{'pool_id'};

    croak "pool_id was not specified" unless ($pool_id);

    my $config = $class->read_config_file( 'pool.config.json' );

    croak "Couldn't read config file pool.config.json: file not found\n" unless defined ($config);

    my %pool_cfg = map { $_->{'pool_id'} => $_ } @$config;

    return ($pool_id eq '*') ? \%pool_cfg : $pool_cfg{$pool_id};
}

sub get_bus_group_config {
    my ($class, %args) = @_;

    my $bus_role = $args{'bus_role'};
    my $bus_id   = $args{'bus_id'};
    my @group_config;

    croak "No bus_role or bus_id was specified" unless ($bus_id || $bus_role);

    my $config = $class->read_config_file( 'bus.config.json' );

    if ($bus_role) {

        @group_config = grep { defined $_->{'bus_role'} && $_->{'bus_role'} eq $bus_role } @$config;
    }
    elsif ($bus_id) {

        my ($bus_config) = grep { $_->{'bus_id'} eq $bus_id } @$config;
        return [] unless $bus_config;

        $bus_role = $bus_config->{'bus_role'};
        return [ $bus_config ] unless $bus_role;

        @group_config = grep {
            (defined $_->{'bus_role'} && $_->{'bus_role'} eq $bus_role) || $_->{'bus_id'} eq $bus_id
        } @$config;
    }

    return \@group_config;
}

sub read_config_file {
    my ($class, $file) = @_;

    croak "Couldn't read config file: filename was not specified\n" unless ($file);

    my $cdir;
    $cdir = $Config_dir;
    $cdir = $ENV{'BEEKEEPER_CONFIG_DIR'} unless ($cdir && -d $cdir);
    $cdir = '~/.config/beekeeper'        unless ($cdir && -d $cdir);
    $cdir = '/etc/beekeeper'             unless ($cdir && -d $cdir);

    $file = "$cdir/$file";

    return $Cache{$file} if exists $Cache{$file};

    return undef unless (-e $file);

    local($/);
    open(my $fh, '<', $file) or croak "Couldn't read config file $file: $!";
    my $data = <$fh>;
    close($fh);

    # Allow comments and end-comma
    my $json = JSON::XS->new->utf8->relaxed;

    my $config = eval { $json->decode($data) };

    if ($@) {
        croak "Couldn't parse config file $file: Invalid JSON syntax";
    }

    $Cache{$file} = $config;

    return $config;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME
 
Beekeeper::Config - Read configuration files
 
=head1 VERSION
 
Version 0.04

=head1 SYNOPSIS

=head1 DESCRIPTION

Beekeeper applications use two config files to define how clients, workers
and brokers connect to each other.

These files are looked for in ENV C<BEEKEEPER_CONFIG_DIR>, C<~/.config/beekeeper>
and then C</etc/beekeeper>.

=head3 pool.config.json

This file defines all worker pools running on this host, specifying 
which logical bus should be used and which services it will run.

The file format is in relaxed JSON, which allows comments and trailing commas.

Each entry define a worker pool. Required parameters are:

C<pool_id>: arbitrary identifier for the worker pool

C<bus_id>: identifier of logical bus used by worker processes

C<workers>: a map of worker classes to arbitrary config hashes

Example:

  [
      {
          "pool_id"     : "myapp",
          "bus_id"      : "backend",
          "description" : "pool of MyApp workers",
  
          "workers" : {
              "MyApp::Service::Foo::Worker" : { "workers_count" : 4 },
              "MyApp::Service::Bar::Worker" : { "workers_count" : 2 },
          },
      },
  ]

=head3 bus.config.json

This file defines all logical buses used by your application, specifying
the conection parameters to the MQTT brokers that will service them.

For development purposes is handy to use a single broker to hold all 
logical buses and easily simulate a complex topology, but in production 
enviroments brokers should be isolated from each other.

The file format is in relaxed JSON, which allows comments and trailing commas.

Each entry define a logical bus. Accepted parameters are:

C<bus_id>: unique identifier of the logical bus (required)

C<bus_role>: specifies if the bus is acting as frontend or backend

C<host>: hostname or IP address of the broker

C<port>: port of the broker (default is 1883)

C<tls>: if set to true enables the use of TLS on broker connection

C<username>: username used to connect to the broker

C<password>: password used to connect to the broker

Example:

  [
      {
          "bus_id"   : "backend",
          "host"     : "localhost",
          "username" : "backend",
          "password" : "def456",
      },
      {
          "bus_id"   : "frontend",
          "host"     : "localhost",
          "username" : "frontend",
          "password" : "def456",
      },
  ]

=head1 METHODS

=head3 get_bus_config( bus_id => $id )

Reads and parse C<bus.config.json> and returns the config of the requested bus.

=head3 get_pool_config( bus_id => $id )

Reads and parse C<pool.config.json> and returns the config of the requested pool.

=head3 read_config_file( $filename )

Reads the given file and returns its content parsed as JSON.

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
