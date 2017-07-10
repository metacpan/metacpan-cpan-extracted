package AnyEvent::FTP::Server::Role::ResponseEncoder;

use strict;
use warnings;
use 5.010;
use Moo::Role;

# ABSTRACT: Server response encoder role
our $VERSION = '0.10'; # VERSION

requires 'encode';
requires 'new';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::Role::ResponseEncoder - Server response encoder role

=head1 VERSION

version 0.10

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
