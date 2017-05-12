package Chess::PGN::Extract;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.02';

use base 'Exporter::Tiny';
our @EXPORT = qw| read_games |;

use Carp       qw| carp croak |;
use Data::Dump qw| dump |;
use Encode     qw| encode_utf8 |;
use IO::Handle;
use JSON::XS   qw| decode_json |;
use Sys::Cmd   qw| spawn |;
use Try::Tiny;

sub read_games {
  my $pgn  = shift;
  my %opts = @_;
  # TODO: add options to be passed to pgn-extract

  my $proc = spawn ( 'pgn-extract', '-s', '-Wjson', $pgn );
  my $out = do { local $/; $proc->stdout->getline };
  my @err = $proc->stderr->getlines;
  if (@err) {
    if ($err[0] =~ /Unknown output format json/) {
      croak ("PGN parse error: pgn-extract has no '-Wjson' option");
    }
    STDERR->print ("pgn-extract: $_") for @err;
  }
  $proc->wait_child; # cleanup

  # Ad-hoc hack for a problem in parsing JSON
  #
  # PGN files may contain illegal characters and it hinders decoding by
  # JSON::XS. At present, I've found the control 'B' and back quote in
  # practice.
  if ( $out =~ s/[\cB\\]//g ) {
    STDERR->print ("Invalid characters found\n");
  }

  $out = encode_utf8 ($out);
  $out =~ s/\n//g;
  $out =~ s/}/},/g;
  chop $out;
  $out = "[" . $out . "]";

  my $decoded = try {
    decode_json ($out);
  } catch {
    croak ("JSON parse error: $out");
  };

  # Filter valid PGNs
  my @games = grep {
    if ( $_->{chash} ) {
      1;
    }
    else {
      my $invalid_game = dump ($_);
      STDERR->print ("Invalid PGN omitted: $invalid_game\n");
      0;
    }
  } @$decoded;

  foreach (@games) {
    delete $_->{chash};
    delete $_->{fhash};
  }

  return @games;
}

1;
__END__

=encoding utf-8

=head1 NAME

Chess::PGN::Extract - Parse PGN files by using `pgn-extract`

=head1 SYNOPSIS

    use Chess::PGN::Extract;

    # Slurp all games in a PGN file
    my @games = read_games ("filename.pgn");

=head1 DESCRIPTION

B<Chess::PGN::Extract> provides a function to extract chess records from
Portable Game Notation (PGN) files.

B<Chess::PGN::Extract> internally depends on
L<JSON-enhanced pgn-extract|https://bitbucket.org/mnacamura/pgn-extract>,
a command line tool to manipulate PGN files. So, please put the C<pgn-extract>
in your C<PATH> for using this module.

If you want to deal with a huge PGN file with which slurping is expensive,
consider to use L<Chess::PGN::Extract::Stream>, which provides a file stream
class to read games iteratively.

=head1 FUNCTIONS

=over

=item B<read_games ($pgn_file)>

Read all games contained in the C<$pgn_file> at once and return an C<ARRAY> of
them.

Perl expression of one game will be something like this:

  { Event     => "LAPUTA: Castle in the Sky",
    Site      => "Tiger Moth",
    Date      => "1986.08.02",
    Round     => 1,
    White     => "Captain Dola",
    Black     => "Jicchan",
    Result    => "1-0",
    Moves     => ["e2-e4", "g7-g6"],
  }

B<NOTE>

In a typical PGN file, moves are recorded in standard algebraic notation
(SAN):

   1. e4 g6
   ...

C<pgn-extract> converts it to long algebraic notation (LAN), and so does this
module:

   my ($game) = read_games ($pgn_file);
   $game->{Moves} #=> ["e2-e4", "g7-g6", ...]

For details about PGN, SAN, and LAN, see, I<e.g.>,
L<http://en.wikipedia.org/wiki/Portable_Game_Notation> and
L<http://en.wikipedia.org/wiki/Chess_notation>.

=back

=head1 SEE ALSO

L<Chess::PGN::Extract::Stream>, L<Chess::PGN::Parse>

=head1 BUGS

Please report any bugs to
L<https://bitbucket.org/mnacamura/chess-pgn-extract/issues>.

=head1 AUTHOR

Mitsuhiro Nakamura <m.nacamura@gmail.com>

Many thanks to David J. Barnes for his original development of
L<pgn-extract|http://www.cs.kent.ac.uk/people/staff/djb/pgn-extract/> and
basicer at Bitbucket for
L<his work on JSON enhancement|https://bitbucket.org/basicer/pgn-extract/>.

=head1 LICENSE

Copyright (C) 2014 Mitsuhiro Nakamura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
