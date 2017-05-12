package CQL::Lexer;

use strict;
use warnings;
use Carp qw( croak );
use String::Tokenizer;
use CQL::Token;

=head1 NAME

CQL::Lexer - a lexical analyzer for CQL

=head1 SYNOPSIS

    my $lexer = CQL::Lexer->new();
    $lexer->tokenize( 'foo and bar' );
    my @tokens = $lexer->getTokens();

=head1 DESCRIPTION

CQL::Lexer is lexical analyzer for a string of CQL. Once you've
got a CQL::Lexer object you can tokenize a CQL string into CQL::Token
objects. Ordinarily you'll never want to do this yourself since
CQL::Parser calls CQL::Lexer for you.

CQL::Lexer uses Stevan Little's lovely String::Tokenizer in the background,
and does a bit of analysis afterwards to handle some peculiarities of 
CQL: double quoted strings, <, <=, etc.

=head1 METHODS

=head2 new()

The constructor. 

=cut

sub new {
    my $class = shift;
    my $self = { 
        tokenizer   => String::Tokenizer->new(),
        tokens      => [],
        position    => 0,
    };
    return bless $self, ref($class) || $class;
}

=head2 tokenize()

Pass in a string of CQL to tokenize. This initializes the lexer with 
data so that you can retrieve tokens.

=cut

sub tokenize {
    my ( $self, $string ) = @_;

    ## extract the String::Tokenizer object we will use
    my $tokenizer = $self->{tokenizer};

    ## reset position parsing a new string of tokens
    $self->reset();

    ## delegate to String::Tokenizer for basic tokenization
    debug( "tokenizing: $string" );
    $tokenizer->tokenize( $string, '\/<>=()"',
        String::Tokenizer->RETAIN_WHITESPACE );

    ## do a bit of lexical analysis on the results of basic
    debug( "lexical analysis on tokens" );
    my @tokens = _analyze( $tokenizer );
    $self->{tokens} = \@tokens;
}

=head2 getTokens()

Returns a list of all the tokens.

=cut

sub getTokens {
    my $self = shift;
    return @{ $self->{tokens} };
}

=head2 token() 

Returns the current token.

=cut

sub token {
    my $self = shift;
    return $self->{tokens}[ $self->{position} ];
}

=head2 nextToken()

Returns the next token, or undef if there are more tokens to retrieve
from the lexer.

=cut

sub nextToken {
    my $self = shift;
    ## if we haven't gone over the end of our token list
    ## return the token at our current position while
    ## incrementing the position.
    if ( $self->{position} < @{ $self->{tokens} } ) {
        my $token = $self->{tokens}[ $self->{position}++ ];
        return $token;
    }
    return CQL::Token->new( '' );
}

=head2 prevToken()

Returns the previous token, or undef if there are no tokens prior
to the current token.

=cut

sub prevToken {
    my $self = shift;
    ## if we're not at the start of our list of tokens
    ## return the one previous to our current position
    ## while decrementing our position.
    if ( $self->{position} > 0 ) {
        my $token = $self->{tokens}[ --$self->{position} ];
        return $token;
    }
    return CQL::Token->new( '' );
}

=head2 reset()

Resets the iterator to start reading tokens from the beginning.

=cut

sub reset {
    shift->{position} = 0;
}

## Private sub used by _analyze for collecting a backslash escaped string terminated by "
sub _getString {
    my $iterator = shift;
    my $string = '"';
    my $escaping = 0;
    # loop through the tokens untill an unescaped " found
    while ($iterator->hasNextToken()) {
        my $token = $iterator->nextToken();
        $string .= $token;
        if ($escaping) {
        	$escaping = 0;
        } elsif ($token eq '"') {       
        	return $string;
        } elsif ($token eq "\\") {
        	$escaping = 1;
        }
    }
    croak( 'unterminated string ' . $string);
}

## Private sub used by _analyze to process \ outside double quotes.
## Because we tokenized on \ any \ outside double quotes (inside is handled by _getString)
## might need to be concatenated with a previous and or next CQL_WORD to form one CQL_WORD token
sub _concatBackslash {
	my $tokensRef = shift;
    my $i = 0;
    while ($i < @$tokensRef) {
    	my $token = $$tokensRef[$i];
    	if ($token->getString() eq "\\") {
    		my $s = "\\";
    		my $replace = 0;
    		if ($i > 0) {
    			my $prevToken = $$tokensRef[$i - 1];
    			if (($prevToken->getType() == CQL_WORD) and !$prevToken->{terminated}) {
    				# concatenate and delete the previous CQL_WORD token
    				$s = $prevToken->getString() . $s;
    				$i--;
    				splice @$tokensRef, $i, 1;
    				$replace = 1;
    			}
    		}
    		if (!$token->{terminated} and ($i < $#$tokensRef)) {
    			my $nextToken = $$tokensRef[$i + 1];
    			if ($nextToken->getType() == CQL_WORD) {
    				# concatenate and delete the next CQL_WORD token
    				$s .= $nextToken->getString();
    				splice @$tokensRef, $i + 1, 1;
    				$replace = 1;
    			}
    		}
    		if ($replace) {
    			$$tokensRef[$i] = CQL::Token->new($s);
    		}
    	}
    	$i++;
    }
}

sub _analyze { 
    my $tokenizer = shift;

    my $iterator = $tokenizer->iterator();
    my @tokens;
    while ( defined (my $token = $iterator->nextToken()) ) {

        ## <=
        if ( $token eq '<' and $iterator->lookAheadToken() eq '=' ) {
            push( @tokens, CQL::Token->new( '<=' ) );
            $iterator->nextToken();
        } 

        ## <>
        elsif ( $token eq '<' and $iterator->lookAheadToken() eq '>' ) {
            push( @tokens, CQL::Token->new( '<>') );
            $iterator->nextToken();
        }

        ## >=
        elsif ( $token eq '>' and $iterator->lookAheadToken() eq '=' ) {
            push( @tokens, CQL::Token->new( '>=' ) );
            $iterator->nextToken();
        }

        ## "quoted strings"
        elsif ( $token eq '"' ) {
        	my $cqlToken = CQL::Token->new( _getString($iterator) );
        	## Mark this and the previous token as terminated to prevent concatenation with backslash
        	$cqlToken->{terminated} = 1;
        	if (@tokens) { $tokens[$#tokens]->{terminated} = 1; }
            push( @tokens, $cqlToken );
        }

        ## if it's just whitespace we can zap it
        elsif ( $token =~ /\s+/ ) { 
            ## Mark the previous token as terminated to prevent concatenation with backslash
            if (@tokens) {
            	$tokens[$#tokens]->{terminated} = 1;
            }
        }

        ## otherwise it's fine the way it is 
        else {
            push( @tokens, CQL::Token->new($token) );
        }
	        
    } # while
    
    ## Concatenate \ outside double quotes with a previous and or next CQL_WORD to form one CQL_WORD token
    _concatBackslash(\@tokens);
    
    return @tokens;
}

sub debug {
    return unless $CQL::DEBUG;
    print STDERR 'CQL::Lexer: ', shift, "\n";
}

1;
