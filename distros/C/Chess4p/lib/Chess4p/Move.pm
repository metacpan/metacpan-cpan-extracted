# -*- mode: cperl -*-
package Chess4p::Move;

use strict;
use warnings;
use v5.36;

use Chess4p::Common;

use overload ('""', => 'uci');

sub new {
    my ($class, $from, $to, $promotion) = @_;
    my $href = {};
    $href->{from} = $from;
    $href->{to} = $to;
    $href->{promotion} = $promotion;
    return bless $href, $class;
}

sub from { ## no critic (Subroutines::RequireArgUnpacking)
    return $_[0]->{from};
}

sub to { ## no critic (Subroutines::RequireArgUnpacking)
    return $_[0]->{to};
}

sub promotion { ## no critic (Subroutines::RequireArgUnpacking)
    return $_[0]->{promotion};    
}

sub uci { ## no critic (Subroutines::RequireArgUnpacking)
    my $result = "$Chess4p::Board::square_names{$_[0]->from()}$Chess4p::Board::square_names{$_[0]->to()}";
    $result .= lc($_[0]->promotion()) if defined $_[0]->promotion();
    return $result;
}


1;



__END__

=encoding utf8

=head1 NAME

Move - Chess move class

=head1 SYNOPSIS

    use Move;

    my $move = Move->new($from, $to);

=head1 DESCRIPTION

Move objects encapsulate the obvious from/to square properties.
Furthermore, optional property promotion piece.


=head1 METHODS


=head2 new($from, $to, $piece_type);

Constructor.
Create a Move by from/to squares, and optional promotion piece type.

=head2 from()

Get the from square.

=head2 to()

Get the to square.

=head2 promotion()

Get the promotion piece type, or undefined if none.

=head2 uci()

Get the UCI move representation.

=head1 AUTHOR

Ejner Borgbjerg

=head1 LICENSE

Perl Artistic License, GPL

=cut
