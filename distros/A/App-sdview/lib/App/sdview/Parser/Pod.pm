#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

use v5.26;

use Object::Pad 0.66;

package App::sdview::Parser::Pod 0.09;
class App::sdview::Parser::Pod
   :isa(Pod::Simple)
   :does(App::sdview::Parser)
   :strict(params);

use List::Keywords qw( any );
use List::Util qw( min );

use String::Tagged;

use constant format => "POD";

sub find_file ( $class, $name )
{
   # We could use `perldoc -l` but it's slow and noisy when it fails

   my $filebase = $name =~ s(::)(/)gr;

   foreach my $dir ( @INC ) {
      # .pod should take precedence over .pm
      foreach my $file ( "$dir/$filebase.pod", "$dir/$filebase.pm" ) {
         -r $file and return $file;
      }
   }

   return undef;
}

sub can_parse_file ( $class, $file )
{
   return $file =~ m/\.pm$|\.pl$|\.pod$/;
}

ADJUST
{
   $self->nix_X_codes( 1 );
}

field @_indentstack;
field @_parastack;

field %_curtags;
field $_curpara;

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
my @FORMAT_TYPES = qw( B I F C L );

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
   elsif( $type eq "Para" and $_curpara and 
      $_curpara->type eq "item" and $_curpara->listtype eq "text" and !length $_curpara->text ) {
      %_curtags = ();
   }
   elsif( my $class = $PARA_TYPES{$type} ) {
      push $_parastack[-1]->@*, $_curpara = $class->new(
         text   => String::Tagged->new,
         indent => $_indentstack[-1],
      );
      %_curtags = ();
   }
   elsif( $type eq "L" ) {
      my $target = $attrs->{to};
      # TODO: more customizable
      if( defined $target and $target !~ m(^\w+://) ) {
         $target = "https://metacpan.org/pod/$target";
      }
      $_curtags{L} = { target => $target };
   }
   elsif( any { $type eq $_ } @FORMAT_TYPES ) {
      ++$_curtags{$type};
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
   elsif( $PARA_TYPES{$type} ) {
      $type eq "Verbatim" and
         $_parastack[-1][-1] = $self->trim_leading_whitespace( $_parastack[-1][-1] );
   }
   elsif( any { $type eq $_ } @FORMAT_TYPES ) {
      delete $_curtags{$type};
   }
   elsif( $type eq "over-block" ) {
      pop @_indentstack;
   }
   elsif( $type =~ m/^over-(.*)/ ) {
      my @items = ( pop @_parastack )->@*;
      $_parastack[-1][-1]->push_item( $_ ) for @items;
   }
   elsif( $type =~ m/^item-.*/ ) {
      # nothing
   }
   else {
      print STDERR "END $type\n";
   }
}

method _handle_text
{
   if( $_curpara->type eq "item" and
         $_curpara->listtype eq "text" and !length $_curpara->term ) {
      $_curpara->term->append_tagged( $_[0], %_curtags );
   }
   else {
      $_curpara->text->append_tagged( $_[0], %_curtags );
   }
}

method trim_leading_whitespace ( $para )
{
   my @lines = $para->text->split( qr/\n/ );

   my $trimlen = min map { m/^(\s*)/; $+[1] } grep { length } @lines;

   length and $_ = $_->substr( $trimlen, length $_ ) for @lines;

   my $text = shift @lines;
   $text .= "\n" . $_ for @lines;

   return (ref $para)->new(
      text => $text,
   );
}

0x55AA;
