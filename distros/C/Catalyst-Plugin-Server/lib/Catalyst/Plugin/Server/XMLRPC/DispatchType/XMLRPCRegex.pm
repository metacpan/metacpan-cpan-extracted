package Catalyst::Plugin::Server::XMLRPC::DispatchType::XMLRPCRegex;

use strict;
use base qw/Catalyst::DispatchType::Regex/;
use Text::SimpleTable;

=head1 NAME

Catalyst::Plugin::Server::XMLRPC::DispatchType::XMLRPCRegex - XMLRPCRegex DispatchType

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

=head1 METHODS

=head2 $self->list($c)

Generates a nice debug-table containing the XMLRPCRegex methods.

=cut

sub list {
    my ( $self, $c ) = @_;
    my $re = Text::SimpleTable->new( [ 36, 'XMLRPCRegex' ], [ 37, 'Private' ] );
    for my $regex ( @{ $self->{_compiled} } ) {
        my $action = $regex->{action};
        $re->row( $regex->{path}, "/$action" );
    }
    $c->log->debug( "Loaded XMLRPCRegex actions:\n" . $re->draw )
      if ( @{ $self->{_compiled} } );
}

=head2 $self->register( $c, $action )

Registers the XMLRPCPath actions into the dispatcher

=cut

sub register {
    my ( $self, $c, $action ) = @_;
    my $attrs = $action->attributes;
    my @register = map { @{ $_ || [] } } @{$attrs}{
                                            'XMLRPCRegex',
                                            'XMLRPCRegexp'
                                        };
    foreach
      my $r ( map { @{ $_ || [] } } @{$attrs}{
                                        'XMLRPCLocalRegex',
                                        'XMLRPCLocalRegexp'
                                    }
            )
    {
        unless ( $r =~ s/^\^// ) { $r = "(?:.*?)$r"; }
        push( @register, '^' . $action->namespace . '/' . $r );
    }

    foreach my $r (@register) {
        $self->register_path( $c, $r, $action );
        $self->register_regex( $c, $r, $action );
    }
    return 1 if @register;
    return 0;
}



=head1 AUTHOR

Michiel Ootjers C<michiel@cpan.org>
Jos Boumans, C<kane@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
