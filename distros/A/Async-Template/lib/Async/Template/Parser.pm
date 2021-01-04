package Async::Template::Parser;

#! @file
#! @author: Serguei Okladnikov <oklaspec@gmail.com>
#! @date 15.10.2012

use strict;
use warnings;
use base 'Template::Parser';

# parser state constants
use constant CONTINUE => Template::Parser::CONTINUE;
use constant ACCEPT   => Template::Parser::ACCEPT;
use constant ERROR    => Template::Parser::ERROR;
use constant ABORT    => Template::Parser::ABORT;


sub rollback_token {
    my $self = shift;
    die unless $self->{ _EVENT_LAST_TOKEN };
    unshift @{ $self->{_EVENT_TOKENS} }, ';';
    unshift @{ $self->{_EVENT_TOKENS} }, ';';
    unshift @{ $self->{_EVENT_TOKENS} }, $self->{_EVENT_LAST_TOKEN}->[1];
    unshift @{ $self->{_EVENT_TOKENS} }, $self->{_EVENT_LAST_TOKEN}->[0];
}


sub location {
   ''
}


#------------------------------------------------------------------------
# _parse(\@tokens, \@info)
#
# TODO: merge every Template Toolkit release with original source
# ( see base class Template::Parser )
#
# Parses the list of input tokens passed by reference and returns a 
# Template::Directive::Block object which contains the compiled 
# representation of the template. 
#
# This is the main parser DFA loop.  See embedded comments for 
# further details.
#
# On error, undef is returned and the internal _ERROR field is set to 
# indicate the error.  This can be retrieved by calling the error() 
# method.
#------------------------------------------------------------------------

sub _parse {
    my ($self, $tokens, $info) = @_;
    my ($token, $value, $text, $line, $inperl);
    my ($state, $stateno, $status, $action, $lookup, $coderet, @codevars);
    my ($lhs, $len, $code);         # rule contents
    my $stack = [ [ 0, undef ] ];   # DFA stack

# DEBUG
#   local $" = ', ';

    # retrieve internal rule and state tables
    my ($states, $rules) = @$self{ qw( STATES RULES ) };

    # If we're tracing variable usage then we need to give the factory a 
    # reference to our $self->{ VARIABLES } for it to fill in.  This is a
    # bit of a hack to back-patch this functionality into TT2.
    $self->{ FACTORY }->trace_vars($self->{ VARIABLES })
        if $self->{ TRACE_VARS };

    # call the grammar set_factory method to install emitter factory
    $self->{ GRAMMAR }->install_factory($self->{ FACTORY });

    $line = $inperl = 0;
    $self->{ LINE   } = \$line;
    $self->{ FILE   } = $info->{ name };
    $self->{ INPERL } = \$inperl;

    $status = CONTINUE;
    my $in_string = 0;

    while(1) {
        # get state number and state
        $stateno =  $stack->[-1]->[0];
        $state   = $states->[$stateno];

        # see if any lookaheads exist for the current state
        if (exists $state->{'ACTIONS'}) {

            # get next token and expand any directives (i.e. token is an 
            # array ref) onto the front of the token list
            $self->{ _EVENT_TOKENS } = $tokens;
            while (! defined $token && @$tokens) {
                $token = shift(@$tokens);
                $self->{ _EVENT_LAST_TOKEN } = [$token];
                if (ref $token) {
                    ($text, $line, $token) = @$token;
                    if (ref $token) {
                        if ($info->{ DEBUG } && ! $in_string) {
                            # - - - - - - - - - - - - - - - - - - - - - - - - -
                            # This is gnarly.  Look away now if you're easily
                            # frightened.  We're pushing parse tokens onto the
                            # pending list to simulate a DEBUG directive like so:
                            # [% DEBUG msg line='20' text='INCLUDE foo' %]
                            # - - - - - - - - - - - - - - - - - - - - - - - - -
                            my $dtext = $text;
                            $dtext =~ s[(['\\])][\\$1]g;
                            unshift(@$tokens, 
                                    DEBUG   => 'DEBUG',
                                    IDENT   => 'msg',
                                    IDENT   => 'line',
                                    ASSIGN  => '=',
                                    LITERAL => "'$line'",
                                    IDENT   => 'text',
                                    ASSIGN  => '=',
                                    LITERAL => "'$dtext'",
                                    IDENT   => 'file',
                                    ASSIGN  => '=',
                                    LITERAL => "'$info->{ name }'",
                                    (';') x 2,
                                    @$token, 
                                    (';') x 2);
                        }
                        else {
                            unshift(@$tokens, @$token, (';') x 2);
                        }
                        $token = undef;  # force redo
                    }
                    elsif ($token eq 'ITEXT') {
                        if ($inperl) {
                            # don't perform interpolation in PERL blocks
                            $token = 'TEXT';
                            $value = $text;
                        }
                        else {
                            unshift(@$tokens, 
                                    @{ $self->interpolate_text($text, $line) });
                            $token = undef; # force redo
                        }
                    }
                }
                else {
                    # toggle string flag to indicate if we're crossing
                    # a string boundary
                    $in_string = ! $in_string if $token eq '"';
                    $value = shift(@$tokens);
                    push @{ $self->{ _EVENT_LAST_TOKEN } }, $value;
                }
            };
            # clear undefined token to avoid 'undefined variable blah blah'
            # warnings and let the parser logic pick it up in a minute
            $token = '' unless defined $token;

            # get the next state for the current lookahead token
            $action = defined ($lookup = $state->{'ACTIONS'}->{ $token })
                      ? $lookup
                      : defined ($lookup = $state->{'DEFAULT'})
                        ? $lookup
                        : undef;
        }
        else {
            # no lookahead actions
            $action = $state->{'DEFAULT'};
        }

#warn "$stateno ".($token||'').' '.($value||'').' '.($action||'')."\n";
        # ERROR: no ACTION
        last unless defined $action;

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # shift (+ive ACTION)
        # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        if ($action > 0) {
            push(@$stack, [ $action, $value ]);
            $token = $value = undef;
            redo;
        };

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # reduce (-ive ACTION)
        # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        ($lhs, $len, $code) = @{ $rules->[ -$action ] };

        # no action imples ACCEPTance
        $action
            or $status = ACCEPT;

        # use dummy sub if code ref doesn't exist
        $code = sub { $_[1] }
            unless $code;

        @codevars = $len
                ?   map { $_->[1] } @$stack[ -$len .. -1 ]
                :   ();

        eval {
            $coderet = &$code( $self, @codevars );
        };
        if ($@) {
            my $err = $@;
            chomp $err;
            return $self->_parse_error($err);
        }

        # reduce stack by $len
        splice(@$stack, -$len, $len);

        # ACCEPT
        return $coderet                                     ## RETURN ##
            if $status == ACCEPT;

        # ABORT
        return undef                                        ## RETURN ##
            if $status == ABORT;

        # ERROR
        last 
            if $status == ERROR;
    }
    continue {
        push(@$stack, [ $states->[ $stack->[-1][0] ]->{'GOTOS'}->{ $lhs }, 
              $coderet ]), 
    }

    # ERROR                                                 ## RETURN ##
    return $self->_parse_error('unexpected end of input')
        unless defined $value;

    # munge text of last directive to make it readable
#    $text =~ s/\n/\\n/g;

    return $self->_parse_error("unexpected end of directive", $text)
        if $value eq ';';   # end of directive SEPARATOR

    return $self->_parse_error("unexpected token ($value)", $text);
}


1;
