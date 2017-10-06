package App::PLab::ImageApp;
use vars qw($testing $VERSION);

$VERSION = '1.00';

use strict;
use Carp;
use Cwd qw(abs_path);

use Prima qw( StartupWindow StdBitmap Widgets StdDlg ImageViewer MsgBox
              IniFile Sliders Utils Notebooks ComboBox Buttons Label Outlines
              ColorDialog KeySelector ImageDialog);
use App::PLab::ButtonGlyphs;
use App::PLab::ImageAppGlyphs;
no Prima::StartupWindow;

package App::PLab::SerOpenDialog;
use vars qw(@ISA);
@ISA = qw(Prima::ImageOpenDialog);

sub init
{
   my $self = shift;
   my %profile = $self-> SUPER::init(@_);

   my $dl = $self-> Files;

   my %pf = (
      name  => 'Files',
      rect  => [ $dl-> rect],
      items => $dl-> items,
      designScale => undef,
      delegations => [ @{$dl-> delegations}, $self, 'DrawItem', 'MeasureItem'],
   );
   $dl-> destroy;
   $self-> insert( ListViewer => %pf);

   return %profile;
}

sub Dir_Change
{
   my ( $self, $dir) = @_;
   my $w = $self-> owner;
   my $mask = $self-> {mask};
   my @files = grep { /$mask/i; } $dir-> files( 'reg');
   @files = sort {uc($a) cmp uc($b)} @files if $self->{sorted};

   my %vecs = ();
   my $nums = $w-> {cypherMask};
   for (@files)
   {
      next unless /^(.+)(\d{$nums})\.([^\.]*)$/;
      my ($sername, $num, $ext) = ($1, $2, $3);
      $vecs{ $sername} = [ pack( "b1000", "0" x 100), $ext] unless exists $vecs{ $sername};
      vec( $vecs{ $sername}->[0], $num, 1) = 1;
   }
   my @series = ();
   my $max = 10 ** $nums - 1;
   for my $sername (sort keys %vecs)
   {
      my ($j, $k);
      my $s = unpack( b1000 => $vecs{ $sername}->[0]);    # to exploit string functions
      $j = index( $s, '1');
      while ( $j >= 0)
      {
         $k = index( $s, '0', $j);
         if ( $k < 0)
         {
            $s = '';
            push @series, [ $sername , $vecs{ $sername}->[1],
               sprintf("%0${nums}d",$j), sprintf("%0${nums}d",$max)] if $j < $max;
         }
         else
         {
            $s = ('0' x $k) . substr( $s, $k);
            push @series, [ $sername , $vecs{ $sername}->[1],
               sprintf("%0${nums}d",$j), sprintf("%0${nums}d",$k - 1)] if $j < $k - 1;
         }
         $j = index( $s, '1');
      }
   }

   $self-> {series} = [@series];
   $self-> Files-> items([ map { "$$_[0]$$_[2].$$_[1]"} @series]);
   $self-> Directory_FontChanged( $self-> Directory);
}

sub Files_DrawItem
{
   my ( $dlg, $me, $canvas, $index, $left, $bottom, $right, $top, $hilite, $focused) = @_;
   return unless $dlg-> {series};
   my $backColor = $hilite ? $me-> hiliteBackColor : $me-> backColor;
   my $color = $hilite ? $me-> hiliteColor : cl::Fore | wc::ListBox;
   $canvas-> color($backColor);
   $canvas-> bar( $left, $bottom, $right, $top);
   $canvas-> color($color);
   my @ser    = @{$dlg->{series}->[$index]};
   my $text   = "$ser[0]$ser[2].$ser[1]";
   my $series = "$ser[2]-$ser[3]";
   my $font   = $canvas-> font;
   my $h = $canvas-> font-> height;
   my $w = $canvas-> get_text_width( $text);
   $canvas-> text_out( $text, $left + 2, ($top + $bottom + 1 - $h) / 2);
   $canvas-> font( height => $canvas-> font-> height - 2, pitch => fp::Fixed, style => fs::Bold);
   $h = $canvas-> font-> height;
   my $x = $left + $canvas-> get_text_width('  ') + $w;
   $w = $canvas-> get_text_width( "9");
   $canvas-> text_out( $series, $x + 1, ($top + $bottom + 1 - $h) / 2);
   $canvas-> rectangle( $x, ($top + $bottom + 1 - $h) / 2, $x + $w * length( $series) + 2, ($top + $bottom + $h) / 2);
   $canvas-> font( $font);
}

sub Files_MeasureItem
{
   my ( $dlg, $self, $index, $sref) = @_;
   $$sref = $self->get_text_width( $self-> get_item_text( $index)) + $self->get_text_width('m') * 8;
   $self-> clear_event;
}

package  App::PLab::TrDeviceBitmap;
use vars qw(@ISA);
@ISA = qw(Prima::DeviceBitmap);

sub translate
{
   unless ( $#_) {
      my @a = $_[0]-> SUPER::translate;
      if ( $_[0]-> {override}) {
         $a[$_] -= $_[0]-> {override}->[$_] for 0,1;
      }
      return @a;
   }
   my ( $self, $trx, $try) = @_;
   if ( $self-> {override}) {
      $trx += $self-> {override}-> [0];
      $try += $self-> {override}-> [1];
   }
   $self-> SUPER::translate( $trx, $try);
}

sub clipRect
{
   unless ( $#_) {
      my @a = $_[0]-> SUPER::clipRect;
      if ( $_[0]-> {override}) {
         $a[$_]   -= $_[0]-> {override}->[$_] for 0,1;
         $a[$_+2] -= $_[0]-> {override}->[$_] for 0,1;
      }
      return @a;
   }
   my ( $self, $trx, $try, $tax, $tay) = @_;
   if ( $self-> {override}) {
      $trx += $self-> {override}-> [0];
      $try += $self-> {override}-> [1];
      $tax += $self-> {override}-> [0];
      $tay += $self-> {override}-> [1];
   }
   $self-> SUPER::clipRect( $trx, $try, $tax, $tay);
}

package App::PLab::MagnifyingGlassWidget;
use vars qw(@ISA);
@ISA = qw(Prima::Widget);

sub profile_default
{
   my $def = $_[ 0]-> SUPER::profile_default;
   my %prf = (
      width     => 154,
      height    => 102,
      syncPaint => 0,
   );
   @$def{keys %prf} = values %prf;
   return $def;
}

sub on_create
{
   $_[0]-> {canvas} = App::PLab::TrDeviceBitmap-> create(
      width  => 76,
      height => 50,
      backColor => $_[0]-> owner-> backColor,
   );
}

sub on_paint
{
   $_[1]-> rectangle( 0, 0, 153, 101);
   $_[1]-> stretch_image( 1, 1, 152, 100, $_[0]-> {canvas});
}


package App::PLab::TrImageViewer;
use vars qw(@ISA);
@ISA = qw(Prima::ImageViewer);

