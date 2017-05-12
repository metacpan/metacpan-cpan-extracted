package AI::Prolog::Term;
$REVISION = '$Id: Term.pm,v 1.10 2005/08/06 23:28:40 ovid Exp $';

$VERSION = '0.07';
use strict;
use warnings;
use Carp qw( croak confess );

use Hash::Util 'lock_keys';

use aliased 'AI::Prolog::Term::Cut';
use aliased 'AI::Prolog::Parser';

use aliased 'Hash::AsObject';

use constant NULL => 'null';

# Var is a type of term
# A term is a basic data structure in Prolog
# There are three types of terms:
#   1. Values     (i.e., have a functor and arguments)
#   2. Variables  (i.e., unbound)
#   3. References (bound to another variable)

my $VARNUM = 1;

# controls where occurcheck is used in unification.
# In early Java versions, the occurcheck was always performed
# which resulted in lower performance.

my $OCCURCHECK = 0;

sub occurcheck {
    my ( $class, $value ) = @_;
    $OCCURCHECK = $value if defined $value;
    return $OCCURCHECK;
}

# controls printing of lists as [a,b]
# instead of cons(a, cons(b, null))

sub prettyprint {1}

my $CUT = Cut->new(0);
sub CUT {$CUT}

sub new {
    my $proto = shift;
    my $class = CORE::ref $proto || $proto;    # yes, I know what I'm doing
    return $class->_new_var unless @_;
    if ( 2 == @_ ) {    # more common (performance)
        return _new_from_functor_and_arity( $class, @_ )
            unless 'ARRAY' eq CORE::ref $_[1];
    }
    elsif ( 1 == @_ ) {
        my $arg = shift;
        return _new_with_id( $class, $arg )
            if !CORE::ref $arg && $arg =~ /^[[:digit:]]+$/;
        return _new_from_string( $class, $arg ) if !CORE::ref $arg;

#return $arg->_term($class)            if   CORE::ref $arg && $arg->isa(Parser);
    }
    croak("Unknown arguments to Term->new");
}

sub _new_from_string {
    my ( $class, $string ) = @_;
    my $parsed = Parser->new($string)->_term($class);
}

sub _new_var {
    my $class = shift;

    #print "*** _new_var @{[$VARNUM+1]}";
    my $self = bless {
        functor => undef,
        arity   => 0,
        args    => [],

        # if bound is false, $self is a reference to a free variable
        bound => 0,
        varid => $VARNUM++,

        # if bound and deref are both true, $self is a reference to a ref
        deref => 0,
        ref   => undef,

        ID       => undef,
        varname  => undef,
        _results => undef,

        #source  => "_new_var",
    } => $class;
    lock_keys %$self;
    return $self;
}

sub _new_with_id {
    my ( $class, $id ) = @_;

    #print "*** _new_with_id: $id";
    my $self = bless {
        functor => undef,
        arity   => 0,
        args    => [],

        # if bound is false, $self is a reference to a free variable
        bound => 0,
        varid => $id,

        # if bound and deref are both true, $self is a reference to a ref
        deref => 0,
        ref   => undef,

        varname  => undef,
        ID       => undef,
        _results => undef,

        #source  => "_new_with_id: $id",
    } => $class;
    lock_keys %$self;
    return $self;
}

sub _new_from_functor_and_arity {
    my ( $class, $functor, $arity ) = @_;
    my $print_functor = defined $functor ? $functor : 'null';
    confess "undefined arity" unless defined $arity;

    #print "*** _new_from_functor_and_arity: ($print_functor) ($arity)";
    my $self = bless {
        functor => $functor,
        arity   => $arity,
        args    => [],

        # if bound is false, $self is a reference to a free variable
        bound => 1,
        varid => 0,    # XXX ??
             # if bound and deref are both true, $self is a reference to a ref
        deref => 0,
        ref   => undef,

        varname  => undef,
        ID       => undef,
        _results => undef,

        #source  => "_new_from_functor_and_arity: ($print_functor) ($arity)",
    } => $class;
    lock_keys %$self;
    return $self;
}

sub varnum  {$VARNUM}              # class method
sub functor { shift->{functor} }
sub arity   { shift->{arity} }
sub args    { shift->{args} }
sub varid   { shift->{varid} }
sub ref     { shift->{ref} }
sub predicate { sprintf "%s/%d" => $_[0]->getfunctor, $_[0]->getarity }

