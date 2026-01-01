# -*- cperl -*-
# ABSTRACT: BeamerReveal


package BeamerReveal;
our $VERSION = '20251231.1441'; # VERSION

use strict;
use warnings;

use Carp;

use BeamerReveal::Object::Presentation;
use BeamerReveal::Object::BeamerFrame;

use BeamerReveal::Log;


sub new {
  my $class = shift;

  my $self = {};
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;

  return $self;
}


sub createFromChunk {
  my $self = shift;
  my ( $chunk, $chunkStartLine ) = @_;
  
  my ( $chunkLine, @lines ) = split( "\n", $chunk );
  my ( $chunkType, $chunkData ) = split( ':', $chunkLine );
  
  if( $chunkType eq 'Presentation' ) {
    return BeamerReveal::Object::Presentation->new( $chunkData, \@lines, $chunkStartLine );
  }
  if( $chunkType eq 'BeamerFrame' ) {
    return BeamerReveal::Object::BeamerFrame->new( $chunkData, \@lines, $chunkStartLine );
  }
  else {
    $BeamerReveal::Log::logger->fatal( 0, "Error: unknown chunk type $chunkType on line $chunkStartLine\n" );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal - BeamerReveal

=head1 VERSION

version 20251231.1441

=head1 SYNOPSIS

Factory object to make objects that correspond to the basic chunks in the C<.rvl> file.
These objects correspond to the actual beamer to reveal conversion.

=head1 METHODS

=head2 new()

  $f = BeamerReveal->new()

Constructor

=head2 createFromChunk

  $f->createFromChunk( $chunk, $chunkStartLine )

factory method: creates a basic object.

=over 4

=item . C<$chunk>

string that contains the data to create the basic object from (i.e. to parse).

=item . C<$chunkStartLine>

The starting line of the chunk (used for error reporting).

=back

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
