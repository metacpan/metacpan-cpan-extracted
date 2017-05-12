package Catalyst::Plugin::XMLRPC::DispatchType::XMLRPC;

use strict;
use base qw/Catalyst::DispatchType/;
use Text::SimpleTable;

=head1 NAME

Catalyst::Plugin::XMLRPC::DispatchType::XMLRPC - XMLRPC DispatchType

=head1 SYNOPSIS

See L<Catalyst::Plugin::XMLRPC>.

=head1 DESCRIPTION

=head1 METHODS

=head2 $self->list($c)

Debug output for XMLRPC dispatch points

=cut

sub list {
    my ( $self, $c ) = @_;
    my $methods = Text::SimpleTable->new( [ 35, 'Method' ], [ 36, 'Private' ] );
    for my $method ( sort keys %{ $self->{methods} } ) {
        my $action = $self->{methods}->{$method};
        $methods->row( "$method", "/$action" );
    }
    $c->log->debug( "Loaded XMLRPC Methods:\n" . $methods->draw )
      if ( keys %{ $self->{methods} } );
}

=head2 $self->match($c)

Do nothing

=cut

sub match { return 0 }

=head2 $self->register( $c, $action )

Call register_path for every path attribute in the given $action.

=cut

sub register {
    my ( $self, $c, $action ) = @_;

    my @register = @{ $action->attributes->{XMLRPC} || [] };

    for my $method (@register) {
        $method ||= "$action";
        $method =~ s#/#.#g;
        $self->{methods}{$method} = $action;
    }

    return 1 if @register;
    return 0;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
