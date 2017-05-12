package Text::CaffeinatedMarkup::PullParser;

use strict;
use warnings;

our $VERSION = 0.01;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($OFF);

use Moo;

has 'pml'				=> (is=>'rw');
has 'pml_chars'			=> (is=>'rw');
has 'num_pml_chars'		=> (is=>'rw');

has 'temporary_token'			=> (is=>'rw');
has 'temporary_token_context'	=> (is=>'rw');

has 'tokens'				=> (is=>'rw');
has 'has_finished_parsing'	=> (is=>'rw');
has 'pointer'				=> (is=>'rw');
has 'state'					=> (is=>'rw');

has 'token' => (is=>'rw'); # Output token

has 'data_context' 	=> (is=>'rw');


my $SYM_STRONG		= '*';
my $SYM_EMPHASIS	= '/';
my $SYM_UNDERLINE	= '_';
my $SYM_DELETE		= '-';

my $SYM_LINK_START				= '[';
my $SYM_LINK_END				= ']';
my $SYM_LINK_CONTEXT_SWITCH		= '|';

my $SYM_IMAGE_START				= '{';
my $SYM_IMAGE_END				= '}';
my $SYM_IMAGE_CONTEXT_SWITCH	= '|';

my $SYM_NEWLINE			= "\n";
my $SYM_SECTION_BREAK	= '~';
my $SYM_HEADER 			= '#';

my $SYM_ROW		= '=';
my $SYM_COLUMN	= '|';

my $SYM_QUOTE				 = '"';
my $SYM_QUOTE_CONTEXT_SWITCH = '|';

my $SYM_ESCAPE	= "\\";


# ------------------------------------------------------------------------------

