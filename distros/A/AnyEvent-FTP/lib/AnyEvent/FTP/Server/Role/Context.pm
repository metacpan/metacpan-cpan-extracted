package AnyEvent::FTP::Server::Role::Context;

use strict;
use warnings;
use 5.010;
use Moo::Role;

# ABSTRACT: Server connection context role
our $VERSION = '0.09'; # VERSION

requires 'push_request';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::Role::Context - Server connection context role

=head1 VERSION

version 0.09

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
