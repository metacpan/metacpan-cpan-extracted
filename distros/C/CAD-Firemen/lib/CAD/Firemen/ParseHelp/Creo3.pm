#!/usr/bin/perl
######################
#
#    Copyright (C) 2015 TU Clausthal, Institut fuer Maschinenwesen, Joachim Langenbach
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
# ABSTRACT: Shared functions to exctract options and their values, default value and descriptions (Creo 3 and later).

use strict;
use warnings;

package CAD::Firemen::ParseHelp::Creo3;
{
  $CAD::Firemen::ParseHelp::Creo3::VERSION = '0.7.2';
}
use Exporter 'import';
our @EXPORT_OK = qw(
  extractHelpCreo3
);

use POSIX;
use Tie::File;
use utf8;
use Term::ProgressBar;
use JSON::Parse 'parse_json';
use IO::HTML;
use HTML::TreeBuilder 5 -weak;
use File::Basename;
use CAD::Firemen;
use CAD::Firemen::Common qw(
  strip
  testPassed
  testFailed
);

sub findOptionPage {
  my $cdbOptions = shift;
  my $optionsInfo = shift;
  my $optionsValues = shift;
  my $optionsDefault = shift;
  my $errors = shift;
  my $file = shift;
  my $app = shift;
  my $verbose = shift;
  if(!defined($verbose)){
    $verbose = 0;
  }

  my @toc;
  if(!tie(@toc, 'Tie::File', $file, recsep => "\n")){
    return (0, "Could not open file to find option page: ". $file);
  }

  my ($fileName, $filePath, $fileSuffix) = fileparse($file);

  # just to avoid unused warning in release tests
  $fileName = undef;
  $fileSuffix = undef;

  my $lines = scalar(@toc);
  my $progress = Term::ProgressBar->new({name => "Parsing index file for app ". $app, count => $lines});
  $progress->minor(0);
  my $i = 0;
  my $json;
  foreach my $line (@toc){
    my $line = strip($line);
    if($i != 0 && substr($line, 0, 1) ne ";"){
      $json .= $line ."\n";
    }
    $i++;
    $progress->update($i);
  }
  if($i < $lines){
    $progress->update($lines);
  }
  print "\n";

  my $jsonContent = parse_json($json);
  if(!$jsonContent || !exists($jsonContent->{"words"}) || !exists($jsonContent->{"pages"})){
    return (0, "Could not parse content of ". $file);
  }

  my $items = scalar(keys(%{$jsonContent->{"words"}}));
  $progress = Term::ProgressBar->new({name => "Processing ". $items ." keywords and ". scalar(keys(@{$jsonContent->{"pages"}})) ." pages for app ". $app, count => $items});
  $progress->minor(0);
  $i = 0;
  foreach my $key (keys(%{$jsonContent->{"words"}})){
    foreach my $option (keys(%{$cdbOptions})){
      if(!exists($optionsInfo->{$option})){
        if($key =~ m/$option/i){
          if(scalar($jsonContent->{"words"}->{$key}) < 2){
            return (0, "Malformed index found --> Stopping here");
          }

          for(my $i = 0; $i < scalar(@{$jsonContent->{"words"}->{$key}}) - 1; $i = $i + 2){
            my $pagesRow = $jsonContent->{"words"}->{$key}->[$i];
            my $pagesColumn = $jsonContent->{"words"}->{$key}->[$i + 1] - 1;
            if($pagesColumn != 0){
              # skip all references, which does not reference the html page (first column in $pages
              next;
            }
            my $page = $jsonContent->{"pages"}->[$pagesRow]->[$pagesColumn];
            my $result=  extractHelp($cdbOptions, $optionsInfo, $optionsValues, $optionsDefault, $errors, $option, $filePath ."/". $page, $verbose);
            if($verbose > 2){
              if($result){
                print $option ." --> ". $page ." OK\n";
              }
              else{
                print $option ." --> ". $page ." - NOT FOUND\n";
              }
            }
          }
        }
      }
    }
    $i++;
    $progress->update($i);
  }
  if($i < $items){
    $progress->update($items);
  }
  print "\n";
  return $errors;
}

