package Chess4p::Pgn::Reader;

use v5.36;

use utf8;

use Chess4p;

use Exporter 'import';

our @EXPORT_OK = qw(
    &read_game
);

our $_debug = 0;

my $NAG_GOOD_MOVE = 1;
my $NAG_MISTAKE = 2;
my $NAG_BRILLIANT_MOVE = 3;
my $NAG_BLUNDER = 4;
my $NAG_SPECULATIVE_MOVE = 5;
my $NAG_DUBIOUS_MOVE = 6;

my $move_text_rx = qr'
                       [NBKRQ]?[a-h]?[1-8]?[\-x]?[a-h][1-8](?:=?[nbrqkNBRQK])?
                     | -- | Z0 | 0000 | @@@@
                     | O-O(?:-O)?
                     | 0-0(?:-0)?    
                     | [?!]{1,2}
                     | \* | 1-0 | 0-1 | 1/2-1/2
                     | \$[0-9]+    # NAG
                     | \{.*        # Game comment    
                     | ;.*         # PGN file comment    
                     | \(          # Variation start
                     | \)          # Variation end
                     'xo;

my $tag_rx = qr'^\[([A-Za-z0-9][A-Za-z0-9_+#=:-]*)\s+\"([^\r]*)\"\]\s*$'o;

my $skip_move_text_rx = qr';|\{|\}'o;

  
sub read_game {
    my ($fh, $visitor) = @_;

    my @errors;

    my $line = <$fh>;

    # Remove BOM if needed
    $line =~ s/^\x{FEFF}// if defined $line;

    say "10---------> $line" if $_debug;

    # Ignore leading empty lines and comments.
    while (defined $line && $line =~/^[;%]?\s*$/) {
        $line = <$fh>; #  Use of uninitialized value $line in pattern match (m//) at lib/Chess4p/Pgn/Reader.pm line 53,
    }

    return undef unless $line;

    say "20---------> $line" if $_debug;

    my $found_game = 0;
    my $skipping_game = 0;
    my @board_stack = ();
    my $consecutive_empty_lines = 0;
    my $fen;

    # Loop to collect game headers
    while ($line) {

        say "30---------> $line" if $_debug;
        
        # Ignore comments.
        if ($line =~/^[;%]/) {
            $line = <$fh>;
            next;
        }
        
        # Ignore up to one consecutive empty line between headers.
        if ($consecutive_empty_lines < 1 && $line =~/^\s*$/) {
            $consecutive_empty_lines++;
            $line = <$fh>;
            next;
        }
        
        # First token of the game.
        unless ($found_game) {
            $found_game = 1;
            $skipping_game = $visitor->begin_game();
        }

        say "40---------> $line" if $_debug;

        last unless $line =~/^\[/;

        $consecutive_empty_lines = 0;

        unless ($skipping_game) {
            # Visitor will handle the headers ('managed header' according to python-chess)
            if ($line =~ /$tag_rx/) {
                my ($name, $value) = ($1, $2);

                if ($_debug) {
                    say $name  if $name;
                    say $value if $value;
                }

                $fen = $value if $name eq 'FEN';
                $visitor->visit_header($name, $value);
            }
            else {
                # Ignore invalid or malformed headers.
                $line = <$fh>;
                next;
            }
        }

        $line = <$fh>;
    }
    # end loop to collect game headers

    return undef unless $found_game;

    unless ($skipping_game) {
        $skipping_game = $visitor->end_headers();
    }

    unless ($skipping_game) {
        my $board =
          defined $fen
          ? Chess4p::Board->fromFen($fen)
          : Chess4p::Board->fromFen();
        push @board_stack, $board;
    }

    # Fast path: Skip entire game.
    if ($skipping_game) {
        my $in_comment = 0;
        while ($line) {
            unless ($in_comment) {
                if ($line =~/^\s*$/) {
                    last;
                }
                elsif ($line =~/^%/) {
                    $line = <$fh>;
                    next;
                }
            }
            my @tokens = ($line =~ /$skip_move_text_rx/g);
            for my $token (@tokens) {
                if ($token eq '{') {
                    $in_comment = 1;
                }
                elsif ($in_comment == 0 && $token eq ';') {
                    last;
                }
                elsif ($token eq '}') {
                    $in_comment = 0;
                }
            }
            $line = <$fh>;
        }
        $visitor->end_game();
        return ($visitor->result(), \@errors);
    }

    my $skip_variation_depth = 0;
    my $fresh_line = 1; # used when a comment ends in the middle of a line

    # loop for movetext of 1 game
    while ($line) {

        say "50---------> $line $fresh_line" if $_debug;
                
        if ($fresh_line) {
            # Ignore comments.
            if ($line =~/^[;%]/) {
                $line = <$fh>;
                next;
            }
            # An empty line means the end of a game.
            if ($line =~/^\s*$/) {

                say "52---------> empty line, end the game" if $_debug;
                
                $visitor->end_game();
                return ($visitor->result(), \@errors);
            }
        }
        $fresh_line = 1;

        say "60---------> $line" if $_debug;

        # find all tokens on current line
        my @tokens = ($line =~ /$move_text_rx/g);

        say "=== TOKENS: @tokens" if $_debug;

        for my $token (@tokens) {
            
            say "70---------> My token is: $token" if $_debug;

            if ($token =~/^{/) {
                # Consume until the end of the comment.
                my $start_index = 1;
                $start_index = 2 if $token =~/^{ /;
                $line = substr($token, $start_index);
                my @comment_lines = ();
                while ($line && index($line, '}') == -1) {
                    push @comment_lines, $line;
                    $line = <$fh>;
                }
                if ($line) {
                    my $close_index = index($line, '}');
                    my $end_index = ($close_index > 0 && substr($line, $close_index - 1, 1) eq ' ') ? $close_index-1 : $close_index;
                    push @comment_lines, substr($line, 0, $end_index);
                    $line = substr($line, $close_index+1);
                }
                $visitor->visit_comment(join ('', @comment_lines)) unless $skip_variation_depth;
                # Continue with the current line.
                $fresh_line = 0;
                last;
            }
            elsif ($token eq '(') {
                if ($skip_variation_depth) {
                    $skip_variation_depth++;
                }
                elsif ($board_stack[-1]->ply()) {

                    say "80---------> ply > 0" if $_debug;
                    
                    if (defined $visitor->begin_variation()) {

                        say "90---------> begin var" if $_debug;
                        
                        # up the board stack
                        my $board = Chess4p::Board->copyOf($board_stack[-1]);
                        $board->pop_move();

                        say "95--------->", $board->fen() if $_debug;

                        push @board_stack, $board;
                    }
                    else {
                        # increment, but otherwise ignore variation
                        $skip_variation_depth = 1;
                    }
                }
            }
            elsif ($token eq ')') {
                if ($skip_variation_depth == 1) {
                    $skip_variation_depth = 0;
                    $visitor->end_variation();
                }
                elsif ($skip_variation_depth) {
                    $skip_variation_depth--;
                }
                elsif (@board_stack > 1) {
                    $visitor->end_variation();
                    pop @board_stack;
                }
            }
            elsif ($skip_variation_depth) {
                next;
            }
            
            elsif ($token eq '!') {
                $visitor->visit_nag($NAG_GOOD_MOVE);
            }
            elsif ($token eq '?') {
                $visitor->visit_nag($NAG_MISTAKE);
            }
            elsif ($token eq '!!') {
                $visitor->visit_nag($NAG_BRILLIANT_MOVE);
            }
            elsif ($token eq '??') {
                $visitor->visit_nag($NAG_BLUNDER);
            }
            elsif ($token eq '!?') {
                $visitor->visit_nag($NAG_SPECULATIVE_MOVE);
            }
            elsif ($token eq '?!') {
                $visitor->visit_nag($NAG_DUBIOUS_MOVE);
            }
            elsif ($token =~/^\$/) {
                $visitor->visit_nag(substr($token,1));
            }
            elsif ($token =~/^;/) {
                last;
            }
            elsif (@board_stack == 1 && ($token eq '*' || $token eq '1-0' || $token eq '0-1' || $token eq '1/2-1/2')) {
                $visitor->visit_result($token);
            }
            else {
                # Parse SAN tokens.
                if ($visitor->begin_parse_san($board_stack[-1], $token)) {
                    my $move;
                    eval {
                        $move = $board_stack[-1]->parse_san($token);
                        say "98---------> Parsed move: $move" if $_debug;
                        $visitor->visit_move($board_stack[-1], $move);
                        $board_stack[-1]->push_move($move);
                    };
                    push @errors, $@ . " <\$fh> line ${.}." if $@;
                }
                $visitor->visit_board($board_stack[-1]);
            }
        }

        $line = <$fh> if $fresh_line;
    }
    # end loop movetext of 1 game

    $visitor->end_game();

    return ($visitor->result(), \@errors);
}



1;



__END__

=encoding utf8

=head1 NAME

Chess4p::Pgn::Reader - PGN reader.

=head1 SYNOPSIS


 use Chess4p::Pgn::Reader qw(read_game);

 open my $fh, '<:encoding(UTF-8):bom', $filename or die $!;

 read_game($fh, $visitor);


=head1 DESCRIPTION

Read chess games from PGN (Portable Game Notation) files.
The files are assumed to abide by the PGN Standard.

=over 4

=item read_game($fh, $visitor)

Read a game from the PGN file.
$fh is a file handle for the opened PGN file.
The visitor will handle the tokens fed by the reader (see below).

Returns a pair ($result, $errors) where
$result is whatever the visitor returns in $visitor->result(),
and $errors is a reference to an array that contains any error messages.

At the end of input, $result will be undefined -
which means that $visitor->result() should always return a defined value,
so that end of input can be detected correctly.

See pgn-reader.t for an example.

It is the callers responsibility to open the file in the
proper encoding. Usually, PGN files are ASCII or UTF-8 encoded.

For example:


 open my $fh, '<:encoding(UTF-8)', $filename or die $!;>

=back

=head2 CALLBACKS

The visitor needs to define a set of callback methods, which will be called at specific parsing
events.

=over 4

=item begin_game($visitor)

This will be called when the reader has determined that another game is available to be read.
Use this for cleaning up from any previous games read.

Return 0 to have the reader call the other callbacks as this game is read.

Return 1 to have the reader skip the game by not calling the other callbacks as this game is read.

=item end_game($visitor)

This is called immediately before the reader returns.

=item visit_header($visitor, $name, $value)

This is called when the reader has read a PGN tag with its value.
The tag name and value are returned.

=item end_headers($visitor)

Called when the reader has determined that there are no more headers to be read.

Return 0 to have the reader call the other callbacks as it reads the movetext section.

Return 1 to have the reader skip the movetext section of this game. This is useful in searching for specific
header values like player names, etc.

=item visit_comment($visitor, $comment)

The visitor has collected a (possibly multi-line) text comment, which is now available in $comment .

=item begin_variation($visitor)

Signals the start of a variation.

=item end_variation($visitor)

Signals the end of a variation.

=item visit_nag($visitor, $nag)

The reader has read a NAG (an integer).

=item visit_result($visitor, $token)

The reader has read a token that signifies the game's result.
This is one of '*', '1-0', '0-1' or '1/2-1/2'.

=item begin_parse_san($visitor, $board, $token)

The reader has seen a token that is supposed to be a SAN move string.

Return 1 to have the reader

=over 2

=item 1

parse the SAN string as a move

=item 2

call $visitor->visit_move($board, $move)
if the move was parsed as being valid ($move is reference to a Chess4p::Move object);

Or add any error message to the readers error stack if the SAN string was not valid.


=back

Whether the SAN was a valid move or not, the reader will call

$visitor->visit_board($board)

afterwards.

Return 0 to have the reader skip the SAN parsing;

The call to

$visitor->visit_board($board)

will happen also in this case.


=back



=head1 AUTHOR

Ejner Borgbjerg

=head1 LICENSE

Perl Artistic License, GPL

=cut
