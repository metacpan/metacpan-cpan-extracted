package Clustericious::Admin::Server;

use strict;
use warnings;
use Sys::Hostname qw( hostname );
use File::Temp qw( tempdir );
use File::Spec;
use File::Path qw( mkpath );

# ABSTRACT: Parallel SSH client server side code
our $VERSION = '1.11'; # VERSION


# This is the implementation of the clad server.
#
#  - requires Perl 5.10
#  - it is pure perl capable 
#  - no non-core requirements as of 5.14
#  - single file implementation
#  - optionally uses YAML::XS IF available
#
# The idea is that if App::clad is properly installed
# on the remote end, "clad --server" can be used to
# invoke, and you get YAML encoded payload.  The YAML
# payload is preferred because it is easier to read
# when things go wrong.  If App::clad is NOT installed
# on the remote end, then you can take this pm file,
# append the payload as Perl Dump after the __DATA__
# section below and send the server and payload and
# feed it into perl on the remote end.

sub _decode
{
  my(undef, $fh) = @_;
  my $raw = do { local $/; <$fh> };

  my $payload;

  if($raw =~ /^---/)
  {
    eval {
      require YAML::XS;
      $payload = YAML::XS::Load($raw);
    };
    if(my $yaml_error = $@)
    {
      print STDERR "Clad Server: side YAML Error:\n";
      print STDERR $yaml_error, "\n";
      print STDERR "payload:\n";
      print STDERR $raw, "\n";
      return;
    }
    print STDERR YAML::XS::Dump($payload) if $payload->{verbose};
  }
  elsif($raw =~ /^#perl/)
  {
    $payload = eval $raw;
    if(my $perl_error = $@)
    {
      print STDERR "Clad Server: side Perl Error:\n";
      print STDERR $perl_error, "\n";
      print STDERR "payload:\n";
      print STDERR $raw, "\n";
      return;
    }
    eval {
      require Data::Dumper;
      print Dumper($payload) if $payload->{verbose};
    };
  }
  else
  {
    print STDERR "Clad Server: unable to detect encoding.\n";
    print STDERR "payload:\n";
    print STDERR $raw;
  }
  
  $payload;
}

sub _server
{
  my $payload = _decode(@_) || return 2;
  
  # Payload:
  #
  #   command: required, must be a array with at least one element
  #     the command to execute
  #
  #   env: optional, must be a hash reference
  #     any environmental overrides
  #
  #   verbose: optional true/false
  #     print out extra diagnostics
  #
  #   version: required number or 'dev'
  #     the client version
  #
  #   require: optional, number or 'dev'
  #     specifies the minimum required server
  #     server should die if requirement isn't met
  #     ignored if set to 'dev'
  #
  #   files: optional list of hashref   [ 1.01 ]
  #     each hashref has:
  #       name: the file basename (no directory)
  #       content: the content of the file
  #       mode: (optional) octal unix permission mode as a string (ie "0755" or "0644")
  #       env: (optional) environment variable to use instead of FILEx
  #
  #   dir: optional hash of hash        [ 1.02 ]
  #     each key is a path
  #       each value is a hash
  #         is_dir
  #         content
  #         mode
  #
  #   stdin: optional scalar            [ 1.04 ]

  if(ref $payload->{command} ne 'ARRAY' || @{ $payload->{command} } == 0)
  {
    print STDERR "Clad Server: Unable to find command\n";
    return 2;
  }
  
  if(defined $payload->{env} && ref $payload->{env} ne 'HASH')
  {
    print STDERR "Clad Server: env is not hash\n";
    return 2;
  }
  
  unless($payload->{version})
  {
    print STDERR "Clad Server: no client version\n";
    return 2;
  }
  
  if($payload->{require} && defined $Clustericious::Admin::Server::VERSION)
  {
    if($payload->{require} ne 'dev' && $payload->{require} > $Clustericious::Admin::Server::VERSION)
    {
      print STDERR "Clad Server: client requested version @{[ $payload->{require} ]} but this is only $Clustericious::Admin::Server::VERSION\n";
      return 2;
    }
  }

  if($payload->{files})
  {
    my $count = 1;
    foreach my $file (@{ $payload->{files} })
    {
      my $path = File::Spec->catfile( tempdir( CLEANUP => 1 ), $file->{name} );
      open my $fh, '>', $path;
      chmod oct($file->{mode}), $path if defined $file->{mode};
      binmode $fh;
      print $fh $file->{content};
      close $fh;
      my $env = $file->{env};
      $env = "FILE@{[ $count++ ]}" unless defined $env;
      $ENV{$env} = $path;
    }
  }
  
  if($payload->{dir})
  {
    my $root = $ENV{DIR} = tempdir( CLEANUP => 1 );
    
    foreach my $name (sort keys %{ $payload->{dir} })
    {
      my $dir = $payload->{dir}->{$name};
      next unless $dir->{is_dir};
      my $path = File::Spec->catdir($root, $name);
      mkdir $path;
      chmod oct($dir->{mode}), $path if defined $dir->{mode};
    }
    
    foreach my $name (sort keys %{ $payload->{dir} })
    {
      my $file = $payload->{dir}->{$name};
      next if $file->{is_dir};
      my $path = File::Spec->catfile($root, $name);
      open my $fh, '>', $path;
      chmod oct($file->{mode}), $fh if defined $file->{mode};
      binmode $fh;
      print $fh $file->{content};
      close $fh;
    }
  }

  $ENV{$_} = $payload->{env}->{$_} for keys %{ $payload->{env} };
  
  if(defined $payload->{stdin})
  {
    my $filename = File::Spec->catfile(tempdir(CLEANUP => 1), 'stdin.txt');
    open OUT, ">$filename"; 
    print OUT $payload->{stdin};
    close OUT;
    open STDIN, "<$filename";
  }
  
  system @{ $payload->{command} };
  
  if($? == -1)
  {
    print STDERR "Clad Server: failed to execute on @{[ hostname ]}\n";
    return 2;
  }
  elsif($? & 127)
  {
    print STDERR "Clad Server: died with signal @{[ $? & 127 ]} on @{[ hostname ]}\n";
    return 2;
  }
  
  return $? >> 8;
}

exit __PACKAGE__->_server(*DATA) unless caller;

1;

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Admin::Server - Parallel SSH client server side code

=head1 VERSION

version 1.11

=head1 SYNOPSIS

 % perldoc clad

=head1 DESCRIPTION

This module provides part of the implementation for the
L<clad> command.  See the L<clad> command for the public
interface.

=head1 SEE ALSO

=over 4

=item L<clad>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__