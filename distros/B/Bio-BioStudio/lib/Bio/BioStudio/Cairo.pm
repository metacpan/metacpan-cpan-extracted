#
# BioStudio functions for Cairo interaction
#

=head1 NAME

BioStudio::Cairo

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions to draw graphic maps from annotated chromosomes

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Cairo;

require Exporter;
use Bio::BioStudio::ConfigData;
use Cairo;
use POSIX;
use Math::Trig ':pi';
use YAML::Tiny;

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  parse_fonts
  parse_colors
  draw_scale
  draw_feature
  draw_RE
  draw_stop
  draw_centromere
  draw_ARS
  draw_SSTR
  draw_CDS
  draw_intron
  draw_amplicon
  draw_repeats
  draw_UTC
  draw_deletion
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

my %featsize = (
  "site_specific_recombination_target_region" => 50,
  "stop_retained_variant" => 20
);

=head1 Functions

=head2 _path_to_conf
      
=cut

sub _path_to_conf
{
  my $bs_dir = Bio::BioStudio::ConfigData->config('conf_path') . 'cairo/';
  return $bs_dir;
}

=head2 parse_fonts

=cut

sub parse_fonts
{
  my $bs_dir = _path_to_conf();
  opendir(my $FDIR, $bs_dir);
  my @fonts = grep {$_ =~ m{\.otf\z}msix} readdir($FDIR);
  closedir $FDIR;
  my %fonthsh;
  foreach my $font (@fonts)
  {
    my $path = $bs_dir . $font;
    my ($name, $ext) = split m{\.}, $font;
    $fonthsh{$name} = $path;
  }
  return \%fonthsh;
}

=head2 _path_to_colors

=cut

sub _path_to_colors
{
  my $bs_dir = _path_to_conf();
  return $bs_dir . 'Cairo_colors.yaml';
}

=head2 parse_colors

=cut

sub parse_colors
{
  my ($path) = @_;
  $path = $path || _path_to_colors();
  my %colorhash;
  my $yaml = YAML::Tiny->read($path);
  foreach my $tag (keys %{$yaml->[0]})
  {
    my $entry =  $yaml->[0]->{$tag};
    if (ref ($entry) eq "HASH")
    {
      my $def = $entry->{default} || "666666";
      $colorhash{$tag} = {default => _RGB_to_HEX($def)};
      foreach my $key (keys %{$yaml->[0]->{$tag}})
      {
        my $val = $entry->{$key} ||  $def;
        $colorhash{$tag}->{$key} = _RGB_to_HEX($val);
      }
    }
    else
    {
      $entry = $entry ? $entry  : "666666";
      $colorhash{$tag} = {default => _RGB_to_HEX($entry)};
    }
  }
  return \%colorhash;
}

=head2 _RGB_to_HEX

=cut

sub _RGB_to_HEX
{
  my ($rgb) = @_;
  my $len = length($rgb);
  my @arr;
  for (my $i = 0; $i <= $len; $i+=2)
  {
    push @arr, hex(substr($rgb, $i, 2)) / 255;
  }
  return \@arr;
}

=head2 draw_scale

Draws the backbone and scale marks of the diagram.

=cut

