package Datastar::SSE;
use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.26';

use JSON ();
use HTTP::ServerEvent;
use Scalar::Util qw/reftype/;
use Exporter qw/import unimport/;

# use Datastar::SSE::Types qw/is_ScalarRef is_ArrayRef is_Int/;
use Datastar::SSE::Types qw/:is/;

my @execute_script_attributes = (
	{ type => 'module' },
);

=pod

=encoding utf-8

=head1 NAME

Datastar::SSE - Module for creating Datastar Server Events

=head1 DESCRIPTION

An implementation of the L<< Datastar|https://data-star.dev/ >> Server Sent Event SDK in Perl

=head1 SYNOPSIS

    use Datastar::SSE qw/:fragment_merge_modes/;
    
    my @events;
    push @events,  Datastar::SSE->merge_fragments( $html_fragment, +{
        selector => '#name-selector',
        merge_mode => FRAGMENT_MERGEMODE_OUTER,
    });
    # $event is a multiline string which should be sent as part of
    # the http response body.  Multiple event strings can be sent in the same response.
    
    for my $evt (@events) {
        $cgi->print( $evt ); # CGI
        $psgi_writer->write( $evt ); # PSGI delayed response "writer"
        $c->write( $evt ); # Mojolicious controller
    }

=cut

my @datastar_events;
my @merge_mode;
my %DATASTAR_EVENTS;
my %MERGEMODES;
BEGIN {
	my @datastar_events = qw/
		datastar_merge_fragments
		datastar_remove_fragments
		datastar_merge_signals 
		datastar_remove_signals 
		datastar_execute_script
	/;
	@merge_mode = qw/
		morph
		inner
		outer
		prepend
		append
		before 
		after
		upsertAttributes
	/;
	@DATASTAR_EVENTS{map uc, @datastar_events} = @datastar_events;
	s/_/-/g for values %DATASTAR_EVENTS;
	%MERGEMODES = +map +( "FRAGMENT_MERGEMODE_\U$_" => $_ ), @merge_mode;
}
		
use constant +{ %DATASTAR_EVENTS, %MERGEMODES };

=head1 EXPORT TAGS

The following tags can be specified to export constants related to the Datastar SSE 

=head2 events

The L<< Datastar SSE|https://data-star.dev/reference/sse_events >> Event names:

=over

=item * DATASTAR_MERGE_FRAGMENTS

L<< datastar-merge-fragments|https://data-star.dev/reference/sse_events#datastar-merge-fragments >>

=item * DATASTAR_REMOVE_FRAGMENTS

L<< datastar-remove-fragments|https://data-star.dev/reference/sse_events#datastar-remove-fragments >>

=item * DATASTAR_MERGE_SIGNALS

L<< datastar-merge-signals|https://data-star.dev/reference/sse_events#datastar-merge-signals >>

=item * DATASTAR_REMOVE_SIGNALS

L<< datastar-remove-signals|https://data-star.dev/reference/sse_events#datastar-remove-signals >>

=item * DATASTAR_EXECUTE_SCRIPT

L<< datastar-execute-script|https://data-star.dev/reference/sse_events#datastar-execute-script >>

=back

=head2 fragment_merge_modes

The Merge Modes for the L</merge_fragments> event:

=over

=item * FRAGMENT_MERGEMODEMORPH

C<morph>

Merges the fragment using L<< Idiomorph|https://github.com/bigskysoftware/idiomorph >>. This is the default merge strategy.

=item * FRAGMENT_MERGEMODE_INNER

C<inner>

Replaces the target’s innerHTML with the fragment.

=item * FRAGMENT_MERGEMODE_OUTER

C<outer>

Replaces the target’s outerHTML with the fragment.

=item * FRAGMENT_MERGEMODE_PREPEND

C<prepend>

Prepends the fragment to the target’s children.

=item * FRAGMENT_MERGEMODE_APPEND

C<append>

Appends the fragment to the target’s children.

=item * FRAGMENT_MERGEMODE_BEFORE

C<before>

Inserts the fragment before the target as a sibling.

=item * FRAGMENT_MERGEMODE_AFTER

C<after>

Inserts the fragment after the target as a sibling.

=item * FRAGMENT_MERGEMODE_UPSERTATTRIBUTES

C<upsertAttributes>

Merges attributes from the fragment into the target – useful for updating a signal.

=back

=cut

our @EXPORT_OK = (keys %DATASTAR_EVENTS, keys %MERGEMODES);
our %EXPORT_TAGS = ( events => [keys(%DATASTAR_EVENTS)], fragment_merge_modes => [keys(%MERGEMODES)] );

my $json; # cache
sub _encode_json($) {
	($json  ||= JSON->new->allow_blessed->convert_blessed)->encode( @_ );
}

sub _decode_json($) {
	# uncoverable subroutine
	($json  ||= JSON->new->allow_blessed->convert_blessed)->decode( @_ ); # uncoverable statement
}