sub invalidate_rect
{
   my ( $self, @r) = @_;
   my $w = $self-> owner;
   $w-> ivm_repaint( $self) if $w-> {magnify};
   $self-> SUPER::invalidate_rect( @r);
}

sub end_paint
{
   my $self = $_[0];
   $self-> SUPER::end_paint;
   my $w = $self-> owner;
   $w-> ivm_repaint( $self) if $w-> {magnify};
}

sub capture
{
   return $_[0]-> SUPER::capture unless $#_;
   my ( $self, $capFlag, @rest) = @_;
   $self-> owner-> iv_cancelmagnify( $self)
      if !$capFlag && $self-> owner-> {magnify};
   $self-> SUPER::capture( $capFlag, @rest);
}

sub screen2point
{
   return map { int } shift-> SUPER::screen2point( @_);
}

sub point2screen
{
   return map { int } shift-> SUPER::point2screen( @_);
}

package App::PLab::ImageAppWindow;
use vars qw(@ISA %dlgProfile $ico $pointClickTolerance);
@ISA = qw(Prima::Window);
$pointClickTolerance = 8;

%dlgProfile = (
   centered    => 1,
   visible     => 0,
   designScale => [7, 16],
);
$ico = Prima::Icon-> create;
$ico-> combine(
   Prima::Image-> create(
      width   => 32,
      height  => 32,
      type    => im::Mono,
      palette => [0,0,0,255,255,255],
      data    => pack( 'C*' ,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,15,244,0,0,3,194,0,0,15,250,
0,0,31,253,0,0,63,253,0,0,127,254,128,0,127,254,128,0,231,255,64,0,215,255,64,1,182,219,64,1,
86,219,64,0,142,219,64,0,13,183,0,0,29,182,0,0,59,180,0,0,55,104,0,0,11,96,0,0,0,128,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      ),
   ),
   Prima::Image-> create(
      width   => 32,
      height  => 32,
      type    => im::Mono,
      palette => [0,0,0,255,255,255],
      data    => pack( 'C*',
255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
255,255,255,255,255,240,7,255,255,224,3,255,255,224,1,255,255,224,1,255,255,192,0,255,255,128,0,
255,255,0,0,127,255,0,0,127,254,0,0,63,254,0,0,63,252,0,0,63,252,32,0,63,254,96,0,63,255,224,0,
127,255,192,0,255,255,128,1,255,255,128,3,255,255,192,15,255,255,252,31,255,255,255,255,255,255,
255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,
      ),
   ),
);

sub dlg_okcancel
{
   my ( $w, $self) = @_;
   $self-> insert( Button =>
      origin => [ 10, 20],
      size   => [ 96, 36],
      text   => '~Ok',
      name   => 'OK',
      default => 1,
      modalResult => mb::Ok,
   );
   $self-> insert( Button =>
      origin => [ 116, 20],
      size   => [ 96, 36],
      text   => 'Cancel',
      modalResult => mb::Cancel,
   );
}

sub dlg_file
{
   my ( $w, %profile) = @_;
   my $d = $w-> {fileDlg} ? $w-> {fileDlg} : Prima::OpenDialog-> create(
      owner     => $w,
   );
   if ( $profile{cwd}) {
      my $dir = exists($profile{directory}) ? $profile{directory} : '.';
      $dir = eval { Cwd::abs_path( $dir)};
      $dir = '.' if $@;
      $dir = '' unless -d $dir;
      delete $profile{cwd};
      $profile{directory} = $dir;
   }   
   if ( exists $profile{directory}) {
      my $xd = eval { Cwd::abs_path( $d-> directory)};
      $xd = '.' if $@;
      $d-> directory( $profile{directory}) if $xd ne $profile{directory};
      delete $profile{directory};
   }
   $d-> set( %profile);
   $w-> {fileDlg} = $d;
   return $d;
}  

sub open_help
{       
   my ( $self, $address) = @_;
   $address = 'index' unless defined $address;
   $::application->open_help('App::PLab::' . $address);
}   

# WIN

sub modified
{
   return $_[0]-> {modified} unless $#_;
   $_[0]-> {modified} = $_[1];
}

sub on_keydown
{
   my ( $self, $code, $key, $mod) = @_;
   my $iv = $self->IV;
   if ( $key == kb::Esc) {
      if ( $iv-> {transaction}) {
         $self-> iv_cancelmode( $iv);
         $self-> clear_event;
         return;
      }
   }
   $self-> clear_event if $iv-> {transaction};
}

sub on_deactivate
{
   my ( $self) = @_;
   $self-> iv_cancelmode( $self-> IV);
}


sub on_mousewheel
{
   my ( $self, $mod, $x, $y, $z) = @_;
   $self = $self-> IV;
   return if $self->{transaction};
   $z = int( $z / 120);
   my $xv = ( $mod & km::Shift) ? $self-> VScroll : $self-> HScroll;
   $z *= ( $mod & km::Ctrl) ? $xv-> step : $xv-> pageStep;
   if ( $mod & km::Shift) {
      $self-> deltaX( $self-> deltaX - $z);
   } else {
      $self-> deltaY( $self-> deltaY - $z);
   }
}

sub on_create
{
   my $w = $_[0];
   my $uname = lc(Prima::Utils::username() || '');
   $uname .= '.' if $uname;
   my @iniDefaults = $w-> win_inidefaults();
   my $keys   = $w-> opt_keys;
   my $colors = $w-> opt_colors;
   push ( @iniDefaults, 
      map { 
         ( "Key_$_", "'" . $keys->{$_}->[0] . "'") 
      } keys %$keys);
   push( @iniDefaults, 
      map { 
         ( "Color_$_", $w-> ini_makecolor( $colors->{$_}->[0]))
      } keys %$colors);
   $w->{iniFile} = Prima::IniFile-> create(
      file => Prima::Utils::path('PLabApps'),
      default => [
         $uname.$::application->name => \@iniDefaults,
      ]
   );
   my $i;
   $w-> {uname} = $uname;
   $i = $w-> {ini} = $w-> {iniFile}-> section( $uname.$::application->name);
   $w-> {keyMappings} = { map { $_ => Prima::AbstractMenu-> translate_shortcut( eval($i-> {$_})); } 
       grep { m/^Key_/  } keys %$i };
   $i->{"Color_$_"} = eval( $i->{"Color_$_"}) for keys %$colors;
   my @rc = split ' ', $i->{WindowRect};
   my @ac = $::application-> rect;
   $ac[3] -= $::application-> get_system_value( sv::YMenu) * 3 + $::application-> get_system_value( sv::YTitleBar);
   $rc[0] = 0 if $rc[0] >= $ac[2];
   $rc[1] = 0 if $rc[1] >= $ac[3];
   $rc[3] = $ac[3] if $rc[3] >= $ac[3];
   $w-> rect(@rc);
   $w-> {cypherMask} = ( lc $w->{ini}->{SerType} eq 'long') ? 3 : 2;
   -d $w-> {ini}-> {path} or $w-> {ini}-> {path} = '.';
   $w-> {ini}-> {path} = eval {&Cwd::abs_path($w-> {ini}-> {path})};
   $w-> {ini}-> {path} = '.' if $@;
   $w-> {ini}-> {path} = '' unless -d $w-> {ini}-> {path};

   $w-> maximize if $i->{MaxState};
   $w-> insert( Popup =>
      auto     => 0,
      selected => 0,
      name     => 'LoadSeriesPopup',
      items    => [['' => '']],
   );
   $::application-> showHint( $w-> {ini}-> {showHint});
   $w-> winmenu_updatemappings;
}

