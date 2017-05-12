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

package App::CPAN2Pkg::Module;
# ABSTRACT: poe session to drive a module packaging
$App::CPAN2Pkg::Module::VERSION = '3.004';
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use App::CPAN2Pkg::Repository;
use App::CPAN2Pkg::Types;


# -- public attributes


has name => ( ro, required, isa=>'Str' );
has local    => ( ro, isa=>"App::CPAN2Pkg::Repository", default=>sub{ App::CPAN2Pkg::Repository->new } );
has upstream => ( ro, isa=>"App::CPAN2Pkg::Repository", default=>sub{ App::CPAN2Pkg::Repository->new } );

has prereqs => (
    ro, auto_deref,
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        _add_prereq => 'push',
    },
);

# -- public methods


sub add_prereq {
    my ($self, $p) = @_;
    $self->_add_prereq($p);
    $self->local->add_prereq($p);
    $self->upstream->add_prereq($p);
}


1;

__END__

=pod

=head1 NAME

App::CPAN2Pkg::Module - poe session to drive a module packaging

=head1 VERSION

version 3.004

=head1 DESCRIPTION

C<App::CPAN2Pkg::Module> implements a class describing a module to be
built, with its prereqs and their availability.

=head1 ATTRIBUTES

=head2 name

The name of the Perl module, eg C<App::CPAN2Pkg>.

=head2 local

The L<App::CPAN2Pkg::Repository> for the local system.

=head2 upstream

The L<App::CPAN2Pkg::Repository> for the upstream Linux distribution.

=head2 prereqs

The modules listed as prerequesites for the module. Note that each
repository (local & upstream) keep in addition a list of prereqs that
are B<missing>. This list keeps the module prereqs, even after they have
been fulfilled on the repositories.

=head1 METHODS

=head2 add_prereq

    $module->add_prereq( $modname );

Add a prerequesite to the module, also list it as missing on both local
& upstream repositories.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
