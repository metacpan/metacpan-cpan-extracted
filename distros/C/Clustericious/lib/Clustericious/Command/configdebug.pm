package Clustericious::Command::configdebug;
 
use strict;
use warnings;
use 5.010001;
use Mojo::Base 'Clustericious::Command';
use Clustericious::Config;
use YAML::XS qw( Dump );

# ABSTRACT: Debug a clustericious configuration file
our $VERSION = '1.27'; # VERSION


has description => <<EOT;
Print the various stages of the clustericious app configuration file
EOT

has usage => <<EOT;
usage $0: configdebug
Print the various stages of the clustericious app configuration file
EOT

sub run
{
  my($self, $name) = @_;
  my $app_name = $name // ref($self->app);

  $ENV{MOJO_TEMPLATE_DEBUG} = 1;

  my $exit = 0;

  eval { 
    my $config = Clustericious::Config->new($app_name, sub {
      my $type = shift;

      if($type eq 'pre_rendered')
      {
        my($src) = @_;
        my $data;
        if(ref $src)
        {
          say "[SCALAR :: template]";
          $data = $$src;
        }
        else
        {
          say "[$src :: template]";
          open my $fh, '<', $src;
          local $/;
          $data = <$fh>;
          close $fh;
        }
        chomp $data;
        say $data;
      }
      elsif($type eq 'rendered')
      {
        my($file, $content) = @_;
        say "[$file :: interpreted]";
        chomp $content;
        say $content;
      }
      elsif($type eq 'not_found')
      {
        say STDERR "ERROR: unable to find $_[0]";
        $exit = 2;
      }
    });

    say "[merged]";
    print Dump({ %$config });

  };
  
  if(my $error = $@)
  {
    say STDERR "ERROR: in syntax: $error";
    $exit = 2;
  }

  exit $exit;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::configdebug - Debug a clustericious configuration file

=head1 VERSION

version 1.27

=head1 SYNOPSIS

Given a L<YourApp> clustericious L<Clustericious::App> and C<yourapp> starter script:

 % yourapp configdebug

or

 % clustericious configdebug YourApp

=head1 DESCRIPTION

This command prints out:

=over 4

=item

The pre-processed template configuration for each configuration file used by your application.

=item

The post-processed template configuration for each configuration file used by your application.

=item

The final merged configuration

=back

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