sub on_destroy
{
   my ($w,$i) = ($_[0],$_[0]->{ini});
   $i->{MaxState}   = $w-> windowState == ws::Maximized;
   $w-> windowState(ws::Normal) if $i->{MaxState};
   my @rc = $w-> rect;
   $i->{WindowRect} = "@rc";
   $i->{SerType}    = ( $w->{cypherMask} == 2) ? 'Short' : 'Long';
   $i-> {$_} = Prima::KeySelector::shortcut( $w-> {keyMappings}->{$_})
      for keys %{$w->{keyMappings}};
   my $optColors = $w-> opt_colors;   
   $i-> {"Color_$_"} = $w-> ini_makecolor( $i-> {"Color_$_"}) for keys %$optColors;
   $::application-> close;
}

sub on_close
{
   my ($w,$i) = ($_[0],$_[0]->{ini});
   $w-> clear_event unless $w-> win_closefile;
}


sub win_inidefaults
{
   my $w = $_[0];
   my @rc = $w-> rect;
   return (
      path         => '.',
      WindowRect   => "@rc",
      MaxState     => 0,
      SerType      => 'Short',
      extSaveDir   => '',
      silentExtDir => 0,
      dirTimeout   => 120,
      statusDelay  => 5,
      showHint     => 1,
   );
}

sub win_extname
{
   my ($w, $extname) = @_;
   my $ext = $w-> {dataExt};
   $extname =~ /([^\\\/]*)$/;
   $extname = $1;
   if ( $extname =~ /\.[^.]*$/) {
      $extname =~ s/\.[^.]*$/\.$ext/
   } else {
      $extname .= ".$ext";
   }
   my $extsave = length($w-> {ini}-> {extSaveDir}) ? $w-> {ini}-> {extSaveDir} : $w-> {ini}-> {path};
   return "$extsave/$extname";
}

sub win_extwarn
{
   my $w = $_[0];
   return unless length $w->{ini}->{extSaveDir};
   return if $w->{ini}->{silentExtDir};
   my $ret = Prima::MsgBox::message_box( $::application-> name, ".".$w-> {dataExt}." save path is ".
      $w->{ini}->{extSaveDir}.".\nDo you want to set it to the current directory, as default?",
      mb::YesNo | mb::Abort | mb::Warning, {
      buttons => { mb::Abort, { text => 'Ne~ver' }},
    });
   if ( $ret == mb::Yes) {
      $w->{ini}->{extSaveDir} = '';
      $w-> win_extpathchanged;
   } elsif ( $ret == mb::Abort) {
      Prima::MsgBox::message("You will be never asked again, until you manually re-set the save path to the default", mb::Information);
      $w->{ini}->{silentExtDir} = 1;
   }
}


sub win_extpathchanged
{
}

sub win_newframe
{
   $_[0]-> modified( 0);
}


sub win_saveframe
{
   return 1;
}

sub win_closeframe
{
}

sub win_framechanged
{
   my $w = $_[0];
   $w-> menu-> FileCloseImage-> enabled( defined $w-> {file});
}

sub win_newextras
{
   my $w = $_[0];
   my $num = $w-> {cypherMask};
   my $file = $w->{file};
   return unless $file;
   my ($fileNum, $fileBeg, $fileEnd, $ff);
   if ( $file =~ /(.*)(\d{$num})(\.(?:tif|gif|jpg|bmp|pcx|png))$/i) {
      ($fileBeg,$fileNum,$fileEnd) = ($1,$2,$3);
      $w-> {prevFile} = $ff
         if ( $fileNum > 0) && ( -f ($ff = sprintf("%s%0${num}d%s",$fileBeg,$fileNum-1,$fileEnd)));
      $w-> {nextFile} = $ff
         if ( $fileNum < 10 ** $num - 1) && ( -f ($ff = sprintf("%s%0${num}d%s",$fileBeg,$fileNum+1,$fileEnd)));
      $w-> {fileBeg} = $fileBeg;
      $w-> {fileEnd} = $fileEnd;
      $w-> {fileNum} = int($fileNum);
   }
}

sub win_closeextras
{
   my $w = $_[0];
   $w-> {$_} = undef for qw( nextFile prevFile fileNum fileBeg fileEnd);
}

sub win_extraschanged
{
   my $w = $_[0];
   my $tb = $w-> ToolBar;
   $w-> menu-> FileNextImage-> enabled( defined $w-> {nextFile});
   $tb-> NextImage-> enabled( defined $w-> {nextFile});
   $w-> menu-> FilePrevImage-> enabled( defined $w-> {prevFile});
   $tb-> PrevImage-> enabled( defined $w-> {prevFile});
   $w-> menu-> FileNext5Image-> enabled( defined $w-> {nextFile});
   $w-> menu-> FilePrev5Image-> enabled( defined $w-> {prevFile});
   $w-> menu-> FileLastImage -> enabled( defined $w-> {nextFile});
   $w-> menu-> FileFirstImage-> enabled( defined $w-> {prevFile});
}

sub win_openfile
{
   my $w   = $_[0];
   my $d   = $w-> dlg_file(
      cwd         => 1,
      directory   => $w->{ini}->{path},
      filterIndex => 0,
      multiSelect => 0,
      filter      => [
         ['Images' => '*.bmp;*.pcx;*.gif;*.jpg;*.png;*.tif'],
         ['All files' => '*.*'],
      ]
   );
   if ( defined $w->{file} && $w-> {file} =~ /([^\\\/]*)$/) {
      my $fname = $1;
      my $i = 0;
      my @items = @{$d-> Files-> items};
      for ( @items) {
         last if $fname eq $items[ $i];
         $i++;
      }
      if ( $i <= @items) {
         $d-> Files-> focusedItem( $i);
         $d-> fileName( $fname);
      }
   }
   $w-> iv_cancelmagnify( $w-> IV);
   return $w-> win_loadfile( $d->fileName) if $d-> execute;
   return 0;
}

sub win_openserfile
{
   my $w = $_[0];
   my $dir = eval { Cwd::abs_path( $w-> {ini}-> {path})};
   $dir = '.' if $@;
   $dir = '' unless -d $dir;
   my $d = $w->{fileserDlg} ? $w->{fileserDlg} : App::PLab::SerOpenDialog-> create(
      owner     => $w,
      directory => $dir,
      filter    => [
        ['Images' => '*.bmp;*.pcx;*.gif;*.jpg;*.png;*.tif'],
        ['All files' => '*.*'],
      ]
   );
   $w-> iv_cancelmode( $w-> IV);
   if ( $d-> execute) {
        $w-> win_loadfile( $d-> fileName);
   }
   $w->{fileserDlg} = $d;
}


