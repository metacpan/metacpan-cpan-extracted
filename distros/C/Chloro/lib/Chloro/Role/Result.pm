package Chloro::Role::Result;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose::Role;

requires 'key_value_pairs';

1;

# ABSTRACT: An interface-only role for results

__END__

=pod

=encoding UTF-8

=head1 NAME

Chloro::Role::Result - An interface-only role for results

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This role defines an interface for all result objects.

It requires one method, C<< $result->key_value_pairs() >>.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Chloro> or via email to L<bug-chloro@rt.cpan.org|mailto:bug-chloro@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Chloro can be found at L<https://github.com/autarch/Chloro>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
