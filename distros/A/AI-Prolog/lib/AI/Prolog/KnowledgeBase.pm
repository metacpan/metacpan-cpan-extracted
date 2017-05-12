package AI::Prolog::KnowledgeBase;
$REVISION = '$Id: KnowledgeBase.pm,v 1.5 2005/06/25 23:06:53 ovid Exp $';
$VERSION  = '0.02';
use strict;
use warnings;
use Carp qw( confess carp );

use Hash::Util 'lock_keys';

use aliased 'AI::Prolog::Engine';
use aliased 'AI::Prolog::Parser';
use aliased 'AI::Prolog::TermList::Clause';

sub new {
    my $self = bless {
        ht         => {},
        primitives => {},    # only uses keys
        oldIndex   => "",
    } => shift;
    lock_keys %$self;
    return $self;
}

sub ht { shift->{ht} }       # temp hack XXX

sub to_string {
    my $self = shift;
    return "{"
        . (
        join ', ' => map { join '=' => $_->[0], $_->[1] }
            sort { $a->[2] <=> $b->[2] }
            map { [ $_, $self->_sortable_term( $self->{_vardict}{$_} ) ] }
            keys %{ $self->{ht} }
        ) . "}";
}

sub _sortable_term {
    my ( $self, $term ) = @_;
    my $string = $term->to_string;
    my $number = substr $string => 1;
    return $string, $number;
}

sub put {
    my ( $self, $key, $termlist ) = @_;
    $self->{ht}{$key} = $termlist;
}

sub elements { [ values %{ shift->{ht} } ] }

sub reset {
    my $self = shift;
    $self->{ht}         = {};
    $self->{primitives} = {};
    $self->{oldIndex}   = '';
}

sub consult {
    my ( $self, $program ) = @_;
    $self->{oldIndex} = '';
    return Parser->consult( $program, $self );
}

sub add_primitive {
    my ( $self, $clause ) = @_;
    my $term      = $clause->term;
    my $predicate = $term->predicate;
    my $c         = $self->{ht}{$predicate};
    if ($c) {
        while ( $c->next_clause ) {
            $c = $c->next_clause;
        }
        $c->next_clause($clause);
    }
    else {
        $self->{primitives}{$predicate} = 1;
        $self->{ht}{$predicate}         = $clause;
    }
}

sub add_clause {
    my ( $self, $clause ) = @_;
    my $term      = $clause->term;
    my $predicate = $term->predicate;
    if ( $self->{primitives}{$predicate} ) {
        carp("Trying to modify primitive predicate: $predicate");
        return;
    }
    unless ( $predicate eq $self->{oldIndex} ) {
        delete $self->{ht}{$predicate};
        $self->{ht}{$predicate} = $clause;
        $self->{oldIndex} = $predicate;
    }
    else {
        my $c = $self->{ht}{$predicate};
        while ( $c->next_clause ) {
            $c = $c->next_clause;
        }
        $c->next_clause($clause);
    }
}

sub assert {
    my ( $self, $term ) = @_;
    $term = $term->clean_up;

    # XXX whoops.  Need to check exact semantics in Term
    my $newC = Clause->new( $term->deref, undef );

    my $predicate = $term->predicate;
    if ( $self->{primitives}{$predicate} ) {
        carp("Trying to assert a primitive: $predicate");
        return;
    }
    my $c = $self->{ht}{$predicate};
    if ($c) {
        while ( $c->next_clause ) {
            $c = $c->next_clause;
        }
        $c->next_clause($newC);
    }
    else {
        $self->{ht}{$predicate} = $newC;
    }
}

sub asserta {
    my ( $self, $term ) = @_;
    my $predicate = $term->predicate;
    if ( $self->{primitives}{$predicate} ) {
        carp("Trying to assert a primitive: $predicate");
        return;
    }
    $term = $term->clean_up;
    my $newC = Clause->new( $term->deref, undef );
    my $c = $self->{ht}{$predicate};
    $newC->next_clause($c);
    $self->{ht}{$predicate} = $newC;
}

sub retract {
    my ( $self, $term, $stack ) = @_;
    my $newC = Clause->new( $term, undef );    #, undef);
    my $predicate = $term->predicate;
    if ( exists $self->{primitives}{$predicate} ) {
        carp("Trying to retract a primitive: $predicate");
        return;
    }
    my $cc;
    my $c = $self->{ht}{$predicate};

    while ($c) {
        my $vars = [];
        my $xxx  = $c->term->refresh($vars);
        my $top  = @{$stack};

        if ( $xxx->unify( $term, $stack ) ) {
            if ($cc) {
                $cc->next_clause( $c->next_clause );
            }
            elsif ( !$c->next_clause ) {
                delete $self->{ht}{$predicate};
            }
            else {
                $self->{ht}{$predicate} = $c->next_clause;
            }
            return 1;
        }
        for ( my $i = @{$stack} - $top; $i > 0; $i-- ) {
            my $t = pop @{$stack};
            $t->unbind;
        }
        $cc = $c;
        $c  = $c->next_clause;
    }
    return;
}

sub retractall {
    my ( $self, $term, $arity ) = @_;
    my $predicate = $term->predicate;
    if ( $self->{primitives}{$predicate} ) {
        carp("Trying to retractall primitives: $predicate");
        return;
    }
    delete $self->{ht}{$predicate};
    return 1;
}

sub get {
    my ( $self, $term ) = @_;
    my $key = ref $term ? $term->to_string : $term;
    return $self->{ht}{$key};
}

sub set {
    my ( $self, $term, $value ) = @_;
    my $key = ref $term ? $term->to_string : $term;
    $self->{ht}{$key} = $value->clean_up;
}

sub _print { print @_ }

sub dump {
    my ( $self, $full ) = @_;
    my $i = 1;
    while ( my ( $key, $value ) = each %{ $self->{ht} } ) {
        next if !$full && ( $self->{primitives}{$key} || $value->is_builtin );
        if ( $value->isa(Clause) ) {
            _print( $i++ . ". $key: \n" );
            do {
                _print( "   " . $value->term->to_string );
                if ( $value->next ) {
                    _print( " :- " . $value->next->to_string );
                }
                _print(".\n");
                $value = $value->next_clause;
            } while ($value);
        }
        else {
            _print( $i++ . ". $key = $value\n" );
        }
    }
    _print("\n");
}

sub list {
    my ( $self, $predicate ) = @_;
    print "\n$predicate: \n";
    my $head = $self->{ht}{$predicate}
        or warn "Cannot list unknown predicate ($predicate)";
    while ($head) {
        print "   " . $head->term->to_string;
        if ( $head->next ) {
            print " :- " . $head->next->to_string;
        }
        print ".\n";
        $head = $head->next_clause;
    }
}

1;

__END__

=head1 NAME

AI::Prolog::KnowledgeBase - The Prolog database.

=head1 SYNOPSIS

 my $kb = KnowledgeBase->new;

=head1 DESCRIPTION

There are no user-serviceable parts inside here.  See L<AI::Prolog|AI::Prolog>
for more information.  If you must know more, there are a few comments
sprinkled through the code.

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