sub win_loadfile
{
   my ($w,$file) = @_;
   return 0 unless defined $file;
   my $path = $file;
   $path =~ s{[/\\][^/\\]*$}{};
   $w-> {preloadfile} = $file;

   if ( defined $w-> {file}) {
      return unless $w-> win_saveframe;
   }

   my $self = $w-> IV;
   $w-> iv_cancelmode( $self);
   $self-> {savePointer} = $self->pointer;
   $self-> pointer(cr::Wait);
   my $i = Prima::Image-> create;
   unless ( $i-> load( $file)) {
      $self->pointer($self-> {savePointer});
      Prima::MsgBox::message_box( $::application-> name, "Error loading file $file", mb::OK|mb::Error);
      return 0;
   }
   $w-> {preloadfile} = undef;

   $w-> win_closeextras;
   $w-> win_closeframe;
   $file =~ m{[/\\]([^/\\]*)$};
   $w-> text( $::application-> name . " - [$1]");
   $w-> {ini}-> {path} = $path;
   $w-> {file} = $file;
   $w-> IV-> image( $i);
   ($w-> {IVx}, $w->{IVy}) = $w-> IV-> image-> size;

   $w-> win_newframe;
   $w-> win_newextras;
   $w-> win_framechanged;
   $w-> win_extraschanged;

   $w-> IV-> repaint;

   $w-> sb_text( "$file loaded OK");
   $self-> pointer($self-> {savePointer});

   return 1;
}

sub win_closefile
{
   my $w = $_[0];
   return 1 unless defined $w->{file};
   return 0 if !$w-> win_saveframe;
   $w-> win_closeframe;
   $w-> win_closeextras;

   $w-> text( $::application-> name);
   $w-> {file} = undef;
   $w-> IV-> image( undef);
   $w-> {IVx} = $w-> {IVy} = 0;
   $w-> IV-> repaint;
   $w-> win_framechanged;
   $w-> win_extraschanged;
   return 1;
}


sub win_nextfile
{
   $_[0]-> win_loadfile( $_[0]-> {nextFile}) if defined $_[0]-> {nextFile};
}

sub win_getseriesrange
{
   my $w = $_[0];

   return (0,0) unless defined $w->{fileNum};
   my $path = $w-> {ini}-> {path};
   my @d;

   if ( exists $w-> {cachedDir} && ( $w-> {cachedDir} eq $path) &&
      (( time - $w-> {cachedDirTime}) < $w-> {ini}-> {dirTimeout})) {
      @d = @{$w-> {cachedDirContent}};
   } else {
      warn("Cannot read directory $path:$!"), return (0,0) unless opendir DIR, $path;
      @d = readdir DIR;
      closedir DIR;
      $w-> {cachedDir}        = $path;
      $w-> {cachedDirTime}    = time;
      $w-> {cachedDirContent} = \@d;
   }

   my ( $min, $max) = ( 0, 10 ** $w-> {cypherMask} - 1);
   my ( $fmin, $fmax, $i) = ( $w->{fileNum}, $w->{fileNum});
   my @bix = ();
   my $num = $w->{cypherMask};
   my $fbeg = $w->{fileBeg};
   $fbeg =~ s{.*[/\\]([^/\\]*)$}{$1};

   for (@d) {
      next unless /(.*)(\d{$num})(\.(?:tif|gif|jpg|bmp|pcx|png))$/i;
      next unless $1 eq $fbeg and $3 eq $w->{fileEnd};
      $bix[ $2] = 1;
   }

   for ( $i = $w->{fileNum}; $i >= $min; $i--) {
       last unless $bix[ $i];
       $fmin = $i;
   }

   for ( $i = $w->{fileNum}; $i <= $max; $i++) {
       last unless $bix[ $i];
       $fmax = $i;
   }

   return $fmin, $fmax;
}

sub win_formfilename
{
   my ( $w, $fnum) = @_;
   my $num = $w-> {cypherMask};
   return sprintf("%s%0${num}d%s",$w->{fileBeg}, $fnum, $w->{fileEnd});
}

sub win_next5file
{
   my $w = $_[0];
   return unless defined $w-> {nextFile};
   my ( $min, $max) = $w-> win_getseriesrange;
   $w-> win_loadfile( $w-> win_formfilename(( $w-> {fileNum} + 5 > $max) ? $max : ( $w-> {fileNum} + 5)));
}

sub win_lastfile
{
   my $w = $_[0];
   return unless defined $w-> {nextFile};
   my ( $min, $max) = $w-> win_getseriesrange;
   $w-> win_loadfile( $w-> win_formfilename( $max));
}

sub win_prevfile
{
   $_[0]-> win_loadfile( $_[0]-> {prevFile}) if defined $_[0]-> {prevFile};
}

sub win_prev5file
{
   my $w = $_[0];
   return unless defined $w-> {prevFile};
   my ( $min, $max) = $w-> win_getseriesrange;
   $w-> win_loadfile( $w-> win_formfilename(( $w-> {fileNum} - 5 < $min) ? $min : ( $w-> {fileNum} - 5)));
}

sub win_firstfile
{
   my $w = $_[0];
   return unless defined $w-> {prevFile};
   my ( $min, $max) = $w-> win_getseriesrange;
   $w-> win_loadfile( $w-> win_formfilename( $min));
}

sub winmenu_file
{
   return
   ["~File" => [
      [ FileOpen             => "~Open"        =>  q(win_openfile)],
      [ FileSerOpen          => "Open ~series..."  => q(win_openserfile)],
      [ '-FileNextImage'     => "~Next File"   => q(win_nextfile)],
      [ '-FilePrevImage'     => "~Prev File"   => q(win_prevfile)],
      [ '-FileFirstImage'    => "~First File"  => q(win_firstfile)],
      [ '-FileLastImage'     => "~Last File"   => q(win_lastfile)],
      [ '-FileNext5Image'    => "Next 5 files" => q(win_next5file)],
      [ '-FilePrev5Image'    => "Prev 5 files" => q(win_prev5file)],
      [ '-FileCloseImage'    => "~Close"       => q(win_closefile)],
      [],
      [ FileExit          =>  "E~xit" => sub{ $::application-> close }],
   ]];
}

