package Clustericious::Command::configdump;
 
use strict;
use warnings;
use 5.010001;
use Mojo::Base 'Clustericious::Command';
use Clustericious::Config;
use YAML::XS qw( Dump );

# ABSTRACT: Dump a clustericious configuration
our $VERSION = '1.27'; # VERSION


has description => <<EOT;
Dump clustericious configuration
EOT

has usage => <<EOT;
usage $0: configdump [ app ]
EOT

sub run
{
  my($self, $name) = @_;
  my $app_name = $name // ref($self->app);

  my $config = eval {
    Clustericious::Config->new($app_name, sub {
      my($type, $name) = @_;
      if($type eq 'not_found')
      {
        say STDERR "ERROR: unable to find $name";
        exit 2;
      }
    })
  };
  
  if(my $error = $@)
  {
    say STDERR "ERROR: in syntax: $error";
    exit 2;
  }
  else
  {
    print Dump({ %$config });
  }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::configdump - Dump a clustericious configuration

=head1 VERSION

version 1.27

=head1 SYNOPSIS

Given a L<YourApp> clustericious L<Clustericious::App> and C<yourapp> starter script:

 % yourapp configdump

or

 % clustericious configdump YourApp

=head1 DESCRIPTION

This command prints out the post-processed configuration in L<YAML> format.

=head1 SEE ALSO

L<Clustericious::Config>,
L<Clustericious>

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
