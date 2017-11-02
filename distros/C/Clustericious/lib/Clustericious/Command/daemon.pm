package Clustericious::Command::daemon;

use strict;
use warnings;
use base qw( Clustericious::Command );
use Mojolicious::Command::daemon;

# ABSTRACT: Clustericious command to stat nginx
our $VERSION = '1.27'; # VERSION


sub description { Mojolicious::Command::daemon->new->description };
sub usage       { Mojolicious::Command::daemon->new->usage       };

sub run
{
  my($self, @args) = @_;
  
  if(!grep /^-l/, @args)
  {
    if(my $url = $self->app->config->{url})
    {
      unshift @args, -l => $url;
    }
  }

  Mojolicious::Command::daemon::run($self, @args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::daemon - Clustericious command to stat nginx

=head1 VERSION

version 1.27

=head1 DESCRIPTION

This is a simple wrapper around L<Mojolicious::Command::daemon> to use
the app's configured URL by default.

=head1 NAME

Clustericious::Command::daemon - Daemon command

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
