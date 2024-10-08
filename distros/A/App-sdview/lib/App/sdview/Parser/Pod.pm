#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.807;

package App::sdview::Parser::Pod 0.19;
class App::sdview::Parser::Pod :strict(params);

inherit Pod::Simple::Methody;

apply App::sdview::Parser;

use List::Keywords qw( any all );
use List::Util qw( min );

use String::Tagged;

use constant format => "Pod";
use constant sort_order => 10;

=head1 NAME

C<App::sdview::Parser::Pod> - parse Pod files for L<App::sdview>

=head1 SYNOPSIS

   $ sdview README.pod

   $ sdview -f Pod my-document

=head1 DESCRIPTION

This parser module adds to L<App::sdview> the ability to parse input text in
Pod formatting.

It uses L<Pod::Simple> as its driving parser.

The C<SE<lt>...E<gt>> formatting code is handled by converting inner spaces to
non-breaking spaces (U+00A0) characters in the returned string.

By default, verbatim blocks are scanned for likely patterns that indicate perl
code, and emitted with the C<language> field set to C<perl> if it looks
plausible. This can be overridden by embedded C<=code> or C<=for highlighter>
directives; see below.

=head2 Extensions

Partly as an experiment into how to handle possible future features of the Pod
spec, the following extensions are recognised:

=over 4

=item *

Inline formatting code C<UE<lt>...E<gt>> to request underline formatting.

=item *

C<=code> directive to set the highlighter language name for the next verbatim
paragraph.

=item *

Also follows the C<=for highlighter ...> spec used by
L<https://metacpan.org/pod/Pod::Simple::XHTML::WithHighlightConfig> for
setting the language name for following verbatim paragraphs.

=item *

Tables are I<partially> supported according to the suggestion given in
L<https://www.nntp.perl.org/group/perl.perl5.porters/2021/11/msg261904.html>,
within a section marked C<=begin table> or C<=begin table md>.

=item *

Tables are also partially supported by a format similar to mediawiki notation,
within a section marked C<=begin table mediawiki>.

=back

=cut

sub find_file ( $class, $name )
{
   # We could use `perldoc -l` but it's slow and noisy when it fails
   require Pod::Perldoc;
   my ( $found ) = Pod::Perldoc->new->searchfor( 0, $name, @INC );
   return $found;
}

sub can_parse_file ( $class, $file )
{
   return $file =~ m/\.pm$|\.pl$|\.pod$/;
}

ADJUST
{
   $self->accept_target( 'highlighter' );
   $self->accept_directive_as_data( 'code' );

   $self->accept_target( 'table' );
}

field @_indentstack;
field @_parastack;

field $_curpara;

field %_verbatim_options = ( language => "__AUTO__" );
field %_next_verbatim_options;

field $_conv_nbsp;

method parse_file ( $fh )
{
   push @_indentstack, 0;
   push @_parastack, [];
   $self->SUPER::parse_file( $fh );
   return $_parastack[0]->@*;
}

method parse_string ( $str )
{
   push @_indentstack, 0;
   push @_parastack, [];
   $self->SUPER::parse_string_document ( $str );
   return $_parastack[0]->@*;
}

my %PARA_TYPES = (
   Para     => "App::sdview::Para::Plain",
   Verbatim => "App::sdview::Para::Verbatim",
);

field $_redirect_text;

method start_Document { $self->reset_tags; }

method start_head1 { $self->_start_head( 1 ); }
method start_head2 { $self->_start_head( 2 ); }
method start_head3 { $self->_start_head( 3 ); }
method start_head4 { $self->_start_head( 4 ); }
method _start_head ( $level )
{
   push $_parastack[-1]->@*, $_curpara = App::sdview::Para::Heading->new(
      level => $level,
      text  => String::Tagged->new,
   );
   $self->reset_tags;
}

method start_code { $self->_start_highlighter( \%_next_verbatim_options ); }
method end_code { undef $_redirect_text; }

method start_for ( $attrs )
{
   my $target = $attrs->{target};
   my $code = $self->can( "start_for_$target" ) or return;
   return $self->$code( $attrs );
}
method end_for  { undef $_redirect_text; }

method start_for_highlighter { $self->_start_highlighter( \%_verbatim_options ) }

