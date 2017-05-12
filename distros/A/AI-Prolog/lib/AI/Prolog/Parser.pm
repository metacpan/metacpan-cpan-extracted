package AI::Prolog::Parser;
$REVISION = '$Id: Parser.pm,v 1.9 2005/08/06 23:28:40 ovid Exp $';

$VERSION = '0.10';
use strict;
use warnings;
use Carp qw( confess croak );
use Regexp::Common;
use Hash::Util 'lock_keys';

# debugging stuff
use Clone;
use Text::Balanced qw/extract_quotelike extract_delimited/;

use aliased 'AI::Prolog::Engine';
use aliased 'AI::Prolog::KnowledgeBase';
use aliased 'AI::Prolog::Parser::PreProcessor';
use aliased 'AI::Prolog::Term';
use aliased 'AI::Prolog::Term::Number';
use aliased 'AI::Prolog::TermList';
use aliased 'AI::Prolog::TermList::Clause';
use aliased 'AI::Prolog::TermList::Primitive';

my $ATOM = qr/[[:alpha:]][[:alnum:]_]*/;

use constant NULL => 'null';

sub new {
    my ( $class, $string ) = @_;
    my $self = bless {
        _str      => PreProcessor->process($string),
        _posn     => 0,
        _start    => 0,
        _varnum   => 0,
        _internal => 0,
        _vardict  => {},
    } => $class;
    lock_keys %$self;
    return $self;
}

sub _vardict_to_string {
    my $self = shift;
    return "{"
        . (
        join ', ' => map { join '=' => $_->[0], $_->[1] }
            sort { $a->[2] <=> $b->[2] }
            map { [ $_, $self->_sortable_term( $self->{_vardict}{$_} ) ] }
            keys %{ $self->{_vardict} }
        ) . "}";
}

sub _sortable_term {
    my ( $self, $term ) = @_;
    my $string = $term->to_string;
    my $number = substr $string => 1;
    return $string, $number;
}

sub to_string {
    my $self   = shift;
    my $output = Clone::clone($self);
    $output->{_vardict} = $self->_vardict_to_string;
    return "{"
        . substr( $self->{_str}, 0, $self->{_posn} ) . " ^ "
        . substr( $self->{_str}, $self->{_posn} ) . " | "
        . $self->_vardict_to_string . " }";
}

sub _posn    { shift->{_posn} }
sub _str     { shift->{_str} }
sub _start   { shift->{_start} }
sub _varnum  { shift->{_varnum} }
sub _vardict { shift->{_vardict} }

sub _internal {
    my $self = shift;
    if (@_) {
        $self->{_internal} = shift;
        return $self;
    }
    return $self->{_internal};
}

# get the current character
sub current {
    my $self = shift;
    return '#' if $self->empty;
    return substr $self->{_str} => $self->{_posn}, 1;
}

# peek at the next character
sub peek {
    my $self = shift;
    return '#' if $self->empty;
    return substr( $self->{_str} => ( $self->{_posn} + 1 ), 1 ) || '#';
}

# is the parsestring empty?
sub empty {
    my $self = shift;
    return $self->{_posn} >= length $self->{_str};
}

my $LINENUM = 1;

sub linenum {
    my $self = shift;
    if (@_) {
        $LINENUM = shift;
        return $self;
    }
    $LINENUM;
}

sub advance_linenum {
    my $self = shift;
    $LINENUM++;
}

# Move a character forward
sub advance {
    my $self = shift;

    # print $self->current; # XXX
    $self->{_posn}++ unless $self->{_posn} >= length $self->{_str};
    $self->advance_linenum if $self->current =~ /[\r\n]/;
}

