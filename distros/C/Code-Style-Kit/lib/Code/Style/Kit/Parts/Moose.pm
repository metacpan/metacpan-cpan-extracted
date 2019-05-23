package Code::Style::Kit::Parts::Moose;
use strict;
use warnings;
our $VERSION = '1.0.0'; # VERSION
# ABSTRACT: Moose-based OO


use Import::Into;
use Carp;
use Hook::AfterRuntime;

# Moose class
sub feature_class_export {
    my ($self, $caller) = @_;

    croak "can't be both a class and a role"
        if $self->is_feature_requested('role');

    require Moose;
    Moose->import({ into => $caller });

    after_runtime { $caller->meta->make_immutable };

    $self->maybe_also_export('types');
}
sub feature_class_order { 200 }

# extend non-moose classes
sub feature_nonmoose_export {
    require MooseX::NonMoose;
    MooseX::NonMoose->import({ into => $_[1] });
}
sub feature_nonmoose_order { 210 }

# Moose role
sub feature_role_export {
    my ($self, $caller) = @_;

    croak "can't be both a class and a role"
        if $self->is_feature_requested('class');

    require Moose::Role;
    Moose::Role->import({ into => $caller });

    $self->maybe_also_export('types');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Style::Kit::Parts::Moose - Moose-based OO

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Moose);
  1;

Then:

  package My::Class;
  use My::Kit 'class';

  # this is now a Moose class

  package My::Role;
  use My::Kit 'role';

  # this is now a Moose role

=head1 DESCRIPTION

This part defines the C<class> and C<role> features, which import L<<
C<Moose> >> and L<< C<Moose::Role> >> respectively. Class are made
immutable automatically.

If your kit defines a C<types> feature, it will be imported as well.

In addition, this part also defines the C<nonmoose> feature, to import
L<< C<MooseX::NonMoose> >>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
