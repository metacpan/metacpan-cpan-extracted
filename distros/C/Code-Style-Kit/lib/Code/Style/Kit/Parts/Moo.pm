package Code::Style::Kit::Parts::Moo;
use strict;
use warnings;
our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: Moo-based OO


use Import::Into;
use Carp;

sub feature_class_default { 0 }
sub feature_class_export {
    my ($self, $caller) = @_;

    croak "can't be both a class and a role"
        if $self->is_feature_requested('role');

    require Moo;
    Moo->import::into($caller);
    $self->maybe_also_export('types');
}

sub feature_role_default { 0 }
sub feature_role_export {
    my ($self, $caller) = @_;

    croak "can't be both a class and a role"
        if $self->is_feature_requested('class');

    require Moo::Role;
    Moo::Role->import::into($caller);
    $self->maybe_also_export('types');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Style::Kit::Parts::Moo - Moo-based OO

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Moo);
  1;

Then:

  package My::Class;
  use My::Kit 'class';

  # this is now a Moo class

  package My::Role;
  use My::Kit 'role';

  # this is now a Moo role

=head1 DESCRIPTION

This part defines the C<class> and C<role> features, which import L<<
C<Moo> >> and L<< C<Moo::Role> >> respectively.

If your kit defines a C<types> feature, it will be imported as well.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
