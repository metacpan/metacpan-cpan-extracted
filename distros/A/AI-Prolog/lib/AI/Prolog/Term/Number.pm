package AI::Prolog::Term::Number;
$REVISION = '$Id: Number.pm,v 1.3 2005/02/28 02:32:11 ovid Exp $';
$VERSION = '0.1';
@ISA = 'AI::Prolog::Term';
use strict;
use warnings;
use Scalar::Util qw/looks_like_number/;

use aliased 'AI::Prolog::Term';

sub new {
    my ($proto, $number) = @_;
    my $self = $proto->SUPER::new($number, 0);
    $self->{varid} = defined $number && looks_like_number($number)
        ? $number
        : 0;
    return $self;
}

sub value { shift->{varid} }

sub dup { # should this be recast as the parent?
    my $self = shift;
    return $self->new($self->{varid});
}

1;

__END__

=head1 NAME

AI::Prolog::Term::Number - Perl implementation of Prolog numbers.

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
