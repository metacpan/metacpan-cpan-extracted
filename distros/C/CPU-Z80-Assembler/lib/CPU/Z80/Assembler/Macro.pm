# $Id$

package CPU::Z80::Assembler::Macro;

#------------------------------------------------------------------------------

=head1 NAME

CPU::Z80::Assembler::Macro - Macro pre-processor for the Z80 assembler

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;

use CPU::Z80::Assembler::Parser;
use Iterator::Simple::Lookahead;
use Asm::Preproc::Token;

our $VERSION = '2.25';

#------------------------------------------------------------------------------
# Class::Struct cannot be used with Exporter
#use Class::Struct (
#	name	=> '$',			# macro name
#	params 	=> '@',			# list of macro parameter names
#	locals	=> '%',			# list of macro local labels
#	tokens	=> '@',			# list of macro tokens
#);
sub new { my($class, %args) = @_;
	return bless [
				$args{name}, 
				$args{params}	|| [], 
				$args{locals}	|| {}, 
				$args{tokens}	|| []
			], $class;
}
sub name   { defined($_[1]) ? $_[0][0] = $_[1] : $_[0][0] }
sub params { defined($_[1]) ? $_[0][1] = $_[1] : $_[0][1] }
sub locals { defined($_[1]) ? $_[0][2] = $_[1] : $_[0][2] }
sub tokens { defined($_[1]) ? $_[0][3] = $_[1] : $_[0][3] }

#------------------------------------------------------------------------------

=head1 SYNOPSIS

  use CPU::Z80::Assembler::Macro;

  my $macro = CPU::Z80::Assembler::Macro->new(
                  name   => $name,
                  params => \@params_names,
                  locals => \%local_labels,
                  tokens => \@token_list);
  $macro->parse_body($input);
  $macro->expand_macro($input);

=head1 DESCRIPTION

This module provides a macro pre-processor to parse macro definition statements,
and expand macro calls in the token stream. Both the input and output streams
are L<Iterator::Simple::Lookahead|Iterator::Simple::Lookahead> objects returning sequences 
of tokens.

The object created by new() describes one macro. It is used during the parse phase
to define the macro object while reading the input token stream.

=head1 EXPORTS

None.

=head1 FUNCTIONS

=head2 new

Creates a new macro definition object, see L<Class::Struct|Class::Struct>.

=head2 name

Get/set the macro name.

=head2 params

Get/set the formal parameter names list.

=head2 locals

Get/set the list of local macro labels, stored as a hash.

=head2 tokens

Get/set the list of tokens in the macro definition.

=cut

#------------------------------------------------------------------------------

=head2 parse_body

This method is called with the token input stream pointing at the first token
after the macro parameter list, i.e. the '{' or ':' or "\n" character.

It parses the macro body, leaving the input stream after the last token of the
macro definition ('endm' or closing '}'), with all the "\n" characters of the
macro defintion pre-pended, and filling in locals() and tokens().

=cut

#------------------------------------------------------------------------------

sub parse_body {
	my($self, $input) = @_;
	my $token;
	
	# skip {
	my $opened_brace;
	defined($token = $input->peek) 
		or Asm::Preproc::Token->error_at($token, "macro body not found");	
	if ($token->type eq '{') {
		$input->next;
		$opened_brace++;
	}
	elsif ($token->type =~ /^[:\n]$/) {
		# OK, macro body follows on next line
	}
	else {
		$token->error("unexpected '". $token->type ."'");
	}
	
	# retrieve tokens
	my @macro_tokens;
	my @line_tokens;
	my %locals;

	# need to note all the labels in the macro, 
	# i.e. NAME after statement end
	my $last_stmt_end = 1;

	my $parens = 0;
	while (defined($token = $input->peek)) {
		my $type = $token->type;
		if ($type eq "{") {
			$parens++;
			push @macro_tokens, $token;
			$input->next;
		}
		elsif ($type eq "endm") {
			$opened_brace 
				and $token->error("expected \"}\"");
			$input->next;							# skip delimiter
			last;
		}
		elsif ($type eq "}") {
			if ($parens > 0) {
				$parens--;
				push @macro_tokens, $token;
				$input->next;
			}
			else {
				$input->next if $opened_brace;		# skip delimiter
				last;
			}
		}
		elsif ($type eq "NAME" && $last_stmt_end) {	# local label
			$locals{$token->value}++;
			push @macro_tokens, $token;
			$input->next;
		}
		else {
			push @macro_tokens, $token;
			push @line_tokens,  $token if $type eq "\n";	
											# save new-lines for listing
			$input->next;
		}
		$last_stmt_end = ($type =~ /^[:\n]$/);
	}
	defined($token) 
		or Asm::Preproc::Token->error_at($token, "macro body not finished");
	($parens == 0)
		or $token->error("Unmatched braces");
	
	# prepend all seen LINE tokens in input
	$input->unget(@line_tokens);
	
	$self->tokens(\@macro_tokens);
	$self->locals(\%locals);					
}

#------------------------------------------------------------------------------

=head2 expand_macro

This method is called with the input stream pointing at the first token
after the macro name in a macro call. It parses the macro arguments, if any
and expands the macro call, inserting the expanded tokens in the input stream.

=cut

#------------------------------------------------------------------------------

