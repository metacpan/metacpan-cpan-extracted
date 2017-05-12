package Config::SL;

use strict;
use warnings;

=head1 NAME

Config::SL - Configuration file abstraction for Silver Lining applications

=head1 ABSTRACT

  use Config::SL;

  $cfg  = Config::SL->new;
  $val  = $cfg->key;
  @vals = $cfg->key;

=head1 DESCRIPTION

This package is responsible for handling Silver Lining configuration data.
It should make our lives less complex.

It is an abstraction of Config::ApacheFormat, and looks for the configuration
file sl.conf in various locations.

=cut

our $VERSION = 0.01;

our ( $config, $conf_dir );
our $file = 'sl.conf';

use base 'Config::ApacheFormat';
use FindBin;

sub new {
    my $class = shift;

    return $config if $config;

    my @config_files;

    # check the local conf dir first
    if ( -d "./conf" && ( -e "./conf/$file" ) ) {

        $conf_dir     = "./conf";
        @config_files = ("$conf_dir/$file");

    }
    elsif ( -d "$FindBin::Bin/../conf" && ( -e "$FindBin::Bin/../conf/$file" ) )
    {

        # development
        $conf_dir = "$FindBin::Bin/../conf";
        @config_files = ( "$conf_dir/$file", "$conf_dir/../$file" );

        # then  check for a global conf file
    }
    elsif ( -e "/etc/sl/$file" ) {

        # global sl dir
        $conf_dir     = "/etc/sl";
        @config_files = ("$conf_dir/$file");
    }
    elsif ( -e "/etc/$file" ) {

        # global etc
        $conf_dir     = "/etc";
        @config_files = ("$conf_dir/$file");
    }
    else {
        die "\nNo file $file found in  "
          . "$FindBin::Bin/../conf/ or /etc/sl/!\n";
    }

    # we have a configuration file to work with, so get to work
    $config = $class->SUPER::new();
    my $read;
    foreach my $config_file (@config_files) {
        next unless ( -e $config_file );
        $config->read($config_file);
        $read++;
    }
    die "\nNo config files read! conf_dir $conf_dir\n" unless $read;

    $config->autoload_support(1);

    return $config;
}

sub sl_debug {
    my $config = shift;

    return $ENV{SL_DEBUG};
}

sub conf_dir {
    my $self = shift;
    return $conf_dir;
}

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Silver Lining Networks - All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
