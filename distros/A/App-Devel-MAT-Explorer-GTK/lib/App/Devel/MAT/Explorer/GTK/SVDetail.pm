#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::Devel::MAT::Explorer::GTK::SVDetail;

use strict;
use warnings;
use feature qw( switch );
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our $VERSION = '0.04';

use Devel::MAT 0.23; # ->ifileno, ->ofileno on IO SVs

use App::Devel::MAT::Explorer::GTK::Resources qw( get_icon );
use App::Devel::MAT::Explorer::GTK::Widgets qw( label textarea );
use App::Devel::MAT::Explorer::GTK::Utils qw( bytes2size );

use Struct::Dumb qw( -named_constructors );
use List::UtilsBy qw( nsort_by );

struct SVDetail => [qw( order type title render expand )];

my @MORE_DETAILS;

sub table_add
{
   my ( $table, $label, $widget, $yoptions, $right ) = @_;

   my $xoptions = [ "expand", "fill" ];
   $yoptions  //= [ "fill" ];
   $right     //= 3;

   my ( $next_row ) = $table->get_size;

   $table->attach( label( $label ), 0, 1,      $next_row, $next_row + 1, $xoptions, $yoptions, 0, 3 );
   $table->attach( $widget,         1, $right, $next_row, $next_row + 1, $xoptions, $yoptions, 0, 3 );
}

sub display_sv_in_table
{
   my ( $sv, $table ) = @_;

   # Common things for all widget types;
   my $type = $sv->type;
   table_add( $table, "Type" => textarea( $type ), undef, 2 );

   table_add( $table, "Address" => textarea( sprintf "%#x", $sv->addr ), undef, 2 );

   table_add( $table, "SvREFCNT" => textarea( $sv->refcnt ), undef, 2 );

   my $sizestr = $sv->size;
   if( $sv->size > 1024 ) {
      $sizestr = bytes2size( $sv->size ) . " ($sizestr)";
   }
   table_add( $table, "Size" => textarea( $sizestr ), undef, 2 );

   table_add( $table, "Description" => textarea( $sv->desc ) );

   $table->attach(
      Gtk2::Image->new_from_pixbuf( get_icon( "type-$type", w => 40, h => 40 ) ),
      2, 3, 1, 5, [], [], 5, 5,
   );

   if( my $stash = $sv->blessed ) {
      table_add( $table, "Blessed", textarea( $stash->stashname ) );
   }

   given( $type ) {
      when([ "GLOB", "CODE", "STASH" ]) {
         table_add( $table, "Stashname", textarea( $sv->stashname ) ) if defined $sv->stashname;
      }
   }

   given( $type ) {
      when( "CODE" ) {
         table_add( $table, "Flags", textarea( join( " ",
                  ( $sv->is_clone       ? "CLONE"       : () ),
                  ( $sv->is_cloned      ? "CLONED"      : () ),
                  ( $sv->is_xsub        ? "XSUB"        : () ),
                  ( $sv->is_weakoutside ? "WEAKOUTSIDE" : () ),
                  ( $sv->is_cvgv_rc     ? "CVGV_RC"     : () ),
                  ( $sv->is_lexical     ? "LEXICAL"     : () ) ) ) );
         table_add( $table, "Oproot", textarea( sprintf "%x (%d)", $sv->oproot, $sv->oproot ) ) if $sv->oproot;

         # depth only makes sense of PP subs
         if( $sv->oproot and ( my $depth = $sv->depth ) > -1 ) {
            table_add( $table, "Depth", textarea( $depth ) );
         }
      }
      when( "SCALAR" ) {
         table_add( $table, "UV", textarea( $sv->uv ) ) if defined $sv->uv;
         table_add( $table, "IV", textarea( $sv->iv ) ) if defined $sv->iv;
         table_add( $table, "NV", textarea( $sv->nv ) ) if defined $sv->nv;
         if( defined $sv->pv ) {
            table_add( $table, "PV len", textarea( $sv->pvlen ) );
            table_add( $table, "PV",     my $pvtext = textarea( $sv->qq_pv( 32 ) ) );
            $pvtext->set_tooltip_text( $sv->qq_pv( 1024 ) );
         }
      }
      when( "REF" ) {
         table_add( $table, "RV", textarea( $sv->rv->desc . ( $sv->is_weak ? " weakly" : " strongly" ) ) )
            if defined $sv->rv;
      }
      when( "IO" ) {
         table_add( $table, "Input fileno",  textarea( $sv->ifileno ) ) if $sv->ifileno != -1;
         table_add( $table, "Output fileno", textarea( $sv->ofileno ) ) if $sv->ofileno != -1;
      }
   }

   given( $type ) {
      when([ "SCALAR", "REF", "ARRAY", "HASH", "STASH", "CODE" ]) {
         table_add( $table, "Name", textarea( $sv->name ) ) if defined $sv->name;
      }
   }

   given( $type ) {
      when([ "GLOB", "CODE" ]) {
         table_add( $table, "Location", textarea( $sv->location ) );
      }
      when([ "PAD", "PADNAMES", "PADLIST" ]) {
         table_add( $table, "CV location", textarea( $sv->padcv->location ) );
      }
   }

   foreach my $extra ( nsort_by { $_->order } @MORE_DETAILS ) {
      my $data = $extra->render->( $sv );
      defined $data or next;

      my $widget;
      given( $extra->type ) {
         when( "widget" ) { $widget = $data }
         when( "text" )   { $widget = textarea( $data ) }
         when( "icon" )   { $widget = Gtk2::Image->new_from_pixbuf( get_icon( $data ) ) }
         default          { die "Unable to handle SV detail type " . $extra->type }
      }

      table_add( $table, $extra->title => $widget, $extra->expand ? [ "expand", "fill" ] : undef )
   }
}

my $next_sv_detail_order = 0;
sub Devel::MAT::UI::provides_sv_detail
{
   shift;
   my %args = @_;

   push @MORE_DETAILS, SVDetail(
      order  => $args{order} // $next_sv_detail_order++,
      type   => $args{type},
      title  => $args{title},
      render => $args{render},
      expand => $args{expand},
   );
}

0x55AA;
