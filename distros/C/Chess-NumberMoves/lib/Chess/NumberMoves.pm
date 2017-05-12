package Chess::NumberMoves;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Chess::NumberMoves ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.

sub from_file {

    my $file = shift;
    use FileHandle;
    my $fh = new FileHandle "< $file";
    $fh or die $!;

    my @line;
    
    my $line = 1;
    my $space = '  '; # 2 spaces to start with
    while (<$fh>) {

	if (/^[A-Z]/i) 
	  {
	      
	      $line == 10 and $space = ' '; # now one space
	      $_ = "$line.$space$_";
	      ++$line;
	  }

	push @line, $_;
    }
    
    join '', @line;

}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Chess::NumberMoves - Perl extension for numbering chess moves

=head1 SYNOPSIS

=head2 INITIAL FILE LACKS MOVE NUMBERS

Because I typed them in from a chess book but didn't feel like entering the 
move numbers:

 [Event "?"]
 [Site "Los Angeles"]
 [EventDate "1963"]
 [White "Benko"]
 [Black "Najdorf"]
 [Result "*"]
 
 d4 Nf6
 c4 c5
 d5 d6
 Nc3 g6
 e4 Bg7
 Be2 O-O
 Nf3 e5
 Bg5 h6
 Bh4 g5
 Bg3 Nh5
 h4 Nf4
 hxg5 hxg5
 Bf1 Bg4
 Qc2 Bxf3
 gxf3 Nd7
 O-O-O Re8
 Bh3 Nxh3
 Rxh3 Nf8
 Rdh1 Ng6
 Nd1 Rc8
 Ne3 Rc7
 Nf5 Rf8
 Qd1 f6
 f4 exf4
 Qh5 Ne5
 Qh7 Kf7
 Qxg7+ Ke8 
 Qxf8+ Kxf8
 Rh8+ Kf7
 Rxd8
 
 =head2 THEN WE NUMBER THE FILE

  use Chess::NumberMoves;
  my $numbered = Chess::NumberMoves::from_file('benko-najdorf.pgn');
  print $numbered;
  
 [Event "?"]
 [Site "Los Angeles"]
 [EventDate "1963"]
 [White "Benko"]
 [Black "Najdorf"]
 [Result "*"]
 
 
 
 1.  d4 Nf6
 2.  c4 c5
 3.  d5 d6
 4.  Nc3 g6
 5.  e4 Bg7
 6.  Be2 O-O
 7.  Nf3 e5
 8.  Bg5 h6
 9.  Bh4 g5
 10. Bg3 Nh5
 11. h4 Nf4
 12. hxg5 hxg5
 13. Bf1 Bg4
 14. Qc2 Bxf3
 15. gxf3 Nd7
 16. O-O-O Re8
 17. Bh3 Nxh3
 18. Rxh3 Nf8
 19. Rdh1 Ng6
 20. Nd1 Rc8
 21. Ne3 Rc7
 22. Nf5 Rf8
 23. Qd1 f6
 24. f4 exf4
 25. Qh5 Ne5
 26. Qh7 Kf7
 27. Qxg7+ Ke8 
 28. Qxf8+ Kxf8
 29. Rh8+ Kf7
 30. Rxd8

=head1 ABSTRACT

  This is a program for numbering a file consisting of chess moves listed
  two per line.

=head1 DESCRIPTION

Any line in the file which matches the regexp:

  /^[A-Z]/

has a line number prepended to it.

I wrote this because I was typing moves from a chess game listed in a book
("Simple Chess" by Michael Stean --- it rocks you should buy it!) but felt
it was not a good use of my time to keep entering numbers.

And presto-chango a little bit of Perl and here ya have it.

=head1 CONVENIENCE SCRIPT

A convenience script C<pgo2pgn> is included which
takes a file with C<.pgo> extension
and converts it to a pgn file, saving it with a C<.pgn> extension. The
conversion is to take a file which contains a pair of moves on each line and
number the lines.

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head2 A better way to do this:

L<Chess::PGN::Parse> on CPAN by Giuseppe Maxia


=head2 The perl-chess mailing list:

   perl-chess-subscribe@yahoogroups.com

to subscribe

   http://www.yahoogroups.com/group/perl-chess

to read the archives.

=head1 AUTHOR

Terrence Brannon, tbone@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Terrence Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
