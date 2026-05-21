package Chess4p::Perft;

use v5.36;

use Chess4p::Board;

use Exporter 'import';

our @EXPORT_OK = qw(perft);


sub perft {
    my ($depth, $board) = @_;
    say "Call perft($depth,\n$board)";
    _perft($depth, $board, $depth);
}

sub _perft {
    my ($depth, $board, $orig_depth) = @_;
    if ($depth == 1) {
        return @{$board->legal_moves()};
    }
    elsif ($depth > 1) {
        my $count = 0;
        for my $move (@{$board->legal_moves()}) {
            $board->push_move($move);
            my $tmp = _perft($depth - 1, $board, $orig_depth);
            $count += $tmp;
            say "$move: $tmp" if $depth == $orig_depth;
            $board->pop_move();
        }
        return $count;
    }
    else {
        return 1;
    }
}



1;



__END__

=encoding utf8

=head1 NAME

Perft - provides Perft functionality.


=head1 SYNOPSIS

    use Chess4p;
    use Chess4p::Perft qw(perft);

    my $board = Chess4p::Board->fromFen($fen);
    my $depth = 5;

    my $result = perft(5, $board);


=head1 DESCRIPTION

Perft calculates the number of leaf positions reached from a given position,
in a given halfmove depth.


=head1 FUNCTIONS

=over 4

=item perft($depth, $board);

Calculates and returns the perft number for the position given by $board
in the depth $depth.

Perft numbers are also printed for each first move, similar to what
Stockfish does in its 'go perft' command. This is useful for debugging
the legal move generator.

=back


=head1 AUTHOR

Ejner Borgbjerg

=head1 LICENSE

Perl Artistic License, GPL

=cut
