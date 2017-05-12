package AI::Prolog::TermList;
$REVISION = '$Id: TermList.pm,v 1.11 2005/08/06 23:28:40 ovid Exp $';

$VERSION = 0.03;

use strict;
use warnings;
use Carp qw( croak confess );

use Hash::Util 'lock_keys';

use aliased 'AI::Prolog::Term';
use aliased 'AI::Prolog::Term::Number';
use aliased 'AI::Prolog::Parser';
use aliased 'AI::Prolog::TermList::Clause';
use aliased 'AI::Prolog::TermList::Primitive';

sub new {

    #my ($proto, $parser, $nexttermlist, $definertermlist) = @_;
    my $proto = shift;
    my $class = ref $proto || $proto;    # yes, I know what I'm doing
    return _new_from_term( $class, @_ ) if 1 == @_ && $_[0]->isa(Term);
    return _new_from_term_and_next( $class, @_ ) if 2 == @_;
    if (@_) {
        croak "Unknown arguments to TermList->new:  @_";
    }
    my $self = bless {
        term => undef,
        next => undef,
        next_clause =>
            undef,    # serves two purposes: either links clauses in database
                      # or points to defining clause for goals
        is_builtin => undef,

        varname  => undef,
        ID       => undef,
        _results => undef,
    } => $class;
    lock_keys %$self;
    return $self;
}

sub _new_from_term {
    my ( $class, $term ) = @_;
    my $self = $class->new;
    $self->{term} = $term;
    return $self;
}

sub _new_from_term_and_next {
    my ( $class, $term, $next ) = @_;
    my $self = $class->_new_from_term($term);
    $self->{next} = $next;
    return $self;
}

sub term { shift->{term} }

sub next {
    my $self = shift;
    if (@_) {
        $self->{next} = shift;
        return $self;
    }
    return $self->{next};
}

sub next_clause {
    my $self = shift;
    if (@_) {

        # XXX debug
        my $next_clause = shift;
        no warnings 'uninitialized';
        if ( $next_clause eq $self ) {
            confess("Trying to assign a termlist as its own successor");
        }
        $self->{next_clause} = $next_clause;
        return $self;
    }
    return $self->{next_clause};
}

sub to_string {
    my $self      = shift;
    my $indent    = "\n\t";
    my $to_string = $indent . $self->term->to_string;

    #my $to_string = "[" . $self->term->to_string;
    my $tl = $self->next;
    while ($tl) {
        $to_string .= ",$indent" . $tl->term->to_string;
        $tl = $tl->next;
    }
    return $to_string;
}

sub resolve {    # a.k.a. lookup_in
    my ( $self, $kb ) = @_;
    my $predicate = $self->{term}->predicate;
    $self->next_clause( $kb->get($predicate) );
}

1;

__END__

=head1 NAME

AI::Prolog::TermList - Create lists of Prolog Terms.

=head1 SYNOPSIS

No user serviceable parts inside.  You should never be seeing this.

=head1 DESCRIPTION

See L<AI::Prolog|AI::Prolog> for more information.  If you must know more,
there are plenty of comments sprinkled through the code.

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
