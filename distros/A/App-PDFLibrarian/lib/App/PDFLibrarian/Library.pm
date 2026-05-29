# Copyright (C) 2016--2026 Karl Wette
#
# This file is part of App::PDFLibrarian.
#
# App::PDFLibrarian is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# App::PDFLibrarian is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with App::PDFLibrarian. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

package App::PDFLibrarian::Library;
$App::PDFLibrarian::Library::VERSION = '6.0.2';
use parent 'Exporter';

use Carp;
use File::Copy;
use File::Find;
use File::Path;
use File::Spec;
use File::stat;
use FindBin qw($Script);
use Text::Unidecode;

use App::PDFLibrarian qw($pdflibrarydir);
use App::PDFLibrarian::BibTeX qw(bib_checksum format_bib_authors);
use App::PDFLibrarian::Util qw(is_in_dir remove_tex_markup remove_tex_markup_undef remove_short_words);

our @EXPORT_OK = qw(pdf_is_in_library update_pdf_lib make_pdf_links cleanup_links);

1;

sub pdf_is_in_library {
  my ($pdffile) = @_;

  # return whether PDF file is already in library
  return is_in_dir("$pdflibrarydir/Files", $pdffile);

}

sub update_pdf_lib {
  my (@bibentries) = @_;
  return unless @bibentries > 0;

  # add PDF files in BibTeX entries to PDF library
  my $newbibentries = 0;
  foreach my $bibentry (@bibentries) {

    # get name of PDF file
    my $pdffile = $bibentry->get('file');

    # record which PDF files are new to the library
    ++$newbibentries unless pdf_is_in_library($pdffile);

    # create name of PDF file in library:
    # - organise PDF files under '$pdflibrarydir/Files', then first uppercase character of key
    # - name PDF files after key with '.pdf' extension
    my $key = $bibentry->key;
    my $pdflibdir = File::Spec->catdir($pdflibrarydir, "Files", uc(substr($key, 0, 1)));
    my $pdflibfile = File::Spec->catfile($pdflibdir, "$key.pdf");

    # ensure directory for PDF file exists
    File::Path::make_path($pdflibdir);

    # move PDF file into library, including if library PDF filename has changed
    if ($pdffile ne $pdflibfile) {
      move($pdffile, $pdflibfile) or croak "$Script: could not move '$pdffile' to '$pdflibfile': $!";
      $pdffile = $pdflibfile;
    }

    # record new PDF filename
    $bibentry->set('file', $pdflibfile);

  }
  printf STDERR "$Script: added %i PDF files to '$pdflibrarydir/Files'\n", $newbibentries if $newbibentries > 0;

}

