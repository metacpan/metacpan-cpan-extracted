#!/usr/bin/env perl

use Bio::BioStudio;
use Bio::BioStudio::Diff;
use English qw(-no_match_vars);
use Getopt::Long;
use Pod::Usage;
use CGI qw(:all);

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_ChromosomeDiff_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %CHANGES = (
  1  => 'LOST FEATURES',
  2  => 'ADDED FEATURES',
  3  => 'LOST SUBFEATURES',
  4  => 'GAINED SUBFEATURES',
  5  => 'LOST SEQUENCE',
  6  => 'GAINED SEQUENCES',
  7  => 'CHANGES IN TRANSLATION',
  8  => 'CHANGES IN SEQUENCE',
  9  => 'LOST ATTRIBUTES',
  10 => 'GAINED ATTRIBUTES',
  11 => 'CHANGES IN ANNOTATIONS',
  12 => 'CHANGES TO SUBFEATURES',
  13 => 'COMMENTS',
);

my %p;
GetOptions (
	'FIRST=s'       => \$p{FIRST},
	'SECOND=s'      => \$p{SECOND},
	'OUTPUT=s'      => \$p{OUTPUT},
	'PTRANSLATION'  => \$p{TRX},
	'NSEQUENCE'     => \$p{SEQ},
	'NALIGN'        => \$p{ALN},
	'PALIGN'        => \$p{TRXLN},
	'GROUP=s'       => \$p{GROUP},
	'help'          => \$p{HELP},
);
pod2usage(-verbose=>99) if ($p{HELP});

################################################################################
################################# SANITY CHECK #################################
################################################################################
my $BS = Bio::BioStudio->new();

die "\tBSERROR: No original was named."  if (! $p{FIRST});
my $oldchr = $BS->set_chromosome(-chromosome => $p{FIRST});
my $oldchrseq = $oldchr->sequence;
my $oldchrlen = length $oldchrseq;

die "\tBSERROR: No variant was named."  if (! $p{SECOND});
my $newchr = $BS->set_chromosome(-chromosome => $p{SECOND});
my $newchrseq = $newchr->sequence;
my $newchrlen = length $newchrseq;

if ($p{FIRST} eq $p{SECOND})
{
  die "\n ERROR: There are no differences to display; you only selected "
       . 'a single chromosome version.';
}

if ($oldchr->species() ne $newchr->species())
{
  die "\tBSERROR: There are no differences to display; you selected "
      . 'chromosomes from two different species.';
}
if ($oldchr->chromosome_id() ne $newchr->chromosome_id())
{
  die "\tBSERROR: There are no differences to display; you selected two "
       . 'different chromosomes, as opposed to two versions of a single '
       . 'chromosome.';
}

$p{OUTPUT}  = $p{OUTPUT}  || 'txt';

$p{GROUP}   = $p{GROUP}   || 'feature';
if ($p{GROUP} ne 'feature' && $p{GROUP} ne 'type')
{
  die "\n ERROR: Group parameter must be either 'feature' or 'type'.";
}

################################################################################
################################# CONFIGURING ##################################
################################################################################
my @output;
my @summary;

################################################################################
################################## COMPARING ###################################
################################################################################
print "In going from $p{FIRST} to $p{SECOND}:\n\n";

my $factory = Bio::BioStudio::Diff->new(
  -oldchr           => $oldchr,
  -newchr           => $newchr,
  -checktranslation => $p{TRX},
  -aligntranslation => $p{TRXLN},
  -checksequence    => $p{SEQ},
  -alignsequence    => $p{ALN},
);

my %DIFF;
my $y = 0;
my @DIFFS = $factory->compare_dbs();