sub draw_scale
{
  my ($ctx, $pa) = @_;
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->set_line_width(6);
  my $bigScaleMark = int($pa->{U_BIG_SCALE_MARK} / $pa->{FACTOR});
  my $bigScaleMarkHeight = 100;
  my $bigScaleMarkText = $pa->{DATASTART};
  my $bigScaleMarkEnd = $pa->{LEFT_MARGIN} + $pa->{SCALE_WIDTH};
  my $totalLevel = ceil(($pa->{DATAEND} - $pa->{DATASTART}) / $pa->{LEVEL_WIDTH}) -1;
  for my $i (0 .. $totalLevel)
  {
    $ctx->move_to($pa->{LEFT_MARGIN}, $pa->{SCALE_HEIGHT} + $i * $pa->{LEVEL_HEIGHT});
    if ($i == $totalLevel)
    {
      $ctx->rel_line_to($pa->{LEFT_REP_WIDTH} + fmod(($pa->{DATAEND} - $pa->{DATASTART}), $pa->{LEVEL_WIDTH}) / $pa->{FACTOR} + $pa->{RIGHT_REP_WIDTH}, 0);
      $bigScaleMarkEnd = $pa->{LEFT_DATA_MARGIN} + ceil(fmod(($pa->{DATAEND} - $pa->{DATASTART}), $pa->{LEVEL_WIDTH}) / $pa->{FACTOR});
    }
    else
    {
      $ctx->rel_line_to($pa->{SCALE_WIDTH}, 0);
    }
    $ctx->stroke();

    for (my $j = $pa->{LEFT_DATA_MARGIN}; $j <= $bigScaleMarkEnd; $j += $bigScaleMark)
    {
      $ctx->move_to($j, $pa->{SCALE_HEIGHT} + $i * $pa->{LEVEL_HEIGHT});
      $ctx->rel_line_to(0, 0-$bigScaleMarkHeight);
      $ctx->stroke();

      my $thref = $ctx->text_extents(int($bigScaleMarkText / 1000) . " kb");
      $ctx->move_to($j - $thref->{width} / 2, $pa->{SCALE_HEIGHT} + $i * $pa->{LEVEL_HEIGHT} - ($bigScaleMarkHeight + 10));
      $ctx->show_text (int($bigScaleMarkText / 1000) . " kb");
      $bigScaleMarkText += $bigScaleMark * $pa->{FACTOR};
    }
    $bigScaleMarkText -= $bigScaleMark * $pa->{FACTOR};
    if ($i == $totalLevel)
    {
      my $thref = $ctx->text_extents(int($pa->{DATAEND}/1000) . " kb");
      if ($pa->{DATAEND} > $bigScaleMarkText + $thref->{width} * $pa->{FACTOR})
      {
        $ctx->move_to($pa->{LEFT_DATA_MARGIN} + fmod(($pa->{DATAEND} - $pa->{DATASTART}), $pa->{LEVEL_WIDTH}) / $pa->{FACTOR}, $pa->{SCALE_HEIGHT} + $i*$pa->{LEVEL_HEIGHT});
        $ctx->rel_line_to(0, 0-$bigScaleMarkHeight);
        $ctx->stroke();

        $ctx->move_to($pa->{LEFT_DATA_MARGIN} + fmod(($pa->{DATAEND}-$pa->{DATASTART}), $pa->{LEVEL_WIDTH}) / $pa->{FACTOR} - $thref->{width} / 2, $pa->{SCALE_HEIGHT} + $i*$pa->{LEVEL_HEIGHT} - ($bigScaleMarkHeight + 10));
        $ctx->show_text (int($pa->{DATAEND}/1000) . " kb");
      }
    }
  }
  return $totalLevel;
}

=head2 draw_feature

=cut

