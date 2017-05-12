#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Sort::Package;
# ABSTRACT: package in need of a rebuild
$App::Magpie::Action::Sort::Package::VERSION = '2.010';
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use App::Magpie::URPM;


# -- public attributes


has name => ( ro, isa => "Str", required );


# -- private attributes


has provides => (
    ro, auto_deref,
    isa     => "ArrayRef[Str]",
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        nb_provides  => 'count',
        add_provides => 'push',
    },
);



has _requires => (
    ro,
    isa     => "HashRef[Str]",
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        has_no_requires => 'is_empty',
        nb_requires     => 'count',
        rm_requires     => 'delete',
        _set_requires   => 'set',
    },
);


# -- public methods


sub add_requires {
    my ($self, @reqs) = @_;
    $self->_set_requires($_=>1) for @reqs;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::Sort::Package - package in need of a rebuild

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This class represents a package to be rebuild, providing some
requirements and requiring some others.

=head1 ATTRIBUTES

=head2 name

The name of the package.

=head2 provides

The list of provides for the package.

=head1 METHODS

=head2 nb_provides

    my $nb = $pkg->nb_provides;

Return the number of provides for C<$pkg>.

=head2 add_provides

    $pkg->add_provides( @provides );

Add C<@provides> to the list of provides for C<$pkg>.

=head2 has_no_requires

    my $bool = $pkg->has_no_requires;

Return true if C<$pkg> doesn't have any more requirements.

=head2 nb_requires

    my $nb = $pkg->nb_requires;

Return the number of C<$pkg> requirements.

=head2 rm_requires

    $pkg->rm_requires( @reqs );

Remove a given list of requirements for C<$pkg>.

=head2 add_requires

    $pkg->add_requires( @reqs );

Add a given list of requires to C<$pkg>.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