method start_for_table ( $attrs )
{
   my @spec = split m/\s+/, $attrs->{title} // "";
   $spec[0] = "style=$spec[0]" if @spec and $spec[0] !~ m/=/;
   my %spec = map { m/^(.*?)=(.*)$/ ? ( $1, $2 ) : () } @spec;

   my $style = $spec{style} // "md";

   $style eq "md" and
      $_redirect_text = \&_handle_text_table_md, return;
   $style eq "mediawiki" and
      $_redirect_text = \&_handle_text_table_mediawiki, return;

   warn "TODO unrecognised table style $style\n";
}

method _start_highlighter ( $options )
{
   $_redirect_text = method ( $text ) {
      my @args = split m/\s+/, $text;
      $args[0] = "language=$args[0]" if @args and $args[0] !~ m/=/;

      %$options = ();

      foreach ( @args ) {
         my ( $key, $val ) = m/^(.*?)=(.*)$/ or next;
         $options->{$key} = $val;
      }
   };
}

method start_S {       $_conv_nbsp = 1; }
method end_S   { undef $_conv_nbsp; }

role App::sdview::Parser::Pod::_TagHandler {
   ADJUST {
      $self->nix_X_codes( 1 );
      $self->accept_codes(qw( U ));
   }

   field %_curtags :reader;
   method reset_tags { %_curtags = (); }

   method start_B {        $_curtags{bold}++ }
   method end_B   { delete $_curtags{bold}   }
   method start_I {        $_curtags{italic}++ }
   method end_I   { delete $_curtags{italic}   }
   method start_U {        $_curtags{underline}++ }
   method end_U   { delete $_curtags{underline}   }
   method start_C {        $_curtags{monospace}++ }
   method end_C   { delete $_curtags{monospace}   }
   method start_F {        $_curtags{file}++ }
   method end_F   { delete $_curtags{file}   }

   method start_L ( $attrs )
   {
      my $uri = $attrs->{to};
      # TODO: more customizable
      if( defined $uri and $uri !~ m(^\w+://) ) {
         $uri = "https://metacpan.org/pod/$uri";
      }
      $_curtags{link} = { uri => $uri };
   }
   method end_L { delete $_curtags{link} }
}

apply App::sdview::Parser::Pod::_TagHandler;

method start_over_block ( $attrs )
{
   push @_indentstack, $_indentstack[-1] + $attrs->{indent};
}
method end_over_block
{
   pop @_indentstack;
}

method start_over_number ( $attrs ) { $self->_start_over( number => $attrs ); }
method start_over_bullet ( $attrs ) { $self->_start_over( bullet => $attrs ); }
method start_over_text   ( $attrs ) { $self->_start_over( text   => $attrs ); }
method _start_over ( $type, $attrs )
{
   push $_parastack[-1]->@*, App::sdview::Para::List->new(
      listtype => $type,
      indent   => $_indentstack[-1] + $attrs->{indent},
   );
   push @_parastack, [];
   undef $_curpara;
}
method end_over_number { $self->_end_list( number => ); }
method end_over_bullet { $self->_end_list( bullet => ); }
method end_over_text   { $self->_end_list( text   => ); }
method _end_list ( $type )
{
   my @items = ( pop @_parastack )->@*;
   $_parastack[-1][-1]->push_item( $_ ) for @items;
}

method start_item_number { $self->_start_item( number => ); }
method start_item_bullet { $self->_start_item( bullet => ); }
method _start_item ( $type )
{
   push $_parastack[-1]->@*, $_curpara = App::sdview::Para::ListItem->new(
      listtype => $type,
      text => String::Tagged->new,
   );
}
method start_item_text
{
   push $_parastack[-1]->@*, $_curpara = App::sdview::Para::ListItem->new(
      listtype => "text",
      term => String::Tagged->new,
      text => String::Tagged->new,
   );
}
method end_item_text { $_parastack[-1][-1]->term_done; }

method start_Para ( $attrs )
{
   if( $_curpara and $_curpara->type eq "item" and $_curpara->listtype eq "text"
         and !length $_curpara->text ) {
      # just extend the existing para
   }
   else {
      push $_parastack[-1]->@*, $_curpara = App::sdview::Para::Plain->new(
         text   => String::Tagged->new,
         indent => $_indentstack[-1],
      );
   }

   $self->reset_tags;
}

method start_Verbatim
{
   push $_parastack[-1]->@*, $_curpara = App::sdview::Para::Verbatim->new(
      text   => String::Tagged->new,
      indent => $_indentstack[-1],
      ( %_verbatim_options, %_next_verbatim_options ),
   );
   $self->reset_tags;
   %_next_verbatim_options = ();
}
method end_Verbatim
{
   my $para = $_parastack[-1][-1];
   my @lines = $para->text->split( qr/\n/ );

   my $trimlen = min map { m/^(\s*)/; $+[1] } grep { length } @lines;

   length and $_ = $_->substr( $trimlen, length $_ ) for @lines;

   my $text = shift @lines;
   $text .= "\n" . $_ for @lines;

   my $language = $para->language;
   if( ( $language // "" ) eq "__AUTO__" ) {
      # Try to detect the language. It doesn't have to be perfect, just a good
      # guess is enough.
      undef $language;

      if( $text =~ m/^use [A-Za-z_]|^package [A-Za-z_]/ ) {
         $language = "perl";
      }
      elsif( $text =~ m/^(my )?[\$\@%][A-Za-z_]/m ) {
         $language = "perl";
      }
      elsif( $text =~ m/^#!.*\bperl\b/ ) {
         $language = "perl";
      }
   }

   $_parastack[-1][-1] = (ref $para)->new(
      text     => $text,
      language => $language,
   );
}

method handle_text ( $text )
{
   if( $_redirect_text ) {
      return $self->$_redirect_text( $text );
   }

   $text =~ s/ /\xA0/g if $_conv_nbsp;

   $_curpara->append_text( $text, $self->curtags );
}

method _handle_text_table_md ( $text )
{
   my @lines = split m/\n/, $text
      or return;

   my @rows;
   push @rows, _split_table_row( shift @lines );

   my $heading = !!0;
   my @align;
   my $alignspec = _split_table_row( shift @lines );
   if( all { $_ =~ m/^(:?)-{3,}(:?)$/ } @$alignspec ) {
      $heading = !!1;
      @align = map {
         m/^(:?)-{3,}(:?)$/;
         ( $1 and $2 ) ? "centre" :
         ( $2        ) ? "right" :
                         "left";
      } @$alignspec;
   }
   else {
      push @rows, $alignspec;
      @align = ( "left" ) x scalar @$alignspec;
   }

   push @rows, map { _split_table_row( $_ ) } @lines;

   foreach my $row ( @rows ) {
      @$row = map {
         my $colidx = $_;
         App::sdview::Para::TableCell->new(
            align => $align[$colidx],
            heading => $heading,
            text  => $row->[$colidx],
         )
      } keys @$row;
      $heading = !!0;
   }

   push $_parastack[-1]->@*, App::sdview::Para::Table->new(
      rows => \@rows
   );
}

sub _split_table_row ( $str )
{
   # Leading/trailing pipes are optional
   $str =~ s/^\s*\|//;
   $str =~ s/\|\s*$//;

   my @cols = split m/\|/, $str;
   s/^\s+//, s/\s+$// for @cols;

   # TODO: Find out why these parsers aren't reusable
   $_ = App::sdview::Parser::Pod::_TableCellParser->new->parse_string( $_ ) for @cols;

   return \@cols;
}

method _handle_text_table_mediawiki ( $text )
{
   my @lines = split m/\n/, $text
      or return;

   my @rows;
   foreach my $line ( @lines ) {
      $line =~ m/^\|-/ and
         push @rows, [] and next;

      $line =~ s/^([!|])\s*// or
         warn "Unsure what to do with line $line" and next;
      my $chr = $1;
      my $heading = ( $chr eq "!" );

      foreach my $cell ( split m/\s*\Q$chr$chr\E\s*/, $line ) {
         @rows or push @rows, [];
         push $rows[-1]->@*, App::sdview::Para::TableCell->new(
            align => "left", # TODO
            heading => $heading,
            text => App::sdview::Parser::Pod::_TableCellParser->new->parse_string( $cell ),
         );
      }
   }

   push $_parastack[-1]->@*, App::sdview::Para::Table->new(
      rows => \@rows,
   );
}

class App::sdview::Parser::Pod::_TableCellParser
{
   inherit Pod::Simple::Methody;
   apply App::sdview::Parser::Pod::_TagHandler;

   field $body;

   method parse_string ( $str )
   {
      $body = String::Tagged->new;

      # Protect a leading equals sign
      $str =~ s/^=/E<61>/;

      $self->SUPER::parse_string_document( "=pod\n\n$str" );

      return $body;
   }

   method handle_text ( $text )
   {
      $body->append_tagged( $text, $self->curtags );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
