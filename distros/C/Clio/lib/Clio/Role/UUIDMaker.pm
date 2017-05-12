
package Clio::Role::UUIDMaker;
BEGIN {
  $Clio::Role::UUIDMaker::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Role::UUIDMaker::VERSION = '0.02';
}
# ABSTRACT: Role for creating UUID

use strict;
use Moo::Role;
use Data::UUID;


sub create_uuid {
    return Data::UUID->new->create_str;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Role::UUIDMaker - Role for creating UUID

=head1 VERSION

version 0.02

=head1 DESCRIPTION

UUID generator role. Used to identify processes and clients.

=head1 METHODS

=head2 create_uuid

Returns UUID in string format

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

