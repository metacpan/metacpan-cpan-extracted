#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;

use Object::Pad;

package App::sdview::Output::Pod 0.07;
class App::sdview::Output::Pod
   does App::sdview::Output
   :strict(params);

use constant format => "POD";

has $_printed_pod;

method output_head1 ( $para ) { $self->_output_head( "=head1", $para ); }
method output_head2 ( $para ) { $self->_output_head( "=head2", $para ); }
method output_head3 ( $para ) { $self->_output_head( "=head3", $para ); }

method _output_head ( $leader, $para )
{
   $self->maybe_blank;

   $self->say( $leader, " ", $self->_convert_str( $para->text ) );
   $_printed_pod = 1;
}

method output_plain ( $para )
{
   $self->say( "=pod" ), $_printed_pod = 1 unless $_printed_pod;
   $self->maybe_blank;

   $self->say( $self->_convert_str( $para->text ) );
}

method output_verbatim ( $para )
{
   $self->say( "=pod" ), $_printed_pod = 1 unless $_printed_pod;
   $self->maybe_blank;

   $self->say( "    ", $_ ) for split m/\n/, $para->text;
}

method output_list_bullet ( $para ) { $self->_output_list( $para ); }
method output_list_number ( $para ) { $self->_output_list( $para ); }
method output_list_text   ( $para ) { $self->_output_list( $para ); }

method _output_list ( $para )
{
   $self->maybe_blank;

   $self->say( "=over ", $para->indent );
   $self->say;

   my @items = $para->items;
   foreach my $idx ( 0 .. $#items ) {
      my $item = $items[$idx];

      if( $item->type ne "item" ) {
         # Non-item has no leader
      }
      elsif( $para->listtype eq "bullet" ) {
         $self->say( "=item *" );
         $self->say;
      }
      elsif( $para->listtype eq "number" ) {
         $self->say( sprintf "=item %d.", $idx + 1 );
         $self->say;
      }
      elsif( $para->listtype eq "text" ) {
         $self->say( sprintf "=item %s", $self->_convert_str( $item->term ) );
         $self->say;
      }

      $self->say( $self->_convert_str( $item->text ) );
      $self->say;
   }

   $self->say( "=back" );
}

method _convert_str ( $s )
{
   my $ret = "";

   # TODO: This sucks for nested tags
   $s->iter_substr_nooverlap(
      sub ( $substr, %tags ) {
         # Escape any literal '<'s that would otherwise break
         my $pod = $substr =~ s/[A-Z]\K</E<lt>/gr;

         my $count = 1;
         $count++ while index( $pod, ">"x$count ) > -1;

         my ( $open, $close ) =
            ( $count == 1 ) ? ( "<", ">" ) : ( "<"x$count . " ", " " . ">"x$count );

         if( my $link = $tags{L} ) {
            # TODO: This is even suckier than the bit in the parser
            if( $link->{target} eq "https://metacpan.org/pod/$substr" ) {
               $pod = "L$open$substr$close";
            }
            else {
               $pod = "L$open$pod|$link->{target}$close";
            }
         }

         $pod = "C$open$pod$close" if $tags{C};
         $pod = "B$open$pod$close" if $tags{B};
         $pod = "I$open$pod$close" if $tags{I};
         $pod = "F$open$pod$close" if $tags{F};

         $ret .= $pod;
      }
   );

   return $ret;
}

0x55AA;
