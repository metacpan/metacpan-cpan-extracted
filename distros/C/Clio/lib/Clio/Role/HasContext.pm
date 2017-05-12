
package Clio::Role::HasContext;
BEGIN {
  $Clio::Role::HasContext::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Role::HasContext::VERSION = '0.02';
}
# ABSTRACT: Role for providing context

use strict;
use Moo::Role;


has 'c' => (
    is => 'ro',
    required => 1,
);

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Role::HasContext - Role for providing context

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Provides access to application context.

=head1 ATTRIBUTES

=head2 c

L<Clio> object.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

