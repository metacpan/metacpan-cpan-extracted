package Antispam::Toolkit::Role::URIChecker;
BEGIN {
  $Antispam::Toolkit::Role::URIChecker::VERSION = '0.08';
}

use strict;
use warnings;
use namespace::autoclean;

use Antispam::Toolkit::Types qw( NonEmptyStr );

use Moose::Role;
use MooseX::Params::Validate qw( validated_hash );

requires 'check_uri';

around check_uri => sub {
    my $orig = shift;
    my $self = shift;
    my %p    = validated_hash(
        \@_,
        uri => { isa => NonEmptyStr },
    );

    $self->$orig(%p);
};

1;

# ABSTRACT: A role for classes which check whether a uri is spam



=pod

=head1 NAME

Antispam::Toolkit::Role::URIChecker - A role for classes which check whether a uri is spam

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  package MyURIChecker;

  use Moose;

  with 'Antispam::Toolkit::Role::URIChecker';

  sub check_uri { ... }

=head1 DESCRIPTION

This role specifies an interface for classes which check whether a specific
uri is spam.

=head1 REQUIRED METHODS

Classes which consume this method must provide one method:

=head2 $checker->check_uri( uri => ... )

This method implements the actual spam checking for a uri. The uri will be
passed as a named parameter.

=head1 METHODS

This role provides an around modifier for the C<< $checker->check_uri() >>
method. The modifier does validation on all the parameters, so there's no need
to implement this in the class itself.

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