sub extractHelp {
  my $cdbOptions = shift;
  my $optionsInfo = shift;
  my $optionsValues = shift;
  my $optionsDefault = shift;
  my $errors = shift;
  my $option = uc(shift);
  my $file = shift;
  my $verbose = shift;
  if(!defined($verbose)){
    $verbose = 0;
  }

  my $optionLowered = lc($option);

  my @htmlContent;
  #if(!tie(@htmlContent, 'Tie::File', $file, recsep => "\x0D\x0A", discipline => ':encoding(utf8)')){
  if(!tie(@htmlContent, 'Tie::File', $file)){
    if(!exists($errors->{$option})){
      $errors->{$option} = "";
    }
    $errors->{$option} .= "Could not open HTML file ". $file;
    return 0;
  }
  my $htmlTree = HTML::TreeBuilder->new;
  if(!$htmlTree->parse_file(html_file($file))){
    if(!exists($errors->{$option})){
      $errors->{$option} = "";
    }
    $errors->{$option} .= "Could not open file ". $file;
    return 0;
  }

  my $optionFound = 0;
  my $regexSection = qr/<div class=\"Section_Title\" id=\"([^\"]+)\"><span class=\"option\">$optionLowered<\/span><\/div>/;
  my @sectionTitles = $htmlTree->look_down("_tag" => "div", "class" => "Section_Title");
  if(scalar(@sectionTitles) < 1 && $verbose > 2){
    print "Found no section titles in file ". $file ."\n";
  }
  foreach my $sectionTitle (@sectionTitles){
    if($sectionTitle->as_HTML() =~ m/$regexSection/){
      my $id = $1;
      $id =~ s/(.+)_[0-9]+/$1/;
      $optionFound = 1;

      my @bodies = $htmlTree->look_down("_tag" => "div", "id" => qr/$id[_0-9]+/);
      foreach my $body (@bodies){
        my @values = $body->as_HTML() =~ m/<span class=\"codeph\">([^>]+)<\/span>/g;
        if(scalar(@values) > 0){
          for(my $i = 0; $i < scalar(@values); $i++){
            $values[$i] = strip($values[$i]);
          }
          $optionsValues->{$option} = [ @values ];
          # check extracted values against those from cdb
          if(scalar($optionsValues->{$option}) == scalar(keys(%{$cdbOptions->{$option}}))){
            if(!exists($errors->{$option})){
              $errors->{$option} = "";
            }
            $errors->{$option} .= "Found different values for option ". $option ."(Expected: ". scalar(keys(%{$cdbOptions->{$option}})) .", Got: ". scalar($optionsValues->{$option}) .")";
          }
          if($body->as_HTML() =~ m/<span class=\"codeph\">([^>]+)<\/span><span class=\"Superscript\">\*<\/span>/){
            # match default option
            $optionsDefault->{$option} = uc(strip($1));
          }
        }
        else{
          if(!exists($optionsInfo->{$option})){
            $optionsInfo->{$option} = "";
          }
          $optionsInfo->{$option} .= " ". $body->as_text_trimmed();
          $optionsInfo->{$option} = strip($optionsInfo->{$option});
        }
      }
      last;
    }
  }
  if(!$optionFound){
    my @divs = $htmlTree->look_down("_tag" => "div");
    if(scalar(@divs) < 1 && $verbose > 2){
      print "Found no divs in file ". $file ."\n";
    }
    my $regexOption = qr/<span class=\"option\">$optionLowered<\/span>[\):\s]{0,}([^<]+)/;
    foreach my $div (@divs){
      if($div->as_HTML() =~ m/$regexOption/){
        $optionFound = 1;
        if(!exists($optionsInfo->{$option})){
          $optionsInfo->{$option} = "";
        }
        $optionsInfo->{$option} .= " ". $1;
        $optionsInfo->{$option} = strip($optionsInfo->{$option});
      }
    }
  }
  return $optionFound;
}

sub extractHelpCreo3 {
  my $directory = shift;
  my $language = shift;
  my $cdbOptions = shift;
  my $verbose = shift;
  my %optionsInfo = ();
  my %optionsValues = ();
  my %optionsDefault = ();
  my %errors = ();

  if(!-d $directory){
    testFailed("Examine help structure");
    if($verbose > 0){
      print "Directory does not exist: ". $directory ."\n";
    }
    return ({}, {}, {}, {});
  }
  $directory =~ s/[\/\\]+$//;
  my $dir;
  if(!opendir($dir, $directory)){
    testFailed("Examine help structure");
    if($verbose > 0){
      print "Could not open directory: ". $directory ."\n";
    }
    return ({}, {}, {}, {});
  }
  while(my $entry = readdir($dir)){
    if($entry !~ m/^\./){
      my $subDir = $directory ."/". $entry;
      if(-d $subDir){
        my @tmp = split(/_/, $entry);
        if(scalar(@tmp) < 1){
          if($verbose > 1){
            print "Error determining app of directory entry ". $entry ."\n";
            exit 1;
          }
        }
        my $app = $tmp[scalar(@tmp) - 1];
        my $file = $subDir ."/". $language ."/". $app ."_sx.js";
        if(!-f $file){
          if($verbose > 1){
            print "Index file does not exists: ". $file ."\n";
          }
          exit 1;
        }
        my $errors = findOptionPage($cdbOptions, \%optionsInfo, \%optionsValues, \%optionsDefault, \%errors, $file, $app, $verbose);
        if(scalar(keys(%{$errors})) > 0){
          if($verbose > 1){
            print "The following errors occured parsing directory ". $subDir .":\n";
            foreach my $option (sort(keys(%{$errors}))){
              print "  ". $option .": ". $errors->{$option} ."\n";
            }
          }
        }
      }
    }
  }
  closedir($dir);
  return (\%optionsInfo, \%optionsValues, \%optionsDefault, \%errors);
}

1;

__END__

=pod

=head1 NAME

CAD::Firemen::ParseHelp::Creo3 - Shared functions to exctract options and their values, default value and descriptions (Creo 3 and later).

=head1 VERSION

version 0.7.2

=head1 METHODS

=head2 findOptionPage

 Parses the option index file (parameter 2) and tries to find
 the related page (html file) for given option (parameter 1)

=head2 extractHelp

 Tries to extract the help for option (parameter 1) from file (parameter 2)

=head2 extractHelpCreo3

 Walks through the help directories (root is in parameter 1) of creo 3 and tries to extract all information about options in cdbOptions (parameter 3).

=head1 AUTHOR

Joachim Langenbach <langenbach@imw.tu-clausthal.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by TU Clausthal, Institut fuer Maschinenwesen.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