sub deref {
    my $self = shift;
    while ( $self->{bound} && $self->{deref} ) {
        $self = $self->{ref};
    }
    return $self;
}

sub bound {
    my $self = shift;
    while ( $self->{bound} && $self->{deref} ) {
        $self = $self->{ref};
    }
    return $self->{bound};
}

sub is_bound { shift->bound }

sub traceln {
    my ( $self, $msg ) = @_;
    if ( $self->{trace} ) {
        print "$msg\n";
    }
}

sub dup {
    my $self = shift;
    $self->new( $self->{functor}, $self->{arity} );
}

# bind a variable to a term
sub bind {
    my ( $self, $term ) = @_;
    return if $self eq $term;
    unless ( $self->{bound} ) {
        $self->{bound} = 1;
        $self->{deref} = 1;
        $self->{ref}   = $term;
    }
    else {
        croak(    "AI::Prolog::Term->bind("
                . $self->to_string
                . ").  Cannot bind to nonvar!" );
    }
}

# unbinds a term -- i.e., resets it to a variable
sub unbind {
    my $self = shift;
    $self->{bound} = 0;
    $self->{ref}   = undef;

    # XXX Now possible for a bind to have had no effect so ignore safety test
    # XXX if (bound) bound = false;
    # XXX else IO.error("Term.unbind","Can't unbind var!");
}

# set specific arguments.  A primitive way of constructing terms is to
# create them with Term(s,f) and then build up the arguments.  Using the
# parser is much simpler
sub setarg {
    my ( $self, $pos, $val ) = @_;
    if ( $self->{bound} && !$self->{deref} ) {
        $self->{args}[$pos] = $val;
    }
    else {
        croak(    "AI::Prolog::Term->setarg($pos, "
                . $val->to_string
                . ").  Cannot setarg on variables!" );
    }
}

# retrieves an argument of a term
sub getarg {
    my ( $self, $pos ) = @_;

    # should check if position is valid
    if ( $self->{bound} ) {
        return $self->{ref}->getarg($pos) if $self->{deref};
        return $self->{args}[$pos];
    }
    else {
        croak("AI::Prolog::Term->getarg.  Error -- lookup on unbound term!");
    }
}

sub getfunctor {
    my $self = shift;
    return "" unless $self->{bound};
    return $self->{ref}->getfunctor if $self->{deref};
    return $self->{functor};
}

sub getarity {
    my $self = shift;
    return 0 unless $self->{bound};
    return $self->{ref}->getarity if $self->{deref};
    return $self->{arity};
}

# check whether a variable occurs in a term
# XXX Since a variable is not consideref to occur in itself,
# XXX added occurs1 and a new front end called occurs()
sub occurs {
    my ( $self, $var ) = @_;
    return if $self->{varid} == $var;
    return $self->occurs1($var);
}

sub occurs1 {
    my ( $self, $var ) = @_;
    if ( $self->{bound} ) {
        return $self->ref->occurs1($var) if $self->{deref};
        for my $i ( 0 .. $self->arity - 1 ) {
            return 1 if $self->{args}[$i]->occurs1($var);
        }
    }
    else {
        return $self->varid == $var;
    }
}

# used internally for debugging
sub _dumpit {
    local $^W;
    my $self = shift;
    my $indent = shift || '';
    print( $indent . "source:  ", $self->{source} );
    print( $indent . "bound:  ", ( $self->{bound} ? 'true' : 'false' ) );
    print( $indent . "functor:  ", ( $self->{functor} || 'null' ) );
    if ( !$self->{ref} ) {
        print( $indent . "ref:  null" );
    }
    else {
        print( "\n$indent" . "ref:" );
        $self->{ref}->_dumpit( $indent . '  ' );
    }
    print( $indent . "arity:  ", $self->{arity} );
    if ( defined $self->{args}[0] ) {
        print( $indent. "args:" );
        foreach ( @{ $self->{args} } ) {
            $_->_dumpit( $indent . "  " );
        }
    }
    else {
        print( $indent. "args:  null" );
    }

#print($indent . "args:  ", scalar @{$self->{args}}) if defined $self->{args}[0];
    print( $indent . "deref:  ", ( $self->{deref} ? 'true' : 'false' ) );
    print( $indent . "varid:  ", $self->{varid}, "\n" );
}

# Unification is the basic primitive operation in logic programming.
# $stack: the stack is used to store the address of variables which
# are bound by the unification.  This is needed when backtracking.

