package AI::Prolog::TermList::Primitive;
$REVISION = '$Id: Primitive.pm,v 1.2 2005/02/20 18:27:55 ovid Exp $';
$VERSION = '0.1';
@ISA = 'AI::Prolog::TermList';
use strict;
use warnings;
use Scalar::Util qw/looks_like_number/;

sub new {
    my ($class, $number) = @_;
    my $self = $class->SUPER::new; # correct?
    $self->{ID} = looks_like_number($number) ? $number : 0;
    return $self;
}

sub ID { shift->{ID} }

sub to_string { " <".shift->{ID}."> " }

1;

__END__

=head1 NAME

AI::Prolog::TermList::Primitive - Perl implementation of Prolog primitives.

=head1 SYNOPSIS

No user serviceable parts inside.  You should never be seeing this.

=head1 DESCRIPTION

See L<AI::Prolog|AI::Prolog> for more information.  If you must know more,
there are plenty of comments sprinkled through the code.

Note that primitives are generally not implemented in terms of Prolog
predicates, but in terms of internal features that Prolog cannot handle
efficiently (or cannot handle at all).  Thus, every primitive has an C<ID>
associated with it.  This C<ID> identifies the internal code that makes it
work.

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
