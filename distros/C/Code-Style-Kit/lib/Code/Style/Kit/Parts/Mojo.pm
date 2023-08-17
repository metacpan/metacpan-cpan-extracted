package Code::Style::Kit::Parts::Mojo;
use strict;
use warnings;
our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: Mojo-based OO


use Import::Into;
use Carp;

sub feature_class_default { 0 }
sub feature_class_takes_arguments { 1 }
sub feature_class_export {
    my ($self, $caller, @arguments) = @_;

    croak "can't be both a class and a role"
        if $self->is_feature_requested('role');

    require Mojo::Base;
    Mojo::Base->import::into(
        $caller,
        @arguments ? ( $arguments[0] ) : ( '-base' ),
    );
}

sub feature_role_default { 0 }
sub feature_role_export {
    my ($self, $caller) = @_;

    croak "can't be both a class and a role"
        if $self->is_feature_requested('class');

    require Mojo::Base;
    Mojo::Base->import::into(
        $caller, '-role',
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Style::Kit::Parts::Mojo - Mojo-based OO

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Mojo);
  1;

Then:

  package My::Class;
  use My::Kit class => [ 'My::Base::Class' ];

  # this is now a Mojo class, extending My::Base::Class

  package My::Role;
  use My::Kit 'role';

  # this is now a Mojo role

=head1 DESCRIPTION

This part defines the C<class> and C<role> features, which import L<<
C<Mojo::Base> >>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