sub BUILD {
	my ($self) = @_;

	die "Must supply 'pml' to ".__PACKAGE__."::new()\n\n" unless $self->pml;

	# Presplit the input before parsing	
	$self->pml_chars([split //,$self->pml]);
	$self->num_pml_chars( scalar @{$self->pml_chars} );

	# Initialise
	$self->tokens([]);
	$self->has_finished_parsing(0);

	$self->pointer(0);
	$self->state('newline');

	$self->data_context([]);
	#$self->data_context('data');

	return;
}

# ============================================================== PUBLIC API ====

sub get_next_token {
	my ($self) = @_;

	return 0 if $self->has_finished_parsing;
	return $self->_get_next_token;
}

# ------------------------------------------------------------------------------

sub get_all_tokens {
	my ($self) = @_;	

	# Not finished parsing yet (or started at all) so get_next_token until 
	# we run out of document! Otherwise we just return what we have.
	unless ($self->has_finished_parsing) {
		while ($self->get_next_token) {}		
	}
	return wantarray ? @{$self->tokens} : $self->tokens;	
}

# ================================================================ INTERNAL ====

sub _get_next_token {
	my ($self) = @_;

	while(!$self->token) {
		my $state = $self->state;
		my $char = $self->pml_chars->[$self->pointer];

		$self->_increment_pointer;
		TRACE "State is '$state'";
		
		$char = 'EOF' unless defined $char;

		TRACE "  Read char [$char]";

		if ($state eq 'data') {

			#$self->data_context('data'); # REMOVE

			if ($char eq $SYM_STRONG)   { $self->_switch_state('strong');    next; }
			if ($char eq $SYM_EMPHASIS) { $self->_switch_state('emphasis');  next; }
			if ($char eq $SYM_UNDERLINE){ $self->_switch_state('underline'); next; }
			if ($char eq $SYM_DELETE)	{ $self->_switch_state('delete');	 next; }

			if ($char eq $SYM_QUOTE) {
				$self->_switch_state('quote-start');
				next;
			}

			if ($char eq $SYM_LINK_START) {
				$self->_switch_state('link-start');
				next;
			}

			if ($char eq $SYM_IMAGE_START) {
				$self->_switch_state('image-start');
				next;
			}

			if ($char eq $SYM_NEWLINE) {
				$self->_create_token({type=>'NEWLINE'});
				$self->_switch_state('newline');
				next;
			}

			if ($char eq 'EOF') {
				$self->_switch_state('end_of_data');
				next;
			}

			# "Anything else"
			# Append to string char, emitting if there was a
			# previous token that wasn't a string.
			my $previous_token = $self->_append_to_string_token( $char );
			next;
		}

		# ---------------------------------------

		if ($state eq 'strong') {

			if ($char eq $SYM_STRONG) {		
				$self->_create_token({type=>'STRONG'});
				$self->_switch_to_data_state;
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token( $SYM_STRONG );
				$self->_switch_state('end_of_data');
				next;
			}

			# "Anything else"
			# Append a star (*) to the current string token, reconsume char
			# and switch to data state.
			$self->_append_to_string_token( $SYM_STRONG );
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'emphasis') {

			if ($char eq $SYM_EMPHASIS) {		
				$self->_create_token({type=>'EMPHASIS'});
				$self->_switch_to_data_state;
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token( $SYM_EMPHASIS );
				$self->_switch_state('end_of_data');
				next;
			}

			# "Anything else"
			# Append a foreslash (/) to the current string token, reconsume char
			# and switch to data state.
			$self->_append_to_string_token( $SYM_EMPHASIS );
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'underline') {

			if ($char eq $SYM_UNDERLINE) {		
				$self->_create_token({type=>'UNDERLINE'});
				$self->_switch_to_data_state;			
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token( $SYM_UNDERLINE );
				$self->_switch_state('end_of_data');
				next;
			}

			# "Anything else"
			# Append an underscore (_) to the current string token, reconsume char
			# and switch to data state.
			$self->_append_to_string_token( $SYM_UNDERLINE );
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'delete') {

			if ($char eq $SYM_DELETE) {		
				$self->_create_token({type=>'DEL'});
				$self->_switch_to_data_state;
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token( $SYM_DELETE );
				$self->_switch_state('end_of_data');
				next;
			}

			# "Anything else"
			# Append a dash (-) to the current string token, reconsume char
			# and switch to data state.
			$self->_append_to_string_token( $SYM_DELETE );
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'link-start') {

			if ($char eq $SYM_LINK_START) {
				$self->_create_token({type=>'LINK',href=>'',text=>''});
				$self->temporary_token_context('href');
				$self->_switch_state('link-href');
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token( $SYM_LINK_START );
				$self->_switch_state('end_of_data');
				next;
			}

			# "Anything else"
			# Append an open square bracket ([) to the current string token,
			# reconsume char and switch to data state.
			$self->_append_to_string_token( $SYM_LINK_START );
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'link-href') {

			if ($char eq $SYM_LINK_CONTEXT_SWITCH) {
				$self->temporary_token_context('text');
				$self->_switch_state('link-text');
				next;
			}
			if ($char eq $SYM_LINK_END) { $self->_switch_state('link-end');  next }
			
			if ($char eq 'EOF') {
				$self->_raise_parse_error("Unexpected 'EOF' while parsing link href");
			}

			# "Anything else"
			# Append to open link token href
			if ($self->temporary_token->{type} eq 'LINK') {
				$self->temporary_token->{href} .= $char;
				next;
			}

			# Oops
			$self->_raise_parse_error("Attempt to append link href data to non-link token");
		}

		# ---------------------------------------

		if ($state eq 'link-text') {

			if ($char eq $SYM_LINK_END) {
				$self->_switch_state('link-end');
				next;
			}

			if ($char eq 'EOF') {
				$self->_raise_parse_error("Unexpected 'EOF' while parsing link text");
			}

			# "Anything else"
			# Append to open link token href
			if ($self->temporary_token->{type} eq 'LINK') {
				$self->temporary_token->{text} .= $char;
				next;
			}

			# Oops
			$self->_raise_parse_error("Attempt to append link text data to non-link token");
		}

		# ---------------------------------------

		if ($state eq 'link-end') {

			if ($char eq $SYM_LINK_END) {
				$self->_switch_to_data_state;
				next;
			}

			if ($char eq 'EOF') {
				$self->_raise_parse_error("Unexpected 'EOF' while parsing link end");
			}

			# "Anything else"
			# Append to href or text depending on context
			my $context = $self->temporary_token_context;
			
			if ($context =~ /^(?:href|text)$/o) {
				$self->temporary_token->{$context} .= $char;
				next;
			}

			$self->_raise_parse_error("Missing or bad link token context");
		}

		# ---------------------------------------

		if ($state eq 'image-start') {

			if ($char eq $SYM_IMAGE_START) {
				$self->_create_token({type=>'IMAGE',src=>'',options=>''});
				$self->temporary_token_context('src');
				$self->_switch_state('image-src');
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token( $SYM_IMAGE_START );
				$self->_switch_state('end_of_data');
				next;
			}

			# "Anything else"
			# Append an open curly bracket ({}) to the current string token,
			# reconsume char and switch to data state.
			$self->_append_to_string_token( $SYM_IMAGE_START );
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'image-src') {

			if ($char eq $SYM_IMAGE_CONTEXT_SWITCH) { $self->_switch_state('image-options'); next }
			if ($char eq $SYM_IMAGE_END) 			{ $self->_switch_state('image-end');	 next }
			
			if ($char eq 'EOF') {
				$self->_raise_parse_error("Unexpected 'EOF' while parsing image src");
			}

			# "Anything else"
			# Append to open link token href
			if ($self->temporary_token->{type} eq 'IMAGE') {
				$self->temporary_token->{src} .= $char;
				next;
			}

			# Oops
			$self->_raise_parse_error("Attempt to append image src data to non-image token");
		}

		# ---------------------------------------

		if ($state eq 'image-options') {

			if ($char eq $SYM_IMAGE_END) {
				$self->_switch_state('image-end');
				next;
			}

			if ($char eq 'EOF') {
				$self->_raise_parse_error("Unexpected 'EOF' while parsing image options");
			}

			# "Anything else"
			# Append to open link token href
			if ($self->temporary_token->{type} eq 'IMAGE') {
				$self->temporary_token->{options} .= $char;
				next;
			}

			# Oops
			$self->_raise_parse_error("Attempt to append image options data to non-image token");
		}

		# ---------------------------------------

		if ($state eq 'image-end') {

			if ($char eq $SYM_IMAGE_END) {
				$self->_switch_to_data_state;
				next;
			}

			if ($char eq 'EOF') {
				$self->_raise_parse_error("Unexpected 'EOF' while parsing image end");
			}

			# "Anything else"
			# Append to src or options depending on context
			my $context = $self->temporary_token_context;
			
			if ($context =~ /^(?:src|options)$/o) {
				$self->temporary_token->{$context} .= $char;
				next;
			}

			$self->_raise_parse_error("Missing or bad image token context");
		}
		
		# ---------------------------------------

		if ($state eq 'newline') {

			if ($char eq 'EOF') 	   { $self->_switch_state('end_of_data'); 	  next }
			if ($char eq $SYM_NEWLINE) { $self->_create_token({type=>'NEWLINE'}); next }
			if ($char eq ' ') 		   { next }

			if ($char eq $SYM_HEADER) {
				$self->_create_token({type=>'HEADER',level=>1});
				$self->_switch_state('header');
				next;
			}

			if ($char eq $SYM_SECTION_BREAK) {
				$self->_switch_state('section-break');
				next;
			}

			if ($char eq $SYM_ROW) {
				$self->_switch_state('row');				
				next;
			}

			# Anything else
			$self->_switch_to_data_state;
			$self->_decrement_pointer;
			next;
		}

		# ---------------------------------------

		if ($state eq 'section-break') {

			if ($char eq $SYM_SECTION_BREAK) {
				$self->_create_token({type=>'SECTIONBREAK'});
				$self->_switch_to_data_state;
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token( $SYM_SECTION_BREAK );
				$self->_switch_state('end_of_data');
				next;
			}
			
			# Anything else
			$self->_append_to_string_token( $SYM_SECTION_BREAK );
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'header') {

			if ($char eq 'EOF') {
				my $cur_level = $self->temporary_token->{level};
				$self->_discard_token;
				my $new_string = $SYM_HEADER x $cur_level;
				$self->_create_token({type=>'STRING',content=>$new_string});
				$self->_switch_state('end_of_data');
				next;
			}

			if ($char eq ' ') { next }			

			if ($char eq $SYM_HEADER) {
				$self->temporary_token->{level}++;
				next;
			}

			# Anything else
			$self->_switch_state('header-text');
			$self->_decrement_pointer;
			next;
		}

		# ---------------------------------------

		if ($state eq 'header-text') {

			if ($char eq 'EOF') {
				$self->_switch_state('end_of_data');			
				next;
			}

			if ($char eq $SYM_NEWLINE) {
				$self->_switch_to_data_state;
				next;
			}

			# Anything else
			$self->temporary_token->{text} .= $char;
			next;
		}

		# ---------------------------------------

		if ($state eq 'row') {

			if ($char eq $SYM_ROW) {
				$self->_discard_token; # Discard previous newline
				$self->_create_token({type=>'ROW'});
				$self->_switch_state('row-end-state');
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token( $SYM_ROW );
				$self->_switch_state('end_of_data');
				next;
			}
			
			# Anything else
			$self->_append_to_string_token( $SYM_ROW );
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'row-end-state') {

			if ($char eq $SYM_NEWLINE) {
				if ($self->_get_data_context eq 'column-data') {	
					TRACE "  -> Data context is 'column-data'";
					$self->_emit_token;
					$self->_pop_data_context;
					$self->_pop_data_context; # Pop two levels (column then row)
					$self->_switch_state('newline');
				}
				else {
					TRACE "  -> Data context other than 'column-data'";
					$self->_push_data_context('row-data');
					$self->_switch_state('row-data-state');
				}
				next;
			}

			if ($char eq 'EOF') {
				if ($self->_get_data_context eq 'column-data') {
					# Oops expecting a newline. We'll be nice though and
					# close the sequence as if it were there.				
				}
				else {
					$self->_discard_token;
					$self->_create_token({type=>'STRING',content=>"$SYM_ROW$SYM_ROW"});					
				}
				$self->_switch_state('end_of_data');
				next;
			}

			# Anything else
			$self->_discard_token;
			$self->_create_token({type=>'STRING',content=>"$SYM_ROW$SYM_ROW"});
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'row-data-state') {
			
			if ($char eq $SYM_COLUMN) {
				$self->_switch_state('first-column');
				next;
			}

			# Anything else
			$self->_raise_parse_error('Unexpected char at start of row data');
		}

		# ---------------------------------------

		if ($state eq 'first-column') {

			if ($char eq $SYM_COLUMN) {				
				$self->_push_data_context('column-data');
				$self->_create_token({type=>'COLUMN'});
				$self->_switch_state('column-data');
				next;
			}

			# Anything else
			$self->_raise_parse_error('Unexpected char in first column tag');
		}

		# ---------------------------------------

		if ($state eq 'column') {

			if ($char eq $SYM_COLUMN) {
				$self->_discard_token if $self->temporary_token->{type} eq 'NEWLINE'; # Discard previous newline
				$self->_push_data_context('column-data');
				$self->_create_token({type=>'COLUMN'});
				$self->_switch_state('column-data');
				next;
			}

			if ($char eq 'EOF') {
				$self->_raise_parse_error('Unexpected end of data in column tag');
			}

			# Anything else
			$self->_append_to_string_token($SYM_COLUMN);
			$self->_decrement_pointer;
			$self->_switch_state('column-data');
			next;
		}

		# ---------------------------------------

		if ($state eq 'column-data') {

			if ($char eq $SYM_COLUMN) {
				$self->_switch_state('column');
				next;
			}

			if ($char eq $SYM_STRONG)   { $self->_switch_state('strong');    next; }
			if ($char eq $SYM_EMPHASIS) { $self->_switch_state('emphasis');  next; }
			if ($char eq $SYM_UNDERLINE){ $self->_switch_state('underline'); next; }
			if ($char eq $SYM_DELETE)	{ $self->_switch_state('delete');	 next; }

			if ($char eq $SYM_QUOTE) {
				$self->_switch_state('quote-start');
				next;
			}

			if ($char eq $SYM_LINK_START) {
				$self->_switch_state('link-start');
				next;
			}

			if ($char eq $SYM_IMAGE_START) {
				$self->_switch_state('image-start');
				next;
			}

			if ($char eq $SYM_NEWLINE) {
				$self->_create_token({type=>'NEWLINE'});
				$self->_switch_state('newline');
				next;
			}

			if ($char eq 'EOF') {
				$self->_raise_parse_error('Unexpected end of data in column data');
			}

			# Anything else
			$self->_append_to_string_token($char);
			next;
		}

		# ---------------------------------------

		if ($state eq 'end_of_data') {
			DEBUG "End of data reached - finish parse";
			$self->has_finished_parsing(1);
			$self->_emit_token;

			if ($self->temporary_token) {
				TRACE "Still got temp token!";
			}

			last;
		}

		# ---------------------------------------

		if ($state eq 'quote-start') {
			if ($char eq $SYM_QUOTE) {
				$self->_create_token({type=>'QUOTE',body=>'',cite=>''});
				$self->temporary_token_context('body');
				$self->_switch_state('quote-body');
				$self->_push_data_context('quote-body');
				next;
			}

			if ($char eq 'EOF') {
				$self->_append_to_string_token('"');
				$self->_switch_state('end_of_data');
				next;
			}

			# Anything else
			$self->_append_to_string_token('"');
			$self->_decrement_pointer;
			$self->_switch_to_data_state;
			next;
		}

		# ---------------------------------------

		if ($state eq 'quote-end') {
			if ($char eq $SYM_QUOTE) {
				$self->_pop_data_context;
				$self->_switch_to_data_state;
				next;
			}

			if ($char eq 'EOF') {
				$self->_raise_parse_error("unexpected end of file in quote end sequence");
			}

			# Anything else			
			my $context = $self->temporary_token_context;
			
			if ($context =~ /^(?:body|cite)$/o) {
				$self->temporary_token->{$context} .= $char;
				next;
			}

			$self->_raise_parse_error("Missing or bad quote token context");
		}

		# ---------------------------------------

		if ($state eq 'quote-body') {
			if ($char eq 'EOF') {
				$self->_raise_parse_error('unexpected end of file in quote');
			}

			if ($char eq $SYM_QUOTE_CONTEXT_SWITCH) {
				$self->temporary_token_context('cite');
				$self->_switch_state('quote-cite');
				next;
			}

			if ($char eq $SYM_QUOTE) {
				$self->_switch_state('quote-end');
				next;
			}

			# Anything else
			$self->temporary_token->{body} .= $char;
			next;
		}

		# ---------------------------------------

		if ($state eq 'quote-cite') {
			if ($char eq 'EOF') {
				$self->_raise_parse_error('unexpected end of file in quote');
			}

			if ($char eq $SYM_QUOTE) {
				$self->_switch_state('quote-end');
				next;
			}

			# Anything else
			$self->temporary_token->{cite} .= $char;
			next;
		}

		# ---------------------------------------

		# Shouldn't ever get here!
		$self->_raise_parse_error("Invalid state! '$state'");

	}

	my $token = $self->token || 0;

	$self->token(undef);

	return $token;
}

# ------------------------------------------------------------------------------

sub _increment_pointer { $_[0]->pointer( $_[0]->pointer + 1) }
sub _decrement_pointer { $_[0]->pointer( $_[0]->pointer - 1); TRACE "  -> Requeue char" }

# ------------------------------------------------------------------------------

# Emit the current "temporary token" if there is one.
# Doing this returns to the client as well as adding to the token bucket.
sub _emit_token {
	my ($self) = @_;

	return unless my $token = $self->temporary_token;
	push @{$self->tokens}, $token;

	# Reset the temporary token
	$self->temporary_token(undef);

	DEBUG "  >> Emit token [ ".$token->{type}.' ]';

	$self->token($token); # Mark the token for output;
	return;
}

# ------------------------------------------------------------------------------

sub _raise_parse_error {
	my ($self, $msg) = @_;
	ERROR "!!Parse error [$msg]";
	die "Encountered parse error [$msg]\n\n";
}

# ------------------------------------------------------------------------------

sub _switch_to_data_state {
	my ($self) = @_;
	$self->_switch_state( $self->_get_data_context );
}

# ------------------------------------------------------------------------------

sub _switch_state {
	my ($self, $switch_to) = @_;
	TRACE "  Switching to state [ $switch_to ]";
	$self->state($switch_to);
}

# ------------------------------------------------------------------------------

# If there's a temporary token, get rid of it
sub _discard_token {
	my ($self) = @_;
	$self->temporary_token(undef);
	$self->temporary_token_context(undef);
	return;
}

# ------------------------------------------------------------------------------

sub _push_data_context {
	my ($self, $context) = @_;
	TRACE "Stack data context '$context'";
	unshift @{$self->data_context}, $context
}

sub _pop_data_context {
	my ($self) = @_;
	shift @{$self->data_context};
	TRACE "Popped data context stack back to '".$self->_get_data_context."'";
}

sub _clear_data_context { $_[0]->data_context([]) };

sub _get_data_context  { $_[0]->data_context->[0] || 'data'    }

# ------------------------------------------------------------------------------

# Append a given char to the current string token or, if there isn't one,
# create one (emitting existing tokens as appropriate)
#
# @param	char 	character to add
#
sub _append_to_string_token {
	my ($self, $char) = @_;

	TRACE "  Append [ $char ] to string token";

	# Look at the current temporary token (if there is one).
	my $tmp_token = $self->temporary_token;

	if ($tmp_token && $tmp_token->{type} eq 'STRING') {
		TRACE "  -> Has existing string token";
		$self->temporary_token->{content} .= $char;
		return; # Nothing to return
	}

	# Otherwise create a new token and return the previous one
	# if there was one.
	$self->_create_token({type=>'STRING',content=>$char});
	return;
}

# ------------------------------------------------------------------------------

# Create a new token in the temporary store. If a token already exists
# there then this method returns it.
#
# @param	tpken		initial token
# @returns	the old temporary token
#			before it was replaced
#			with the new one.
#
sub _create_token {
	my ($self, $token) = @_;

	$self->_raise_parse_error("No token data passed to _create_token()") unless $token;

	TRACE "  Create new token [ ".$token->{type}." ]";
	my $old_temporary_token = undef;

	if ($self->temporary_token) {			
		$self->_emit_token;
	}

	# Clear any current context
	$self->temporary_token_context(undef);

	$self->temporary_token( $token );
	return undef;
}

1;

__END__

=pod

=head1 Title

Text::CaffeinatedMarkup::PullParser

=head1 Synopsis

  use Text::CaffeinatedMarkup::PullParser;

  my $parser = Text::CaffeinatedMarkup::PullParser->new( pml => 'Parse **this**' );

  my @tokens = $parser->get_all_tokens;

  # or

  while (my $token = $parser->get_next_token) {
	 # ...
  }

=head1 Description

This module implements a I<Pull Parser> for C<The Caffeinated Markup Language>.
For details on the syntax that B<CML> implements, please see the
L<Github wiki|https://github.com/necrophonic/text-caffeinatedmarkup/wiki>.

This module isn't designed to be used directly in a client, but instead used by a
I<formatter> such as L<Text::CaffeinatedMarkup::HTMLFormatter>.


=head1 Methods

This module implements the following methods.

=head2 get_next_token

  my $token = $parser->get_next_token;

Whilst there is a token to return, this method will return it. If there are no
tokens left then this will return 0 (zero).


=head2 get_all_tokens

  my @tokens   = $parser->get_all_tokens;
  my $tokens_r = $parser->get_all_tokens;
  
Returns all the tokens from the parsed document.

Please note, this uses C<get_next_token> internally so, if you've already called
C<get_next_token> a couple of times and rhen call C<get_all_tokens>, then
C<get_all_tokens> will return all the rest of the tokens I<from that point onwards> and
not the entire document.


=head1 See Also

L<The Github wiki|https://github.com/necrophonic/text-caffeinatedmarkup/wiki>

=head1 Author

J Gregory <jgregory@cpan.org>

=cut