sub unify {
    my ( $self, $term, $stack ) = @_;

    #_dumpit($self);
    #_dumpit($term);

    foreach ( $self, $term ) {
        $_ = $_->{ref} while $_->{bound} and $_->{deref};
    }

    if ( $self->{bound} and $term->{bound} ) {    # bound and not deref
        if (   $self->functor eq $term->getfunctor
            && $self->arity == $term->getarity )
        {
            for my $i ( 0 .. $self->arity - 1 ) {
                return
                    unless $self->{args}[$i]
                    ->unify( $term->getarg($i), $stack );
            }
            return 1;
        }
        else {
            return;    # functor/arity don't match ...
        }
    }    # at least one arg not bound ...
    if ( $self->{bound} ) {

        # added missing occurcheck
        if ( $self->occurcheck ) {
            if ( $self->occurs( $term->varid ) ) {
                return;
            }
        }
        $term->bind($self);
        push @{$stack} => $term;    # side-effect -- setting stack vars
        return 1;
    }

    # do occurcheck if turned on
    return if $self->occurcheck && $term->occurs( $self->varid );
    $self->bind($term);
    push @{$stack} => $self;        # save for backtracking
    return 1;
}

# refresh creates new variables.  If the variables already exist
# in its arguments then they are used.  This is used when parsing
# a clause so that variables throughout the clause are shared.
# Includes a copy operation.

sub refresh {
    my ( $self, $term_aref ) = @_;
    if ( $self->{bound} ) {
        if ( $self->{deref} ) {
            return $self->{ref}->refresh($term_aref);
        }
        else {
            if ( 0 == $self->{arity} ) {
                return $self;
            }
            else {
                my $term = ( CORE::ref $self)
                    ->_new_from_functor_and_arity( $self->{functor},
                    $self->{arity} );
                for my $i ( 0 .. $self->{arity} - 1 ) {
                    $term->{args}[$i]
                        = $self->{args}[$i]->refresh($term_aref);
                }
                return $term;
            }
        }
    }

    # else unbound
    unless ( $term_aref->[ $self->{varid} ] ) {
        $term_aref->[ $self->{varid} ] = $self->new;
    }
    return $term_aref->[ $self->{varid} ];
}

sub to_data {
    my $self = shift;
    $self->{_results} = {};

    # @results is the full results, if we ever need it
    my @results = $self->_to_data($self);
    return AsObject->new( $self->{_results} ), \@results;
}

sub _to_data {
    my ( $self, $parent ) = @_;
    if ( defined $self->{varname} ) {

        # XXX here's where the [HEAD|TAIL] bug is.  The engine works fine,
        # but we can't bind TAIL to a result object and are forced to
        # switch to raw_results.
        my $varname = delete $self->{varname};
        ( $parent->{_results}{$varname} ) = $self->_to_data($parent);
        $self->{varname} = $varname;
    }
    if ( $self->{bound} ) {
        my $functor = $self->functor;
        my $arity   = $self->arity;
        return $self->ref->_to_data($parent) if $self->{deref};
        return [] if NULL eq $functor && !$arity;
        if ( "cons" eq $functor && 2 == $arity ) {
            my @result = $self->{args}[0]->_to_data($parent);
            my $term   = $self->{args}[1];

            while ( "cons" eq $term->getfunctor && 2 == $term->getarity ) {
                if ( $term->{varname} ) {
                  push @result => $term->_to_data($parent);
                } else {
                  push @result => $term->getarg(0)->_to_data($parent);
                }
                $term = $term->getarg(1);
            }

            # XXX Not really sure about this one
            push @result => $term->_to_data($parent)
                unless NULL eq $term->getfunctor && !$term->getarity;

            #    ? "]"
            #    : "|" . $term->_to_data($parent) . "]";
            return \@result;
        }
        else {
            my @results = $self->functor;
            if ( $self->arity ) {

                #push @results => [];
                my $arity = $self->arity;
                my @args  = @{ $self->args };
                if (@args) {
                    for my $i ( 0 .. $arity - 1 ) {
                        push @results => $args[$i]->_to_data($parent);
                    }

                    # I have no idea what the following line was doing.
                    #push @results => $args[$arity - 1]->_to_data($parent)
                }
            }
            return @results;
        }
    }    # else unbound;
    return undef;
}

my %varname_for;
my $varname = 'A';

sub to_string {
    require Data::Dumper;
    my $self = shift;
    return $self->_to_string(@_);
}

