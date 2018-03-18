package Clustericious::Config::Helpers;

use strict;
use warnings;
use 5.010001;
use Hash::Merge qw/merge/;
use Data::Dumper;
use Carp qw( croak );
use base qw( Exporter );
use JSON::MaybeXS qw( encode_json );
use Clustericious::Config;

# ABSTRACT: Helpers for clustericious config files.
our $VERSION = '1.29'; # VERSION


our @mergeStack;
our @EXPORT = qw( extends_config get_password home file dir hostname hostname_full json yaml address public_address interface );


sub extends_config
{
  my($name, @args) = @_;
  push @mergeStack, Clustericious::Config->new($name, \@args);
  return '';
}

#
#
# do_merges:
#
# Called after reading all config files, to process extends_config
# directives.
#
sub _do_merges {
  my($class, $data) = @_;

  return $data unless @mergeStack;

  # Nested extends_config's form a tree which we traverse depth first.
  Hash::Merge::set_behavior( 'RIGHT_PRECEDENT' );
  my %so_far = %{ shift @mergeStack };
  while (my $c = shift @mergeStack)
  {
    my %h = %$c;
    %so_far = %{ merge( \%so_far, \%h ) };
  }
  %$data = %{ merge( \%so_far, $data ) };
}


sub get_password
{
  return Clustericious::Config::Callback::Password->new->to_yaml;
}


sub home (;$)
{
  require File::Glob;
  $_[0] ? File::Glob::bsd_glob("~$_[0]") : File::Glob::bsd_glob('~');
}


sub file
{
  eval { require Path::Class::File };
  croak "file helper requires Path::Class" if $@;
  Path::Class::File->new(@_);
}


sub dir
{
  require Path::Class::Dir;
  croak "dir helper requires Path::Class" if $@;
  Path::Class::Dir->new(@_);
}


sub hostname
{
  state $hostname;
  
  unless(defined $hostname)
  {
    require Sys::Hostname;
    $hostname = Sys::Hostname::hostname();
    $hostname =~ s/\..*$//;
  }
  
  $hostname;
}


sub hostname_full
{
  require Sys::Hostname;
  Sys::Hostname::hostname();
}


sub json ($)
{
  encode_json($_[0]);
}


sub yaml ($)
{
  require YAML::XS;
  local $YAML::UseHeader = 0;
  my $str = YAML::XS::Dump($_[0]);
  $str =~ s{^---\n}{};
  $str;
}


# TODO: for now the filtering of loop back only works on Linux
# and any system where the loopback interface is lo

sub address (;$)
{
  my($if) = @_;
  
  require Sys::HostAddr;
  
  my $filter = sub { !/^lo$/ };
  
  if(defined $if)
  {
    if(ref $if eq 'Regexp')
    {
      $filter = sub { $_ =~ $if };
    }
    elsif(ref $if eq 'ARRAY')
    {
      my %if = map { $_ => 1 } @$if;
      $filter = sub { $if{$_} }
    }
    else
    {
      $filter = sub { $_ eq $if };
    }
  }

  my @if = grep { $filter->() } @{ Sys::HostAddr->new(ipv=>4)->interfaces };
  map { @{ $_->addresses } } map { Sys::HostAddr->new(ipv => 4, interface => $_) } @if;
}


sub public_address ()
{
  require Sys::HostAddr;
  Sys::HostAddr->new(ipv=>4)->public;
}


sub interface ()
{
  require Sys::HostAddr;
  grep !/^lo$/, @{ Sys::HostAddr->new(ipv=>4)->interfaces };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Config::Helpers - Helpers for clustericious config files.

=head1 VERSION

version 1.29

=head1 SYNOPSIS

 ---
 % extend_config 'SomeOtherConfig';

=head1 DESCRIPTION

This module provides the functions available in all configuration files
using L<Clustericious::Config>.

=head1 FUNCTIONS

=head2 extends_config 

 % extends_config $config_name, %arguments

Extend the config using another config file.

=head2 get_password

 <%= get_password %>

Prompt for a password.  This will prompt the user the first time it is
encountered for a password.

=head2 home

 <%= home %>
 <%= home $user %>

Return the given users' home directory, or if no user is
specified return the calling user's home directory.

=head2 file

 <%= file @list %>

The C<file> shortcut from Path::Class, if it is installed.

=head2 dir

 <%= dir @list %>

The C<dir> shortcut from Path::Class, if it is installed.

=head2 hostname

 <%= hostname %>

The system hostname (uses L<Sys::Hostname>)

=head2 hostname_full

 <%= hostname_full %>

The system hostname in full, including the domain, if
it can be determined (uses L<Sys::Hostname>).

=head2 json

 <%= json $ref %>

Encode the given hash or list reference.

=head2 yaml

 <%= yaml $ref %>

Encode the given hash or list reference.

=head2 address

 <%= address %>
 <%= address $interface %>

Returns a list of IP addresses.  Requires L<Sys::HostAddr> to be installed.
C<$interfaces>, if specified may be either a string or regular expression.
For example you can do C<address qr{^en[0-9]+$}> on Linux to get only ethernet
interfaces.

By default does not return loop back interfaces.

Only returns IPv4 addresses.

=head2 public_address

 <%= public_address %>

Returns the public IPv4 address.  May not be an address on your host, if you
are behind a firewall.  Requires L<Sys::HostAddr> to be installed.

=head2 interface

 <%= join ' ', interfaces %>

Returns a list of network interfaces.  Requires L<Sys::HostAddr> to be installed.

By default does not return loop back interfaces.

=head1 SEE ALSO

L<Clustericious::Config>, L<Clustericious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
