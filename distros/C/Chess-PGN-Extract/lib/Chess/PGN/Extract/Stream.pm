package Chess::PGN::Extract::Stream;
use 5.008001;
use strict;
use warnings;

use base 'Exporter::Tiny';
our @EXPORT = qw| pgn_file read_game read_games |;

use Carp       qw| croak |;
use File::Temp qw| tempdir tempfile |;
use Chess::PGN::Extract 'read_games' => { -prefix => '_' };
use IO::Handle;

sub new {
  my ( $class, $pgn_file ) = @_;

  croak ("'new' requires a PGN file name")
    unless defined $pgn_file;

  my $self = {};
  $self->{pgn_file} = $pgn_file;
  open my $pgn_handle, '<', $pgn_file
    or croak ("Cannot open PGN file: \"$pgn_file\"");
  $self->{pgn_handle} = $pgn_handle;

  bless $self => $class;
}

sub pgn_file { $_[0]->{pgn_file} }

sub read_game {
  ( $_[0]->read_games (1) )[0];
}

sub read_games {
  my $self = shift;
  my ($limit) = @_;

  my $handle = $self->{pgn_handle};
  return if $handle->eof;

  unless ( defined $limit ) {
    return _read_all ($handle);
  }

  # Force integer
  $limit = int $limit;

  if    ( $limit  < 0 ) { _read_all ($handle) }
  elsif ( $limit == 0 ) { return }
  else {
    my ( $game, @games );
    while ( $limit-- and $game = _get_one_game_string ($handle) ) {
      push @games, $game;
    }
    return _read_pgn_string ( join '', @games );
  }
}

{
  # Parser contexts:
  #   $start        - Before parsing tag sections
  #   $expect_tag   - Parsing tag sections has started
  #   $expect_moves - Parsing moves section has started
  my ( $start, $expect_tag, $expect_moves ) = 0 .. 2;

  # Regular expressions to identify which section the given $line is
  my $blank     = qr/^[\s\t]*\n$/;
  my $tag       = qr/^[\s\t]*\[[\s\t]*\w+[\s\t]+\".+\"[\s\t]*\][\s\t]*\n$/;
  my $tag_begin = qr/^[\s\t]*\[/;
  # my $moves = ...;

  # _get_one_game_string ($handle) => $pgn_string
  sub _get_one_game_string {
    my $context = $start;
    _parse_lines ( $_[0], $context, [] );
  }

  # _parse_lines ($handle, $context, $buffer) => $pgn_string
  sub _parse_lines {
    return join '', @{ $_[2] } if $_[0]->eof;

    my $line = $_[0]->getline;

    # Ignore blank lines
    goto \&_parse_lines if $line =~ $blank;

    if ( $_[1] == $start ) {

      if ( $line =~ $tag_begin ) {
        _complete_tag_line ($_[0], $line);
        push @{ $_[2] }, $line;
        $_[1] = $expect_tag;
        goto \&_parse_lines;
      }
      else {
        croak ("PGN parse error: Move section started without any tags");
      }
    }
    elsif ( $_[1] == $expect_tag ) {

      if ( $line =~ $tag_begin ) {
        _complete_tag_line ($_[0], $line);
        push @{ $_[2] }, $line;
        goto \&_parse_lines;
      }
      else {
        push @{ $_[2] }, $line;
        $_[1] = $expect_moves;
        goto \&_parse_lines;
      }
    }
    elsif ( $_[1] == $expect_moves ) {

      if ( $line =~ $tag_begin ) {
        seek $_[0], -length $line, 1;    # go back to the head of $line
        return join '', @{ $_[2] };
      }
      else {
        push @{ $_[2] }, $line;
        goto \&_parse_lines;
      }
    }
    else {
      croak ("PGN parse error: Unknown context");
    }
    croak ("PGN parse error: Unknown parse error");
  }

  # _complete_tag_line ($handle, $partial_tag_line)
  sub _complete_tag_line {
    return if $_[1] =~ $tag;
    if ( $_[0]->eof ) {
      croak ("PGN parse error: Parse finished inside a tag section");
    }
    chomp $_[1];
    $_[1] .= $_[0]->getline;
    goto \&_complete_tag_line;
  }
}

# _read_all ($handle) => @games
sub _read_all {
  my $handle = shift;
  my $all = do { local $/; $handle->getline };
  _read_pgn_string ($all);
}

# _read_pgn_string ($pgn_string) => @games
sub _read_pgn_string {
  my ($pgn_string) = @_;

  my $tmp_dir = tempdir ( $ENV{TMPDIR} . "/chess_pgn_extract_stream_XXXXXXXX",
    CLEANUP => 1 );
  my ( $tmp_handle, $tmp_file ) = tempfile ( DIR => $tmp_dir );
  $tmp_handle->print ($pgn_string);
  $tmp_handle->close;

  return _read_games ($tmp_file);
}

1;
__END__

=encoding utf-8

=head1 NAME

Chess::PGN::Extract::Stream - File stream for reading PGN files

=head1 SYNOPSIS

    my $stream = Chess::PGN::Extract->new ("filename.pgn");
    while ( my $game = $stream->read_game ) {
      # You can read games one by one
    }

    # ... or a chunk of games you want
    my @game = $stream->read_games (10);

=head1 DESCRIPTION

B<Chess::PGN::Extract::Stream> provides a simple class of file stream by which
you can extract chess records one by one or chunk by chunk from Portable Game
Notation (PGN) files.

=head1 ATTRIBUTES AND METHODS

=over

=item B<$class-E<gt>new ($pgn_file)>

Create a stream instance from the C<$pgn_file>.

=item B<$self-E<gt>pgn_file>

PGN file name from which the stream reads games.

=item B<$self-E<gt>read_game ()>

Read a game from the stream.

=item B<$self-E<gt>read_games ($limit)>

Read a number of games at once and return an C<ARRAY> of them. If C<$limit> is a
positive number, it reads games until the number of them reaches the C<$limit>.
If C<$limit> is C<undef> or negative, it slurps the PGN file and returns all the
games contained.

=back

=head1 SEE ALSO

L<Chess::PGN::Extract>

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
