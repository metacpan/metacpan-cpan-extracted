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

package App::Magpie::Action::Old::Set;
# ABSTRACT: a set of AM::Old::Modules objects
$App::Magpie::Action::Old::Set::VERSION = '2.010';
use Moose;
use MooseX::Has::Sugar;


# -- public attributes


has name     => ( ro, isa=>"Str", required );


has _modules => (
    ro,
    traits  => ['Array'],
    isa     => 'ArrayRef[App::Magpie::Action::Old::Module]',
    default => sub { [] },
    handles => {
        all_modules    => 'elements',
        add_module     => 'push',
        nb_modules     => 'count',
    },
);

#--


sub nb_packages {
    my $self = shift;
    my %seen;
    @seen{
        map { $_->packages->[0] }
        $self->all_modules
    }++;
    return scalar keys %seen;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::Old::Set - a set of AM::Old::Modules objects

=head1 VERSION

version 2.010

=head1 SYNOPSIS

This class holds a set of modules that have been updated on CPAN. There
can be multiple sets - eg: core, dual, ...

=head1 ATTRIBUTES

=head2 name

The name of the set.

=head1 METHODS

=head2 all_modules

    my @modules = $set->all_modules;

Return all the modules currently in the C<$set>.

=head2 add_module

    $set->add_module( $module );

Add C<$module> to the C<$set>.

=head2 nb_modules

    my $nb = $set->nb_modules;

Return the number of modules the set is holding.

=head2 nb_packages

    my $nb = $set->nb_packages;

Return the nimber of Mageia packages the set is holding.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
