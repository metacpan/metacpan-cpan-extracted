package Clustericious::Command::configpath;

use strict;
use warnings;
use 5.010;
use Mojo::Base 'Clustericious::Command';
use Clustericious;

# ABSTRACT: Print the configuration path
our $VERSION = '1.24'; # VERSION


has description => <<EOT;
Print configuration path.
EOT

has usage => <<EOT;
usage $0: configpath
EOT

sub run
{
  my($self, @args) = @_;
  say for Clustericious->_config_path  
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::configpath - Print the configuration path

=head1 VERSION

version 1.24

=head1 SYNOPSIS

 % clustericious configpath

=head1 DESCRIPTION

Prints the Clustericious configuration path.

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