sub _to_string {
    my ( $self, $extended ) = @_;
    if ( $self->{bound} ) {
        my $functor     = $self->functor;
        my $arity       = $self->arity;
        my $prettyprint = $self->prettyprint;
        return $self->ref->_to_string($extended) if $self->{deref};
        return "[]" if NULL eq $functor && !$arity && $prettyprint;
        my $string;
        if ( "cons" eq $functor && 2 == $arity && $prettyprint ) {
            $string = "[" . $self->{args}[0]->_to_string;
            my $term = $self->{args}[1];

            while ( "cons" eq $term->getfunctor && 2 == $term->getarity ) {
                $string .= "," . $term->getarg(0)->_to_string;
                $term = $term->getarg(1);
            }

            $string .=
                ( NULL eq $term->getfunctor && !$term->getarity )
                ? "]"
                : "|" . $term->_to_string . "]";
            return "$string";
        }
        else {
            $string = $self->functor;
            if ( $self->arity ) {
                $string .= "(";
                if ( $self->arity ) {
                    local $Data::Dumper::Terse  = 1;    # don't use $var1
                    local $Data::Dumper::Indent = 0;    # no newline
                    my @args = map {
                        my $string = $_->_to_string;
                        $string =~ /\s/
                            && !$_->arity
                            ? Data::Dumper::Dumper($string)
                            : $string;
                    } @{ $self->args };
                    $string .= join ", " => @args;
                }
                $string .= ")";
            }
        }
        return $string;
    }    # else unbound;
         # return "_" . $self->varid;
    my $var = $self->{varname} || $varname_for{ $self->varid } || $varname++;
    $varname_for{ $self->varid } = $var;
    return $var;
}

# ----------------------------------------------------------
#  Copy a term to put in the database
#    - with new variables (freshly renumbered)
# ----------------------------------------------------------

# XXX XProlog
my %CVDICT;
my $CVN;

sub clean_up {
    my $self = shift;
    %CVDICT = ();
    $CVN    = 0;
    return $self->_clean_up;
}

sub _clean_up {
    my $self = shift;
    my $term;
    if ( $self->{bound} ) {
        if ( $self->{deref} ) {
            return $self->{ref}->_clean_up;
        }
        elsif ( defined $self->{arity} && 0 == $self->{arity} ) {
            return $self;
        }
        else {
            $term = $self->dup;
            for my $i ( 0 .. $self->{arity} - 1 ) {
                $term->{args}[$i] = $self->{args}[$i]->_clean_up;
            }
        }
    }
    else {    # unbound
        $term = $CVDICT{$self};
        unless ($term) {
            $term = $self->new( $CVN++ );
            $CVDICT{$self} = $term;    # XXX Should this be $self->to_string?
        }
    }
    return $term;
}

# From XProlog
sub value {

    # int i, res = 0;
    my $self = shift;
    my ( $i, $res ) = ( 0, 0 );

    unless ( $self->{bound} ) {
        my $term = $self->to_string;
        croak("Tried to to get value of unbound term ($term)");
    }
    return $self->{ref}->value if $self->{deref};
    my $functor = $self->getfunctor;
    my $arity   = $self->getarity;
    if ( 'rnd' eq $functor && 1 == $arity ) {

        # implement rand
    }
    if ( $arity < 2 ) {
        my $term = $self->to_string;
        croak("Term ($term) is not binary");
    }
    my $arg0 = $self->{args}[0]->value;
    my $arg1 = $self->{args}[1]->value;

    return $arg0 + $arg1 if 'plus'  eq $functor;
    return $arg0 - $arg1 if 'minus' eq $functor;
    return $arg0 * $arg1 if 'mult'  eq $functor;
    return $arg0 / $arg1 if 'div'   eq $functor;
    return $arg0 % $arg1 if 'mod'   eq $functor;
    return $arg0**$arg1  if 'pow'   eq $functor;
    croak("Unknown operator ($functor)");
}

1;

__END__

=head1 NAME

AI::Prolog::Term - Create Prolog Terms.

=head1 SYNOPSIS

 my $query = Term->new("steals(Somebody, Something).");

=head1 DESCRIPTION

See L<AI::Prolog|AI::Prolog> for more information.  If you must know more,
there are plenty of comments sprinkled through the code.

=head1 BUGS

A query using C<[HEAD|TAIL]> syntax does not bind properly with the C<TAIL>
variable when returning a result object.  This bug can be found in the
C<_to_data> method of this class.

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
