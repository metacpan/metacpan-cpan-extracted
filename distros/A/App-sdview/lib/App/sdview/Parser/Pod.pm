#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.807;

package App::sdview::Parser::Pod 0.17;
class App::sdview::Parser::Pod :strict(params);

inherit Pod::Simple;

apply App::sdview::Parser;

use List::Keywords qw( any );
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

By default, verbatim blocks are presumed to contain Perl code, and emitted
with the C<language>> field set to C<perl>. This can be altered by embedded
C<=code> or C<=for highlighter> directives; see below.

=head2 Extensions

Partly as an experiment into how to handle possible future features of the Pod
spec, the following extensions are recognised:

=over 4

=item *

Inline formatting code C<UE<lt>...E<gt>> to request underline formatting.

=item *

C<=code> directive to set the highlighter language name of any following
verbatim paragraphs.

=item *

Also follows the C<=for highlighter ...> spec used by
L<https://metacpan.org/pod/Pod::Simple::XHTML::WithHighlightConfig> for
setting the language name

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
   $self->nix_X_codes( 1 );

   $self->accept_codes(qw( U ));

   $self->accept_target( 'highlighter' );
   $self->accept_directive_as_data( 'code' );
}

field @_indentstack;
field @_parastack;

field %_curtags;
field $_curpara;

field %_verbatim_options = ( language => "perl" );

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
my %FORMAT_TYPES = (
   B => "bold",
   I => "italic",
   U => "underline",
   C => "monospace",

   F => "file",
   L => "link",
);

field $_redirect_text;

method _handle_element_start ( $type, $attrs )
{
   if( $type eq "Document" ) {
      %_curtags = ();
   }
   elsif( $type =~ m/^head(\d+)$/ ) {
      push $_parastack[-1]->@*, $_curpara = App::sdview::Para::Heading->new(
         level => $1,
         text  => String::Tagged->new,
      );
      %_curtags = ();
   }
   elsif( $type eq "code" or
         ( $type eq "for" and $attrs->{target} eq "highlighter" ) ) {
      $_redirect_text = method ( $text ) {
         my @args = split m/\s+/, $text;
         $args[0] = "language=$args[0]" if @args and $args[0] !~ m/=/;

         %_verbatim_options = ();

         foreach ( @args ) {
            my ( $key, $val ) = m/^(.*?)=(.*)$/ or next;
            $_verbatim_options{$key} = $val;
         }
      };
   }
   elsif( $type eq "Data" ) {
      # ignore?
   }
   elsif( $type eq "Para" and $_curpara and 
      $_curpara->type eq "item" and $_curpara->listtype eq "text" and !length $_curpara->text ) {
      %_curtags = ();
   }
   elsif( my $class = $PARA_TYPES{$type} ) {
      push $_parastack[-1]->@*, $_curpara = $class->new(
         text   => String::Tagged->new,
         indent => $_indentstack[-1],
         ( $type eq "Verbatim" ) ? ( %_verbatim_options ) : (),
      );
      %_curtags = ();
   }
   elsif( $type eq "L" ) {
      my $uri = $attrs->{to};
      # TODO: more customizable
      if( defined $uri and $uri !~ m(^\w+://) ) {
         $uri = "https://metacpan.org/pod/$uri";
      }
      $_curtags{link} = { uri => $uri };
   }
   elsif( my $tag = $FORMAT_TYPES{$type} ) {
      ++$_curtags{$tag};
   }
   elsif( $type eq "S" ) {
      $_conv_nbsp = 1;
   }
   elsif( $type eq "over-block" ) {
      push @_indentstack, $_indentstack[-1] + $attrs->{indent};
   }
   elsif( $type =~ m/^over-(.*)/ ) {
      push $_parastack[-1]->@*, App::sdview::Para::List->new(
         listtype => $1,
         indent   => $_indentstack[-1] + $attrs->{indent},
      );
      push @_parastack, [];
      undef $_curpara;
   }
   elsif( $type eq "item-text" ) {
      push $_parastack[-1]->@*, $_curpara = App::sdview::Para::ListItem->new(
         listtype => "text",
         term => String::Tagged->new,
         text => String::Tagged->new,
      );
   }
   elsif( $type =~ m/^item-(.*)/ ) {
      push $_parastack[-1]->@*, $_curpara = App::sdview::Para::ListItem->new(
         listtype => "$1",
         text => String::Tagged->new,
      );
   }
   else {
      print STDERR "START $type\n";
   }
}

method _handle_element_end ( $type, @ )
{
   if( $type eq "Document" ) {
      # nothing
   }
   elsif( $type =~ m/^head\d+$/ ) {
      # nothing
   }
   elsif( $type eq "code" ) {
      undef $_redirect_text;
   }
   elsif( $type eq "for" ) {
      undef $_redirect_text;
   }
   elsif( $type eq "Data" ) {
      # ignore?
   }
   elsif( $PARA_TYPES{$type} ) {
      $type eq "Verbatim" and
         $_parastack[-1][-1] = $self->trim_leading_whitespace( $_parastack[-1][-1] );
   }
   elsif( my $tag = $FORMAT_TYPES{$type} ) {
      delete $_curtags{$tag};
   }
   elsif( $type eq "S" ) {
      undef $_conv_nbsp;
   }
   elsif( $type eq "over-block" ) {
      pop @_indentstack;
   }
   elsif( $type =~ m/^over-(.*)/ ) {
      my @items = ( pop @_parastack )->@*;
      $_parastack[-1][-1]->push_item( $_ ) for @items;
   }
   elsif( $type eq "item-text" ) {
      $_parastack[-1][-1]->term_done;
   }
   elsif( $type =~ m/^item-.*/ ) {
      # nothing
   }
   else {
      print STDERR "END $type\n";
   }
}

method _handle_text ( $text )
{
   if( $_redirect_text ) {
      return $self->$_redirect_text( $text );
   }

   $text =~ s/ /\xA0/g if $_conv_nbsp;

   $_curpara->append_text( $text, %_curtags );
}

method trim_leading_whitespace ( $para )
{
   my @lines = $para->text->split( qr/\n/ );

   my $trimlen = min map { m/^(\s*)/; $+[1] } grep { length } @lines;

   length and $_ = $_->substr( $trimlen, length $_ ) for @lines;

   my $text = shift @lines;
   $text .= "\n" . $_ for @lines;

   return (ref $para)->new(
      text     => $text,
      language => $para->language,
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
