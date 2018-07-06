#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::Devel::MAT::Explorer::GTK::Resources;

use strict;
use warnings;

our $VERSION = '0.06';

use File::ShareDir qw( module_file );
use Gtk2;

use Exporter 'import';

our @EXPORT_OK = qw(
   get_icon
);
our %EXPORT_TAGS = (
   all => [ @EXPORT_OK ],
);

my %ICON_PATHS;   # {$name} = $path

BEGIN {
   use List::Util qw( any );

   unless( any { $_->{name} eq "svg" } Gtk2::Gdk::Pixbuf->get_formats ) {
      die <<'EOF';
This installation of gdk-pixbuf is unable to load SVG files, which
App::Devel::MAT::Explorer::GTK requires. This is most likely fixed by
installing librsvg2.

EOF
   }
}

## Tool plugin hooks

sub Devel::MAT::UI::register_icon
{
   shift;
   my %args = @_;
   my $name = delete $args{name};

   my $path = delete $args{svg} or die "Cannot register an icon - need an SVG path";

   -f $path or $path = module_file( "Devel::MAT::UI", $path );

   $ICON_PATHS{$name} = $path;
}

my %ICONS;  # {$name}{"$w*$h"} = $pixbuf

sub get_icon
{
   my ( $name, %opts ) = @_;

   my $path = $ICON_PATHS{$name} or do {
      warn "Unregistered icon name $name";
      undef;
   };

   if( defined $opts{w} and defined $opts{h} ) {
      my $w = $opts{w};
      my $h = $opts{h};
      return $ICONS{$name}{"$w*$h"} ||= Gtk2::Gdk::Pixbuf->new_from_file_at_size(
         $path, $w, $h
      );
   }
   else {
      return $ICONS{$name}{default} ||= Gtk2::Gdk::Pixbuf->new_from_file(
         $path
      );
   }
}

foreach (qw( UNDEF SCALAR REF ARRAY HASH CODE GLOB STASH LVALUE REGEXP IO FORMAT PADLIST PADNAMES PAD INVLIST )) {
   Devel::MAT::UI->register_icon( name => "type-$_", svg => "icons/type-$_.svg" );
}
foreach (qw( strong weak indirect inferred )) {
   Devel::MAT::UI->register_icon( name => "strength-$_", svg => "icons/strength-$_.svg" );
}

0x55AA;
