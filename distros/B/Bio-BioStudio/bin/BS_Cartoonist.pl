#!/usr/bin/env perl

use Bio::BioStudio;
use Bio::BioStudio::Cairo qw(:BS);
use Getopt::Long;
use List::Util qw(first);
use Pod::Usage;
use POSIX;
use English qw(-no_match_vars);
use Carp;
use Cairo;
use Font::FreeType;

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_Cartoonist_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
      'CHROMOSOME=s'  => \$p{CHROMOSOME},
      'FACTOR=i'      => \$p{FACTOR},
      'LEVELWIDTH=i'  => \$p{LEVEL_WIDTH},
      'REPEATLEFT=i'  => \$p{LEFT_REPEAT},
      'REPEATRIGHT=i' => \$p{RIGHT_REPEAT},
      'START=i'       => \$p{DATASTART},
      'STOP=i'        => \$p{DATAEND},
			'help'          => \$p{HELP}
);
pod2usage(-verbose=>99) if ($p{HELP});

################################################################################
################################# SANITY CHECK #################################
################################################################################
my $BS = Bio::BioStudio->new();

die "BSERROR: No chromosome was named.\n"  unless ($p{CHROMOSOME});
my $chr = $BS->set_chromosome(-chromosome => $p{CHROMOSOME});

die ("BSERROR: Factor must be at least 2.\n")
  if ($p{FACTOR} && $p{FACTOR} < 2);

################################################################################
################################# CONFIGURING ##################################
################################################################################
my $chrseq = $chr->sequence;
my $chrlen = length $chrseq;

my @features = $chr->db->features;

$p{DATAEND} = $p{DATAEND} && $p{DATAEND} <= $chrlen
              ? $p{DATAEND}
              : $chrlen;
$p{DATASTART} = $p{DATASTART} && $p{DATASTART} >= 1 && $p{DATASTART} < $p{DATAEND}
              ? $p{DATASTART}
              : 1;

#Scaling factor
$p{FACTOR} = $p{FACTOR} ? $p{FACTOR} : 10;

#PDF margins
$p{LEFT_MARGIN} = 100;
$p{RIGHT_MARGIN} = 100;

#Each level represent 50kb of data, with a height of 400
$p{LEVEL_WIDTH} = $p{LEVEL_WIDTH} ? $p{LEVEL_WIDTH}  : 50000;
$p{LEVEL_HEIGHT} = 460;

#Left Freedom Data: amount of data that will repeat from the last line
$p{LEFT_REPEAT} = $p{LEFT_REPEAT} ? $p{LEFT_REPEAT}  : 1000; # 1000 = 1kb @ factor 10
$p{LEFT_REP_WIDTH} = int($p{LEFT_REPEAT} / $p{FACTOR});
$p{LEFT_DATA_MARGIN} = $p{LEFT_MARGIN} + $p{LEFT_REP_WIDTH};

#Right Freedom Data: amount of data that will repeat on the next line
$p{RIGHT_REPEAT} = $p{RIGHT_REPEAT} ? $p{RIGHT_REPEAT} : 1000; # 1000 = 1kb @ factor 10
$p{RIGHT_REP_WIDTH} = int($p{RIGHT_REPEAT} / $p{FACTOR});

#Scale Height and Width
$p{SCALE_HEIGHT} = 150;
$p{SCALE_WIDTH} = int($p{LEVEL_WIDTH} / $p{FACTOR}) + $p{LEFT_REP_WIDTH} + $p{RIGHT_REP_WIDTH};
$p{SCALE_LENGTH} = $p{SCALE_WIDTH}-$p{RIGHT_REP_WIDTH}-$p{LEFT_REP_WIDTH};

#intial feature y position and y distance between W/C strands
$p{STRAND_Y_POS} = 245;
$p{STRAND_DISTANCE} = 70;

$p{FEAT_RGB} = parse_colors();

$p{U_BIG_SCALE_MARK} = ceil(.2*$p{LEVEL_WIDTH});

my %drawing = ("stop_retained_variant" => 1, "CDS" => 1, "PCR_product" => 1,
  "centromere" => 1, "ARS" => 1, "restriction_enzyme_recognition_site" => 1,
  "enzyme_recognition_site" => 1,
  "site_specific_recombination_target_region" => 1, "intron" => 1,
  "repeat_family" => 1, "universal_telomere_cap" => 1, "deletion" => 1);
 
my %labeling = ("gene" => 1, "centromere" => 1, "ARS" => 1);

my %legending = (
  "stop_retained_variant" => "stop swap",
  "PCR_product" => "PCRTag amplicon",
  "ARS" => "ARS",
  "intron" => 0, "centromere" => 0,
  "universal_telomere_cap" => "Telomere seed sequence",
  "site_specific_recombination_target_region" => "loxPsym site",
  "repeat_family" => 0,
  "deletion" => 0,
  "CDS" => 0
);

