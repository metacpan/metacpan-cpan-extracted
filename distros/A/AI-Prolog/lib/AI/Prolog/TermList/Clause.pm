package AI::Prolog::TermList::Clause;

$REVISION = '$Id: Clause.pm,v 1.4 2005/08/06 23:28:40 ovid Exp $';
$VERSION  = '0.1';

use strict;
use warnings;
use base 'AI::Prolog::TermList';

sub new {

    #      Term  TermList
    my $class = shift;
    return $class->SUPER::new(@_);
}

sub to_string {
    my $self = shift;
    my ( $term, $next ) = ( $self->term, $self->next );
    foreach ( $term, $next ) {
        $_ = $_ ? $_->to_string : "null";
    }
    return sprintf "%s :- %s" => $term, $next;
}

sub is_builtin {
    my $self = shift;
    if (@_) {
        $self->{is_builtin} = shift;
        return $self;
    }
    return $self->{is_builtin};
}

1;

__END__

=head1 NAME

AI::Prolog::TermList::Clause - Perl implementation of Prolog clauses.

=head1 SYNOPSIS

No user serviceable parts inside.  You should never be seeing this.

=head1 DESCRIPTION

See L<AI::Prolog|AI::Prolog> for more information.  If you must know more,
there are plenty of comments sprinkled through the code.

=head1 SEE ALSO

L<AI::Prolog>

L<AI::Prolog::Introduction>

L<AI::Prolog::Builtins>

W-Prolog:  L<http://goanna.cs.rmit.edu.au/~winikoff/wp/>

X-Prolog:  L<http://www.iro.umontreal.ca/~vaucher/XProlog/>

Roman BartE<225>k's online guide to programming Prolog:
L<http://kti.ms.mff.cuni.cz/~bartak/prolog/index.html>

=head1 AUTHOR

Curtis "Ovid" Poe, E<lt>moc tod oohay ta eop_divo_sitrucE<gt>

Reverse the name to email me.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Curtis "Ovid" Poe

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