sub expand_macro {
	my($self, $input) = @_;
	our $instance++;									# unique ID for local labels
	
	my $start_token = $input->peek;						# for error messages
	defined($start_token) or die;						# must have at least a "\n"
	
	my $args = $self->parse_macro_arguments($input);
	
	# compute token expansion
	my $macro_stream  = Iterator::Simple::Lookahead->new(@{$self->tokens});
	my $expand_stream = Iterator::Simple::Lookahead->new(
		sub {
			for(;;) {
				my $token = $macro_stream->next;
				defined($token) or return undef;		# end of expansion
				
				$token = $token->clone;					# make a copy
				$token->line($start_token->line);		# set the line of invocation
				
				if ($token->type eq 'NAME') {
					my $name = $token->value;
					if (exists $args->{$name}) {
						my @tokens = @{$args->{$name}};	# expansion of the name
						return sub {shift @tokens};		# insert a new iterator to return	
														# these - $macro_stream->unget();
														# would allow recursive expansion 
														# of arg names - not intended
					}
					elsif (exists $self->locals->{$name}) {
						$token->value("_macro_".$instance."_".$name);
						return $token;
					}
					else {
						return $token;
					}
				}
				else {
					return $token;
				}
			}
		});
		
	# prepend the expanded stream in the input
	$input->unget($expand_stream);
}

#------------------------------------------------------------------------------

=head2 parse_macro_arguments

This method is called with the input stream pointing at the first token
after the macro name in a macro call. It parses the macro arguments, leaves 
the input stream after the macro call, and returns an hash reference mapping
formal argument names to list of tokens in the actual parameters.

The arguments are list of tokens separated by ','. An argument can be enclosed
in braces '{' '}' to allow ',' to be passed - the braces are not part of the argument
value.

=cut

#------------------------------------------------------------------------------

sub parse_macro_arguments {
	my($self, $input) = @_;
	my %args;
	my $token;
	
	my @params = @{$self->params};						# formal parameters
	for (my $i = 0; $i < @params; $i++) {
		my $param = $params[$i];
		$token = $input->peek;
		defined($token) && $token->type !~ /^[:\n,]$/
			or Asm::Preproc::Token->error_at($token, 
										"expected value for macro parameter $param");
		my @arg = $self->_parse_argument($input);
		$args{$param} = \@arg;
		
		if ($i != $#params) {							# expect a comma
			$token = $input->peek;
			defined($token) && $token->type eq ','
				or Asm::Preproc::Token->error_at($token, 
										"expected \",\" after macro parameter $param");
			$input->next;
		}
	}
	
	# expect end of statement, keep input at end of statement marker
	$token = $input->peek;
	(!defined($token) || $token->type =~ /^[:\n]$/)
		or Asm::Preproc::Token->error_at($token, "too many macro arguments");
	
	return \%args;
}

#------------------------------------------------------------------------------
# @tokens = _parse_argument($input)
#	Extract the sequence of input tokens from $input into @tokens up to and
#	not including the delimiter token
sub _parse_argument {
	my($class, $input) = @_;
	my $token;	

	# retrieve tokens
	my @tokens;
	my $parens = 0;
	my $opened_brace;
	while (defined($token = $input->peek)) {
		my $type = $token->type;
		if ($type =~ /^[:\n,]$/ && $parens == 0) {
			last;
		}
		elsif ($type eq '{') {
			$parens++;
			push(@tokens, $token) if $opened_brace++;
			$input->next;
		}
		elsif ($type eq '}') {
			if ($parens > 0) {
				$parens--;
				push(@tokens, $token) if --$opened_brace;
				$input->next;
			}
			else {
				$input->next if $opened_brace;		# skip delimiter
				last;
			}
		}
		else {
			push(@tokens, $token);
			$input->next;
		}
	}
	Asm::Preproc::Token->error_at($token, "unmatched braces") 
		if $parens != 0;

	return @tokens;
}

#------------------------------------------------------------------------------

=head1 SYNTAX

=head2 Macros

Macros are created thus.  This example creates an "instruction" called MAGIC
that takes two parameters:

    MACRO MAGIC param1, param2 {
        LD param1, 0
        BIT param2, L
        label = 0x1234
        ... more real instructions go here.
    }

Within the macro, param1, param2 etc will be replaced with whatever
parameters you pass to the macro.  So, for example, this:

    MAGIC HL, 2

Is the same as:

    LD HL, 0
    BIT 2, L
    ...

Any labels that you define inside a macro are local to that macro.  Actually
they're not but they get renamed to _macro_NN_... so that they
effectively *are* local.

There is an alternative syntax, for compatibility with other assemblers, with exactly the
same effect.

    MACRO MAGIC param1, param2
        LD param1, 0
        BIT param2, L
        label = 0x1234
        ... more real instructions go here.
    ENDM

A ',' can be passed as part of a macro argument, by enclosing the arguments between {braces}.

    MACRO PAIR x {
        LD x
    }
    PAIR {A,B}

expands to:

    LD A,B

=head1 BUGS and FEEDBACK

See L<CPU::Z80::Assembler|CPU::Z80::Assembler>.

=head1 SEE ALSO

L<CPU::Z80::Assembler|CPU::Z80::Assembler>
L<Iterator::Simple::Lookahead|Iterator::Simple::Lookahead>

=head1 AUTHORS, COPYRIGHT and LICENCE

See L<CPU::Z80::Assembler|CPU::Z80::Assembler>.

=cut

#------------------------------------------------------------------------------

1;
