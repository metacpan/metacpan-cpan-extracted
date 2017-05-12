#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.016;
use strict;
use warnings;

package App::Magpie::Action::Recent;
# ABSTRACT: recent command implementation
$App::Magpie::Action::Recent::VERSION = '2.010';
use CPAN::Recent::Uploads;
use List::AllUtils qw{ apply uniq };
use MetaCPAN::Client;
use Moose;

use App::Magpie::URPM;

with 'App::Magpie::Role::Logging';



sub run {
    my ($self) = @_;

    # get raw list of uploads
    $self->log( "fetching list of recent uploads" );
    my $dayago = time() - ( 24 * 60 * 60 );
    my @uploads = uniq
        apply { s{^.*/}{}; s{-[^-]*$}{}; s{-}{::}g; }
        CPAN::Recent::Uploads->recent( $dayago );

    # check if available within mageia
    $self->log( "filter out modules available in mageia" );
    my $urpm = App::Magpie::URPM->instance;
    my @nomageia =
        grep { scalar($urpm->packages_providing($_)) == 0 }
        @uploads;

    # raw list transformed distname such as:
    #      L/LI/LIOSHA/Geo-Openstreetmap-Parser-0.02.tar.gz
    # to:
    #      Geo::Openstreetmap::Parser
    # however, there may be some troubles due to weird numbering, or
    # tarball /dist name not matching the module(s) inside the dist. so
    # we need to check whether our wild transformation really points to
    # an existing perl module on cpan.
    $self->log( "validating modules" );
    my $mcpan = MetaCPAN::Client->new;
    my $nbvalid;
    foreach my $module ( sort @nomageia ) {
        my $result;
        eval { $result = $mcpan->module( $module ); };
        next if $@;
        say $module;
        $nbvalid++;
    }

#    $self->log( "uploads:  " . scalar(@uploads) );
#    $self->log( "nomageia: " . scalar(@nomageia) );
#    $self->log( "valid:    $nbvalid" );
    my $uploads = @uploads;
    my $percent = 100 - int( $nbvalid * 100 / $uploads );
    $self->log( "new=$uploads, not in mageia=$nbvalid, mageia coverage=$percent%" );
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::Recent - recent command implementation

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    App::Magpie::Action::Recent->new->run;

=head1 DESCRIPTION

This module implements the C<recent> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    $recent->run;

Print the list of Perl modules with recently uploaded to PAUSE and not
yet available in Mageia.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
