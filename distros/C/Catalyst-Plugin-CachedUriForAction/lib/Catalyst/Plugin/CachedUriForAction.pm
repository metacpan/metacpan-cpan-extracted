use 5.008005; use strict; use warnings;

package Catalyst::Plugin::CachedUriForAction;

our $VERSION = '1.005';

use mro;
use Carp ();
use URI::Encode::XS 'uri_encode_utf8';

sub CACHE_KEY () { __PACKAGE__ . '::action_uri_info' }

sub setup_finalize {
	my $c = shift;
	$c->maybe::next::method( @_ );

	my $cache = \%{ $c->dispatcher->{(CACHE_KEY)} };
	for my $action ( values %{ $c->dispatcher->_action_hash } ) {
		my $xa = $c->dispatcher->expand_action( $action );
		my $n_caps = $xa->number_of_captures;

		# not an action that a request can be dispatched to?
		next if not defined $c->dispatcher->uri_for_action( $action, [ ('dummy') x $n_caps ] );

		my $n_args = $xa->number_of_args; # might be undef to mean "any number"
		my $tmpl = $c->uri_for( $action, [ ("\0\0\0\0") x $n_caps ], ("\0\0\0\0") x ( $n_args || 0 ) );
		my ( $prefix, @part ) = split /%00%00%00%00/, $tmpl, -1;
		$prefix =~ s!\A/!!;
		$cache->{ '/' . $action->reverse } = [ $n_caps, $n_args, \@part, $prefix ];
	}
}