################################################################################
################################### Drawing ####################################
################################################################################
my $width = int($p{LEFT_MARGIN} + $p{RIGHT_MARGIN} + $p{SCALE_WIDTH});
my $height = ceil(($p{DATAEND} - $p{DATASTART}) / $p{LEVEL_WIDTH}) * $p{LEVEL_HEIGHT};
my $filename = $chr->name . ".pdf";
my $outputloc = $filename;

my $surface = Cairo::PdfSurface->create($outputloc, $width, $height)
  || croak "$OS_ERROR";
my $ctx = Cairo::Context->create($surface);

#Set fonts
my $fonts = parse_fonts();
my $fontfile = $fonts->{Inconsolata};
my $ftfont = Font::FreeType->new->face($fontfile);
my $fontface = Cairo::FtFontFace->create($ftfont);
$ctx->set_font_face($fontface);
my $fontsize = 500 / $p{FACTOR};
$fontsize = 7 if ($fontsize < 7);
$ctx->set_font_size($fontsize);

#Draw white background
$ctx->set_source_rgb(1, 1, 1);
$ctx->rectangle(0, 0, $width, $height);
$ctx->fill;


#Draw backbone and scale marks
$p{LEVEL_COUNT} = draw_scale($ctx, \%p);
$ctx->set_line_width(5);

#Draw name of file
$ctx->save();
my $thref = $ctx->text_extents($chr->name);
$ctx->move_to($p{LEFT_MARGIN} / 2, $height / 2 + ($thref->{width} / 2));
$ctx->rotate(-1.57079633);
$ctx->show_text($chr->name);
$ctx->restore();

#length of the Last level
my $LastScaleMidLen = fmod(($p{DATAEND} - $p{DATASTART}), $p{LEVEL_WIDTH}) / $p{FACTOR};

#Set font Size for other feature (Restriction Enzymes)
my $fontSize = 450 / $p{FACTOR};
$fontSize = 20 if ($fontSize < 20);
$ctx->set_font_size ($fontSize);

$p{FEATURES} = {};
$p{CDSDATA} = {};
foreach my $feat (grep {! $_->Tag_parent_id} @features)
{
  unless (($feat->start > $p{DATAEND} + $p{RIGHT_REP_WIDTH} * $p{FACTOR})
        || $feat->end < $p{DATASTART} - $p{LEFT_REP_WIDTH} * $p{FACTOR})
  {
    my $obj = {};
    my $shiftedStart = $feat->start - $p{DATASTART};
    my $shiftedEnd = $feat->end - $p{DATASTART};
    $obj->{LevelNumStart} = int($shiftedStart / $p{LEVEL_WIDTH});
    $obj->{LevelNumEnd} = int($shiftedEnd / $p{LEVEL_WIDTH});

    $obj->{scaledStart} = fmod($shiftedStart, $p{LEVEL_WIDTH}) / $p{FACTOR} + $p{LEFT_REP_WIDTH} + $p{LEFT_MARGIN};
    $obj->{scaledEnd} = fmod($shiftedEnd, $p{LEVEL_WIDTH}) / $p{FACTOR} + $p{LEFT_REP_WIDTH} + $p{LEFT_MARGIN};

    if ($obj->{scaledStart} <= ($p{RIGHT_REP_WIDTH} + $p{LEFT_DATA_MARGIN}) && $obj->{LevelNumStart} != 0)
    {
      $obj->{LevelNumStart} -= 1;
      $obj->{scaledStart} += int($p{LEVEL_WIDTH}/$p{FACTOR});
    }
    if ($obj->{scaledEnd} >= $p{LEFT_MARGIN} + $p{SCALE_LENGTH})
    {
      $obj->{LevelNumEnd} += 1;
      $obj->{scaledEnd} -= int($p{LEVEL_WIDTH} / $p{FACTOR});
    }
    $obj->{Children} = [];
    foreach my $child ($chr->flatten_subfeats($feat))
    {
      my $cobj = {};
      my $shiftedStart = $child->start - $p{DATASTART};
      my $shiftedEnd = $child->end - $p{DATASTART};
      $child->remove_tag("parent_id");
      $child->add_tag_value("parent_id", $feat->id);
      $cobj->{LevelNumStart} = int($shiftedStart / $p{LEVEL_WIDTH});
      $cobj->{LevelNumEnd} = int($shiftedEnd / $p{LEVEL_WIDTH});

      $cobj->{scaledStart} = fmod($shiftedStart, $p{LEVEL_WIDTH}) / $p{FACTOR} + $p{LEFT_REP_WIDTH} + $p{LEFT_MARGIN};
      $cobj->{scaledEnd} = fmod($shiftedEnd, $p{LEVEL_WIDTH}) / $p{FACTOR} + $p{LEFT_REP_WIDTH} + $p{LEFT_MARGIN};

      if ($cobj->{scaledStart} <= ($p{RIGHT_REP_WIDTH} + $p{LEFT_DATA_MARGIN}) && $cobj->{LevelNumStart} != 0)
      {
        $cobj->{LevelNumStart} -= 1;
        $cobj->{scaledStart} += int($p{LEVEL_WIDTH}/$p{FACTOR});
      }
      if ($cobj->{scaledEnd} >= $p{LEFT_MARGIN} + $p{SCALE_LENGTH})
      {
        $cobj->{LevelNumEnd} += 1;
        $cobj->{scaledEnd} -= int($p{LEVEL_WIDTH} / $p{FACTOR});
      }
      $cobj->{feat} = $child;
      $cobj->{LevelNum} = $cobj->{LevelNumStart};
      push @{$obj->{Children}}, $cobj;
    }
    $obj->{feat} = $feat;
    $obj->{LevelNum} = $obj->{LevelNumStart};
    $p{FEATURES}->{$feat->id} = $obj;
  }
}