sub winmenu_view
{
   return
   ['~View' => [
      [ ViewNormal => '~Normal ( 100%)' =>  sub{$_[0]->IV->zoom(1.0)}],
      [ ViewBestFit => '~Best fit'       =>  sub { $_[0]-> iv_zbestfit($_[0]-> IV);} ],
      [],
      [ ViewAutoBestFit => '~Auto best fit' => sub{
         $_[0]-> iv_zbestfit($_[0]->IV) if $_[0]->IV->{autoBestFit} = $_[0]->menu->ViewAutoBestFit-> toggle;
      }],
      [],
      [ View25  => '25%'   => sub{$_[0]->IV->zoom(0.25)}],
      [ View50  => '50%'   => sub{$_[0]->IV->zoom(0.5)}],
      [ View75  => '75%'   => sub{$_[0]->IV->zoom(0.75)}],
      [ View150 => '150%'  => sub{$_[0]->IV->zoom(1.5)}],
      [ View200 => '200%'  => sub{$_[0]->IV->zoom(2)}],
      [ View300 => '300%'  => sub{$_[0]->IV->zoom(3)}],
      [ View400 => '400%'  => sub{$_[0]->IV->zoom(4)}],
      [ View600 => '600%'  => sub{$_[0]->IV->zoom(6)}],
      [ View1600 => '1600%' => sub{$_[0]->IV->zoom(16)}],
      [],
      [ ViewIncrease => '~Increase' => sub{$_[0]->IV->zoom( $_[0]->IV->zoom * 1.1); $_[0]-> sb_text("Zoom: ".$_[0]->IV->zoom);}],
      [ ViewDecrease => '~Decrease' => sub{$_[0]->IV->zoom( $_[0]->IV->zoom / 1.1); $_[0]-> sb_text("Zoom: ".$_[0]->IV->zoom);}],
   ]];
}

sub win_emulatemouse
{
   my ( $self, $button) = @_;
   my @pos = $self-> IV-> pointerPos; 
   my $state = $self-> IV-> get_shift_state;
   $self-> IV-> notify( 'MouseDown',  $button, $state, @pos);
   $self-> IV-> notify( 'MouseUp',    $button, $state, @pos);
   $self-> IV-> notify( 'MouseClick', $button, $state, @pos, 0);
}

sub winmenu_edit
{
   return
   [ edit => '~Edit' => [
      [ EditEmulation  => '~Emulation' => [
         [ 'EditEmulation1' => "Left mouse button" => sub { $_[0]-> win_emulatemouse(mb::Left)}],
         [ 'EditEmulation2' => "Right mouse button" => sub { $_[0]-> win_emulatemouse(mb::Right)}],
         [ 'EditEmulation3' => "Middle mouse button" => sub { $_[0]-> win_emulatemouse(mb::Middle)}],
      ]],
      [ EditProperties => "~Properties..." => q(opt_properties),],
   ]];
}

sub winmenu_options
{
   return
   ['~Options' => [
   ]];
}

sub winmenu_updatemappings
{
   my $w = $_[0];
   my $menu = $w-> menu;
   for ( keys %{$w-> {keyMappings}}) {
      next unless m/^Key_(.*)$/;
      my ( $item, $value) = ( $1, $w-> {keyMappings}->{$_});
      $menu-> key( $item, $value);
      $menu-> accel( $item, ($value == kb::NoKey) ? '' : Prima::KeySelector::describe( $value));
   }
}

sub ini_makecolor
{
   return sprintf( "0x%02x%02x%02x", ( $_[1] >> 16) & 0xFF, ( $_[1] >> 8) & 0xFF, $_[1] & 0xFF);
}

# WIN_END
# OPT
sub opt_colormount
{
}

sub opt_colors
{
   return {};
}

sub opt_keys
{
   return {
      'FileOpen'        => [ kb::F3,             "Open an image file"],
      'FileSerOpen'     => [ kb::NoKey,          "Open series of files"],
      'FileNextImage'   => [ kb::Right,          "Load next file in series"],
      'FilePrevImage'   => [ kb::Left,           "Load previous file in series"],
      'FileFirstImage'  => [ kb::Home,           "Load first in series"],
      'FileLastImage'   => [ kb::End,            "Load last file in series"],
      'FileNext5Image'  => [ km::Ctrl|kb::Right, "Skip five files forward"],
      'FilePrev5Image'  => [ km::Ctrl|kb::Left,  "Skip five files backward"],
      'FileCloseImage'  => [ kb::NoKey,          "Close the opened file"],
      'FileExit'        => [ '@X',               "Exit the program"],
      'EditProperties'  => [ kb::NoKey        ,  "Edit program properties"],
      'EditEmulation1'  => [ 'a'              ,  "Emulate left mouse button"],
      'EditEmulation2'  => [ 'd'              ,  "Emulate right mouse button"],
      'EditEmulation3'  => [ 's'              ,  "Emulate bottom mouse button"],
      'ViewNormal'      => [ '^1'             ,  "Set image zoom factor to 1:1"],
      'ViewBestFit'     => [ '^Z'             ,  "View image so it fits best to the window"],
      'ViewAutoBestFit' => [ kb::NoKey        ,  "Toggle automatic 'best fitting' options"],
      'View50'          => [ '^5'             ,  "Set image zoom factor to 1:2"],
      'View200'         => [ '^2',               "Set image zoom factor to 2:1"],
      'View300'         => [ '^3',               "Set image zoom factor to 3:1"],
      'View400'         => [ '^4',               "Set image zoom factor to 4:1"],
      'View600'         => [ '^6',               "Set image zoom factor to 6:1"],
      'View25'          => [ kb::NoKey        ,  "Set image zoom factor to 1:4"],
      'View75'          => [ kb::NoKey        ,  "Set image zoom factor to 3:4"],
      'View150'         => [ kb::NoKey        ,  "Set image zoom factor to 3:2"],
      'View1600'        => [ kb::NoKey        ,  "Set image zoom factor to 16:1"],
      'ViewIncrease'    => [ '+'              ,  "Increase image zoom factor by 10%"],
      'ViewDecrease'    => [ '-'              ,  "Decrease image zoom factor by 10%"],
   }   
}


