#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.800;

package App::sdview::Output::Pod 0.11;
class App::sdview::Output::Pod
   :does(App::sdview::Output)
   :strict(params);

use constant format => "POD";

=head1 NAME

C<App::sdview::Output::Pod> - generate POD output from L<App::sdview>

=head1 SYNOPSIS

   $ sdview README.md -o POD > README.pod

=head1 DESCRIPTION

This output module adds to L<App::sdview> the ability to output text in POD
formatting. Given a POD file as input, the output should be relatively
similar, up to minor details like whitespacing. Given input in some other
format, it will do a reasonable job attempting to represent most of the
structure and formatting.

=cut

field $_printed_pod;

method output_head1 ( $para ) { $self->_output_head( "=head1", $para ); }
method output_head2 ( $para ) { $self->_output_head( "=head2", $para ); }
method output_head3 ( $para ) { $self->_output_head( "=head3", $para ); }
method output_head4 ( $para ) { $self->_output_head( "=head4", $para ); }

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

=head1 TODO

=over 4

=item *

Some handling of tables. POD does not (currently?) support tables, but at
least we could emit some kind of plain-text rendering of the contents.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
