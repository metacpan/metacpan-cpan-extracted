package Chloro::ErrorMessage;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose;
use MooseX::StrictConstructor;

use Chloro::Types qw( NonEmptyStr );

has category => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has text => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An error message

__END__

=pod

=encoding UTF-8

=head1 NAME

Chloro::ErrorMessage - An error message

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    print $message->category . ': ' . $message->text();

=head1 DESCRIPTION

This class represents an error message. A message has a category and message
text.

=head1 METHODS

This class has the following methods:

=head2 $error->category()

This is a string that tells what kind of error message this is. By default,
Chloro only uses "invalid" and "missing", but there's nothing preventing you
from using other categories in your code.

=head2 $error->text()

The text of the error message.

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
