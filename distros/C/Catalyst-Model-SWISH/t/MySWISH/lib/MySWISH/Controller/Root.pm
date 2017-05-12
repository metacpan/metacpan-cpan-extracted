package MySWISH::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

MySWISH::Controller::Root - Root Controller for MySWISH

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

sub search : Local {
    my ( $self, $c ) = @_;

    #my ( $pager, $results, $query, $order, $total, $stime, $btime )
    my (@result) = $c->model('SWISH')->search(
        query     => $c->request->params->{q},
        page      => $c->request->params->{page} || 0,
        page_size => $c->request->params->{page_size} || 0,
        order_by  => 'swishrank desc swishtitle asc'
    );

    #warn Data::Dump::dump( \@result );

    my ( $pager, $results, $query, $order, $total, $stime, $btime ) = @result;
    $c->stash(
        search => {
            results     => $results,
            pager       => $pager,
            query       => $query,
            order       => $order,
            hits        => $total,
            search_time => $stime,
            build_time  => $btime
        }
    );
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {
}

=head1 AUTHOR

Peter Karman

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
