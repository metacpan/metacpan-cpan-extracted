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

package App::Magpie::URPM;
# ABSTRACT: magpie interface to L<URPM>
$App::Magpie::URPM::VERSION = '2.010';
use MooseX::Singleton;
use MooseX::Has::Sugar;
use URPM;

with "App::Magpie::Role::Logging";


# -- private attributes


has _urpm => (
    ro, lazy_build,
    isa     => "URPM",
    handles => {
        packages => "packages_by_name",
    },
);


# -- initialization

sub _build__urpm {
    my ($self) = @_;

    my $urpm = URPM->new;
    my @hdlists = glob "/var/lib/urpmi/*/synthesis.hdlist.cz";

    foreach my $hdlist ( @hdlists ) {
        $self->log_debug( "parsing $hdlist" );
        $urpm->parse_synthesis( $hdlist );
    }

    return $urpm;
}

# -- public methods


sub packages_providing {
    my ($self, $module) = @_;
    return $self->_urpm->packages_providing("perl($module)");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::URPM - magpie interface to L<URPM>

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    my $urpm = App::Magpie::URPM->instance;

=head1 DESCRIPTION

This module is a wrapper around URPM, and allows to query it for Perl
modules requires & provides.

=head1 METHODS

=head2 packages

    my @pkgs = $urpm->packages( $name );

Return Mageia packages (plural because of multiple archs) which name is
C<$name>.

=head2 packages_providing

    my @pkgs = $urpm->packages_providing( $module );

Return the list of Mageia packages providing a given Perl C<$module>.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
