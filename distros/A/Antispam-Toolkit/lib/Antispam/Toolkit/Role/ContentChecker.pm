package Antispam::Toolkit::Role::ContentChecker;
BEGIN {
  $Antispam::Toolkit::Role::ContentChecker::VERSION = '0.08';
}

use strict;
use warnings;
use namespace::autoclean;

use Antispam::Toolkit::Types qw( ArrayRef NonEmptyStr );
use List::AllUtils qw( first );

use Moose::Role;
use MooseX::Params::Validate qw( validated_hash );

requires qw( check_content _build_accepted_content_types );

has _accepted_content_types => (
    is       => 'bare',
    isa      => ArrayRef [NonEmptyStr],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_accepted_content_types',
);

around check_content => sub {
    my $orig = shift;
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        content_type => { isa => NonEmptyStr },
        content      => { isa => NonEmptyStr },
    );

    return
        unless first { $_ eq $p{content_type} }
        @{ $self->_accepted_content_types() };

    return $self->$orig(@_);
};

1;

# ABSTRACT: A role for classes which check whether a piece of content is spam



=pod

=head1 NAME

Antispam::Toolkit::Role::ContentChecker - A role for classes which check whether a piece of content is spam

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  package MyContentChecker;

  use Moose;

  with 'Antispam::Toolkit::Role::ContentChecker';

  sub check_content { ... }

=head1 DESCRIPTION

This role specifies an interface for classes which check whether a piece of
content is spam.

=head1 ATTRIBUTES

This role provides one attribute:

=head2 $checker->_accepted_content_types()

This is an array reference of non-empty strings. Each string should be a MIME
type. This attribute cannot be set by the constructor. The class consuming the
role must provide a C<< $checker->_build_accepted_content_types() >> method.

=head1 REQUIRED METHODS

Classes which consume this method must provide two methods:

=head2 $checker->_build_accepted_content_types()

This method should return an array reference of mime types which the class can
check, such as "text/html", "text/plain", etc.

=head2 $checker->check_content( ... )

This method implements the actual spam checking for a piece of content. It
must accept the following named parameters:

=over 4

=item * content_type

The MIME type for the piece of content.

=item * content

The content itself. This must be a non-empty string.

=back

=head1 METHODS

This role provides an around modifier for the C<< $checker->check_content() >>
method. The modifier does validation on all the parameters, so there's no need
to implement this in the class itself.

If the provided C<content_type> is not one of the accepted types, the original
method will not be called.

=head1 BUGS

See L<Antispam::Toolkit> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__