=head1 METHODS

=head2 headers

	->headers();

Returns an Array Ref of the recommended headers to sent for Datastar SSE responses.

	Content-Type: text/event-stream
	Cache-Control: no-cache
	Connection: keep-alive
	Keep-Alive: timeout=300, max=100000

=cut

my $headers;
sub headers {
	$headers ||= +[
		'Content-Type', 'text/event-stream',
		'Cache-Control', 'no-cache',
		'Connection', 'keep-alive',
		'Keep-Alive', 'timeout=300, max=100000'
	]
}

=head1 EVENTS

Each Datastar SSE event is implements as a class method on L<Datastar::SSE>.  Each method accepts, but does not require,  
an options hashref as the last parameter, the options are documented per event, additionally all options from 
L<HTTP::ServerEvent> are supported.

=over

=item * id

The event id. If you send this, a client will send the "Last-Event-Id" header when reconnecting, allowing you to send the events missed 
while offline. Newlines or null characters in the event id are treated as a fatal error.

=item * retry

the amount of miliseconds to wait before reconnecting if the connection is lost. Newlines or null characters in the retry interval are 
treated as a fatal error.

=back

=head2 merge_fragments

	->merge_fragments( $html_fragment, $options_hashref );
	->merge_fragments( $html_fragment_arrayref, $options_hashref );

L<< datastar-merge-fragments|https://data-star.dev/reference/sse_events#datastar-merge-fragments >>

Merges one or more fragments into the DOM. By default, Datastar merges fragments using L<< Idiomorph|https://github.com/bigskysoftware/idiomorph >>,
which matches top level elements based on their ID.

=head3 OPTIONS

=over

=item * selector

B<Str>

Selects the target element of the merge process using a CSS selector.

=item * use_view_transition

B<Bool>

B<Default>: 0

B<Sends As>: C<useViewTransition>

Whether to use view transitions when merging into the DOM.

=item * merge_mode

B<Str|MERGEMODE>

B<Default>: FRAGMENT_MERGEMODE_MORPH

B<Sends As>: C<mergeMode>

The mode to use when merging into the DOM.

See L<< merge modes|/merge_modes >>

=back

=cut

sub merge_fragments {
	my $class = shift;
	my ($fragment, $options) = @_;
	my $event = DATASTAR_MERGE_FRAGMENTS;
	my @data;
	return "" unless $fragment;
	$fragment ||= [];
	if (!is_ArrayRef($fragment)) {
		$fragment = [$fragment];
	}

	if (my $selector = delete $options->{selector}) {
		push @data, +{ selector => $selector };
	}
	if (my $merge_mode = delete $options->{merge_mode}) {
		if (is_Mergemode( $merge_mode ) && $merge_mode ne FRAGMENT_MERGEMODE_MORPH) {
			push @data, +{ mergeMode => $merge_mode };
		}
	}
	if (my $use_view_transition = delete $options->{use_view_transition}) {
		$use_view_transition ||= 0;
		if ($use_view_transition) {
			push @data, +{ useViewTransition => _bool( $use_view_transition )};
		}
	}
	for (@$fragment) {
		my $frag = is_ScalarRef($_) ? $$_ : $_;
		my @frags = split /\cM\cJ?|\cJ/, $frag;
		for my $f (@frags) {
			push @data, +{ fragments => $f }
		}
	}
	$class->_datastar_event(
		$event,
		$options,
		@data
	);
}

=head2 merge_signals

	->merge_signals( $signals_hashref, $options_hashref );

L<< datastar-merge-signals|https://data-star.dev/reference/sse_events#datastar-merge-signals >>

Updates the signals with new values. The only_if_missing option determines whether to update the 
signals with new values only if the key does not exist. The signals line should be a valid 
data-signals attribute. This will get merged into the signals.

=head3 OPTIONS

=over

=item * only_if_missing

B<Bool>

B<Default>: 0

B<Sends As>: C<onlyIfMissing>

Only update the signals with new values if the key does not exist.

=back

=cut

sub merge_signals {
	my $class = shift;
	my ($signals, $options) = @_;
	return "" unless $signals;
	$options ||= {};
	my $event = DATASTAR_MERGE_SIGNALS;
	my @data;
	if (exists $options->{only_if_missing}) {
		my $only_if_missing = delete( $options->{only_if_missing} ) || 0;
		push @data, +{ onlyIfMissing => _bool( $only_if_missing )};
	}
	if (ref $signals) {
		$signals = _encode_json( $signals);
	}
	push @data, +{ signals => $signals };
	$class->_datastar_event(
		$event,
		$options,
		@data
	);
}

=head2 remove_fragments

	->remove_fragments( $selector, $options_hashref )

L<< datastar-remove-fragments|https://data-star.dev/reference/sse_events#datastar-remove-fragments >>

Removes one or more HTML fragments that match the provided selector (B<$selector>) from the DOM.

