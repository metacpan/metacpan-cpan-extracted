package Catalyst::Plugin::Server::JSONRPC::DispatchType::JSONRPCPath;

use strict;
use base qw/Catalyst::DispatchType::Path/;
use Text::SimpleTable;
use Data::Dumper;

__PACKAGE__->mk_accessors(qw/config/);

=head1 NAME

Catalyst::Plugin::Server::JSONRPC::DispatchType::JSONRPCPath - JSONRPCPath DispatchType

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

=head1 METHODS

=head2 $self->list($c)

Generates a nice debug-table containing the JSONRPCPath methods.

=cut

sub list {
    my ( $self, $c ) = @_;
    my $prefixwarning = 1;

    ### Because this is the only place where we need the config
    $self->config( $c->server->jsonrpc->config );

    my $paths = Text::SimpleTable->new(
                            [ 36, 'JSONRPCPath Method' ],
                            [ 37, 'Private' ]
                        );

    for my $method ( sort keys %{ $self->methods($c) } ) {
        my $action = $self->methods($c)->{$method};
        $paths->row( $method, "/$action" );
    }

    $c->log->debug( "Loaded JSONRPC entrypoint:\n    host.tld" .
                        $self->config->path);
    $c->log->debug( "Loaded JSONRPCPath Method actions:\n" . $paths->draw )
      if ( keys %{ $self->methods($c) } );
    $c->log->debug( 'WARNING: JSONRPC prefix set, but _not_ used!' ) if
                    ($prefixwarning && $self->config->prefix);

}

=head2 $self->methods()

Returns a hashref containing 'methods' => action_object mappings. Methods
are in the form of "example.bla.get"

=cut

sub methods {
    my ( $self, $c ) = @_;
    my $prefixwarning = 1;

    ### Cached list of method => path mapping
    return $self->{methods} if $self->{methods};
    $self->{methods} = {};

    ### Because this is the only place where we need the config
    $self->config( $c->server->jsonrpc->config)
            unless $self->config;

    for my $path ( sort keys %{ $self->{_paths} } ) {
        my $action = UNIVERSAL::isa($self->{_paths}->{$path}, 'ARRAY') ?
                $self->{_paths}->{$path}->[0] : $self->{_paths}->{$path};
        $path = "/$path" unless $path eq '/';
        my ($method) = $path =~ m|^/?(.*)$|;
        my $separator= $self->config->separator;
        my $prefix = $self->config->prefix;
        $method =~ s|/|$separator|g;
        $method =~ s|^$prefix\.||g;
        $self->{methods}->{$method} = $action;
    }

    return $self->{methods};
}

=head2 $self->register( $c, $action )

Registers the JSONRPCPath actions into the dispatcher

=cut

sub register {
    my ( $self, $c, $action ) = @_;

    my $attrs = $action->attributes;
    my @register;

    foreach my $r ( @{ $attrs->{JSONRPCPath} || [] } ) {
        unless ($r) {
            $r = $action->namespace;
            $r = '/' unless $r;
        }
        elsif ( $r !~ m!^/! ) {    # It's a relative path
            $r = $action->namespace . "/$r";
        }
        push( @register, $r );
    }

    if ( $attrs->{JSONRPCGlobal} ) {
        push( @register, $action->name );    # Register sub name against root
    }

    if ( $attrs->{JSONRPCLocal} || $attrs->{JSONRPC} ) {
        push( @register, join( '/', $action->namespace, $action->name ) );

        # Register sub name as a relative path
    }

    $self->register_path( $c, $_, $action ) for @register;

    $c->server->jsonrpc->dispatcher->{Path} = $self
        unless (scalar %{$c->server->jsonrpc->dispatcher});

    return 1 if @register;
    return 0;
}

sub match {
    my $self        = shift;
    my ($c, $name)  = @_;

    ### This subtile line is available to prevent backing up to
    ### a default action
    return unless $c->req->path eq $name;

    $self->SUPER::match( @_ );
}


=head1 AUTHOR

Sergey Nosenko C<darknos@cpan.org>

=head1 BASED ON

Catalyst::Plugin::Server::JSONRPC::DispatchType::JSONRPCPath of

Michiel Ootjers C<michiel@cpan.org>
Jos Boumans, C<kane@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
