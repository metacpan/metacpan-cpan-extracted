package Antispam::Toolkit::Result;
BEGIN {
  $Antispam::Toolkit::Result::VERSION = '0.08';
}

use strict;
use warnings;

use Antispam::Toolkit::Types qw( Details NonNegativeNum );

use overload 'bool' => sub { $_[0]->score() > 0 };

use Moose;
use MooseX::StrictConstructor;

has score => (
    is       => 'ro',
    isa      => NonNegativeNum,
    required => 1,
);

has _details => (
    traits   => ['Array'],
    is       => 'bare',
    isa      => Details,
    coerce   => 1,
    default  => sub { [] },
    init_arg => 'details',
    handles  => {
        details => 'elements',
    },
);

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents the result of a spam check


__END__
=pod

=head1 NAME

Antispam::Toolkit::Result - Represents the result of a spam check

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  return Antispam::Toolkit::Result->new(
      score   => 2,
      details => [
          q{The user's ip address was found in a list of known spammers},
          q{The user's email address was found in a list of known bad email addresses},
      ],
  );

=head1 DESCRIPTION

This class represents the result of a spam check. It consists of a score and
details associated with that score.

The score is simple a non-negative number. The details are optional, and
should be provided as an array reference of strings, each of which describes
some aspect of the spam check.

=head1 METHODS

This class provides the following methods:

=head2 Antispam::Toolkit::Result->new( ... )

This method constructs a new result object. It accepts the following
attributes:

=over 4

=item * score

This attribute is required, and must be a non-negative number.

=item * details

This attribute can be either a single non-empty string or an array reference
of non-empty strings. It is not required.

=back

=head2 $result->score()

Returns the score for the result.

=head2 $result->details()

Returns I<a list> of strings. This list may be empty.

=head1 OVERLOADING

This object overloads the boolean operator. If the score is greater than 0, it
overloads as true, otherwise it overloads as false.

=head1 BUGS

See L<Antispam::Toolkit> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