sub make_pdf_links {
  my (@bibentries) = @_;
  return unless @bibentries > 0;

  # find existing links
  my %existinglinks;
  {
    my $wanted = sub {
      if (-l $_) {
        my $pdffile = readlink($_);
        $existinglinks{$pdffile}->{$_} = 1 if defined($pdffile);
      }
    };
    find({wanted => \&$wanted, bydepth => 1, no_chdir => 1}, $pdflibrarydir);
  }

  # make symbolic links in PDF links directory to real PDF files
  my $count = 0;
  foreach my $bibentry (@bibentries) {

    # get name of PDF file
    my $pdffile = $bibentry->get('file');

    # get key from PDF filename
    my $key;
    {
      my ($vol, $dir, $file) = File::Spec->splitpath($pdffile);
      $key = $file;
      $key =~ s/\.pdf$//;
    }

    # format and abbreviate title
    my $title = remove_tex_markup_undef($bibentry->get("title")) // "!NO-TITLE!";
    $title = join(' ', map { ucfirst($_) } remove_short_words(split(/\s+/, $title)));

    # make PDF link names; should be unique within library
    my %pdflinkby;
    {

      # format authors, editors, and collaborations
      my @authors = format_bib_authors("vl", 2, "et al", $bibentry->names("author"));
      my @editors = format_bib_authors("vl", 2, "et al", $bibentry->names("editor"));
      my @collaborations = format_bib_authors("vl", 2, "et al", $bibentry->names("collaboration"));

      # first non-empty of authoring collaborations, individual authors, and/or editors
      my $authorstr = "@collaborations";
      $authorstr = "@authors" unless length($authorstr) > 0;
      $authorstr = "@editors ed" unless length($authorstr) > 0;
      $authorstr = "!NO-AUTHOR!" unless length($authorstr) > 0;

      # title, plus volume number (if any) for books and proceedings
      my $titlestr = $title;
      $titlestr .= " vol" . $bibentry->get("volume") if (grep { $bibentry->type eq $_ } qw(book inbook proceedings)) && $bibentry->exists("volume");

      # year
      my $yearstr .= " " . $bibentry->get("year");

      # link name by author
      $pdflinkby{Author} = "$authorstr $yearstr $titlestr";

      # link name by title
      $pdflinkby{Title} = "$titlestr $authorstr $yearstr";

      # link name by year
      $pdflinkby{Year} = "$yearstr $authorstr $titlestr";

    }

    # list of symbolic links to make
    my @links;

    # make links by DOI
    if ($bibentry->exists('doi')) {
      my @doidirs = grep(/./, File::Spec->splitdir($bibentry->get('doi')));
      push @links, ["DOIs", @doidirs];
    }

    # make links by all listed collaborations, authors, and editors
    {

      # format authors, editors, and collaborations
      my @authors = format_bib_authors("vl", undef, "", $bibentry->names("author"));
      my @editors = format_bib_authors("vl", undef, "", $bibentry->names("editor"));
      my @collaborations = format_bib_authors("vl", undef, "", $bibentry->names("collaboration"));

      # make links
      foreach my $by (qw(Year Title)) {
        foreach my $author (@collaborations, @authors) {
          next if $author eq "";
          push @links, ["Authors", $author, "${by}s", "$pdflinkby{$by}"];
        }
        foreach my $editor (@editors) {
          next if $editor eq "";
          push @links, ["Authors", "$editor ed", "${by}s", "$pdflinkby{$by}"];
        }
      }

    }

    # make links by first word of title
    my $firstword = ucfirst($title);
    $firstword =~ s/\s.*$//;
    foreach my $by (qw(Author Year)) {
      push @links, ["Titles", $firstword, "${by}s", "$pdflinkby{$by}"];
    }

    # make links by year
    foreach my $by (qw(Author Title)) {
      my $year = $bibentry->get("year") // "!NO-YEAR!";
      push @links, ["Years", $year, "${by}s", "$pdflinkby{$by}"];
    }

    # make links by keyword(s)
    my %keywords;
    foreach (split /[,;]/, $bibentry->get("keyword")) {
      next if /^\s*$/;
      $keywords{$_} = 1;
    }
    if (keys %keywords == 0) {
      $keywords{"!NO-KEYWORDS!"} = 1;
    }
    foreach my $keyword (keys %keywords) {
      my @subkeywords = split /:|(?: - )/, $keyword;
      s/\b(\w)/\U$1\E/g for @subkeywords;
      foreach my $by (qw(Author Title Year)) {
        push @links, ["Keywords", @subkeywords, "${by}s", "$pdflinkby{$by}"];
      }
    }

    # make links by pre-print server
    if ($bibentry->exists('archiveprefix')) {
      my $archiveprefix = $bibentry->get('archiveprefix');
      my $eprint = "!NO-EPRINT!";
      my $eprintprefix = $eprint;
      if ($bibentry->exists('eprint')) {
        $eprint = $bibentry->get('eprint');
        $eprintprefix = $eprint;
        $eprintprefix =~ s/[^\d]//g;
        $eprintprefix = substr($eprintprefix, 0, 2);
      }
      push @links, ["Pre Prints", "$archiveprefix", "$eprintprefix", "$eprint $pdflinkby{Author}"];
    }

    if (grep { $bibentry->type eq $_ } qw(article)) {

      # make links to articles by journal
      my $journal = remove_tex_markup_undef($bibentry->get("journal")) // "!NO-JOURNAL!";
      my $archiveprefix = $bibentry->get('archiveprefix') // "";
      my ($volume, $pages);
      if ( $journal eq $archiveprefix ) {

        # extract volume/pages from pre-print number
        my $eprint = $bibentry->get('eprint') // "!NO-EPRINT!";
        if ($eprint =~ /^(\d+)[.](.*)$/ || $eprint =~ /^(.{2})(.*)$/) {
          $volume = $1;
          $pages = $2;
        } else {
          $volume = "!NO-VOLUME!";
          $pages = "!NO-PAGES!";
        }

      } else {
        $volume = $bibentry->get("volume") // "!NO-VOLUME!";
        $pages = $bibentry->get("pages") // "!NO-PAGES!";
      }
      push @links, ["Journals", "$journal", "v$volume", "p$pages $pdflinkby{Author}"];

    } elsif (grep { $bibentry->type eq $_ } qw(techreport)) {

      # make links to technical reports by institution
      my $institution = remove_tex_markup_undef($bibentry->get("institution")) // "!NO-INSTITUTION!";
      my $number = "!NO-NUMBER!";
      my $numberprefix = $number;
      if ($bibentry->exists('number')) {
        $number = $bibentry->get('number');
        $numberprefix = $number;
        $numberprefix =~ s/[^\d]//g;
        $numberprefix = substr($numberprefix, 0, 2);
      }
      push @links, ["Tech Reports", "$institution", "$numberprefix", "$number $pdflinkby{Author}"];

    } elsif (grep { $bibentry->type eq $_ } qw(book inbook proceedings)) {

      # make links to books and (whole) proceedings
      push @links, ["Books", "$pdflinkby{Author}"];

    } elsif (grep { $bibentry->type eq $_ } qw(conference incollection inproceedings)) {

      # make links to articles in collections and proceedings
      my $booktitle = remove_tex_markup_undef($bibentry->get("booktitle")) // "!NO-BOOKTITLE!";
      my $pages = $bibentry->get("pages") // "!NO-PAGES!";
      $booktitle = join(' ', map { ucfirst($_) } remove_short_words(split(/\s+/, $booktitle)));
      push @links, ["In", $booktitle, "p$pages $pdflinkby{Author}"];
      if ($bibentry->exists("series")) {
        my $series = remove_tex_markup($bibentry->get("series"));
        my $volume = $bibentry->get("volume") // "!NO-VOLUME!";
        push @links, ["In", "$series", "v$volume", "p$pages $pdflinkby{Author}"];
      }

    } elsif (grep { $bibentry->type eq $_ } qw(mastersthesis phdthesis)) {

      # make links to theses
      push @links, ["Theses", "$pdflinkby{Author}"];

    } elsif ($bibentry->exists('howpublished')) {

      # make links by publication method
      my $howpublished = $bibentry->get("howpublished");
      $howpublished = join(' ', map { ucfirst($_) } remove_short_words(split(/\s+/, $howpublished)));
      foreach my $by (qw(Author Title Year)) {
        push @links, ["How Published", $howpublished, "${by}s", "$pdflinkby{$by}"];
      }

    } else {

      # make links to everything else
      my $type = ucfirst($bibentry->type);
      foreach my $by (qw(Author Title Year)) {
        push @links, ["Other", "${type}s", "${by}s", "$pdflinkby{$by}"];
      }

    }

    # make links to entries with missing information
    my @errorlinks;
    foreach (@links) {
      my @linkpath = @{$_};
      foreach (@linkpath) {
        if (/!(NO-[A-Z]*)!/) {
          my $errorcode = $1;
          push @errorlinks, ["Errors", "$errorcode", "$key"];
        }
      }
    }
    push @links, @errorlinks;

    # mark old links for removal
    foreach my $oldlink (keys %{$existinglinks{$pdffile}}) {
      $existinglinks{$pdffile}->{$oldlink} = 0;
    }

    # make symbolic links
    foreach (@links) {

      # normalise elements of symbolic link path
      my @linkpath = @{$_};
      foreach (@linkpath) {
        die unless defined($_) && $_ ne "";
        $_ = unidecode($_);
        s/[`'"!]//g;
        s/[^-+.A-Za-z0-9]/_/g;
        s/[-_][-_]+/_/g;
        s/^_+//;
        s/_+$//;
      }

      # make symbolic link path directories
      my $linkfilebase = pop @linkpath;
      my $linkdir = File::Spec->catdir($pdflibrarydir, @linkpath);
      File::Path::make_path($linkdir);

      # make symbolic link file
      my $linkfile = File::Spec->catfile($linkdir, "$linkfilebase.pdf");
      if (-l $linkfile) {
        unlink($linkfile) or croak "$Script: could not unlink '$linkfile': $!";
      }
      symlink($pdffile, $linkfile) or croak "$Script: could not link '$linkfile' to '$pdffile': $!";
      $existinglinks{$pdffile}->{$linkfile} = 1;

    }

    # print progress
    ++$count;
    if ($count % 50 == 0 || $count == @bibentries) {
      printf STDERR "$Script: making links to %i/%i PDF files in '$pdflibrarydir'\r", $count, scalar(@bibentries);
      flush STDERR;
    }
  }
  printf STDERR "\n";

  # remove old links
  foreach my $pdffile (keys %existinglinks) {
    foreach my $oldlink (keys %{$existinglinks{$pdffile}}) {
      if (!$existinglinks{$pdffile}->{$oldlink}) {
        unlink($oldlink) or croak "$Script: could not unlink '$oldlink': $!";
      }
    }
  }

}

sub cleanup_links {

  # remove broken links and empty directories
  my $wanted = sub {
    if (-d $_) {
      rmdir $_;
    }
    if (-l $_ && !stat($_)) {
      unlink($_) or croak "$Script: could not unlink '$_': $!";
    }
  };
  find({wanted => \&$wanted, bydepth => 1, no_chdir => 1}, $pdflibrarydir);
  printf STDERR "$Script: cleaned up PDF file links in '$pdflibrarydir'\n";

}
