package AI::Prolog::TermList::Step;
$REVISION = '$Id: Step.pm,v 1.2 2005/02/20 18:27:55 ovid Exp $';
$VERSION = '0.1';
@ISA = 'AI::Prolog::TermList';
use strict;
use warnings;

use aliased 'AI::Prolog::Term';

sub new {
    my ($class, $termlist) = @_;
    my $self = $class->SUPER::new;

    $self->{next}     = $termlist->next;
    $termlist->{next} = $self;
    $self->{term}     = Term->new('STEP',0);
    return $self;
}

1;
__END__

=head1 NAME

AI::Prolog::TermList::Step - Perl implementation of Prolog "step" mechanism.

=head1 SYNOPSIS

No user serviceable parts inside.  You should never be seeing this.  This is
a debugging tool.

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
