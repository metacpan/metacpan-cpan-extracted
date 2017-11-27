package Chloro::Role::Error;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose::Role;

1;

# ABSTRACT: An interface role for error objects

__END__

=pod

=encoding UTF-8

=head1 NAME

Chloro::Role::Error - An interface role for error objects

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This role contains no methods or attributes. It is simply used to mark a class
as representing an error.

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