sub uri_for_action {
	my $c = shift;

	my $dispatcher = $c->dispatcher;
	my $cache = $dispatcher && $dispatcher->{(CACHE_KEY)}
		or return $c->next::method( @_ ); # fall back if called too early

	my $action   = shift;
	my $captures = @_ && 'ARRAY'  eq ref $_[0]  ? shift : [];
	my $fragment = @_ && 'SCALAR' eq ref $_[-1] ? pop   : undef;
	my $params   = @_ && 'HASH'   eq ref $_[-1] ? pop   : undef;

	$action = '/' . $dispatcher->get_action_by_path( $action )->reverse
		if ref $action
		and do { local $@; eval { $action->isa( 'Catalyst::Action' ) } };

	my $info = $cache->{ $action }
		or Carp::croak "Can't find action for path '$action' in uri_for_action";

	my ( $uri, $base ) = '';
	if ( ref $c ) {
		$base = $c->request->base;
		$uri = '/' if $$base !~ m!/\z!;
	} else { # fallback if called as class method
		$base = bless \( my $tmp = '' ), 'URI::_generic';
		$uri = '/';
	}

	my ( $n_caps, $n_args, $extra_parts ) = @$info;
	$uri .= $info->[-1];

	# this is not very sensical but it has to be like this because it is what Catalyst does:
	# the :Args() case (i.e. any number of args) is grouped with the :Args(0) case (i.e. no args)
	# instead of being grouped with with the :Args(N) case (i.e. a fixed non-zero number of args)
	if ( $n_args ) {
		Carp::croak "Not enough captures for path '$action' (need $n_caps) in uri_for_action"
			if @$captures < $n_caps;
	} else {
		Carp::croak "Wrong number of captures for path '$action' (need $n_caps) in uri_for_action"
			if @$captures != $n_caps;
	}

	# the following is carefully written to
	# - loop over every input array exactly once
	# - avoid any conditionals inside each loop body
	# - use only simple loop forms that are specially optimised by the perl interpreter
	my $i = -1;
	if ( defined $n_args ) { # the non-slurpy case
		Carp::croak "Wrong number of args+captures for path '$action' (need ".@$extra_parts.") in uri_for_action"
			if ( @$captures + @_ ) != @$extra_parts;
		# and now since @$extra_parts is exactly the same length as @$captures and @_ combined
		# iterate over those arrays and use a cursor into @$extra_parts to interleave its elements
		for ( @$captures ) { ( $uri .= uri_encode_utf8 $_ ) .= $extra_parts->[ ++$i ] }
		for ( @_ )         { ( $uri .= uri_encode_utf8 $_ ) .= $extra_parts->[ ++$i ] }
	} else {
		# in the slurpy case, the size of @$extra_parts is determined by $n_caps alone since $n_args was undef
		# and as we checked above @$captures alone has at least length $n_caps
		# so we will need all of @$captures to cover @$extra_parts, and may then still have some of it left over
		# so iterate over @$extra_parts and use a cursor into @$captures to interleave its elements
		for ( @$extra_parts )       { ( $uri .= uri_encode_utf8 $captures->[ ++$i ] ) .= $_ }
		# and then append the rest of @$captures, and then everything from @_ after that
		for ( ++$i .. $#$captures ) { ( $uri .= '/' ) .= uri_encode_utf8 $captures->[ $_ ] }
		for ( @_ )                  { ( $uri .= '/' ) .= uri_encode_utf8 $_ }
	}

	$uri =~ s/%2B/+/g;
	substr $uri, 0, 0, $$base;

	if ( defined $params ) {
		my $query = '';
		my $delim = $URI::DEFAULT_QUERY_FORM_DELIMITER || '&';
		my ( $v, $enc_key );
		for my $key ( sort keys %$params ) {
			$v = $params->{ $key };
			if ( 'ARRAY' ne ref $v ) {
				( $query .= $delim ) .= uri_encode_utf8 $key;
				( $query .= '=' ) .= uri_encode_utf8 $v if defined $v;
			} elsif ( @$v ) {
				$enc_key = $delim . uri_encode_utf8 $key;
				for ( @$v ) {
					$query .= $enc_key;
					( $query .= '=' ) .= uri_encode_utf8 $_ if defined;
				}
			}
		}
		if ( '' ne $query ) {
			$query =~ s/%20/+/g;
			( $uri .= '?' ) .= substr $query, length $delim;
		}
	}

	if ( defined $fragment ) {
		( $uri .= '#' ) .= uri_encode_utf8 $$fragment;
	}

	bless \$uri, ref $base;
}

BEGIN { delete $Catalyst::Plugin::CachedUriForAction::{'uri_encode_utf8'} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::CachedUriForAction - drop-in supercharger for uri_for_action

=head1 SYNOPSIS

 use Catalyst qw( CachedUriForAction );

=head1 DESCRIPTION

This provides a (mostly) drop-in replacement version of C<uri_for_action>.

The stock Catalyst C<uri_for_action> method is a thin wrapper around C<uri_for>.
Every time you pass C<uri_for> an action to create a parametrized URL for it, it introspects the dispatcher.
This is expensive, and on views that generate a lot of URLs, it can add up to a substantial cost.
Doing this introspection repeatedly can only possibly be useful if the set of controllers and actions in the application can change at runtime.
Even then it is still wasted time on any view that generates many URLs for the same action.

This plugin scans the dispatch table once during startup and pregenerates templates for all possible output URLs.
The only work then left in C<uri_for_action> is the string manipulation to assemble a URL from its template.

=head1 LIMITATIONS

The following things are unsupported in this plugin:

=over 3

=item * Controller and action addition/removal at runtime

This is by design and not likely to ever change.

B<If you need this then you will not be able to use this plugin.>

=item * Incorrect C<uri_for_action> inputs

The stock method returns undef when given an unknown action path or the wrong number of captures or args.
This has never been useful to me but has been a cause of some annoying debugging sessions.
This plugin puts an end to that by throwing an exception instead.

If you run into this, you can use C<eval> or fall back to C<uri_for> for those calls.

=item * Setting the URL fragment as part of the args

This plugin does not handle args in the sloppy/DWIM fashion C<uri_for> tries to offer.
Setting a URL fragment is supported, but only by passing it as a trailing scalar ref.
Plain parameters are always treated as args and therefore encoded.

If you run into this, you can fall back to C<uri_for> for those calls.

=item * Arg constraints (such as C<:CaptureArgs(Int,Str)>)

Note that this plugin does not affect request dispatch so constraints will still apply there.
They will merely not be validated when generating URLs.

This may be possible to support but demand would have to justify an attempt at it.

=item * C<"\0\0\0\0"> in the PathPart of any action

This string is internally used as a marker for placeholder values.
The dispatch table scanner will generate bogus templates for such actions.
This is mentioned here just for completeness as it seems unlikely to bite anyone in practice.

If you do run into this, you can fall back to C<uri_for> for those actions.

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