#Correct base counts and load into hash
foreach (@DIFFS)
{
  if ($_->code == 1 || $_->code == 2)
  {
    my $feat = $_->feature;
    my $flag = 0;
    $flag++ if ($feat->primary_tag eq 'restriction_enzyme_recognition_site');
    $flag++ if ($feat->primary_tag eq 'enzyme_recognition_site');
    $flag++ if ($feat->primary_tag eq 'PCR_product');
    $flag++ if ($feat->primary_tag eq 'megachunk');
    $flag++ if ($feat->primary_tag eq 'deletion');
    $flag++ if ($feat->primary_tag eq 'chunk');
    $flag++ if ($feat->has_tag('newseq'));
    $_->baseloss(0) if ($flag && $_->code == 1);
    $_->basegain(0) if ($flag && $_->code == 2);
  }
  $DIFF{$y} = $_;
  $y++;
}

my %types = map {$_->code() => 2} @DIFFS;
my %featids = map {$_->id() => 2} @DIFFS;

my $x = 0;

if ($p{GROUP} eq 'type')
{
  foreach my $changetype (keys %types)
  {
    my @foundchanges = grep { $_->code() == $changetype } @DIFFS;
    my $header = scalar(@foundchanges) . q{ } . $CHANGES{$changetype};
    if ($p{OUTPUT} eq 'html')
    {
      my @tablerows = map {td() . $_->htmlline} @foundchanges;
      my $headanchor = "<a name=\"$x\">$header</a>";
      push @summary, "<a href=\"\#$x\">$header</a><br>";
      unshift @tablerows, th({-colspan => 2}, $headanchor) . td('+bp')
                . td('-bp') . td('&#916bp');
      push @output, table({-border=>1, -width=>'90%', -align=>'CENTER'},
                        TR({-align=>'LEFT', -valign=>'TOP'}, \@tablerows));
    }
    else
    {
      push @summary, $header . "\n";
      push @output, $header . "\t\t+bp\t-bp\t∆bp\n";
      push @output,  map {"\t" . $_->textline} @foundchanges;
    }
    push @output, "\n\n";
    $x++;
  }
}

