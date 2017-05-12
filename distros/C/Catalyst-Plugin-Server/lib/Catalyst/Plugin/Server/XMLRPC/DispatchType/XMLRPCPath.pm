package Catalyst::Plugin::Server::XMLRPC::DispatchType::XMLRPCPath;

use strict;
use base qw/Catalyst::DispatchType::Path/;
use Text::SimpleTable;
use Data::Dumper;
use Scalar::Util 'reftype';

__PACKAGE__->mk_accessors(qw/config/);

=head1 NAME

Catalyst::Plugin::Server::XMLRPC::DispatchType::XMLRPCPath - XMLRPCPath DispatchType

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

=head1 METHODS

=head2 $self->list($c)

Generates a nice debug-table containing the XMLRPCPath methods.

=cut

sub list {
    my ( $self, $c ) = @_;
    my $prefixwarning = 1;

    ### Because this is the only place where we need the config
    $self->config( $c->server->xmlrpc->config );

    my $paths = Text::SimpleTable->new(
                            [ 36, 'XMLRPCPath Method' ],
                            [ 37, 'Private' ]
                        );

    for my $method ( sort keys %{ $self->methods($c) } ) {
        my $action = $self->methods($c)->{$method};
        $paths->row( $method, "/$action" );
    }

    $c->log->debug( "Loaded XMLRPC entrypoint:\n    host.tld" .
                        $self->config->path);
    $c->log->debug( "Loaded XMLRPCPath Method actions:\n" . $paths->draw )
      if ( keys %{ $self->methods($c) } );
    $c->log->debug( 'WARNING: XMLRPC prefix set, but _not_ used!' ) if
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
    $self->config( $c->server->xmlrpc->config)
            unless $self->config;

    for my $path ( sort keys %{ $self->{_paths} } ) {
        my $action = (reftype($self->{_paths}->{$path}) eq 'ARRAY') ?
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

Registers the XMLRPCPath actions into the dispatcher

=cut

sub register {
    my ( $self, $c, $action ) = @_;

    my $attrs = $action->attributes;
    my @register;

    foreach my $r ( @{ $attrs->{XMLRPCPath} || [] } ) {
        unless ($r) {
            $r = $action->namespace;
            $r = '/' unless $r;
        }
        elsif ( $r !~ m!^/! ) {    # It's a relative path
            $r = $action->namespace . "/$r";
        }
        push( @register, $r );
    }

    if ( $attrs->{XMLRPCGlobal} ) {
        push( @register, $action->name );    # Register sub name against root
    }

    if ( $attrs->{XMLRPCLocal} || $attrs->{XMLRPC} ) {
        push( @register, join( '/', $action->namespace, $action->name ) );

        # Register sub name as a relative path
    }

    $self->register_path( $c, $_, $action ) for @register;

    $c->server->xmlrpc->dispatcher->{Path} = $self
        unless (scalar %{$c->server->xmlrpc->dispatcher});

    return 1 if @register;
    return 0;
}

sub match {
    my $self        = shift;
    my ($c, $name)  = @_;

    ### This subtile line is available to prevent backing up to
    ### a default action
    return unless $c->req->path eq $name;

    $self->next::method( @_ );
}


=head1 AUTHOR

Michiel Ootjers C<michiel@cpan.org>
Jos Boumans, C<kane@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
