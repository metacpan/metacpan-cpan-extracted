use 5.014;
use strict;
use warnings;

package Banal::Role::Fallback::Moo;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: A Moo/Moose compatible incarnation of C<Banal::Role::Fallback>
# KEYWORDS: author utility

our $VERSION = '0.001';
# AUTHORITY


use namespace::autoclean;
use Moo::Role;
  with 'Banal::Role::Fallback::Tiny';



1;

=pod

=encoding UTF-8

=head1 NAME

Banal::Role::Fallback::Moo - A Moo/Moose compatible incarnation of C<Banal::Role::Fallback>

=head1 VERSION

version 0.001

=head1 DESCRIPTION

=for stopwords TABULO
=for stopwords GitHub DZIL

This is Moo/Moose compatible incarnation of its tiny cousin C<Banal::Role::Fallback::Tiny>.
For further info, please refer to that module.

=head1 SEE ALSO

=over 4

=item *

L<Role::Tiny>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Banal-Role-Fallback>
(or L<bug-Banal-Role-Fallback@rt.cpan.org|mailto:bug-Banal-Role-Fallback@rt.cpan.org>).

=head1 AUTHOR

Ayhan ULUSOY <dev@tabulo.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ayhan ULUSOY.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#region pod


#endregion pod
