#
# This file is part of App-CPAN2Pkg
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package App::CPAN2Pkg::Repository;
# ABSTRACT: repository details for a given module
$App::CPAN2Pkg::Repository::VERSION = '3.004';
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use App::CPAN2Pkg::Types;


# -- public attributes


has status  => ( rw, isa=>"Status", default=>"not started" );
has _prereqs => (
    ro,
    traits  => ['Hash'],
    isa     => 'HashRef[Str]',
    default => sub { {} },
    handles => {
        _add_prereq => 'set',
        prereqs     => 'keys',
        rm_prereq   => 'delete',
        can_build   => 'is_empty',
        miss_prereq => 'exists',
    },
);


# -- public methods


# methods above provided for free by moose traits.


sub add_prereq {
    my ($self, $modname) = @_;
    $self->_add_prereq( $modname, $modname );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

App::CPAN2Pkg::Repository - repository details for a given module

=head1 VERSION

version 3.004

=head1 DESCRIPTION

C<cpan2pkg> deals with two kinds of systems: the local system, and
upstream distribution repository. A module has some characteristics on
both systems (such as availability, etc). Those characteristics are
gathered in this module.

=head1 ATTRIBUTES

=head2 status

The status of the module: available, building, etc.

=head2 prereqs

    my @prereqs = $repo->prereqs;

The prerequesites needed before attempting to build the module.

=head1 METHODS

=head2 can_build

    my $bool = $repo->can_build;

Return true if there are no more missing prereqs.

=head2 miss_prereq

    my $bool = $repo->miss_prereq( $modname );

Return true if C<$modname> is missing on the system.

=head2 rm_prereq

    $repo->rm_prereq( $modname );

Remove C<$modname> as a missing prereq on the repository.

=head2 add_prereq

    $repo->add_prereq( $modname );

Mark a prereq as missing on the repository.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
