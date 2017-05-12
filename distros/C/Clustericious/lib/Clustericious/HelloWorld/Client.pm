package Clustericious::HelloWorld::Client;

use strict;
use warnings;
use Clustericious::Client;
use Clustericious::Client::Command;

# ABSTRACT: Clustericious hello world client
our $VERSION = '1.24'; # VERSION

route 'welcome' => "GET",  '/';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::HelloWorld::Client - Clustericious hello world client

=head1 VERSION

version 1.24

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
