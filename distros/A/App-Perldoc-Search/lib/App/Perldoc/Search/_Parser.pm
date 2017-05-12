package App::Perldoc::Search::_Parser;
BEGIN {
  $App::Perldoc::Search::_Parser::VERSION = '0.11';
}

=head1 NAME

App::Perldoc::Search::_Parser - Pod parser for extracting NAME and searching for matchs

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  my $parser = App::Perldoc::Search::_Parser->new;
  $parser->{pattern} = qr/thing_to_search_for/;
  $parser->parse_from_filehandle( $fh );

  if ( $parser->{matched} ) {
      print "$parser->{name}\n";
  }

=head1 DESCRIPTION

Parses pod to extract the NAME and also search for a pattern match.

=head1 ATTRIBUTES

=over

=item pattern

Set this to a regular expression prior to parsing. This is the pattern being searched for.

=item matched

A boolean returned which tells whether the pattern matched.

=item name

The extracted name and description

=back

=cut



use 5.006;
use strict;
use warnings;
no warnings 'uninitialized';
use Pod::Parser ();
our @ISA = 'Pod::Parser';


=head1 METHODS

=head2 command

Checks for =head NAME commands and searches for the pattern.

=cut

sub command {
    my ( $self, $cmd, $text, $line_num, $pod_para ) = @_;

    # Check for "=head1 NAME"
    $self->{expect_name} =
        $cmd =~ /^head\d+$/
        && $text =~ /^\s*NAME\b/;

    # Check our pattern.
    if ( length $self->{pattern} ) {
        ++$self->{matched} while $text =~ /$self->{pattern}/g;
    }

    return;
}



=head2 verbatim

Searches for the pattern.

=cut

sub verbatim  {
    my ( $self, $text ) = @_;

    # Check our pattern.
    if ( length $self->{pattern} ) {
       ++  $self->{matched} while $text =~ /$self->{pattern}/g;
    }

    return;
}




=head2 textblock

Searches for the pattern. Extracts the name if a =head command was just encountered

=cut

sub textblock {
    my ( $self, $text, $line_num ) = @_;

    # Check our pattern.
    if ( length $self->{pattern} ) {
        ++$self->{matched} while $text =~ /$self->{pattern}/g;
    }

    # If we recently found "=head1 NAME" then look for a name.
    if ( $self->{expect_name} ) {
        $self->{expect_name} = 0;

        $text =~ s/^\s+//;
        $text =~ s/\s+$//;
        $self->{name} ||= $text;
    }

    return;
}



q(Soviet Jesus's gift at Christmas of a blow-up doll to Debbie would always turn to be the most enigmatic);