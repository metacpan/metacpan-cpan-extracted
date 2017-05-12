#
# BioStudio module for Foswiki interaction
#

=head1 NAME

Bio::BioStudio::Foswiki

=head1 VERSION

Version 1.06

=head1 DESCRIPTION

BioStudio functions for Foswiki interaction

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Foswiki;

require Exporter;

use Time::Format qw(%time);
use Carp;
use English qw(-no_match_vars);

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '1.06';

our @EXPORT_OK = qw(
  make_new_topic
  make_new_web
  update_wiki
  wiki_edit_prep
  wiki_update_feature
  wiki_add_feature
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 Functions

=head2 wiki_edit_prep

=cut

sub wiki_edit_prep
{
  my ($pa, $BS, $featlist) = @_;
  $pa->{AUTHSTR} = "-- [[Main." . $BS->{wiki_user} . "]] - ";
  $pa->{AUTHSTR} .= $time{'dd Mon yyyy'} . "<br>";
  $pa->{SPWEBPATH} = $BS->{wiki_data} . "BioStudio_" . $pa->{SPECIES};
  $pa->{CHRPATH} = $pa->{SPWEBPATH} . q{/} . "Chromosome" . $pa->{CHRNAME};
  $pa->{PARENTS} = {};
  foreach my $feattype (@{$featlist})
  {
    my $name = $feattype . q{s};
    substr $name, 0, 1, (uc substr($name, 0, 1));
    my $path = $pa->{CHRPATH} . q{/} . $name . ".txt";
    make_new_topic($path, "Features", 1, [], $BS) unless (-e $path);
    $pa->{PARENTS}->{$feattype} = $name;
  }
  $pa->{WIKICOMMENTS} = [];
  return;
}

=head2 wiki_add_feature

=cut

sub wiki_add_feature
{
  my ($pa, $BS, $feat, $buds) = @_;
  my $path = $pa->{CHRPATH} . q{/} . $feat->Tag_load_id . ".txt";
  my @arr = ($pa->{AUTHSTR});
  if ($BS->{enable_gbrowse})
  {
    my $text = "See this feature in GBrowse ($pa->{NEWCHROMOSOME})";
    push @arr, make_link($feat, $text, $pa, $BS) . "<br>";
  }
  foreach my $att ($feat->get_all_tags())
  {
    next if $att eq "load_id";
    push @arr, "$att: " . join(", ", $feat->get_tag_values($att)) . "<br>";
  }
  foreach my $bud (%{$buds})
  {
    push @arr, "$bud: [[" . $buds->{$bud}->Tag_load_id . "]]<br>";
  }
  my $type = $feat->primary_tag();
  make_new_topic($path, $pa->{PARENTS}->{$type}, 0, \@arr, $BS);
  return;
}

=head2 wiki_update_feature

=cut

sub wiki_update_feature
{
  my ($pa, $BS, $feat, $add, $flag1, $note, $flag2) = @_;
  my $path = $pa->{CHRPATH} . q{/} . $feat->Tag_load_id . ".txt";
  my $text = $flag2 
            ? "See this feature in GBrowse ($pa->{OLDCHROMOSOME})"
            : "See this feature in GBrowse ($pa->{NEWCHROMOSOME})";
  open (my $WH, '>>', "$path") || croak ("CAN'T WORK ON WIKI!");
  if ($flag1)
  {
    print $WH "\n" . $pa->{AUTHSTR};
    if ($BS->{enable_gbrowse})
    {
      print $WH make_link($feat, $text, $pa, $BS);
    }
    print $WH "\n$note" if ($note);
  }
  print $WH "$add" if ($add);
  close $WH;
  return;
}

=head2 update_wiki

=cut

sub update_wiki
{
  my ($BS, $pa, $commentarr) = @_;
  my $VERPATH = $pa->{CHRPATH} . "/$pa->{NEWCHROMOSOME}.txt";
  my @arr = @{$commentarr};
  if ($BS->{enable_gbrowse})
  {
    my $verlink = "http://$BS->{this_server}/cgi-bin/gb2/gbrowse/$pa->{NEWCHROMOSOME}";
    my $href = "<a href=\"$verlink\" target=\"_blank\" style=\"text-decoration:none\">See this version in GBrowse</a>\n";
    unshift @arr, $href;
  }
  unshift @arr, "-- [[Main." . $BS->{wiki_user} . "]] - " . $time{'dd Mon yyyy'} . "\n";
  make_new_topic($VERPATH, "Versions", 0, \@arr, $BS);
  return;
}

=head2 make_new_web

=cut

sub make_new_web
{
  my ($webpath, $linkreplace, $BS) = @_;
  my $now = time;
  my $template = $BS->{wiki_default_web} . q{/};
  $linkreplace = q{} unless $linkreplace;
  my $repl = q{/} . $BS->{wiki_placeholder} . q{/} . $linkreplace . q{/};
  mkdir $webpath;
  system "cp -R $template $webpath";
  opendir(WEB, $webpath);
  my @FILES= readdir(WEB);
  closedir(WEB);
  my $auth = "/ProjectContributor/$BS->{wiki_user}/";
  my $time = "/date=\".+\"/date=\"$now\"/";
	foreach my $name (grep {! -d && $_ !~ m{\A\.}msx} @FILES)
	{
	  my $path = $webpath . q{/} . $name;
	  my $temp = $path . "_tmp";
		system ("sed -e 's$auth' $path >$temp && mv $temp $path");
		system ("sed -e 's$time' $path >$temp && mv $temp $path");
		if ($name eq "WebHome.txt")
		{
		  system ("sed -e 's$repl' $path >$temp && mv $temp $path");
		}
  }
  return;
}

=head2 make_new_topic

=cut

sub make_new_topic
{
  my ($path, $parent, $flag, $arrref, $BS) = @_;
  my $now = time;
  open (my $TOPIC, '>', "$path") || croak ("Can't open $path: $OS_ERROR");
  print $TOPIC "\%META:TOPICINFO{author=\"$BS->{wiki_user}\" comment=\"\"";
  print $TOPIC " date=\"$now\" format=\"1.1\" version=\"1\"}\%\n";
  print $TOPIC "\%META:TOPICPARENT{name=\"$parent\"}\%\n";
  if ($flag)
  {
    print $TOPIC "Subtopics:<br> \%SEARCH{\"parent.name='%TOPIC%'\" ";
    print $TOPIC "type=\"query\" nonoise=\"on\" format=\"[[\$topic]]\" ";
    print $TOPIC "separator=\"<br>\" }\%\n";
  }
  print $TOPIC @{$arrref} if ($arrref);
  close $TOPIC;
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