package Clustericious::Command::morbo;

use strict;
use warnings;
use 5.010001;
use base qw( Clustericious::Command );
use Mojolicious::Command::daemon;
use File::Which qw( which );
use Capture::Tiny qw( capture );

# ABSTRACT: Clustericious command to stat nginx
our $VERSION = '1.29'; # VERSION


sub description { 'Start application with Morbo server' };
sub usage       {
  state $usage;
  
  unless($usage)
  {
    my $command = which 'morbo';
    die "morbo not found!" unless defined $command;
    my($out, $err) = capture { system $command, '--help' };
    $usage = $err;
  }
  
  $usage;
};

sub run
{
  my($self, @args) = @_;
  
  if(my $url = $self->app->config->{url})
  {
    unshift @args, -l => $url;
  }

  my $command = which 'morbo';
  die "morbo not found!" unless defined $command;

  exec $command, @args, $0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::morbo - Clustericious command to stat nginx

=head1 VERSION

version 1.29

=head1 DESCRIPTION

This is a simple wrapper around L<morbo> to use
the app's configured URL by default.

=head1 NAME

Clustericious::Command::morbo - Run clustericious service with morbo

=head1 SEE ALSO

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