sub opt_propcreate
{
   my ( $w, $dlg, $nb, $nbpages) = @_;
# General
   my $nbgrp = $nb-> insert_to_page( 0, RadioGroup =>
      name   => 'RG_SeriesType',
      origin => [ 10, 70],
      size   => [ 197, 53],
      text   => 'Series type',
   );
   $nbgrp-> insert( [ Radio =>
      origin => [ 9, 5],
      name => 'RG_Short',
      size => [ 89, 28],
      text => '~Short',
      hint => 'Sets file grouping mask as file00.ext, from 0 to 99',
   ], [ Radio =>
      origin => [ 102, 5],
      name => 'RG_Long',
      size => [ 89, 28],
      text => '~Long',
      hint => 'Sets file grouping mask as file000.ext, from 0 to 999',
   ]);


   $nb-> insert_to_page( 0,
   [ Label =>
      origin    => [ 10, 28],
      size      => [ 100, 36],
      autoWidth => 0,
      text      => 'Save path:',
      valignment => ta::Middle,
   ], [ CheckBox =>
      origin => [ 110, 28],
      size => [ 374, 36],
      name => 'UseDef',
      text => '~Use default save path',
      onClick => sub {
         $_[0]-> owner-> Path-> enabled( !$_[0]-> checked);
      },
      hint => 'Default path is where image file located',
   ], [ InputLine =>
      origin => [ 10, 10],
      size   => [ 341, 20],
      name   => 'Path',
   ], [ SpeedButton =>
      origin => [ 354, 10],
      name => 'VB::Button1',
      size => [ 26, 20],
      text => '...',
      borderWidth => 1,
      hint    => 'Select custom directory where additional files will be saved',
      onClick => sub {
         my $d = defined $w->{dirpt} ? $w->{dirpt} : Prima::ChDirDialog-> create;
         $w->{dirpt} = $d;
         $d-> directory( $_[0]-> owner-> Path-> text);
         if ( $d-> execute != mb::Cancel) {
            $_[0]-> owner-> UseDef-> uncheck;
            $_[0]-> owner-> Path-> enabled(1);
            $_[0]-> owner-> Path-> text( $d-> directory);
         }
      },
   ]);

   $nb-> insert_to_page( 0,
   [ Label =>
      origin => [ 230, 94],
      size   => [ 135, 20],
      text   => 'Status line delay (sec)',
   ], [ SpinEdit => 
      origin => [ 230, 72],
      size   => [ 135, 20],
      min    => 1,
      max    => 60,
      step   => 1,
      name   => 'StatusDelay',
   ]);

# Colors and appearance
   $nb-> insert_to_page( 1, CheckBox =>
      origin => [ 10, 60],
      text   => 'Show ~hints',
      name   => 'ShowHint',
      hint   => 'Enables these little pop-ups like the one you are looking at right now',
   );

   my $optColors  = $w-> opt_colors;
   my @colorNames = map { $optColors->{$_}->[1] } sort keys %$optColors;
   my @colorKeys  = map { "Color_$_" } sort keys %$optColors;
   if ( scalar keys %$optColors) {
      my $x1 = $nb-> insert_to_page( 1, ComboBox =>
         origin => [ 10, 10],
         size   => [ 170, $nb-> font-> height + 2],
         style  => cs::DropDownList,
         name   => 'NameSel',
         items  => \@colorNames,
         onChange => sub {
            my $colors = $dlg-> {page2}-> {colors};
            $nbpages-> {deprecate} = 1;
            $nbpages-> ColorSel-> value( $$colors[ $w->{nameSelFoc} = $_[0]-> focusedItem]);
            $nbpages-> {deprecate} = undef;
         },
      );
      $nb-> insert_to_page( 1, Label =>
         origin => [ 10, 12 + $x1-> height],
         size   => [ 300, 28],
         text   => 'Color setup',
         focusLink => $x1,
      );
      $nb-> insert_to_page( 1, ColorComboBox =>
         name   => 'ColorSel',
         origin => [ 190, 10],
         size   => [ 56, $nb-> font-> height + 2],
         onChange => sub {
	    my $self = shift;
            if ( !$nbpages-> {deprecate} && $self->enabled) {
               my $colors = $dlg-> {page2}-> {colors};
               $$colors[ $nbpages-> NameSel-> focusedItem] = $self-> value;
               my $i;
               for ( $i = 0; $i < scalar @colorKeys; $i++) {
                  $w->{ini}->{$colorKeys[$i]} = $colors->[$i];
               }
               $w-> opt_colormount;
               $w-> IV-> repaint;
            }
         },
      );
   }

# Keys
   my $optKeys = $w-> opt_keys;
   my %o_items;
   for ( keys %$optKeys) {
      m/^([A-Z][a-z]*)/;
      push( @{$o_items{$1}}, [$_]);
   }
   $nb-> insert_to_page( 2, [ StringOutline  =>  
      origin => [ 10, 58],
      size   => [ 200, 222],
      name   => 'KeyList',
      items  => [ map {[ $_, $o_items{$_}]} sort keys %o_items ],
      onSelectItem => sub {
         my ( $me, $foc) = @_;
         my ( $item, $lev) = $_[0]-> get_item( $foc);
         return unless $item;
         $w-> {keyMappings_change} = 1;
         unless ( ref($item->[1])) {
            my $key = $_[0]-> get_item_text( $item);
            my $x = $w-> {keyMappings}-> {"Key_$key"};
            $nbpages-> KeySelector-> enabled(1);
            $nbpages-> KeySelector-> key( $w-> {keyMappings}-> {"Key_$key"} );
            $nbpages-> KeyDescription-> text( $optKeys-> {$key}-> [1] );
            $nbpages-> KeySelector-> show;
         } else {
            $nbpages-> KeySelector-> hide;
            $nbpages-> KeySelector-> enabled(0);
            $nbpages-> KeyDescription-> text( '');
         }
         delete $w-> {keyMappings_change};
      },
  ], [ KeySelector =>  
      origin => [ 220, 110],
      size   => [ 150, 170],
      name   => 'KeySelector',
      visible => 0,
      onChange => sub {
         return if $w-> {keyMappings_change};
         my $kl = $nbpages-> KeyList;
         my ( $item, $lev) = $kl-> get_item( $kl-> focusedItem);
         return unless $item;
         my $okey = $kl-> get_item_text( $item);
         my $key = "Key_$okey";
         my $value = $_[0]-> key; 
         if ( $value != kb::NoKey) {
            for ( keys %{$w-> {keyMappings}}) {
               next if $_ eq $key;
               next unless $value == $w-> {keyMappings}->{$_};
               s/^Key_//;
               $w-> {keyMappings_change} = 1;
               $_[0]-> key( $w-> {keyMappings}->{$key}); 
               delete $w-> {keyMappings_change};
               my $l = $nbpages-> KeyDescription;
               $l-> backColor( cl::LightRed);
               $l-> color( cl::Yellow);
               $l-> text( "This key combination is already occupied by $_ and cannot be used");
               $l-> insert(  Timer => timeout => 100 => onTick => sub {
                  $l-> backColor( cl::Back);
                  $l-> color( cl::Fore);
                  $_[0]-> destroy;
               })-> start;
               return;
            }
         }
         $w-> {keyMappings}->{$key} = $value;
         $nbpages-> KeyDescription-> text( $optKeys-> {$okey}-> [1] );
      },
   ], [ Label => 
      origin => [ 220, 10],
      size   => [ 150, 100],
      autoWidth  => 0,
      autoHeight => 0,
      text       => '',
      name       => 'KeyDescription',
      wordWrap   => 1,
   ], [ Button => 
      origin  => [ 10, 10],
      size    => [96, 36],
      text    => '~Clear',
      hint    => 'Clears the key',
      onClick => sub {
         $nbpages-> KeySelector-> key( kb::NoKey);
      },
   ] , [ Button => 
      origin  => [ 114, 10],
      size    => [96, 36],
      text    => '~Default',
      hint    => 'Set default value for a key',
      onClick => sub {
         my $kl = $nbpages-> KeyList;
         my ( $item, $lev) = $kl-> get_item( $kl-> focusedItem);
         return unless $item;
         $nbpages-> KeySelector-> key( Prima::AbstractMenu-> translate_shortcut(
            $w-> opt_keys()-> {$kl-> get_item_text( $item)}-> [0])); 
      },
   ] );
   $nbpages-> KeyList-> focusedItem(0);
}