my (@layer1, @layer2, @layer3) = ((), (), ());
my @labels;
foreach my $id (keys %{$p{FEATURES}})
{
  my $obj = $p{FEATURES}->{$id};
  my $feat = $obj->{feat};
  if ($feat->primary_tag eq "PCR_product")
  {
    my $genearr = $feat->{attributes}->{ingene};
    my $pobj = $p{FEATURES}->{$genearr->[0]};
    my $pfeat = $pobj->{feat};
    $feat->strand($pfeat->strand);
    push @layer2, $obj;
    push @labels, $feat;
  }
  elsif ($feat->primary_tag eq "deletion")
  {
    push @layer3, $obj;
    push @labels, $feat;
  }
  elsif ($feat->primary_tag eq "gene")
  {
    push @labels, $feat;
    foreach my $cobj (@{$obj->{Children}})
    {
      my $cfeat = $cobj->{feat};
      my $ptag = $cfeat->primary_tag;
      if ($ptag eq "stop_retained_variant" || $ptag eq "intron")
      {
        push @labels, $cfeat;
        push @layer3, $cobj;
        next;
      }
      push @labels, $cfeat;
      push @layer1, $cobj;
    }
  }
  else
  {
    push @layer1, $obj;
    push @labels, $feat;
  }
}

#Draw Each Layer
my %index;
foreach my $obj (@layer1, @layer2, @layer3)
{
  my $feat = $obj->{feat};
  $index{$feat->primary_tag} = [] unless $index{$feat->primary_tag};
  push @{$index{$feat->primary_tag}}, $obj;
  next unless (exists $drawing{$feat->primary_tag});
  my $midEnd = $p{SCALE_WIDTH} + $p{LEFT_MARGIN} - $p{RIGHT_REP_WIDTH};
  my $rightEnd = $p{SCALE_WIDTH} + $p{LEFT_MARGIN};
 
  #Draw on Multiple level for features that cross different levels
  #print "Preparing to draw ", $obj->{feat}, "\n";
  for (my $i = $obj->{LevelNumStart}; $i <= $obj->{LevelNumEnd}; $i++)
  {
    #Special Case for Last Line
    if ($i == $p{LEVEL_COUNT})
    {
      $midEnd = $p{LEFT_DATA_MARGIN} + $LastScaleMidLen;
      $rightEnd = $p{LEFT_DATA_MARGIN} + $LastScaleMidLen + $p{RIGHT_REP_WIDTH};
    }
    $obj->{DrawStart} = $obj->{scaledStart} - ($i - $obj->{LevelNumStart}) * $p{SCALE_LENGTH};
    $obj->{DrawEnd} = $obj->{scaledEnd} + ($obj->{LevelNumEnd} - $i) * $p{SCALE_LENGTH};
    $obj->{LevelNum} = $i;
    #Draw left freedom dashed,
    if ($obj->{DrawStart} <= $p{LEFT_DATA_MARGIN})
    {
      draw_feature($ctx, $obj, $p{LEFT_MARGIN}, $p{LEFT_DATA_MARGIN}, 1, \%p);
    }
    #Draw middle solid
    if ($obj->{DrawStart} <= $midEnd) #&& $obj->{DrawEnd} >= $p{LEFT_DATA_MARGIN}
    {
      draw_feature($ctx, $obj, $p{LEFT_DATA_MARGIN}, $midEnd, 0, \%p);
    }
    #Draw right freedom dashed
    if ($obj->{DrawEnd} >= $midEnd || $obj->{LevelNumStart} > $i)
    {
      draw_feature($ctx, $obj, $midEnd, $rightEnd, 1, \%p);
    }
  }
}

