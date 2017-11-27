package Chloro::Role::ResultSet;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose::Role;

use Chloro::Types qw( HashRef Result );

has _results => (
    traits   => ['Hash'],
    isa      => HashRef [Result],
    init_arg => 'results',
    required => 1,
    handles  => {
        results        => 'elements',
        result_for     => 'get',
        _result_values => 'values',
    },
);

1;

# ABSTRACT: An interface-only for resultset classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Chloro::Role::ResultSet - An interface-only for resultset classes

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This role defines an interface for all resultsets, and is shared by the
L<Chloro::ResultSet> and L<Chloro::Result::Group> classes.

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