=cut

sub remove_fragments {
	my $class = shift;
	my ($selector, $options) = @_;
	return "" unless $selector;
	my $event = DATASTAR_REMOVE_FRAGMENTS;
	my @data = +{
		selector => $selector,
	};
	$class->_datastar_event(
		$event,
		$options,
		@data
	);
}

=head2 remove_signals

	->remove_signals( @paths, $options_hashref )
	->remove_signals( $paths_arrayref, $options_hashref )

L<< datastar-remove-signals|https://data-star.dev/reference/sse_events#datastar-remove-signals >>

Removes signals that match one or more provided paths (B<@paths>).

=cut

sub remove_signals {
	my $class = shift;
	my @signals = @_;
	my $options;
	if (@signals && is_HashRef($signals[ $#signals ])) {
		$options = pop( @signals );
	}
	my @data;
	my $event = DATASTAR_REMOVE_SIGNALS;
	my @sig;
	for my $signal (@signals) {
		if ($signal && !ref( $signal)) {
			push @sig, $signal;
		}
		if (is_ArrayRef($signal)) {
			push @sig, @$signal;
		}
	}
	return "" unless @sig;
	@data = map +{ paths => $_ }, @sig;
	$class->_datastar_event(
		$event,
		$options,
		@data
	);
}

=head2 execute_script

	->execute_script( $script, $options_hashref )
	->execute_script( $script_arrayref, $options_hashref )

L<< datastar-execute-script|https://data-star.dev/reference/sse_events#datastar-execute-script >>

Executes JavaScript (B<$script> or @B<$script_arrayref>) in the browser. 

=head3 OPTIONS

=over

=item * auto_remove

B<Bool>

B<Default>: 1

B<Sends As>: C<autoRemove>

Determines whether to remove the script element after execution.

=item * attributes

B<Map[Name,Value]>

B<CycleTuple[ Str | Map[Name,Value] ]>

B<Default>: [{ type => 'module' }]

Each attribute adds an HTML attribute to the B<< <script> >> tag used for the script, in either
C<< name='value' >> or C<< name >> format.

The C<attributes> option can be one of

=over 4

=item * A HashRef of keys and values, with boolean attributes (attributes without a value), as a
C<false> value

	options => {
		type => 'script',
		async => 0,
		defer => 0,
		class => 'my-script',
	},

=item * An ArrayRef of key,value pairs as Hashrefs, and simple strings for boolean attributes

	options => [
		{ type => 'script' },
		'async',
		'defer',
		{ class => 'my-script' },
	];

=back

=back

=cut

sub execute_script {
	my $class = shift;
	my ($script, $options) = @_;
	my $event = DATASTAR_EXECUTE_SCRIPT;
	my @data;
	return "" unless $script || (is_ArrayRef($script) && @$script);
	$script ||= [];

	if (!is_ArrayRef($script)) {
		$script = [$script];
	}
	$options ||= +{};
	my $auto_remove = delete( $options->{auto_remove} ) // 1;
	my $attributes = delete( $options->{attributes} ) // [@execute_script_attributes];
	if (!$auto_remove) {
		push @data, +{ autoRemove => _bool( $auto_remove )};
	}
	$attributes = _convert_attributes( $attributes );
	
	if (_encode_json( $attributes ) ne _encode_json( [@execute_script_attributes] )) {
		push @data, 
			+{ attributes => is_HashRef( $_ ) ? join(' ', %$_) : $_ }  for @$attributes;
	}
	
	for (@$script) {
		my $sc = is_ScalarRef($_) ? $$_ : $_;
		my @s = split /\cM\cJ?|\cJ/, $sc;
		for my $s (@s) {
			push @data, +{ script => $s };	
		}
	}
	$class->_datastar_event(
		$event,
		$options,
		@data
	);
}

sub _convert_attributes {
	my $attributes = shift;
	return $attributes if is_ArrayRef($attributes);
	return [] unless $attributes && is_HashRef($attributes);
	my $output = [];
	for my $key (sort keys %$attributes) {
		my $value = $attributes->{$key};
		# false / undef == attribute with no value
		push @$output, $value ? +{ $key => $value } : $key;
	}
	$output;
}
=pod

All events return the falsey empty string (C<>) when they cannot generate an event string.

=cut

sub _datastar_event {
	my $class = shift;
	my ($event, $options, @data) = @_;
	return "" unless $event;
	return "" unless is_Datastar( $event );
	my @event_data;
	for my $data (@data) {
		push @event_data, join(' ', %$data);
	}
	$options ||= {};
	$options = {} unless is_HashRef( $options );
	HTTP::ServerEvent->as_string(
		%$options,
		event => $event,
		data  => join("\n", @event_data),
	);
}

# 0/1 to false/true
sub _bool($) {
	shift() ? "true" : "false";
}

=head1 AUTHOR

James Wright <jwright@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by James Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

no Scalar::Util; 
1;