$surface->flush();
$surface->finish();


#Draw Labels and Key
my $lloc =  q{./} . $chr->name . "_key.pdf";
my $lsurface = Cairo::PdfSurface->create($lloc, $width, $height) || croak $OS_ERROR;
my $key = Cairo::Context->create($lsurface);
$key->set_font_face($fontface);
$key->set_font_size ($fontSize);

my @labellist = grep {exists $labeling{$_->primary_tag}} @labels;
my $y = 200;
my $x = 500;
#Draw Feature Labels
foreach my $feat (sort {$a->start <=> $b->start} @labellist)
{
  my $text = $feat->Tag_load_id;
  my $thref = ($key->text_extents($text));
  if ($x + $thref->{width} > $width)
  {
    $x = 500;
    $y = $y+100;
  }
  my $tx = $x - $thref->{width}/2;
  $key->move_to($tx, $y);
  $key->show_text($text);
  $y = ($x+(2*$thref->{width}) > $width - 500)  ? $y+100 : $y + 2;
  $x = ($x+(2*$thref->{width}) > $width - 500)  ? 500 : $x+(2*$thref->{width});
}

#Draw Key
$x = 500;
$y += 100;
foreach my $type (grep {exists $legending{$_}} keys %index)
{
  print "got a $type!\n";
  my %objs;
  if ($type eq 'CDS')
  {
    my @CDSes = @{$index{$type}};
    if ($CDSes[0]->{feat}->has_tag('essential_status') && $CDSes[0]->{feat}->has_tag('orf_classification'))
    {
      $objs{"essential ORF"} = first {$_->{feat}->Tag_essential_status eq "Essential"} @{$index{$type}};
      $objs{"slow growth ORF"} = first {$_->{feat}->Tag_essential_status eq "fast_growth"} @{$index{$type}};
      $objs{"non-essential ORF"} = first {$_->{feat}->Tag_orf_classification eq "Verified"} @{$index{$type}};
      $objs{"uncharacterized ORF"} = first {$_->{feat}->Tag_orf_classification eq "Uncharacterized"} @{$index{$type}};
      $objs{"dubious ORF"} = first {$_->{feat}->Tag_orf_classification eq "Dubious"} @{$index{$type}}; 
    }
    else
    {
      $objs{"ORF"} = $CDSes[0];
    }
  }
  else
  {
    $objs{$type} = first {1} @{$index{$type}};
  }
  foreach my $text (keys %objs)
  {
    my $xywref = [$x, $y, 50];
    my $obj = $objs{$text};
    $text = $legending{$type} if ($legending{$type});
    print "keying $text\n";
    my $thref = ($key->text_extents($text));
    my $xbeg = $p{LEFT_MARGIN};
    my $xend = $p{LEFT_DATA_MARGIN} + $LastScaleMidLen + $p{RIGHT_REP_WIDTH};
    draw_feature($key, $obj, $xbeg, $xend, 0, \%p, $xywref);
    $key->move_to($x + 50 + ($thref->{width} / 2), $y);
    $key->show_text($text);
    $y = $y + 100;
    $x = 500;
  }
}
$lsurface->flush();
$lsurface->finish();

print "See " . q{./} . $chr->name . ".pdf\n\n";

exit;

__END__

=head1 NAME

  BS_Cartoonist.pl

=head1 VERSION

  Version 2.10

=head1 DESCRIPTION

  This utility takes a chromosome from the BioStudio genome repository and makes
   a vector image of its annotations.

=head1 ARGUMENTS

Required arguments:

  -C, --CHROMOSOME : The chromosome to be rendered.  Must be in the BioStudio
    genome repository.
 
Optional arguments:

  -F, --FACTOR : [def 10] The factor by which data will be scaled. Must be at
      least 2 - do you really want a 1:1 diagram of a chromosome?
  -L, --LEVELWIDTH : [def 50000] The bases represented per level of the diagram.
      A width of 50000 with a scaling factor of 10 will result in an image about
      5000 pixels wide.
  --REPEATLEFT : [def 1000] The number of bases from the previous level of the
      diagram that will be repeated in dashed lines, on the next level.
  --REPEATRIGHT : [def 1000] The number of bases at the end of each level of the
      diagram that will be repeated in dashed lines, on the next level.
  --START : [def 1] The first base to be displayed in the diagram. If it is not
      less than the length and equal to or greater than 1, it will default to 1.
  --STOP : [def chromosome length] The last base to be displayed in the
      diagram. If this number is larger than the length of the chromosome, it
      will default to chromosome length.
  -h, --help : Display this message
 
=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the BioStudio developers may
not be used to endorse or promote products derived from this software without
specific prior written permission.

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
