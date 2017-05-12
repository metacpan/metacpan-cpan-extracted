package Catalyst::Plugin::Pluggable;

use strict;

our $VERSION = '0.04';

=head1 NAME

Catalyst::Plugin::Pluggable - Plugin for Pluggable Catalyst applications

=head1 SYNOPSIS

    # use it
    use Catalyst qw/Pluggable/;

    $c->forward_all('test');
    $c->forward_all( 'test', [ 'foo', 'bar' ], '$b->{class} cmp $a->{class}' );
    $c->forward_all( 'test', '$b->{class} cmp $a->{class}' );

=head1 DESCRIPTION

Pluggable Catalyst applications. 

=head2 METHODS

=head3 $c->forward_all($action,[$argsref $sort])

    Like C<forward>, but forwards to all actions with the same name in the
    whole application, ordered by class name by default.
    The optional $sortref parameter allows you to pass a code reference
    to a function that will be used in the sort function. The default
    here is { $a->{class} cmp $b->{class} }

=cut

sub forward_all {
    my ( $c, $name, $args, $sort ) = @_;
    my @actions;
    my $walker = sub {
        my ( $walker, $parent, $prefix ) = @_;
        $prefix .= $parent->getNodeValue || '';
        $prefix .= '/' unless $prefix =~ /\/$/;
        my $node = $parent->getNodeValue->actions;

        for my $action ( keys %{$node} ) {
            my $action_obj = $node->{$action};
            next if $action_obj->{name} !~ /^$name$/;
            push @actions, $action_obj;
        }

        $walker->( $walker, $_, $prefix ) for $parent->getAllChildren;
    };
    $walker->( $walker, $c->dispatcher->tree, '' );
    if ( ($args) && ( ref $args ne 'ARRAY' ) ) {
        $sort = $args;
        $args = undef;
    }
    my $code;
    eval "\$code = sub { $sort }" if $sort;
    $code ||= sub { $a->{class} cmp $b->{class} };
    @actions = sort $code @actions if @actions;
    for my $action (@actions) {
        my $reverse = $action->{reverse};
        $c->forward( "/$reverse", $args );
    }
    return $c->state;
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
