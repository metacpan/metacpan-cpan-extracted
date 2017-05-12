package AI::Prolog::ChoicePoint;
$REVISION = '$Id: ChoicePoint.pm,v 1.5 2005/02/20 18:27:55 ovid Exp $';

$VERSION = '0.02';
use strict;
use warnings;
use Hash::Util 'lock_keys';

sub new {
    my ( $class, $goal, $clause ) = @_;
    my $self = bless {
        goal   => $goal,
        clause => $clause,
    } => $class;
    lock_keys %$self;
    return $self;
}

sub goal   { $_[0]->{goal} }
sub clause { $_[0]->{clause} }

sub to_string {
    my $self = shift;
    return "  ||" . $self->clause->to_string . "||   ";
}

1;

__END__

=head1 NAME

AI::Prolog::ChoicePoint - Create a choicepoint object for the Engine.

=head1 SYNOPSIS

No user serviceable parts inside.  You should never be seeing this.  This
little snippet is merely used when backtracking and needing to try other
alternatives.

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
