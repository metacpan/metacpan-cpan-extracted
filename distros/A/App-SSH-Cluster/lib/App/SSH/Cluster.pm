package App::SSH::Cluster;
$App::SSH::Cluster::VERSION = '0.004';
# ABSTRACT: CLI to Net::OpenSSH that runs the same command via SSH on many remote servers at the same time
use strict;
use warnings;

use List::MoreUtils qw(all);
use MooseX::App::Simple;
use MooseX::Types::Moose qw/HashRef Str/;
use Net::OpenSSH::Parallel;
use YAML::Tiny;

option 'command' => (
   is            => 'ro',
   isa           => Str,
   required      => 1,
   cmd_aliases   => [qw(c)],
   documentation => 'command to run on remote servers',
);

option 'config_file' => (
   is          => 'ro',
   isa         => Str,
   default     => "$ENV{HOME}/.app-clusterssh.yml",
   cmd_aliases => [qw(p)],
   cmd_flag    => 'config-file',
);

has '_config' => (
   is       => 'ro',
   isa      => HashRef,
   builder  => '_build_config',
   init_arg => undef,
   lazy     => 1,
);

sub run {
   my ($self) = @_;
   $self->_validate_config;

   my $parallel_executor    = Net::OpenSSH::Parallel->new;
   my $global_identity_file = $self->_config->{identity_file};
   my $global_username      = $self->_config->{user};

   my @hosts = @{ $self->_config->{servers} };
   foreach my $host ( @hosts ) {
      my $hostname = $host->{hostname};
      my $username = $host->{user} // $global_username;
      my $identity_file 
         = $host->{identity_file} // $global_identity_file;
      
      $host->{STDOUT} = "/tmp/$hostname.out";
      open my $fh, '>', $host->{STDOUT}
         or die "Unable to open file '$host->{STDOUT}' for writing: $!";

      $parallel_executor->add_host(
         $hostname, 
         user              => $username, 
         key_path          => $identity_file,
         default_stdout_fh => $fh,
      );
   }
   $parallel_executor->push('*', 'command' => $self->command);
   $parallel_executor->run;

   foreach my $host ( @hosts ) {
      open my $fh, '<', $host->{STDOUT}
         or die "Unable to open file '$host->{STDOUT}' for reading: $!";
      
      print "$host->{hostname}: [@{[$self->command]}]\n";
      print '-' x 80 . "\n";
      {
         local $/ = undef;
         my $output = <$fh>;
         print "$output\n";
      }
      close $fh;
   }
}

sub _build_config {
   my ($self) = @_;

   return YAML::Tiny->read( $self->config_file )->[0];
}

sub _validate_config {
   my ($self) = @_;

   die "No 'servers' key found in " . $self->config_file
      unless exists $self->_config->{servers};
   die "Existing 'servers' key found in " . $self->config_file . ", but has no servers listed"
      if exists $self->_config->{servers} 
      && ref $self->_config->{servers} ne 'ARRAY'
      || ( 
         ref $self->_config->{servers} eq 'ARRAY'
         && @{$self->_config->{servers}} == 0
      );

   foreach my $key ( qw(hostname identity_file user) ) { 
      $self->_has_config_key($key);
   }
}

sub _has_config_key {
   my ($self, $key) = @_;

   die "No '$key' key found in " . $self->config_file
      unless exists $self->_config->{$key} 
      || all { exists $_->{$key} } @{ $self->_config->{servers} };   
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SSH::Cluster - CLI to Net::OpenSSH that runs the same command via SSH on many remote servers at the same time

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use App::SSH::Cluster;
 App::SSH::Cluster->new_with_options;

=head1 DESCRIPTION

Simple application to execute the same remote command across one or more remote servers. This module does *not* handle errors that are generated from remote commands and currently does not log the STDERR of the remote commands that are executed. Any error handling will need to implementing in the calling code.

=head1 NAME 

App::SSH::Cluster

=head1 ATTRIBUTES

=over 4 

=item C<command>

command to run on remote servers

=item C<config_file>

Absolute path to YAML configuration file that defines the listing of servers, users, and identity-files. If no config_file is supplied, the default file .app-clusterssh.yml is assumed in the users home directory.

=back

=head1 METHODS

=over 4

=item C<run>

Runs the supplied command (--command <command> or -c <command>) on each remote server. Logging STDOUT to separate files then dumping STDOUT in blocks labelled by the name of the host the STDOUT is from 

=back

=head1 CONFIGURATION

The follow items are required for *each* server that you wish to run commands on:

=over 4 

=item C<identity_file> 

absolute path to the SSH private key to use to connect 

=item C<user>

name of user to connect to remote server as

=item C<hostname>

name of remote host

=back

each of these may be defined globally or for each individual server, individual server options take precedence. Global options will be used if any individual options are not listed.

=head4 EXAMPLE CONFIGURATIONs

 identity_file: "/home/hunter/.ssh/id_rsa"  
 servers:
   - hostname: bastion
     user: hunter
     identity_file: "/home/hunter/.ssh/bastion_rsa"
   - hostname: asphodel
     user: hades

or

 identity_file: "/home/hunter/.ssh/id_rsa"
 user: hunter
 servers:                                 
   - hostname: bastion                    
   - hostname: asphodel
   - hostname: localhost

=head1 AUTHOR

Hunter McMillen <mcmillhj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Hunter McMillen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
