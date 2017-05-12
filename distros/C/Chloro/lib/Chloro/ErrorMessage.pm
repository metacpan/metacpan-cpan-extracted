package Chloro::ErrorMessage;
BEGIN {
  $Chloro::ErrorMessage::VERSION = '0.06';
}

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

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



=pod

=head1 NAME

Chloro::ErrorMessage - An error message

=head1 VERSION

version 0.06

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

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

