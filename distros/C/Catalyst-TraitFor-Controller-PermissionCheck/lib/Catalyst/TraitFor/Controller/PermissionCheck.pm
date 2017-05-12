package Catalyst::TraitFor::Controller::PermissionCheck;
BEGIN {
  $Catalyst::TraitFor::Controller::PermissionCheck::VERSION = '0.04';
}

use Moose::Role;
use Try::Tiny;

## ABSTRACT: Provides an opinionated method for verifying permissions on a per-action basis by inspecting the user.


# Requires setup in the consuming class.
requires 'setup';


has 'permissions' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [ 'Hash' ],
    default => sub { { } },
    lazy    => 1,
    handles => {
        'get_permission_for_action' => 'get',
        'has_permissions' => 'count',
    }
);


has 'allow_by_default' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 1; },
    lazy    => 1,
);


sub fetch_permissions {
    my ( $self, $c ) = @_;
    return $c->stash->{context}->{permissions} || {};
}


after 'setup' => sub {
    my ( $self, $c ) = @_;
    my $namespace = $self->action_namespace($c);
    my $chain     = $c->dispatcher->expand_action($c->action);

    my @actions   = grep { $_->namespace eq $namespace } @{ $chain->chain };
    # XX This should crawl the entire action chain and iterate to find
    # permissions. But it doesn't, so supply a patch!
    my $action = $actions[-1] ? $actions[-1]->name : $c->action->name;

    my $perm;
    if ( $c->req->method eq 'GET' ) {
        $perm = $self->get_permission_for_action( $action );
    } else {
        # Not a GET request, so look up the $action_PUT style actions that
        # Catalyst::Controller::REST uses.
        $perm = $self->get_permission_for_action( $action . '_' . $c->req->method);
        $c->log->debug("Nothing on top level, checking req method: $action") if $c->debug;
    }
    # Still don't have permissions, look at setup
    if ( not defined $perm ) {
        $perm = $self->get_permission_for_action( 'setup' );
    }

    if ( not defined $perm and not $self->allow_by_default ) {
        $c->log->error("Action misconfiguration! allow_by_default is off but this action ($action) has no permissions configured (nor a setup action)");
        $c->detach('permission_denied');
    }
    elsif ( defined $perm and
            not grep { exists $self->fetch_permissions($c)->{$_} } @$perm
    ) {
        $c->log->info(
            "Access denied for user: " .
            ( $c->user_exists ? $c->user->name : 'anonymous' ) .
            ", require permissions @$perm for action $action, only has: " .
            join(', ', keys %{ $self->fetch_permissions($c) } )
        );
        $c->detach('permission_denied');
    }
};

no Moose::Role;
1;



=pod

=head1 NAME

Catalyst::TraitFor::Controller::PermissionCheck - Provides an opinionated method for verifying permissions on a per-action basis by inspecting the user.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    package MyApp::Controller::Something;

    use Moose;

    BEGIN { extends 'Catalyst::Controller'; }

    # Include the role here
    with 'Catalyst::TraitFor::Controller::PermissionCheck';

    __PACKAGE__->config(
        permissions => {
            'some_action' => [ qw/List Of Permissions Required/ ],
        },
        # Deny everything, requires all actions have permissions.
        # allow_by_default => 1 only checks if a permission entry exists
        allow_by_default => 0,
    );

    # Your root chain must be called 'setup'. This is convention must be
    # followed if you want to use this module.
    sub setup : Chained('/something_that_sets_permissions') PathPart('') CaptureArgs(0) {
        my ( $self, $c ) = @_;
        # Permissions must be in $c->stash->{context}->{permissions}
        # and you can set them here. The module only looks at the keys
        # of the hash.
        $c->stash->{context}->{permissions} = {
            'Admin' => 1,
            'Super Admin' => 1,
        }
    }

    sub some_action : Chained('setup') Args(0) {
        my ( $self, $c ) = @_;
        $c->res->body('Only accessible if permissions are ok');
    }

    sub permission_denied : Private {
        my ( $self, $c ) = @_;
        $c->res->status(403);
        $c->res->body('GTFO');
        $c->detach;
    }

    no Moose;
    1;

=head1 ATTRIBUTES

=head2 permissions

Configuration hash that is keyed by action name and should point to an
array ref of required permissions.

Set via config:

    __PACKAGE__->config(
        permissions => {
            'action_name' => [ qw/Permission List/ ]
        }
    );

=head2 allow_by_default

A boolean configuration option to control whether this module should restrict
everything or let things go and only check permissions if they exist in
the permissions hash.

=head1 METHODS

=head2 fetch_permissions

Retrieve a hashref of permissions. This may be overridden to allow alternate
sources of permissions, but by default it looks in
$c->stash->{context}->{permissions}.

=head2 setup

Before setup is called, this role inspects
C<< $c->stash->{context}->{permissions} >> for applicable roles.

It confirms permissions to access the action. This only works with
L<Catalyst::DispatchType::Chained> and will walk the entire chain and verify
access checks at each level.

=head1 CONTRIBUTORS

Andrew Nelson

=head1 AUTHOR

J. Shirley <jshirley@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