sub opt_proppush
{
   my ( $w, $dlg, $nb, $nbpages) = @_;
# General
   $nbpages->RG_SeriesType-> RG_Short-> checked( $w-> {cypherMask} == 2);
   $nbpages->RG_SeriesType-> RG_Long -> checked( $w-> {cypherMask} == 3);
   $dlg->{page0}->{extSaveDir} = $w->{ini}->{extSaveDir};
   $nbpages-> UseDef-> checked( length($w->{ini}->{extSaveDir}) ? 0 : 1);
   $nbpages-> Path-> enabled(( length( $w->{ini}->{extSaveDir}) > 0) ? 1 : 0);
   $nbpages-> Path-> text( length($w->{ini}->{extSaveDir}) ? $w->{ini}->{extSaveDir} : '.');
   $nbpages-> StatusDelay-> value( $w->{ini}->{statusDelay});
# Colors
   $nbpages-> ShowHint-> checked( $w-> {ini}-> {showHint});
   my $optColors = $w-> opt_colors;
   my @colors    = map { $w-> {ini}->{"Color_$_"}} sort keys %$optColors;
   $dlg-> {page2}-> {csave} =  { map { ( "Color_$_", $w-> {ini}->{"Color_$_"}) } keys %$optColors};
   $dlg-> {page2}-> {colors} = [ @colors ];
   if ( scalar @colors) {
      $nbpages-> NameSel-> focusedItem( defined $w->{nameSelFoc} ? $w->{nameSelFoc} : 0);
      $nbpages-> ColorSel-> value( $colors[ $nbpages-> NameSel-> focusedItem]);
   }
# Keys
   $w-> {keyMappings_save} = { %{ $w-> {keyMappings}} }; 
}

sub opt_propvalid
{
   my ( $w, $dlg, $nb, $nbpages) = @_;
# General
   unless ( $nbpages-> UseDef-> checked) {
      unless ( -d $nbpages-> Path-> text) {
         $nb-> pageIndex(0);
         return 0 if Prima::MsgBox::message_box( "External save path",
              "Unexistent directory: ".$nbpages-> Path-> text.
              "\nDo you want to use it anyway?",
              mb::YesNo|mb::Warning) != mb::Yes;
      }
   }

   return 1;
}

sub opt_proppop
{
   my ( $w, $dlg, $nb, $nbpages, $mr) = @_;

   if ( $mr) {
# General
      my $x = $nbpages-> Path-> text;
      $x =~ s/^\s+//;
      $x =~ s/\s+$//;
      if ( $x eq '.' || $x eq '..' || length( $x) == 0) {
         $nbpages-> UseDef-> check;
      }
      $w->{ini}->{extSaveDir} = $nbpages-> UseDef-> checked ?
         '' : $nbpages-> Path-> text;
      $w->{ini}->{silentExtDir} = 0 unless length $w->{ini}->{extSaveDir};
      $w-> win_extpathchanged if $w->{ini}->{extSaveDir} ne $dlg->{page0}->{extSaveDir};

      my $newmask = $nbpages-> RG_SeriesType-> RG_Long-> checked ? 3 : 2;
      if ( $newmask != $w-> {cypherMask}) {
         $w-> {cypherMask} = $newmask;
         $w-> win_closeextras;
         $w-> win_newextras;
         $w-> win_extraschanged;
      }
      $w->{ini}->{statusDelay} = $nbpages-> StatusDelay-> value;
# Hints
      $::application-> showHint( $w-> {ini}-> {showHint} = $nbpages-> ShowHint-> checked);
# Keys 
      $w-> winmenu_updatemappings;
   } else {
# Colors
      if ( $dlg-> {page2}-> {csave}) {
         $w-> {ini}-> {$_} = $dlg->{page2}->{csave}-> {$_} for keys %{$dlg->{page2}->{csave}};
         $w-> opt_colormount;
         $w-> IV-> repaint;
      }
# Keys      
      $w-> {keyMappings} = $w-> {keyMappings_save};
      $nbpages-> KeyList-> notify(q(SelectItem), $nbpages-> KeyList-> focusedItem);
   }
   delete $w-> {keyMappings_save};
}

sub opt_properties
{
   my $w = $_[0];
   unless ( $w-> {propertySheet}) {
      my $dlg = Prima::Window-> create(
         size     => [ 420, 460],
         text     => 'Properties',
         owner    => $w,
         ownerShowHint => 0,
#        font     => $::application-> get_message_font,
         %dlgProfile,
      );
      my $nb;

      $w-> dlg_okcancel( $dlg);
      $dlg-> OK-> set(
         modalResult => 0,
         onClick => sub {
            $dlg-> ok if $w-> opt_propvalid( $dlg, $nb, $nb-> Notebook);
         },
      );
      $nb = $dlg-> insert( TabbedNotebook =>
         origin    => [ 5, 66],
         size      => [ 410, 392],
         growMode  => gm::Client,
         pageCount => 2,
         tabs      => ['General', 'Appearance', 'Keys'],
         name      => 'Notebook',
      );
      $w-> opt_propcreate( $dlg, $nb, $nb-> Notebook);
      $w-> {propertySheet} = $dlg;
   }
   my $dlg     = $w-> {propertySheet};
   my $nb      = $dlg-> Notebook;
   my $nbpages = $nb-> Notebook;

   $w-> opt_proppush( $dlg, $nb, $nbpages);
   $w-> iv_cancelmode( $w-> IV);
   $w-> opt_proppop( $dlg, $nb, $nbpages, $dlg-> execute == mb::OK);
}

# OPT_END
# IV


sub IV_MouseDown
{
   my ( $w, $self, $btn, $mod, $x, $y) = @_;

   {
      my @r = $self-> get_active_area;
      $self-> clear_event, return if $x < $r[0] or $x >= $r[2] or $y < $r[1] or $y >= $r[3];
   }

   $self-> clear_event, return if !$ImageApp::testing and !defined $w-> IV-> image;

   my $ms = $self-> get_mouse_state;
   my $lr = mb::Left | mb::Right;
   if ((( $ms & $lr) == $lr) or ( $btn == mb::Middle)) {
      defined $w-> {magnify} ? $w-> iv_cancelmagnify( $self) : $w-> iv_magnify( $self),
      return;
   }

   if (( $btn == mb::Right) and ( !defined $self->{transaction})) {
      $self-> {dragData} = [ $x, $y, $self-> deltas];
      $w-> iv_entermode( $self, 3);
      $self-> {savePointer} = $self->pointer;
      $self-> pointer( $ico);
      $self-> clear_event;
      return;
   }
}


sub IV_MouseUp
{
   my ( $w, $self, $btn, $mod, $x, $y) = @_;
   return unless $self->{transaction};
   if ( $btn == mb::Right and $self-> {transaction} == 3) {
      $self-> pointer( $self-> {savePointer});
      $self-> {savePointer} = undef;
      $self-> capture(0);
      $self-> {transaction} = undef;
      $self-> clear_event;
   }
}

