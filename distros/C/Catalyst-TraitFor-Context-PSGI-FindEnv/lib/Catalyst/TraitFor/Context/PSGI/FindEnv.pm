#
# This file is part of Catalyst-TraitFor-Context-PSGI-FindEnv
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Catalyst::TraitFor::Context::PSGI::FindEnv;
{
  $Catalyst::TraitFor::Context::PSGI::FindEnv::VERSION = '0.001';
}

# ABSTRACT: Hunt down our PSGI environment, even in 5.8x

use Moose::Role;
use namespace::autoclean;


sub psgi_env {
    my ($self) = @_;

    my $env
        = $self->req->can('env')     ? $self->req->env
        : $self->engine->can('env')  ? $self->engine->env
        # no env to infiltrate
        : return
        ;

    return $env;
}

!!42;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl conditionalize

=head1 NAME

Catalyst::TraitFor::Context::PSGI::FindEnv - Hunt down our PSGI environment, even in 5.8x

=head1 VERSION

This document describes version 0.001 of Catalyst::TraitFor::Context::PSGI::FindEnv - released October 31, 2012 as part of Catalyst-TraitFor-Context-PSGI-FindEnv.

=head1 DESCRIPTION

This is a L<Catalyst> context trait that aids in finding a PSGI
environment, if one is available, even in a 5.8x environment.

Note the key part about "if one is available" :)  This is not always the case
under 5.8x.

=head1 METHODS

=head2 psgi_env

This method will attempt to locate and return the PSGI environment hashref.
If one is not found, nothing will be returned.

=head1 TRAIT APPLICATION

Neither L<CatalystX::Component::Traits> nor L<CatalystX::RoleApplicator>
handle applying context class traits at the moment.

=head2 Directly in your application class

    with 'Catalyst::TraitFor::Context::PSGI::FindEnv';

=head2 In your PSGI file

If you're only enabling this for debug purposes, it might be better to
conditionalize this in your C<app.psgi>, with something like:

    Catalyst::TraitFor::Context::PSGI::FindEnv
        ->meta
        ->apply(Class::MOP::class_of('MyApp'))
        ;

...or, as that's a bit of a mouthful:

    use Moose::Util 'ensure_all_roles';
    ensure_all_roles MyApp => 'Catalyst::TraitFor::Context::PSGI::FindEnv';

Both do the same thing (for generally indistinguishable values of "same
thing").

Note that your application class will need to be mutable (that is, not
immutable) for these approaches to work.

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/Catalyst-TraitFor-Context-PSGI-FindEnv>
and may be cloned from L<git://github.com/RsrchBoy/Catalyst-TraitFor-Context-PSGI-FindEnv.git>

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