sub draw_feature
{
  my ($ctx, $obj, $xbeg, $xend, $isdash, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
  $ctx->set_dash(15,7,7) if $isdash;
  $ctx->set_dash(0) unless $isdash;
  $xywref = $xywref ? $xywref : undef;
  unless ($xywref)
  {
    my $flag;
    my $clipEnd = $obj->{DrawEnd};
    if ($clipEnd >= $xend)
    {
      $clipEnd = $xend + 2;
      $flag = 1;
    }
    my $clipStart = $obj->{DrawStart};
    if ($clipStart <= $xbeg)
    {
       $clipStart = $xbeg - 2;
       $flag = 1;
    }
    my $clipWidth = $clipEnd - $clipStart;
    if (exists $featsize{$feat->primary_tag})
    {
      $clipWidth = $featsize{$feat->primary_tag};
      $clipStart -= .5 *$clipWidth;
    }
    if ($flag)
    {
      ##I WISH THIS CLIPPING REGION WAS BETTER RESTRICTED TO OBJECT HEIGHT
      my $y = $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
      $ctx->rectangle($clipStart, $y, $clipWidth, $pa->{LEVEL_HEIGHT});
      $ctx->clip();
    }
  }
 
  #Check what feature is it and start drawing (Put it in alphabetical order)
  if ($feat->primary_tag eq "CDS")
  {
    draw_CDS($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "PCR_product")
  {
    draw_amplicon($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "site_specific_recombination_target_region")
  {
    draw_SSTR($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "ARS")
  {
    draw_ARS($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "stop_retained_variant")
  {
    draw_stop($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "centromere")
  {
    draw_centromere($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "restriction_enzyme_recognition_site")
  {
    draw_RE($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "enzyme_recognition_site")
  {
    draw_RE($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "intron")
  {
    draw_intron($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "repeat_family")
  {
    draw_repeats($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "universal_telomere_cap")
  {
    draw_UTC($ctx, $obj, $pa, $xywref);
  }
  elsif ($feat->primary_tag eq "deletion")
  {
    draw_deletion($ctx, $obj, $pa, $xywref);
  }
  #Reset all drawing setting
  $ctx->set_dash(0);
  $ctx->reset_clip();
  return;
}

=head2 draw_RE

=cut

sub draw_RE
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
 
  my $colref = $pa->{FEAT_RGB}->{restriction_enzyme_recognition_site}->{default};
  $ctx->set_source_rgba($colref->[0], $colref->[1], $colref->[2], .95);
 
  my $RELineHeight = 50.0;
  my ($start, $radius, $movey);
  my $thref = ($ctx->text_extents($feat->Tag_enzyme));
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    $radius = ($obj->{DrawEnd} - $start) / 2;
    $movey = $pa->{SCALE_HEIGHT} + $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
  }
  else
  {
    ($start, $radius, $movey) = @{$xywref};
    $radius = $radius / 2;
  }
  $ctx->move_to($start + $radius, $movey);
  $ctx->rel_line_to(0, -$RELineHeight);
 
  my $tx = $start - $thref->{width}/2;
  my $ty = $movey - ($RELineHeight+10);
  $ctx->move_to($tx, $ty);
  $ctx->show_text ($feat->Tag_enzyme);
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_centromere

=cut

sub draw_centromere
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
 
  my $colref = $pa->{FEAT_RGB}->{centromere}->{default};
  $ctx->set_source_rgb($colref->[0], $colref->[1], $colref->[2]);
 
  my ($start, $movey, $radius);
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    $radius = ($obj->{DrawEnd} - $start) / 2;
    $movey = $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
    $movey += $pa->{STRAND_Y_POS} + $pa->{STRAND_DISTANCE}/2;
  }
  else
  {
    ($start, $movey, $radius) = @{$xywref};
    $radius = $radius / 2;
  }
  my $centromereRadius = 200/$pa->{FACTOR};
  $centromereRadius = $radius if ($radius > $centromereRadius);
  $centromereRadius = 7 if ($centromereRadius < 7);
 
  $ctx->move_to($start, $movey);
  $ctx->arc($start + $radius, $movey, $centromereRadius, 0, 2*pi);
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_stop

=cut

sub draw_stop
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
  my $parent = $feat->Tag_parent_id;
  my $pobj = $pa->{FEATURES}->{$parent};
  my $pfeat = $pobj->{feat};
 
  my $colref = $pa->{FEAT_RGB}->{stop_retained_variant}->{default};
  $ctx->set_source_rgb($colref->[0], $colref->[1], $colref->[2]);
 
  my $CodonSide = 80 / $pa->{FACTOR};
  $CodonSide = 4 if ($CodonSide < 4);
  my $smove = $CodonSide / sqrt(2);
 
  my ($start, $movey, $radius);
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    $radius = ($obj->{DrawEnd} - $start) / 2;
    $start = $obj->{DrawEnd} if ($pfeat->strand == -1);
    $movey = $obj->{LevelNum} * $pa->{LEVEL_HEIGHT} + $pa->{STRAND_Y_POS};
    $movey += $pa->{STRAND_DISTANCE} if ($pfeat->strand == -1);
  }
  else
  {
    ($start, $movey, $radius) = @{$xywref};
    $radius = $radius/2;
  }
  $ctx->move_to($start + $radius, $movey);

  $ctx->rel_move_to(-$CodonSide / 2, -($CodonSide / 2+$smove));
  $ctx->rel_line_to($CodonSide, 0);
  $ctx->rel_line_to($smove, $smove);
  $ctx->rel_line_to(0, $CodonSide);
  $ctx->rel_line_to(-$smove, $smove);
  $ctx->rel_line_to(-$CodonSide, 0);
  $ctx->rel_line_to(-$smove, -$smove);
  $ctx->rel_line_to(0, -$CodonSide);
  $ctx->close_path();
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_ARS

=cut

sub draw_ARS
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};

  my $colref = $pa->{FEAT_RGB}->{ARS}->{default};
  $ctx->set_source_rgba($colref->[0], $colref->[1], $colref->[2], .95);
  my $ARSHeight = 50;

  my ($start, $movey, $width);
  unless($xywref)
  {
    $start = $obj->{DrawStart};
    $width = $obj->{DrawEnd} - $start;
    $movey = $obj->{LevelNum} * $pa->{LEVEL_HEIGHT} + $pa->{SCALE_HEIGHT};
  }
  else
  {
    ($start, $movey, $width) = @{$xywref};
  }
  $ctx->move_to($start, $movey);
 
  $ctx->rel_line_to(0, -$ARSHeight/2);
  $ctx->rel_line_to($width, 0);
  $ctx->rel_line_to(0, $ARSHeight);
  $ctx->rel_line_to(-$width, 0);
  $ctx->close_path();
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_SSTR

=cut

sub draw_SSTR
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
 
  my $colref = $pa->{FEAT_RGB}->{$feat->primary_tag};
  $ctx->set_source_rgba($colref->[0], $colref->[1], $colref->[2], .95);
            
  my $SSRTsize = $pa->{U_BIG_SCALE_MARK} / ($pa->{FACTOR} * 15);
  $SSRTsize = 7 if ($SSRTsize < 7);
  $SSRTsize = 20 if ($SSRTsize > 20);
 
  my ($start, $movey, $radius);
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    $radius =  ($obj->{DrawEnd} - $start) / 2;
    $movey = $obj->{LevelNum} * $pa->{LEVEL_HEIGHT} + $pa->{SCALE_HEIGHT};
  }
  else
  {
    ($start, $movey, $radius) = @{$xywref};
    $radius = $radius / 2;
  }
  $ctx->move_to($start + $radius, $movey - $SSRTsize);
 
  $ctx->rel_line_to($SSRTsize, $SSRTsize);
  $ctx->rel_line_to(-$SSRTsize, $SSRTsize);
  $ctx->rel_line_to(-$SSRTsize, -$SSRTsize);
  $ctx->close_path();
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_CDS

=cut

sub draw_CDS
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
  my $triLen = 50;
  my $CDSHeight = 50;
  my $key = 'default';
  if ($feat->has_tag('essential_status'))
  {
    my $key = $feat->Tag_essential_status eq 'Essential'
          ? 'Essential'
          : $feat->Tag_essential_status eq 'fast_growth'
            ? 'fast_growth'
            : $feat->Tag_orf_classification;
  }
  my $colref = $pa->{FEAT_RGB}->{gene}->{$key};
  $ctx->set_source_rgb($colref->[0], $colref->[1], $colref->[2]);
 
  my ($start, $end, $movey, $width);
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    $end = $obj->{DrawEnd};
    $width = $end - $start;
    $movey = $pa->{STRAND_Y_POS} + $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
    if ($feat->strand == -1)
    {
      ($start, $end) = ($end, $start);
      $movey += $pa->{STRAND_DISTANCE};
      my $unitVec = (($end-$start) / abs($end-$start));
      $triLen = $triLen * $unitVec;
    }
  }
  else
  {
    ($start, $movey, $width) = @{$xywref};
    $end = $width + $start;
  }

  #Calculate x2 = rectangle's Len , x3 = triangle part's Len |----x2----->
  my ($x2, $x3);
  if ($width <= abs($triLen * 1.3))
  {
    $x2 = $end - ($end - $start) / 2-$start;
    $x3 = ($end-$start)/2;
  }
  else
  {
    $x2 = $end - $triLen - $start;
    $x3 = $triLen;
  }
  $pa->{CDSDATA}->{$feat->Tag_parent_id} = [$start, $movey, $x2, $x3];
  $ctx->move_to($start, $movey);
 
  $ctx->rel_line_to(0, 0-$CDSHeight/2);
  $ctx->rel_line_to($x2, 0);
  $ctx->rel_line_to($x3, $CDSHeight/2);
  $ctx->rel_line_to(0-$x3, $CDSHeight/2);
  $ctx->rel_line_to(0-$x2, 0);
  $ctx->close_path();
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_intron

=cut

sub draw_intron
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
  my $parent = $feat->Tag_parent_id;
  my $pobj = $pa->{FEATURES}->{$parent};
  my $pfeat = $pobj->{feat};
  my $CDSHeight = 50;
 
  my $colref = $pa->{FEAT_RGB}->{intron}->{default};
  $ctx->set_source_rgb($colref->[0], $colref->[1], $colref->[2]);
 
  my ($start, $movey, $radius);
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    $radius = ($obj->{DrawEnd} - $start) / 2;
    $movey = $pa->{STRAND_Y_POS} + $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
    $movey += $pa->{STRAND_DISTANCE} if ($pfeat->strand == -1);
  }
  else
  {
    ($start, $movey, $radius) = @{$xywref};
  }
  $ctx->move_to($start, $movey);

  $ctx->rel_line_to($radius, -$CDSHeight/3.0);
  $ctx->rel_line_to($radius, $CDSHeight/3.0);
  $ctx->fill_preserve();
 
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_amplicon

=cut

sub draw_amplicon
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
  my $gene = $feat->Tag_ingene;
  my $CDSHeight = 50;
 
  my $colref = $pa->{FEAT_RGB}->{PCR_product}->{default};
  $ctx->set_source_rgba($colref->[0], $colref->[1], $colref->[2], .8);
 
  my ($start, $movey, $mwidth);
 
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    $mwidth = abs($obj->{DrawEnd}-$start);
    my ($psmove, $pemove, $px2, $px3) = @{$pa->{CDSDATA}->{$feat->Tag_ingene}};
    {
      $ctx->move_to($psmove, $pemove);
      $ctx->rel_line_to(0, 0-$CDSHeight/2);
      $ctx->rel_line_to($px2, 0);
      $ctx->rel_line_to($px3, $CDSHeight/2);
      $ctx->rel_line_to(0-$px3, $CDSHeight/2);
      $ctx->rel_line_to(0-$px2, 0);
      $ctx->clip();
    }
    $movey = $pa->{STRAND_Y_POS} + $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
    $movey += $pa->{STRAND_DISTANCE} if ($feat->strand == -1);
  }
  else
  {
    ($start, $movey, $mwidth) = @{$xywref;}
  }
  $ctx->move_to($start, $movey);
 
  $ctx->rel_line_to(0, $CDSHeight/2);
  $ctx->rel_line_to($mwidth, 0);
  $ctx->rel_line_to(0, -$CDSHeight);
  $ctx->rel_line_to(- $mwidth, 0);
  $ctx->close_path();
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_repeats

=cut

sub draw_repeats
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
  my $repeatfamilyHeight = 50;
  my $colref = $pa->{FEAT_RGB}->{repeat_family}->{default};
  $ctx->set_source_rgba($colref->[0], $colref->[1], $colref->[2], .95);
 
  my ($start, $width, $movey);
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    my $end = $obj->{DrawEnd};
    $width = $end - $start;
    $movey = $pa->{SCALE_HEIGHT} + $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
  }
  else
  {
    ($start, $movey, $width) = @{$xywref};
  }
  $ctx->move_to($start, $movey);
 
  $ctx->rel_line_to(0, -$repeatfamilyHeight/2);
  $ctx->rel_line_to($width, 0);
  $ctx->rel_line_to(0, $repeatfamilyHeight);
  $ctx->rel_line_to(-$width, 0);
  $ctx->close_path();
 
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_UTC

=cut

sub draw_UTC
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
  my $radius = 50;
  my $UTCHeight = 50;
 
  my $colref = $pa->{FEAT_RGB}->{universal_telomere_cap}->{default};
  $ctx->set_source_rgb($colref->[0], $colref->[1], $colref->[2]);
 
  my ($start, $end, $width, $movey);
  unless ($xywref)
  {
    ($start, $end) = ($obj->{DrawStart}, $obj->{DrawEnd});
    $width = $end - $start;
    $movey = $pa->{SCALE_HEIGHT} + $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
    if ($feat->strand == -1)
    {
      ($start, $end) = ($end, $start);
      $movey+= $pa->{STRAND_DISTANCE};
      my $unitVec = ($width/abs($width));
      $radius = $radius*$unitVec;
    }
  }
  else
  {
    $width = $xywref->[2];
    $movey = $xywref->[1];
    ($start, $end) = ($xywref->[0], $xywref->[0] + $width);
  }
  $ctx->move_to($start, $movey);
 
  my ($x2, $x3);
  #Calculate x2 = rectangle's Len , x3 = triangle part's Len |----x2----->
  if (abs($width) <= abs($radius*1.3))
  {
    $x2 = $end-($width)*2/3-$start;
    $x3 = ($width)*2/3;
  }
  else
  {
    $x2 = $end - $radius - $start;
    $x3 = $radius;
  }

  $ctx->rel_line_to(0, -$UTCHeight/2);
  $ctx->rel_line_to($x2, 0);
  $ctx->rel_curve_to(0, 0, $x3, $UTCHeight/2, 0, $UTCHeight);
  $ctx->rel_line_to(-$x2, 0);
  $ctx->close_path();
  $ctx->fill_preserve();
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

=head2 draw_deletion

=cut

sub draw_deletion
{
  my ($ctx, $obj, $pa, $xywref) = @_;
  my $feat = $obj->{feat};
  my $height = 50;
  my $width = 200/$pa->{FACTOR};
  $width = 7 if ($width < 7);
 
  my $colref = $pa->{FEAT_RGB}->{deletion}->{default};
  $ctx->set_source_rgb($colref->[0], $colref->[1], $colref->[2]);
 
  my ($start, $movey);
  unless ($xywref)
  {
    $start = $obj->{DrawStart};
    my $ypos = $obj->{LevelNum} * $pa->{LEVEL_HEIGHT};
    $movey =  $pa->{STRAND_Y_POS} + $pa->{STRAND_DISTANCE} + $ypos;
  }
  else
  {
    $start = $xywref->[0];
    $movey = $xywref->[1];
  }
  $ctx->move_to($start - $width / 2, $movey);

  $ctx->rel_line_to($width, -$height);
  $ctx->rel_move_to(0, $height);
  $ctx->rel_line_to(-$width, -$height);
 
  $ctx->set_source_rgb(0, 0, 0);
  $ctx->stroke();
  return;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