sub IV_MouseMove
{
   my ( $w, $self, $mod, $x, $y) = @_;
   if ( $w-> {magnify} && !$w-> {magnifyLock}) {
      $w-> {magnifyLock} = 1;
      $w-> ivm_repaint( $self, $x, $y);
      $w-> {magnify}-> origin( $x - 77, $y - 51);
      $w-> {magnify}-> update_view;
      $self-> update_view;
      $w-> {magnifyLock} = 0;
   }
   
   return unless $self->{transaction};
   if ( $self-> {transaction} == 3) {
      my @dd = @{$self->{dragData}};
      my ($dx,$dy) = ($x - $dd[0], $y - $dd[1]);
      $self-> deltas( $dd[2] - $dx, $dd[3] + $dy);
      $self-> clear_event;
   }
}

sub iv_entermode
{
   my ( $w, $self, $mode) = @_;
   # $w-> iv_cancelmode( $self);
   if ( $self->{transaction}) {
      $self-> {transaction} = undef;
      $self-> capture(0);
      $self-> repaint;
      $self-> pointer( $self-> {savePointer}) if $self-> {savePointer};
      $self-> {savePointer} = undef;
   }
   $self-> {transaction} = $mode;
   $self-> capture(1);
}

sub iv_cancelmode
{
   my ( $w, $self) = @_;
   $w-> iv_cancelmagnify( $self) if $w-> {magnify};
   return unless $self->{transaction};
   $self-> {transaction} = undef;
   $self-> capture(0);
   $self-> repaint;
   $self-> pointer( $self-> {savePointer}) if $self-> {savePointer};
   $self-> {savePointer} = undef;
   $w-> sb_text("Action cancelled");
}


sub iv_zbestfit
{
   my ( $w, $self) = @_;
   return unless $self->image;
   my @szA = $self->image->size;
   my @szB = $self->get_active_area(2);
   my $x = $szB[0]/$szA[0];
   my $y = $szB[1]/$szA[1];
   $self-> zoom( $x < $y ? $x : $y);
   $w-> sb_text("Zoom: ".$self->zoom);
}

sub IV_Size
{
   my ( $w, $self) = @_;
   $w-> iv_zbestfit( $self) if $self->{autoBestFit};
}

sub ivm_repaint
{
   my ( $w, $self) = @_;
   return unless $w-> {magnify};
   my $j = $w-> {magnify}-> {canvas};
   $j-> {override} = [ 0, 0];
   $j-> translate( 0, 0);
   $j-> clear;
   my @o = $self-> pointerPos;
   $j-> {override} = [ -$o[0] + 38, -$o[1] + 25];
   $j-> translate( 0, 0);
   $w-> IV_Paint( $self, $j);
   $j-> {override} = [ 0, 0];
   $j-> translate( 0, 0);
   $w-> {magnify}-> repaint;
}

sub iv_magnify
{
   my ( $w, $self) = @_;
   return if $w-> {magnify};
   my $x = $self-> insert( 'App::PLab::MagnifyingGlassWidget' );
   $x-> focus;
   $w-> IV-> capture(1);
   $w-> {magnify} = $x;
   $w-> ivm_repaint( $self, $self-> pointerPos);
}

sub iv_cancelmagnify
{
   my ( $w, $self) = @_;
   return unless $w->{magnify};
   $w->{magnify}-> destroy;
   $w->{magnify} = undef;
   $w-> IV-> capture(0);
}

# IV_END
# SB

sub sb_text
{
   my ( $w, $text, $color) = @_;
   my $self = $w-> StatusBar;
   $self-> color( defined $color ? cl::LightRed : cl::Fore);
   $self-> set(
      text  => $text,
      raise => 1,
   );
   $self-> update_view;
   $self-> { timer} = $self-> insert( Timer =>
      onTick  => sub {
         $_[0]-> stop;
         $_[0]-> owner-> set(
            text  => '',
            raise => 0,
         );
      },
   ) unless $self-> { timer};
   $self-> { timer}-> stop;
   $self-> { timer}-> timeout(  $w-> {ini}-> {statusDelay} * 1000);
   $self-> { timer}-> start;
}

# SB_END

sub profile_default
{
   my $def = $_[ 0]-> SUPER::profile_default;
   my %prf = (
      name       => 'MainWindow',
      size       => [ 531, 594],
      text       => $::application-> name,
      widgetClass=> wc::Dialog,
   );
   @$def{keys %prf} = values %prf;
   return $def;
}

sub init
{
   my $self = shift;
   my %profile = $self-> SUPER::init(@_);

   my $w = $self;
   my ($x, $y) = $w-> size;

   my $scale = $::application-> uiScaling;
   $scale = 1 if $scale < 1;

   $w-> insert( "Panel",
      text      => "",
      name      => "ToolBar",
      origin    => [ 2, $y - 2 - 38 * $scale],
      size      => [ $x - 4, 38 * $scale],
      raise     => 1,
      image     => App::PLab::ImageAppGlyphs::image( bga::tile_m),
      growMode  => gm::GrowHiX | gm::GrowLoY,
   );

   my %btn_profile = (
     glyphs      => 2,
     text        => "",
     selectable  => 0,
     transparent => 1,
     flat        => 1,
     size        => [ map { $_ * $scale } 36, 36],
     borderWidth => 1,
   );

   $w-> ToolBar-> insert(
      [ SpeedButton =>
         origin    => [1, 1],
         image     => App::PLab::ButtonGlyphs::icon( bg::fldropen),
         hint      => 'Open file',
         onClick   => sub { $w-> win_openfile; },
         %btn_profile,
      ],
      [ SpeedButton =>
         name    => "PrevImage",
         origin  => [42 * $scale, 1],
         image   => App::PLab::ImageAppGlyphs::icon( bga::prev),
         enabled => 0,
         hint    => 'Previous image',
         onClick => sub { $w-> win_prevfile; },
         %btn_profile,
      ],
      [ SpeedButton =>
         name    => "NextImage",
         origin  => [78 * $scale, 1],
         image   => App::PLab::ImageAppGlyphs::icon( bga::next),
         enabled => 0,
         hint    => 'Next image',
         onClick => sub { $w-> win_nextfile; },
         %btn_profile,
      ],
   );

   $w-> insert( "Panel",
      text  => "",
      name     => "StatusBar",
      rect     => [0, 0, $w-> width, 22],
      indent   => 2,
      raise    => 0,
      buffered => 1,
      growMode => gm::GrowHiX,
      font     => { name => "System VIO", height => 18,},
   );


   $w-> insert( 'App::PLab::TrImageViewer' =>
      name     => "IV",
      rect     => [ 2, $w-> StatusBar-> height + 2, $x - 2, $y - $w-> ToolBar-> height - 8],
      hScroll  => 1,
      vScroll  => 1,
      growMode => gm::Client,
      delegations => [qw(Size MouseUp MouseDown MouseMove Paint)],
      widgetClass => wc::Window,
   );
   return %profile;
}

1;

=pod

=head1 NAME

App::PLab::ImageApp - ancient stuff, please move along, nothing to see here

=cut
