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

package App::Magpie::Action::BSWait;
# ABSTRACT: bswait command implementation
$App::Magpie::Action::BSWait::VERSION = '2.010';
use LWP::UserAgent;
use Moose;

with 'App::Magpie::Role::Logging';



sub run {
    my ($self, $opts) = @_;
    $self->log( "checking bs wait hint" );

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->head('http://pkgsubmit.mageia.org/');
    $self->log_fatal( $response->status_line ) unless $response->is_success;

    my $sleep = $response->header( "x-bs-throttle" );
    $self->log( "bs recommends to sleep $sleep seconds" );

    if ( !$opts->{nosleep} && $sleep ) {
        $self->log_debug( "sleeping $sleep seconds" );
        sleep($sleep);
    }

    return $sleep;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::BSWait - bswait command implementation

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    my $bswait = App::Magpie::Action::BSWait->new;
    $bswait->run;

=head1 DESCRIPTION

This module implements the C<bswait> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    App::Magpie::Action::BSWait->new->run( $opts );

Check Mageia build-system and fetch the wait hint. Sleep according to
this hint, unless $opts->{nosleep} is true.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
