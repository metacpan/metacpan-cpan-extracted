use strict; use warnings;

package Catalyst::Plugin::Digress;

use Scalar::Util ();
use Carp ();

our $VERSION = '1.100';

sub digress {
	my $c = shift;

	my ( $action, $path );
	if ( Scalar::Util::blessed( $_[0] ) && $_[0]->isa( 'Catalyst::Action' ) ) {
		$action = shift;
	}
	else {
		$path   = shift;
		$path   = $c->stack->[-1]->namespace . '/' . $path if $path !~ m!/!;
		$action = $c->dispatcher->get_action_by_path( $path )
			or Carp::croak "Cannot digress to nonexistant action '$path'";
	}

	my $scope_guard = bless [ $c ], 'Catalyst::Plugin::Digress::_ScopeGuard';
	if ( $c->use_stats ) { # basically Catalyst::_stats_start_execute with less nonsense
		my $action_name = $action->reverse;
		my $uid = $action_name . ++$c->counter->{ $action_name };
		my $stats_info = '-> ' . ( $action_name =~ /->/ ? '' : '/' ) . $action_name;
		my ( $parent ) = grep exists $c->counter->{ $_ }, $c->stack->[-1] || ();
		$c->stats->profile(
			begin => $stats_info,
			uid   => $uid,
			$parent ? ( parent => $parent . $c->counter->{ $parent } ) : (),
		);
		push @$scope_guard, $stats_info;
	}
	push @{ $c->stack }, $action;

	# using a scope guard to unwind the Catalyst stack allows this call to
	# happen as the last thing in the function, which avoids the need to
	# explicitly recreate caller context with wantarray
	$action->execute( $c->components->{ $action->class }, $c, @_ );
}

sub Catalyst::Plugin::Digress::_ScopeGuard::DESTROY {
	my ( $c, $stats_info ) = @{ $_[0] };
	$c->stats->profile( end => $stats_info ) if $stats_info;
	pop @{ $c->stack };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Digress - A cleaner, simpler, action-only $c->forward

=head1 SYNOPSIS

 $c->digress( 'some/other/action' );
 $c->digress( 'action_in_same_controller' );
 $c->digress( $self->action_for( 'action_in_same_controller' ) );
 
 my %form = $c->digress( 'validate_params', {
   name  => { required => 1 },
   email => { type => 'Str' },
 } );

 $c->digress( $c->view ); # FAIL: cannot digress to components

=head1 DESCRIPTION

This plugin gives you the useful part of the Catalyst C<forward> method without
the weirdness (or the madness).

=head1 METHODS

=head2 C<digress>

This is akin to C<forward>, with the following differences:

=over 2

=item * It does not catch exceptions (the most important benefit).

=item * It passes parameters like in a normal Perl method call.

=item * It does not mess with C<< $c->request->arguments >>.

=item * It preserves list vs scalar context for the call.

=item *

It does not walk the Perl call stack every time (or ever, even once)
to figure out what its own name was (or for any other purpose).

=item *

It cannot forward to components, only actions
(because don’t ask how forwarding to components works).

=back

In other words, is almost identical to a straight method call:

 package MyApp::Controller::Some;
 sub other_action : Private { ... }

 package MyApp::Controller::Root;
 sub index : Path {
   my ( $c, @some_args ) = ( shift, @_ );
   # ...
   my @some_return = $c->digress( '/some/other_action', @any_old_args );
   # this is nearly identical to the following line:
   my @some_return = $c->controller( 'Some' )->other_action( $c, @any_old_args );
   # ...
 }

Except, of course, that it takes an action path instead of a plain method name,
and it maintains the Catalyst action stack for you just like C<forward> would,
which keeps various Catalyst mechanisms working, such as calling C<forward> and
friends from C<other_action> with a local action name.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
