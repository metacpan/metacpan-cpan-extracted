
package Clio::Role::HasManager;
BEGIN {
  $Clio::Role::HasManager::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Role::HasManager::VERSION = '0.02';
}
# ABSTRACT: Role for providing manager object

use strict;
use Moo::Role;


has 'manager' => (
    is => 'ro',
    required => 1,
);


has 'log' => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub {
        $_[0]->manager->c->log( ref $_[0] );
    }
);


1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Role::HasManager - Role for providing manager object

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Provides access to manager object - L<Clio::ProcessManager> for processes and
L<Clio::Server::ClientsManager> for clients.

=head1 ATTRIBUTES

=head2 manager

Returns appropriate manager object.

=head2 log

Helper shortcut to L<Clio's log|Clio/"log"> method via L<"manager"> object.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