elsif ($p{GROUP} eq 'feature')
{
  foreach my $changefeat (keys %featids)
  {
    my @fkeys = grep { $DIFF{$_}->id() eq $changefeat && $DIFF{$_}->code() > 2}
                keys %DIFF;
    next if (! scalar @fkeys);
    my $geneflag = 0;
    foreach my $key (@fkeys)
    {
      my $feat = $DIFF{$key}->feature();
      $geneflag = 1 if ($feat->primary_tag eq 'gene');
    }
    my @pakeys = grep {$DIFF{$_}->code() <= 2} keys %DIFF;
    my @akeys;
    foreach my $key (@pakeys)
    {
      my $feat = $DIFF{$key}->feature();
      if ($feat->has_tag('ingene') && $feat->Tag_ingene eq $changefeat)
      {
        push @akeys, $key;
      }
      elsif ($feat->has_tag('aimed_at') && $feat->Tag_aimed_at eq $changefeat)
      {
        push @akeys, $key;
      }
    }
    unshift @fkeys, @akeys;
    my ($alladd, $allloss, $allchange) = (0, 0, 0);
    my @foundchanges;
    foreach my $change (map {$DIFF{$_}} @fkeys)
    {
      push @foundchanges, $change;
      $alladd += $change->basegain();
      $allloss += $change->baseloss();
      $allchange += $change->basechange();
    }
    if ($geneflag == 1)
    {
      $allloss = $allloss /2;
      $allchange = $allchange / 3;
    }
    delete $DIFF{$_} foreach @fkeys;
    my $ext = scalar @foundchanges > 1 ? 's' : q{};
    my $header = scalar @foundchanges . " change$ext to $changefeat";
    if ($p{OUTPUT} eq 'html')
    {
      my @tablerows = map {td() . $_->htmlline} @foundchanges;
      my $headanchor = "<a name=\"$x\">$header</a>";
      push @summary, "<a href=\"\#$x\">$header</a><br>";
      unshift @tablerows, th({-colspan => 2}, $headanchor)
                        . td('+bp') . td('-bp') . td('&#916bp')
                        . td({-colspan =>3});
      push @tablerows, th({-colspan => 5}, q{}) . td($alladd) . td($allloss)
                        .td($allchange);
      push @output, table({-border=>1, -width=>'90%', -align=>'CENTER'},
                        TR({-align=>'LEFT', -valign=>'TOP'}, \@tablerows));
    }
    else
    {
      push @summary, $header . "\n";
      push @output, $header . "\t\t+bp\t-bp\t∆bp\n";
      push @output,  map {"\t" . $_->textline} @foundchanges;
      push @output, "\t\t\t\t\t$alladd\t$allloss\t$allchange\n";
    }
    push @output, "\n\n";
    $x++;
  }
  foreach my $changetype (1, 2)
  {
    my ($alladd, $allloss, $allchange) = (0, 0, 0);
    my @fkeys = grep { $DIFF{$_}->code() == $changetype} keys %DIFF;
    next if (! scalar @fkeys);
    my @foundchanges;
    foreach my $change (map {$DIFF{$_}} @fkeys)
    {
      push @foundchanges, $change;
      $alladd += $change->basegain();
      $allloss += $change->baseloss();
      $allchange += $change->basechange();
    }
    my $header = scalar(@foundchanges) . q{ } . $CHANGES{$changetype};
    if ($p{OUTPUT} eq 'html')
    {
      my @tablerows = map {td() . $_->htmlline} @foundchanges;
      my $headanchor = "<a name=\"$x\">$header</a>";
      push @summary, "<a href=\"\#$x\">$header</a><br>";
      unshift @tablerows, th({-colspan => 2}, $headanchor) . td('+bp')
              . td('-bp') . td('&#916bp'). td({-colspan =>3});
      push @tablerows, th({-colspan => 5}, q{}) . td($alladd) . td($allloss)
                .td($allchange);
      push @output, table({-border=>1, -width=>'90%', -align=>'CENTER'},
                        TR({-align=>'LEFT', -valign=>'TOP'}, \@tablerows));
    }
    else
    {
      push @summary, $header . "\n";
      push @output, $header . "\t\t+bp\t-bp\t∆bp\n";
      push @output,  map {"\t" . $_->textline} @foundchanges;
    }
    push @output, "\n\n";
    $x++;
  }

}

#Version annotation
if ($p{OUTPUT} eq 'html')
{
  push @summary, "<a href=\"\#$x\">Diff of Comments</a><br>";
  my $topper  = "<a name = \"$x\">Diff</a> of annotation comments ";
     $topper .= "from $p{FIRST} to $p{SECOND}:<br>\n";
  push @output, $topper;
}
else
{
  push @summary, "Diff of Comments\n";
  push @output,  "Diff of annotation comments from $p{FIRST} to $p{SECOND}:\n";
}
my @diffresults = $factory->compare_comments();
push @output, @diffresults;

print "Summary:\n";
print "$_" foreach (@summary);
print "\n\n";
print "Results:\n";
print "@output";
print "\n\n";

exit;

__END__

=head1 NAME

  BS_ChromosomeDiff.pl

=head1 VERSION

  Version 1.01

=head1 DESCRIPTION

  This utility takes two versions of a chromosome and lists the differences
   between them. It will take note of added or deleted features, the addition or
   loss of subfeatures, changes in ORF translation, changes in feature sequence,
   and changes in annotation.

=head1 ARGUMENTS

Required arguments:

  -F   --FIRST   : the 'original' chromosome
  -S   --SECOND  : the 'variant' chromosome

Optional arguments:

  -PT,   --PTRANSLATION : check ORF translations
  -PA,   --PALIGN : make alignments for features with translation differences
  -NS,   --NSEQUENCE : check nucleotide sequence differences
  -NA,   --NALIGN : make alignments for features with nucleotide changes
  -G,    --GROUP : sort results by 'feature' (default) or by change 'type'
  -O,    --OUTPUT : html or defaults to txt
  -h,    --help : Display this message

=cut
