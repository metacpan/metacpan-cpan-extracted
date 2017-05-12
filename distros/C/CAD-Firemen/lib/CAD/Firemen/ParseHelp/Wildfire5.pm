#!/usr/bin/perl
######################
#
#    Copyright (C) 2011 - 2015 TU Clausthal, Institut fuer Maschinenwesen, Joachim Langenbach
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
######################

# Pod::Weaver infos
# PODNAME: fm_create_help
# ABSTRACT: Walks through an installation and tries to extract all options with informations into a database

use strict;
use warnings;

package CAD::Firemen::ParseHelp::Wildfire5;
{
  $CAD::Firemen::ParseHelp::Wildfire5::VERSION = '0.7.2';
}
use Exporter 'import';
our @EXPORT_OK = qw(
  extractHelpWildfire5
);

use POSIX;
use Archive::Zip qw/ :ERROR_CODES :CONSTANTS/;
use HTML::TreeBuilder;
use IO::HTML;
use XML::LibXML;
use Tie::File;
use Term::ProgressBar;
use CAD::Firemen;
use CAD::Firemen::Common qw(
  strip
  testPassed
  testFailed
);

sub getChildDivs {
  my $parent = shift;
  my @results = ();

  if(!defined($parent) || (ref($parent) ne "HTML::Element")){
    return @results;
  }

  foreach my $elem ($parent->content_list()){
    if(ref($elem) ne "HTML::Element"){
      next;
    }
    if($elem->tag() eq "div"){
      push(@results, $elem);
    }
  }
  return @results;
}

sub extractHelpWildfire5 {
  my $tocUrl = shift;
  my $language = shift;
  my $cdbOptionsRef = shift;
  my %cdbOptions = %{$cdbOptionsRef};
  my $verbose = shift;
  my $zipUrl = shift;

  # just to avoid unused warning in release tests
  $language = undef;

  my %optionsInfo = ();
  my %optionsValue = ();
  my %optionsDefault = ();

  my $zip = undef;
  if(-e $zipUrl){
    # catch file not exists error before Zip->new(), because Zip->new() gives ugly error messages
    $zip = Archive::Zip->new($zipUrl);
    if(!defined($zip)){
      testFailed("Load help archive");
      return ({}, {}, {}, {});
    }
    else{
      testPassed("Load help archive");
    }
  }


  my @toc;
  if(tie(@toc, 'Tie::File', $tocUrl)){
    testPassed("Open TOC");
    # the linebreak is needed to uncolor Term::ProgressBar
    print "\n";
  }
  else{
    testFailed("Open TOC");
    if($verbose > 0){
      print "TOC Url: ". $tocUrl ."\n";
    }
    return ({}, {}, {}, {});
  }
  # enabling autoflush to print parse status
  my $lines = scalar(@toc);
  my $progress = Term::ProgressBar->new({name => "Collecting infos", count => $lines});
  $progress->minor(0);
  my $i = 0;
  my %errors = ();
  foreach my $line (@toc){
    my $line = strip($line);#
    if($line =~ m/label=\"([^\"]+)\" path=\"([^(?:\"|#)]+)/){
      my $opt = uc($1);
      my $file = $2;
      # exclude directories, only file paths are used here
      if($file =~ m/\/$/){
        next;
      }
      # some options exists several times, therefore only use the first entry found
      # (Last condition)
      if(exists($cdbOptions{$opt}) && ($file ne "") && (!exists($optionsInfo{$opt}))){
        # option found and file path also not empty
        my $htmlTree = HTML::TreeBuilder->new();
        if(defined($zip)){
          my $content = $zip->contents($file);
          if(!$content){
            $errors{$opt} = "Could not extract file ". $file;
            next;
          }
          if(utf8::is_utf8($content)){
            $content = utf8::decode($content);
          }
          $htmlTree->parse($content);
        }
        else{
          next;
        }

        # do some cleanup on the tree
        $htmlTree->eof();

        # first check whether we've got the correct file with help of title
        my $element = $htmlTree->find('title');
        if(!$element){
          $errors{$opt} = "Could not find <title>";
          next;
        }
        my @contents = $element->content_refs_list();
        my $title = uc(${$contents[0]});
        if($title ne $opt){
          $errors{$opt} = "Title are not matching (Expected: ". $opt .", Got: ". $title .")";
          next;
        }

        $element = $htmlTree->look_down("_tag", "div");
        my @elements = getChildDivs($element);
        if(scalar(@elements) != 2){
          if(scalar(@elements) == 3){
            # fixing those with empty second div
            if($elements[1]->as_trimmed_text() eq ""){
              $elements[1] = $elements[2];
              pop(@elements);
            }
            else{
              $errors{$opt} = "Second div-container of three within the first div container is not empty.";
              next;
            }
          }
          else{
            $errors{$opt} = "Wrong number of div-containers within the first div container (Expected: 2, Got: ". scalar(@elements) .")";
            next;
          }
        }
        # the first div container contains the option name and the second
        # contains the values and the description
        @elements = getChildDivs($elements[1]);
        if(scalar(@elements) < 1){
          $errors{$opt} = "Wrong number of div-containers within the second div container (Expected: >=1, Got: ". scalar(@elements) .")";
          next;
        }

        # get values
        my @values = ();
        # the text of the options div (like ansi * , iso)
        my $text = $elements[0]->as_trimmed_text();
        my @tmp = split(/,/, $text);
        foreach my $value (@tmp){
          # if we have replaced a *, this is the default value,
          # because only the default value contains a star
          if($value =~ s/\*//){
            $optionsDefault{$opt} = uc(strip($value));
          }
          $value = uc(strip($value));
          push(@values, $value);
        }
        $optionsValue{$opt} = [ @values ];
        # check extracted values against those from cdb
        if(scalar($optionsValue{$opt}) == scalar(keys(%{$cdbOptions{$opt}}))){
          $errors{$opt} = "Found different values for option ". $opt ."(Expected: ". scalar(keys(%{$cdbOptions{$opt}})) .", Got: ". scalar($optionsValue{$opt}) .")";
        }

        # get info (all div after the values div, contains description
        $optionsInfo{$opt} = "";
        for(my $j = 1; $j < scalar(@elements); $j++){
          $optionsInfo{$opt} .= $elements[$j]->as_trimmed_text() ."\n";
        }
        # remove last linebreak
        $optionsInfo{$opt} = strip($optionsInfo{$opt});
        # remove wide characters
        $optionsInfo{$opt} =~ s/[^[:ascii:]]+//g;
        $htmlTree->delete();
      }
    }
    $i++;
    $progress->update($i);
  }
  if($i < $lines){
    $progress->update($lines);
  }
  print "\n"; # print line break to keep the progress bar of the last step
  untie @toc;
  return (\%optionsInfo, \%optionsValue, \%optionsDefault, \%errors);
}

1;

__END__

=pod

=head1 NAME

fm_create_help - Walks through an installation and tries to extract all options with informations into a database

=head1 VERSION

version 0.7.2

=head1 METHODS

=head2 getChildDivs

 Helper function to parse the help html page (extracts div containers from the HTML File

=head2 extractHelpWildfire5

 Walks through the help table of contents (parameter 1) of Wildfire 5 to Creo 2 help and tries to extract all information about options in cdbOptions (parameter 3).

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
