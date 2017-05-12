package Catalyst::Plugin::Server::JSONRPC::DispatchType::JSONRPCRegex;

use strict;
use base qw/Catalyst::DispatchType::Regex/;
use Text::SimpleTable;

=head1 NAME

Catalyst::Plugin::Server::JSONRPC::DispatchType::JSONRPCRegex - JSONRPCRegex DispatchType

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

=head1 METHODS

=head2 $self->list($c)

Generates a nice debug-table containing the JSONRPCRegex methods.

=cut

sub list {
    my ( $self, $c ) = @_;
    my $re = Text::SimpleTable->new( [ 36, 'JSONRPCRegex' ], [ 37, 'Private' ] );
    for my $regex ( @{ $self->{_compiled} } ) {
        my $action = $regex->{action};
        $re->row( $regex->{path}, "/$action" );
    }
    $c->log->debug( "Loaded JSONRPCRegex actions:\n" . $re->draw )
      if ( @{ $self->{_compiled} } );
}

=head2 $self->register( $c, $action )

Registers the JSONRPCPath actions into the dispatcher

=cut

sub register {
    my ( $self, $c, $action ) = @_;
    my $attrs = $action->attributes;
    my @register = map { @{ $_ || [] } } @{$attrs}{
                                            'JSONRPCRegex',
                                            'JSONRPCRegexp'
                                        };
    foreach
      my $r ( map { @{ $_ || [] } } @{$attrs}{
                                        'JSONRPCLocalRegex',
                                        'JSONRPCLocalRegexp'
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

Sergey Nosenko C<darknos@cpan.org>

=head1 BASED ON

Catalyst::Plugin::Server::JSONRPC::DispatchType::JSONRPCRegex of

Michiel Ootjers C<michiel@cpan.org>
Jos Boumans, C<kane@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
