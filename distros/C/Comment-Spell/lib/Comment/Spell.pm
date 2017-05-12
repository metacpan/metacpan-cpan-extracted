use 5.006;
use strict;
use warnings;

package Comment::Spell;

our $VERSION = '0.001002';

# ABSTRACT: Spell Checking for your comments

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Moo qw( has );
use Pod::Wordlist 1.07;
use PPI;
use Path::Tiny qw( path );
use IO::Handle;
use IO::Scalar;
use Text::Wrap qw( wrap );

# this comment is for self testing
## this comment is hidden for self testing

has stopwords => (
  is      => 'rw',
  lazy    => 1,
  builder => '_build_stopwords',
  handles => {
    '_learn_stopwords' => 'learn_stopwords',
  },
);

has output_filehandle => (
  is      => 'ro' =>,
  writer  => 'set_output_filehandle',
  builder => '_build_output_filehandle',
  handles => {
    '_print_output'  => 'print',
    '_printf_output' => 'printf',
    '_flush_output'  => 'flush',
  },
);

no Moo;

# Default loader for the stopword list
sub _build_stopwords {
  return Pod::Wordlist->new();
}

# Default output is STDOUT
sub _build_output_filehandle {
  return \*STDOUT;
}

# ->set_output_file( "path/to/file" )
sub set_output_file {
  my ( $self, $filename ) = @_;
  $self->set_output_filehandle( path($filename)->openw_raw );
  return;
}

# ->set_output_string( my $str );
sub set_output_string {    ## no critic (Subroutines::RequireArgUnpacking)
  my $fh = IO::Scalar->new( \$_[1] );
  $_[0]->set_output_filehandle($fh);
  return;
}

# Returns a PPI Document for a filehandle
# ->_ppi_fh( $filehandle )
sub _ppi_fh {
  my ( undef, $fh ) = @_;
  my $content = do {
    local $/ = undef;
    scalar <$fh>;
  };
  return PPI::Document->new( \$content, readonly => 1 );
}

# Returns a PPI Document for a file name
# ->_ppi_file( $filename )
sub _ppi_file {
  my ( undef, $file ) = @_;
  return PPI::Document->new( $file, readonly => 1 );
}

# Returns a PPI Document for a scalar
# ->_ppi_string( $source_code )
sub _ppi_string {    ## no critic (Subroutines::RequireArgUnpacking)
  return PPI::Document->new( \$_[1], readonly => 1 );
}

# Determines if a PPI::Token::Comment should be skipped.
# Presently this skips directive comments, which by default have two # marks leading them
# if ( ->_skip_comment( PPI::Token::Comment ) )
sub _skip_comment {
  my ( undef, $comment ) = @_;
  return scalar $comment->content =~ /\A[#]{2}/msx;
}

# Extract comment text from a PPI::Token::Comment
# Returns comments with leading # removed and trailing \n  or \r\n removed.
# my $txt = ->_comment_text( PPI::Token::Comment )
sub _comment_text {
  my ( undef, $comment ) = @_;
  my $content = $comment->content;
  $content =~ s/\A[#]//msx;
  $content =~ s/\r?\n\z//msx;
  return $content;
}

# Primary target for "this is the text of a comment we want"
# strips stopwords from the comments, and then prints them to the output target
# ->_handle_comment_text( $text_string );
sub _handle_comment_text {
  my ( $self, $comment_text ) = @_;
  return $self->_print_words( $self->stopwords->strip_stopwords($comment_text) );
}

# Primary target for "This is a PPI::Token::Comment we want"
# Extracts the content and ferrys it to the output target via _handle_comment_text
# ->_handle_comment( PPI::Token::Comment )
sub _handle_comment {
  my ( $self, $comment ) = @_;
  return $self->_handle_comment_text( $self->_comment_text($comment) );
}

# Print a text to the output target wrapped
# Overflows instead of snapping words.
# ->_print_words( $text )
sub _print_words {
  my ( $self, $text ) = @_;
  return unless length $text;

  local $Text::Wrap::huge = 'overflow';    ## no critic (Variables::ProhibitPackageVars)
  return $self->_print_output( wrap( q[], q[], $text ) . "\n\n" );
}

# Scan a PPI::Document for Comments, feeding
# only the comments to the output target.
# ->parse_from_document( PPI::Document )
sub parse_from_document {
  my ( $self, $document ) = @_;
  my (@comments) = @{ $document->find('PPI::Token::Comment') || [] };
  for my $comment (@comments) {
    next if $self->_skip_comment($comment);
    $self->_handle_comment($comment);
  }
  $self->_flush_output;
  return;
}

# Load a PPI::Document from a filehandle and process it for comments
# ->parse_from_filehandle( $fh );
sub parse_from_filehandle {
  my ( $self, $infh ) = @_;
  return $self->parse_from_document( $self->_ppi_fh($infh) );
}

# Load a PPI::Document from a file and process it for comments
# ->parse_from_file( $filename )
sub parse_from_file {
  my ( $self, $infile ) = @_;
  return $self->parse_from_document( $self->_ppi_file($infile) );
}

# Load a PPI::Document from a string, and process it for comments
# ->parse_from_string( "A String" )
sub parse_from_string {    ## no critic (Subroutines::RequireArgUnpacking)
  return $_[0]->parse_from_document( $_[0]->_ppi_string( $_[1] ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Comment::Spell - Spell Checking for your comments

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

C<Comment::Spell> is a work-a-like for Perl Comments similar to C<Pod::Spell>.

It offers no I<in-built> spell checking services, merely streamlines extracting tokens
to pass to a spell checker of your choice, while removing some basic useful items (stop-words).

It also, by default, ignores comments with two or more leading hashes so to avoid directive comments
like those found in C<Perl::Critic>

  # Shorthand for CLI
  perl -MComment::Spell -e 'Comment::Spell->new->parse_from_file(q[Foo.pm])' | spell -a

  # Advanced Usage:

  my $speller = Comment::Spell->new();

  $speller->parse_from_file(q[Foo.pm]); # streams words to spell to STDOUT by default

  $speller->parse_from_filehandle( $myfh ); # again to STDOUT

  $speller->set_output_file('out.txt');

  $speller->parse_from_file(q[Foo.pm]); # Now writes to out.txt

  my $str;

  $speller->set_output_string($str);

  $speller->parse_from_file(q[Foo.pm]); # Now writes to $str

=head1 METHODS

=head2 C<new>

  ->new(
    stopwords         => A Pod::Wordlist instance
    output_filehandle => A IO Handle ( default is STDOUT )
  )

=head2 C<output_filehandle>

The file handle to write to.

See L</set_output_filehandle>, L</set_output_string> and L</set_output_file>

=head2 C<set_output_filehandle>

  ->set_output_filehandle( $fh );
  ->set_output_filehandle( \*STDOUT );

=head2 C<set_output_string>

  my $str;
  ->set_output_string( $str ); # will write to $str

=head2 C<set_output_file>

  ->set_output_file('./out.txt');

=head2 C<parse_from_file>

  ->parse_from_file('./in.pm'); # Read in.pm and stream tokens to current FH

=head2 C<parse_from_filehandle>

  ->parse_from_filehandle( $fh ); # Slurps FH and streams its tokens to current FH

=head2 C<parse_from_string>

  ->parse_from_string( $string ); # decode $string as a PPI document and stream its comments tokens to FH

=head2 C<parse_from_document>

Lower level interface if you want to make C<PPI> Objects yourself.

  ->parse_from_document( $ppi_document );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