# all three get methods must be called before advance
# recognize a name (sequence of alphanumerics)
# XXX the java methods do not directly translate, so
#     we need to revisit this if it breaks
# XXX Update:  There was a subtle bug.  I think
#     I've nailed it, though.  The string index was off by one
sub getname {
    my $self = shift;

    $self->{_start} = $self->{_posn};
    my $getname;
    if ( $self->current =~ /['"]/ ) {

     # Normally, Prolog distinguishes between single and double quoted strings
        my $string = substr $self->{_str} => $self->{_start};
        $getname = extract_delimited($string);
        $self->{_posn} += length $getname;
        return substr $getname => 1, length($getname) - 2;  # strip the quotes
    }
    else {
        my $string = substr $self->{_str} => $self->{_start};
        ($getname) = $string =~ /^($ATOM)/;
        $self->{_posn} += length $getname;
        return $getname;
    }
}

# recognize a number
# XXX same issues as getname
sub getnum {
    my $self = shift;

    $self->{_start} = $self->{_posn};
    my $string = substr $self->{_str} => $self->{_start};
    my ($getnum) = $string =~ /^($RE{num}{real})/;
    if ( '.' eq substr $getnum => -1, 1 ) {
        $getnum = substr $getnum => 0, length($getnum) - 1;
    }
    $self->{_posn} += length $getnum;
    return $getnum;
}

# get the term corresponding to a name.
# if the name is new, create a new variable
sub getvar {
    my $self   = shift;
    my $string = $self->getname;
    my $term   = $self->{_vardict}{$string};
    unless ($term) {
        $term = Term->new( $self->{_varnum}++ );    # XXX wrong _varnum?
        $self->{_vardict}{$string} = $term;
    }
    return ( $term, $string );
}

my $ANON = 'a';

sub get_anon {
    my $self = shift;

    # HACK!!!
    my $string = '___' . $ANON++;
    $self->advance;
    my $term = $self->{_vardict}{$string};
    unless ($term) {
        $term = Term->new( $self->{_varnum}++ );    # XXX wrong _varnum?
        $self->{_vardict}{$string} = $term;
    }
    return ( $term, $string );
}

# handle errors in one place
sub parseerror {
    my ( $self, $character ) = @_;
    my $linenum = $self->linenum;
    croak "Unexpected character: ($character) at line number $linenum";
}

# skips whitespace and prolog comments
sub skipspace {
    my $self = shift;
    $self->advance while $self->current =~ /[[:space:]]/;
    _skipcomment($self);
}

# XXX Other subtle differences
sub _skipcomment {
    my $self = shift;
    if ( $self->current eq '%' ) {
        while ( $self->current ne "\n" && $self->current ne "#" ) {
            $self->advance;
        }
        $self->skipspace;
    }
    if ( $self->current eq "/" ) {
        $self->advance;
        if ( $self->current ne "*" ) {
            $self->parseerror("Expecting '*' after '/'");
        }
        $self->advance;
        while ( $self->current ne "*" && $self->current ne "#" ) {
            $self->advance;
        }
        $self->advance;
        if ( $self->current ne "/" ) {
            $self->parseerror("Expecting terminating '/' on comment");
        }
        $self->advance;
        $self->skipspace;
    }
}

# reset the variable dictionary
sub nextclause {
    my $self = shift;
    $self->{_vardict} = {};
    $self->{_varnum}  = 0;
}

# takes a hash and extends it with the clauses in the string
# $program is a string representing a prolog program
# $db is an initial program that will be augmented with the
# clauses parsed.
# class method, not an instance method
sub consult {
    my ( $class, $program, $db ) = @_;
    $db ||= KnowledgeBase->new;
    my $self = $class->new($program);
    $self->linenum(1);
    $self->skipspace;

    until ( $self->empty ) {
        my $termlist = $self->_termlist;

        my $head = $termlist->term;
        my $body = $termlist->next;

        my $is_primitive = $body && $body->isa(Primitive);
        unless ($is_primitive) {
            my $predicate = $head->predicate;
            $is_primitive = exists $db->{primitives}{$predicate};
        }
        my $add = $is_primitive ? 'add_primitive' : 'add_clause';
        my $clause = Clause->new( $head, $body );
        my $adding_builtins = Engine->_adding_builtins;
        $clause->is_builtin(1) if $adding_builtins;
        $db->$add( $clause, $adding_builtins );
        $self->skipspace;
        $self->nextclause;    # new set of vars
    }
    return $db;
}

sub resolve {
    my ( $class, $db ) = @_;
    foreach my $termlist ( values %{ $db->ht } ) {
        $termlist->resolve($db);
    }
}

sub _termlist {
    my ($self)   = @_;
    my $termlist = TermList->new;
    my @ts       = $self->_term;
    $self->skipspace;

    if ( $self->current eq ':' ) {
        $self->advance;

        if ( $self->current eq '=' ) {

            # we're parsing a primitive
            $self->advance;
            $self->skipspace;
            my $id = $self->getnum;
            $self->skipspace;
            $termlist->{term} = $ts[0];
            $termlist->{next} = Primitive->new($id);
        }
        elsif ( $self->current ne '-' ) {
            $self->parseerror("Expected '-' after ':'");
        }
        else {
            $self->advance;
            $self->skipspace;

            push @ts => $self->_term;
            $self->skipspace;

            while ( $self->current eq ',' ) {
                $self->advance;
                $self->skipspace;
                push @ts => $self->_term;
                $self->skipspace;
            }

            my @tsl;
            for my $j ( reverse 1 .. $#ts ) {
                $tsl[$j] = $termlist->new( $ts[$j], $tsl[ $j + 1 ] );
            }

            $termlist->{term} = $ts[0];
            $termlist->{next} = $tsl[1];
        }
    }
    else {
        $termlist->{term} = $ts[0];
        $termlist->{next} = undef;
    }

    if ( $self->current ne '.' ) {
        $self->parseerror("Expected '.' Got '@{[$self->current]}'");
    }
    $self->advance;
    return $termlist;
}

# This constructor is the simplest way to construct a term.  The term is given
# in standard notation.
# Example: my $term = Term->new(Parser->new("p(1,a(X,b))"));
sub _term {
    my ($self) = @_;
    my $term = Term->new( undef, 0 );
    my $ts   = [];
    my $i    = 0;

    $self->skipspace;    # otherwise we crash when we hit leading
                         # spaces
    if ( $self->current =~ /^[[:lower:]'"]$/ ) {
        $term->{functor} = $self->getname;
        $term->{bound}   = 1;
        $term->{deref}   = 0;

        if ( '(' eq $self->current ) {
            $self->advance;
            $self->skipspace;
            $ts->[ $i++ ] = $self->_term;
            $self->skipspace;

            while ( ',' eq $self->current ) {
                $self->advance;
                $self->skipspace;
                $ts->[ $i++ ] = $self->_term;
                $self->skipspace;
            }

            if ( ')' ne $self->current ) {
                $self->parseerror(
                    "Expecting: ')'.  Got (@{[$self->current]})");
            }

            $self->advance;
            $term->{args} = [];

            $term->{args}[$_] = $ts->[$_] for 0 .. ( $i - 1 );
            $term->{arity} = $i;
        }
        else {
            $term->{arity} = 0;
        }
    }
    elsif ( $self->current =~ /^[[:upper:]]$/ ) {
        $term->{bound} = 1;
        $term->{deref} = 1;
        my ( $ref, $string ) = $self->getvar;
        $term->{ref}     = $ref;
        $term->{varname} = $string;
    }
    elsif ( '_' eq $self->current && $self->peek =~ /^[\]\|\.;\s\,\)]$/ ) {

        # temporary hack to allow anonymous variables
        # this should really be cleaned up
        $term->{bound} = 1;
        $term->{deref} = 1;
        my ( $ref, $string ) = $self->get_anon;
        $term->{ref}     = $ref;
        $term->{varname} = $string;
    }
    elsif ( $self->current =~ /^[-.[:digit:]]$/ ) {
        return Number->new( $self->getnum );
    }
    elsif ( '[' eq $self->current ) {
        $self->advance;

        if ( ']' eq $self->current ) {
            $self->advance;
            $term->{functor} = NULL;
            $term->{arity}   = 0;
            $term->{bound}   = 1;
            $term->{deref}   = 0;
        }
        else {
            $self->skipspace;
            $ts->[ $i++ ] = $self->_term;
            $self->skipspace;

            while ( ',' eq $self->current ) {
                $self->advance;
                $self->skipspace;
                $ts->[ $i++ ] = $self->_term;
                $self->skipspace;
            }

            if ( '|' eq $self->current ) {
                $self->advance;
                $self->skipspace;
                $ts->[ $i++ ] = $self->_term;
                $self->skipspace;
            }
            else {
                $ts->[ $i++ ] = $term->new( NULL, 0 );
            }

            if ( ']' ne $self->current ) {
                $self->parseerror("Expecting ']'");
            }

            $self->advance;
            $term->{bound}   = 1;
            $term->{deref}   = 0;
            $term->{functor} = "cons";
            $term->{arity}   = 2;
            $term->{args}    = [];
            for my $j ( reverse 1 .. $i - 2 ) {
                my $term = $term->new( "cons", 2 );
                $term->setarg( 0, $ts->[$j] );
                $term->setarg( 1, $ts->[ $j + 1 ] );
                $ts->[$j] = $term;
            }
            $term->{args}[0] = $ts->[0];
            $term->{args}[1] = $ts->[1];
        }
    }
    elsif ( '!' eq $self->current ) {
        $self->advance;
        return $term->CUT;
    }
    else {
        $self->parseerror(
            "Term should begin with a letter, a digit, or '[', not a @{[$self->current]}"
        );
    }
    return $term;
}

1;

__END__

=head1 NAME

AI::Prolog::Parser - A simple Prolog parser.

=head1 SYNOPSIS

 my $database = Parser->consult($prolog_text).

=head1 DESCRIPTION

There are no user-serviceable parts inside here.  See L<AI::Prolog|AI::Prolog>
for more information.  If you must know more, there are a few comments
sprinkled through the code.

=head1 SEE ALSO

W-Prolog:  L<http://goanna.cs.rmit.edu.au/~winikoff/wp/>

Michael BartE<225>k's online guide to programming Prolog:
L<http://kti.ms.mff.cuni.cz/~bartak/prolog/index.html>

=head1 AUTHOR

Curtis "Ovid" Poe, E<lt>moc tod oohay ta eop_divo_sitrucE<gt>

Reverse the name to email me.

This work is based on W-Prolog, L<http://goanna.cs.rmit.edu.au/~winikoff/wp/>,
by Dr. Michael Winikoff.  Many thanks to Dr. Winikoff for granting me
permission to port this.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Curtis "Ovid" Poe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

