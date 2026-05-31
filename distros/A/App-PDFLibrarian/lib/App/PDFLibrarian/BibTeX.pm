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

package App::PDFLibrarian::BibTeX;
$App::PDFLibrarian::BibTeX::VERSION = '6.2.0';
use parent 'Exporter';

use Capture::Tiny;
use Carp;
use Digest::SHA;
use Encode;
use File::ShareDir qw(dist_file);
use File::Temp;
use FindBin qw($Script);
use List::Util qw(max);
use Scalar::Util qw(blessed);
use Text::BibTeX qw(:nameparts :joinmethods :macrosubs);
use Text::BibTeX::Bib;
use Text::BibTeX::NameFormat;
use Text::Unidecode;
use Text::Wrap;
use URI::Encode qw(uri_encode uri_decode);
use XML::LibXML;
use XML::LibXSLT;

use App::PDFLibrarian qw(%bibtex_macros);
use App::PDFLibrarian::Util qw(unique_list keyword_display_str parallel_loop remove_tex_markup remove_short_words);

our @EXPORT_OK = qw(bib_checksum read_bib_from_str read_bib_from_file read_bib_from_pdf format_bib write_bib_to_fh write_bib_to_pdf edit_bib_in_fh find_dup_bib_keys format_bib_authors generate_bib_keys);

# BibTeX database structure
my $structure = new Text::BibTeX::Structure('Bib');
foreach my $type ($structure->types()) {
  $structure->add_fields($type, [qw(keyword title year file)], [qw(collaboration)]);
}
foreach my $type (qw(booklet manual misc)) {
  $structure->add_fields($type, [qw(author)]);
}
$structure->add_fields("mastersthesis", [qw(type)]);
$structure->add_fields("misc", [qw(howpublished)]);

# BibTeX field order
my @fieldorder = qw (
                      keyword
                      title
                      key author collaboration
                      journal school institution type
                      editor booktitle edition series
                      volume number issue chapter pages eid numpages
                      month year
                      publisher organization address isbn issn
                      howpublished
                      doi
                      archiveprefix primaryclass eprint
                      url adsurl
                      note annote comments
                      abstract
                   );

1;

sub bib_checksum {
  my ($bibentry, @exclude) = @_;

  # generate a checksum for a BibTeX entry
  push @exclude, 'checksum';
  my $digest = Digest::SHA->new();
  $digest->add($bibentry->type, $bibentry->key);
  foreach my $bibfield (sort { $a cmp $b } $bibentry->fieldlist()) {
    next if grep /^$bibfield$/, @exclude;
    $digest->add($bibfield, $bibentry->get($bibfield));
  }

  return $digest->hexdigest;
}

sub read_bib_from_str {
  my ($bibstr) = @_;

  # read BibTeX entry from a string
  my $bibentry = new Text::BibTeX::BibEntry $bibstr;
  croak "$Script: failed to parse BibTeX entry" unless $bibentry->parse_ok;
  $bibentry->{structure} = $structure;

  return $bibentry;
}

sub read_bib_from_file {
  my ($errors, $bibentries, $filename) = @_;
  die unless ref($errors) eq 'ARRAY';
  die unless ref($bibentries) eq 'ARRAY';

  # initialise output arrays
  @$errors = ();
  @$bibentries = ();

  # check that the file contains non-comment, non-empty lines
  {
    my $nonempty = 1;
    open(my $fh, $filename) or croak "$Script: could not open file '$filename': $!";
    while (<$fh>) {
      next if /^%/;
      next if /^\s*$/;
      $nonempty = 0;
      last;
    }
    $fh->close();
    return if $nonempty;
  }

  # define BibTeX macros
  foreach my $macro (keys %bibtex_macros) {
    delete_macro($macro);
    add_macro_text($macro, $bibtex_macros{$macro});
  }

  # parse the BibTeX file, capturing any error messages
  my $errmsgs;
  {
    croak "$Script: file '$filename' does not exist" unless -r $filename;
    my $bib = new Text::BibTeX::File $filename or croak "$Script: could not open file '$filename'";
    $bib->{structure} = $structure;
    $errmsgs = Capture::Tiny::capture_merged {
      while (my $bibentry = new Text::BibTeX::BibEntry $bib) {
        next unless $bibentry->parse_ok;
        next unless $bibentry->check();
        push @$bibentries, $bibentry;
      }
    };
    $bib->close();
  }

  # remove 'file' field from Text::BibTeX::BibEntry, since it
  # contains a GLOB item that cannot be serialised by Storable
  foreach my $bibentry (@$bibentries) {
    delete($bibentry->{file}) if defined($bibentry->{file});
  }

  # format error messages, if any
  if (length($errmsgs) > 0) {
    foreach my $msg (split(/\n/, $errmsgs)) {
      $msg =~ s/^$filename,\s*//;
      if ($msg =~ /^line (\d+)[,:]?\s*(.*)$/) {
        push @$errors, { from => $1, msg => $2 };
      } elsif ($msg =~ /^lines (\d+)-(\d+)[,:]?\s*(.*)$/) {
        push @$errors, { from => $1, to => $2, msg => $3 };
      } else {
        push @$errors, { msg => $msg };
      }
    }
  }

}

sub read_bib_from_pdf {
  my (@pdffiles) = @_;

  # get location of BibTeX XSLT style file
  my $xsltbibtex = dist_file('App-PDFLibrarian', 'bibtex.xsl');
  croak "$Script: missing XSLT style file '$xsltbibtex'" unless -f $xsltbibtex;

  # read BibTeX entries from PDF files
  my $body = sub {
    my ($pdffile) = @_;

    # open PDF file and read XMP metadata
    my $pdf = PDF::API2->open($pdffile);
    my $xmp = "";
    eval {
      $xmp = $pdf->xmpMetadata() // "";
    };
    $xmp = "" unless $xmp =~ /<\?xpacket /;
    $xmp =~ s/\s*<\?xpacket .*\?>\s*//g;
    $pdf->end();

    # convert BibTeX XML (if any) to parsed BibTeX entry
    my $bibstr = '@article{:,}';
    my $xml = "";
    if (length($xmp) > 0) {
      eval {
        $xml = XML::LibXML->load_xml(string => $xmp);
      };
    }
    if (length($xml) > 0) {
      my $xslt = XML::LibXSLT->new();
      my $xsltstylesrc = XML::LibXML->load_xml(location => $xsltbibtex);
      my $xsltstyle = $xslt->parse_stylesheet($xsltstylesrc);
      my $bib = $xsltstyle->transform($xml);
      my $bibtext = $bib->textContent();
      $bibtext =~ s/^\s+//;
      $bibtext =~ s/\s+$//;
      if (length($bibtext) > 0) {
        $bibstr = $bibtext;
      }
    }
    my $bibentry = read_bib_from_str($bibstr);

    # save name of PDF file
    $bibentry->set('file', $pdffile);

    return $bibentry;
  };
  my @bibentries = parallel_loop("reading BibTeX entries from %i/%i PDF files", \@pdffiles, $body);

  # add checksums to BibTeX entries
  foreach my $bibentry (@bibentries) {
    my $checksum = bib_checksum($bibentry);
    $bibentry->set('checksum', $checksum);
  }

  return @bibentries;
}

sub format_bib {
  my ($opts, @bibentries) = @_;

  # check options
  $opts->{max_authors} = 0 unless defined($opts->{max_authors});
  $opts->{only_first_author} = 0 unless defined($opts->{only_first_author});

  # format BibTeX entries
  my @fmtbibentries;
  foreach my $bibentry (@bibentries) {

    # create a copy of BibTeX entry
    $bibentry = $bibentry->clone();

    # merge BibTeX field names which differ by 's', e.g. 'keyword' and 'keywords'
    foreach my $bibfield ($bibentry->fieldlist()) {
      if ($bibentry->exists($bibfield) && $bibentry->exists($bibfield . "s")) {
        my $bibfieldvalue = $bibentry->get($bibfield);
        my $bibfieldsvalue = $bibentry->get($bibfield . "s");
        if ($bibfieldvalue eq "") {
          $bibfieldvalue = $bibfieldsvalue;
        } elsif ($bibfieldsvalue ne "") {
          $bibfieldvalue .= ", " . $bibfieldsvalue;
        }
        $bibentry->set($bibfield, $bibfieldvalue);
        $bibentry->delete($bibfield . "s");
      }
    }

    # uniformly format authors, editors, and collaborations
    foreach my $bibfield (qw(author editor collaboration)) {
      if ($bibentry->exists($bibfield)) {

        # determine author format
        my $authorformat;
        if ($bibfield eq "collaboration") {
          $authorformat = new Text::BibTeX::NameFormat("l");
          $authorformat->set_text(BTN_LAST, "{", "}", undef, undef);
        } else {
          $authorformat = new Text::BibTeX::NameFormat("vljf");
          $authorformat->set_text(BTN_LAST, "{", "}", undef, undef);
          $authorformat->set_text(BTN_FIRST, undef, undef, undef, ".");
          $authorformat->set_options(BTN_FIRST, 1, BTJ_FORCETIE, BTJ_SPACE);
        }

        # iterate over authors
        my @authors = $bibentry->split($bibfield);
        foreach my $author (@authors) {

          # sanitise author string
          $author =~ s/~/ /g;
          $author =~ s/\.\s-/.-/g;
          $author =~ s/\bet\sal\.?/others/;

          if ($author ne "others") {

            # format author
            $author = Text::BibTeX::Name->new($author);
            $author = $authorformat->apply($author);

            # use braces around special character commands
            $author =~ s/\\(\W)(\w)/\{\\$1$2\}/g;
            $author =~ s/\\(\w+)\s+(\w)/\\$1\{$2\}/g;

            # remove duplicate braces
            my @parts = split(",", $author);
            foreach my $part (@parts) {
              while ($part =~ s{\{\{(.*?(\{(?:(?>[^{}]+)|(?2))*\}.*?)*)\}\}}{\{$1\}}) {
                next;
              }
            }
            $author = join(",", @parts);

          }
        }

        # truncate author list
        if ($opts->{max_authors} > 0 && @authors > $opts->{max_authors}) {
          if ($opts->{only_first_author}) {
            @authors = ($authors[0]);
          } else {
            @authors = @authors[0 .. ($opts->{max_authors} - 1)];
          }
          push @authors, "others";
        }

        # set BibTeX field to concatenated authors
        $bibentry->set($bibfield, join(" and ", @authors));

      }
    }

    # handle e-print journals
    if ($bibentry->exists('journal') && $bibentry->exists('archiveprefix') && $bibentry->exists('eprint')) {
      my $journal = $bibentry->get('journal');
      my $archiveprefix = $bibentry->get('archiveprefix');
      my $eprint = $bibentry->get('eprint');
      if ($journal eq $archiveprefix) {
        $bibentry->set('pages', $eprint);
        $bibentry->set('eid', $eprint);
      }
    }

    # regularise BibTeX 'month' field
    if ($bibentry->exists('month')) {
      my $month = $bibentry->get('month');
      $month =~ s/\s//g;
      $month =~ s/^jan.*$/January/i;
      $month =~ s/^feb.*$/February/i;
      $month =~ s/^mar.*$/March/i;
      $month =~ s/^apr.*$/April/i;
      $month =~ s/^may.*$/May/i;
      $month =~ s/^jun.*$/June/i;
      $month =~ s/^jul.*$/July/i;
      $month =~ s/^aug.*$/August/i;
      $month =~ s/^sep.*$/September/i;
      $month =~ s/^oct.*$/October/i;
      $month =~ s/^nov.*$/November/i;
      $month =~ s/^dec.*$/December/i;
      $bibentry->set('month', $month);
    }

    # regularise BibTeX 'volume', 'number', 'issue', 'numpages' fields
    # - remove redundant prefixes e.g. 'vol.', 'p.'
    # - use single hyphen for ranges
    foreach my $bibfield (qw(chapter volume number issue pages numpages)) {
      if ($bibentry->exists($bibfield)) {
        my $field = $bibentry->get($bibfield);
        $field =~ s/^[a-z]+\.//;
        $field =~ s/--+/-/g;
        $field =~ s/\s*-\s*/-/g;
        $bibentry->set($bibfield, $field);
      }
    }

    # regularise BibTeX 'edition' field
    # - if a number, add appropriate ordinal suffix
    foreach my $bibfield (qw(edition)) {
      if ($bibentry->exists($bibfield)) {
        my $field = $bibentry->get($bibfield);
        if ($field =~ /^\s*[0-9]/) {
          $field =~ s/[^0-9]//g;
          my $last_digit = $field % 10;
          if ($last_digit == 2 && $field != 12) {
            $field .= 'nd';
          } elsif ($last_digit == 3 && $field != 13) {
            $field .= 'rd';
          } else {
            $field .= 'th';
          }
        }
        $bibentry->set('edition', $field);
      }
    }

    # remove braces and trailing periods in BibTeX 'title' fields
    # - except where required for LaTeX commands
    foreach my $bibfield ($bibentry->fieldlist()) {
      if ($bibfield =~ /title$/) {
        my $title = $bibentry->get($bibfield);
        $title =~ s/\.+$//;
        my @words = split /\s+/, $title;
        foreach my $word (@words) {
          $word =~ s/[{}]//g;
          $word =~ s/((?:\\.)?[A-Z]+)/\{$1\}/g;
          $word =~ s/\$\{([A-Z]+)\}\$/{\$$1\$}/g;
          $word =~ s/^\{([A-Z])\}/$1/
        }
        $title = join(" ", @words);
        $bibentry->set($bibfield, $title);
      }
    }

    # regularise BibTeX 'doi' field
    if ($bibentry->exists('doi')) {
      my $doi = $bibentry->get('doi');
      $doi =~ s|https?[:]//[\w.]*doi\.org/||g;
      $bibentry->set('doi', $doi);
    }

    # set missing BibTeX 'doi' field from arXiv e-print
    if (!$bibentry->exists('doi') && $bibentry->exists('archiveprefix') && $bibentry->exists('eprint')) {
      my $archiveprefix = $bibentry->get('archiveprefix');
      my $eprint = $bibentry->get('eprint');
      if ($archiveprefix =~ /arxiv/i) {
        my $doi = "10.48550/arXiv.$eprint";
        $bibentry->set('doi', $doi);
      }
    }

    # set missing BibTeX 'doi' field from hyphenated ISBN-13
    if (!$bibentry->exists('doi') && $bibentry->exists('isbn')) {
      my $isbn = $bibentry->get('isbn');
      if ($isbn =~ /^(97[89])-(\d+)-(\d+)-(\d+)-(\d+)/) {
        my $doi = "10.$1.$2$3/$4$5";
        $bibentry->set('doi', $doi);
      }
    }

    # set BibTeX 'url' field
    if ($bibentry->exists('doi')) {
      my $doi = $bibentry->get('doi');
      my $url = "https://doi.org/$doi";
      $bibentry->set('url', $url);
    } else {
      my @urlbibfields = grep { $_ =~ /.url$/ } $bibentry->fieldlist();
      if (@urlbibfields == 1) {
        $bibentry->set('url', $bibentry->get($urlbibfields[0]));
      }
    }

    # set BibTeX 'misc' entry 'howpublished' field
    if ($bibentry->type eq 'misc') {
      if ($bibentry->exists('archiveprefix')) {
        my $archiveprefix = $bibentry->get('archiveprefix');
        $bibentry->set('howpublished', $archiveprefix);
      }
    }

    # escape special characters
    foreach my $bibfield ($bibentry->fieldlist()) {
      my $bibfieldvalue = $bibentry->get($bibfield);
      if ($bibfield =~ /url$/) {

        # encode special URL characters
        $bibfieldvalue = uri_decode($bibfieldvalue);
        $bibfieldvalue = uri_encode($bibfieldvalue, {encode_reserved => 0, double_encode => 0});

      } else {

        # escape special TeX characters
        $bibfieldvalue =~ s{\\*&}{\\&}g;

      }
      $bibentry->set($bibfield, $bibfieldvalue);
    }

    # arrange BibTeX fields in the order given by @fieldorder
    my %order;
    my $orderidx;
    foreach my $bibfield (@fieldorder, sort { $a cmp $b } $bibentry->fieldlist()) {
      $order{$bibfield} = ++$orderidx if $bibentry->exists($bibfield) && !defined($order{$bibfield});
    }
    $order{'file'} = ++$orderidx if $bibentry->exists('file');
    my @fieldlist = sort { $order{$a} <=> $order{$b} } keys(%order);
    $bibentry->set_fieldlist(\@fieldlist);

    # output formatted entry
    push @fmtbibentries, $bibentry;

  }

  return @fmtbibentries;
}

sub write_bib_to_fh {
  my ($opts, @bibentries) = @_;

  # check options
  die unless defined($opts->{fh});
  my $fh = $opts->{fh};

  # print BibTeX entries
  foreach my $bibentry (sort { $a->key cmp $b->key } @bibentries) {

    # create a copy of BibTeX entry
    $bibentry = $bibentry->clone();

    # remove checksum before printing
    $bibentry->delete('checksum');

    # decide if/how to output PDF filename
    my $pdf_file_comment = "";
    if (defined($opts->{pdf_file})) {
      if ($opts->{pdf_file} eq "comment") {
        my $pdf_file = $bibentry->get("file");
        $pdf_file_comment = "% file: $pdf_file\n";
      }
      $bibentry->delete("file");
    }

    # print entry
    my $bibstr = $bibentry->print_s();
    $bibstr =~ s/^\s+//g;
    $bibstr =~ s/\s+$//g;
    print $fh "\n", $pdf_file_comment, encode('iso-8859-1', $bibstr, Encode::FB_CROAK), "\n";

  }

}

sub write_bib_to_pdf {
  my (@bibentries) = @_;

  # get location of DublinCore XSLT style file
  my $xsltdublincore = dist_file('App-PDFLibrarian', 'dublincore.xsl');
  croak "$Script: missing XSLT style file '$xsltdublincore'" unless -f $xsltdublincore;

  # filter out unmodified BibTeX entries
  my @modbibentries;
  foreach my $bibentry (@bibentries) {
    my $checksum = bib_checksum($bibentry);
    next if ($bibentry->get('checksum') // "") eq $checksum;
    push @modbibentries, $bibentry;
    $bibentry->set('checksum', $checksum);
  }
  printf STDERR "$Script: not writing %i unmodified BibTeX entries\n", @bibentries - @modbibentries if @modbibentries < @bibentries;

  # write modified BibTeX entries to PDF files
  my $body = sub {
    my ($bibentry) = @_;

    # get name of PDF file
    my $pdffile = $bibentry->get('file');

    # check for existence of PDF file
    croak "$Script: BibTeX entry '@{[$bibentry->key]}' cannot be written to missing PDF file '$pdffile'" unless -f $pdffile;

    # create XML document
    my $xml = XML::LibXML::Document->new('1.0', 'utf-8');
    my $xmlmeta = $xml->createElementNS("adobe:ns:meta/", "xmpmeta");
    $xmlmeta->setNamespace("adobe:ns:meta/", "x", 1);
    $xml->setDocumentElement($xmlmeta);

    # convert BibTeX into XML
    my $xmlbibentry = $xml->createElementNS("http://bibtexml.sf.net/", "entry");
    $xmlbibentry->setNamespace("http://bibtexml.sf.net/", "bibtex", 1);
    $xmlbibentry->setAttribute("id" => $bibentry->key);
    $xmlmeta->appendChild($xmlbibentry);
    my $xmlbibtype = $xml->createElementNS("http://bibtexml.sf.net/", lc($bibentry->type));
    $xmlbibtype->setNamespace("http://bibtexml.sf.net/", "bibtex", 1);
    $xmlbibentry->appendChild($xmlbibtype);
    foreach my $bibfield ($bibentry->fieldlist()) {
      next if grep { $bibfield eq $_ } qw(checksum file);
      next unless length($bibentry->get($bibfield)) > 0;
      my $xmlbibfield = $xml->createElementNS("http://bibtexml.sf.net/", lc($bibfield));
      $xmlbibfield->setNamespace("http://bibtexml.sf.net/", "bibtex", 1);
      $xmlbibfield->appendTextNode($bibentry->get($bibfield));
      $xmlbibtype->appendChild($xmlbibfield);
    }

    # convert BibTeX XML to DublinCore XML and append
    my $xslt = XML::LibXSLT->new();
    my $xsltstylesrc = XML::LibXML->load_xml(location => $xsltdublincore);
    my $xsltstyle = $xslt->parse_stylesheet($xsltstylesrc);
    my $xmldc = $xsltstyle->transform($xml);
    my $xmldcentry = $xmldc->documentElement()->cloneNode(1);
    $xml->adoptNode($xmldcentry);
    $xmlmeta->insertBefore($xmldcentry, $xmlbibentry);

    # open PDF file
    my $pdf = PDF::API2->open($pdffile);

    # write document information to PDF file
    my %pdfinfo;
    eval {
      %pdfinfo = $pdf->info();
    };
    $pdfinfo{Author} = remove_tex_markup($bibentry->get("author") // $bibentry->get("editor") . " ed.");
    $pdfinfo{Title} = remove_tex_markup($bibentry->get("title"));
    $pdfinfo{Subject} = remove_tex_markup($bibentry->get("abstract"));
    $pdf->infoMetaAttributes(keys(%pdfinfo));
    $pdf->info(%pdfinfo);
    $pdf->preferences(-displaytitle => 1);

    # write XMP metadata to PDF file
    my $xmp = "";
    eval {
      $xmp = $pdf->xmpMetadata() // "";
    };
    my $xmphead = "<?xpacket begin='﻿' id='W5M0MpCehiHzreSzNTczkc9d'?>\n";
    my $xmpdata = encode('utf-8', $xml->documentElement()->toString(0), Encode::FB_CROAK);
    my $xmptail = "\n<?xpacket end='w'?>";
    my $xmplen = length($xmphead) + length($xmpdata) + length($xmptail);
    my $xmppadlen = length($xmp) - $xmplen;
    if ($xmppadlen <= 0) {
      $xmppadlen = max(4096, 2*length($xmp), 2*length($xmpdata)) - $xmplen;
    }
    my $xmppad = ((" " x 99) . "\n") x int(1 + $xmppadlen / 100);
    my $newxmp = $xmphead . $xmpdata . substr($xmppad, 0, $xmppadlen) . $xmptail;
    $pdf->xmpMetadata($newxmp);

    # write PDF file
    eval {
      $pdf->update();
      $pdf->end();
      1;
    } or do {
      chomp(my $error = $@);
      print STDERR "$Script: could not save PDF file '$pdffile': $error\n";
      $bibentry = undef;
    };

    return $bibentry;
  };
  @modbibentries = parallel_loop("writing BibTeX entries to %i/%i PDF files", \@modbibentries, $body);

  return @modbibentries;
}

sub edit_bib_in_fh {
  my ($oldfh, @bibentries) = @_;
  die unless blessed($oldfh) eq 'File::Temp';

  # save checksums of BibTeX entries
  my %checksums;
  foreach my $bibentry (@bibentries) {
    $checksums{$bibentry->get('file')} = $bibentry->get('checksum');
  }

  # edit and re-read BibTeX entries, allowing for errors
  my @errors;
  while (1) {

    while (1) {

      # open new temporary file for editing BibTeX entries
      my $fh = File::Temp->new(SUFFIX => '.bib', EXLOCK => 0) or croak "$Script: could not create temporary file";
      binmode($fh, ":encoding(iso-8859-1)");

      # write header message
      if (@errors > 0) {
        print $fh wrap("% ", "% ", <<"EOF");
PDFLibrarian has encountered several errors in parsing the following BibTeX records. These errors are indicated with comments next to the line where the errors occurred.

All errors MUST be corrected before the BibTeX records can be written back to the PDF file given by the 'file' field in each record.

To ABORT ANY CHANGES from being written, simply delete the relevant records, or the entire contents of this file.
EOF
      } else {
        print $fh wrap("% ", "% ", <<"EOF");
PDFLibrarian has extracted the following BibTeX records for editing. Any changes to the records will be written back to the PDF file given by the 'file' field in each record.

To ABORT ANY CHANGES from being written, simply delete the relevant records, or the entire contents of this file.
EOF
      }
      if (%bibtex_macros > 0) {
        print $fh "%\n% Available BibTeX macros:\n";
        foreach my $macro (keys %bibtex_macros) {
          print $fh "% $macro: $bibtex_macros{$macro}\n";
        }
      }
      print $fh "\n";

      # build hash of errors by line number
      my %errorsbyline;
      foreach (@errors) {
        if (defined($_->{from})) {
          push @{$errorsbyline{$_->{from}}}, $_->{msg};
        } else {
          push @{$errorsbyline{0}}, $_->{msg};
        }
      }

      # write any error messages without line numbers
      if (defined($errorsbyline{0})) {
        foreach (@{$errorsbyline{0}}) {
          print $fh "% ERROR: $_\n";
        }
        delete $errorsbyline{0};
        print $fh "\n";
      }

      # write contents of old temporary file, with any error messages inline
      $oldfh->flush();
      $oldfh->seek(0, SEEK_SET);
      while (<$oldfh>) {
        chomp;
        my $line = sprintf("%i", $oldfh->input_line_number);
        foreach (@{$errorsbyline{$line}}) {
          print $fh "% ERROR: $_\n";
        }
        delete $errorsbyline{$line};
        s/\s+$//;
        next if /^%/;
        next if /^$/;
        print $fh "$_\n";
        if (/^}$/) {
          print $fh "\n";
        }
      }
      $fh->flush();

      # write any remaining error messages
      foreach (keys %errorsbyline) {
        foreach (@{$errorsbyline{$_}}) {
          print $fh "% ERROR: $_\n";
        }
      }

      # print index of all currently-defined keywords
      print $fh keyword_display_str();

      # save handle to new temporary file; old temporary file is deleted
      $oldfh = $fh;

      # edit BibTeX entries
      my $editor = $ENV{'VISUAL'} // $ENV{'EDITOR'} // 'editor';
      printf STDERR "$Script: opening %i BibTeX entries in editing program '$editor' ...\n", scalar(@bibentries);
      system($editor, $fh->filename) == 0 or croak "$Script: could not edit file '$fh->filename' with editing program '$editor'";

      # try to re-read BibTeX entries
      read_bib_from_file(\@errors, \@bibentries, $fh->filename);

      # error if duplicate BibTeX keys are found
      foreach my $dupkey (find_dup_bib_keys(@bibentries)) {
        push @errors, { msg => "duplicated key '$dupkey'" };
      }

      foreach my $bibentry (@bibentries) {

        # error if required fields are empty
        foreach my $bibfield ($structure->required_fields($bibentry->type)) {
          my $bibfieldvalue = $bibentry->get($bibfield) // "";
          $bibfieldvalue =~ s/[{}]//g;
          if ($bibfieldvalue eq "") {
            push @errors, { msg => "entry '@{[$bibentry->key]}' is missing required field '${bibfield}'" };
          }
        }

        # error if BibTeX entries contain field names which differ by 's', e.g. 'keyword' and 'keywords'
        foreach my $bibfield ($bibentry->fieldlist()) {
          if ($bibentry->exists($bibfield) && $bibentry->exists($bibfield . "s")) {
            push @errors, { msg => "entry '@{[$bibentry->key]}' contains duplicate fields '${bibfield}' and '${bibfield}s'" };
          }
        }
      }

      # BibTeX entries have been successfully read
      last if @errors == 0;

    }

    {
      # open new temporary file for editing BibTeX entries
      my $fh = File::Temp->new(SUFFIX => '.bib', EXLOCK => 0) or croak "$Script: could not create temporary file";
      binmode($fh, ":encoding(iso-8859-1)");

      # format and print BibTeX entries
      write_bib_to_fh({ fh => $fh }, format_bib({}, @bibentries));
      $fh->flush();

      # save handle to new temporary file; old temporary file is deleted
      $oldfh = $fh;

      # try to re-read BibTeX entries
      read_bib_from_file(\@errors, \@bibentries, $fh->filename);
    }

    # BibTeX entries have been successfully read
    last if @errors == 0;

  }

  # restore checksums of BibTeX entries
  foreach my $bibentry (@bibentries) {
    $bibentry->set('checksum', $checksums{$bibentry->get('file')});
  }

  return @bibentries;
}

sub find_dup_bib_keys {
  my (@bibentries) = @_;

  # find duplicate keys in BibTeX entries
  my %keycount;
  foreach my $bibentry (@bibentries) {
    ++$keycount{$bibentry->key};
  }

  return grep { $keycount{$_} > 1 } keys(%keycount);
}

sub format_bib_authors {
  my ($nameformat, $maxauthors, $etal, @authors) = @_;

  # format authors
  my $authorformat = new Text::BibTeX::NameFormat($nameformat);
  foreach my $author (@authors) {
    $author = $authorformat->apply($author);
    $author = remove_tex_markup($author);
    if ($author =~ /\sCollaboration$/i) {
      $author =~ s/\s.*$//;
    }
  }

  if (@authors > 0) {

    # limit number of authors to '$maxathors'
    if (defined($maxauthors) && $maxauthors > 0 && @authors > $maxauthors) {
      @authors = ($authors[0], $etal);
    }

    # replace 'others' with preferred form of 'et al.'
    $authors[-1] = $etal if $authors[-1] eq "others";

  }

  return @authors;
}

sub generate_bib_keys {
  my (@bibentries) = @_;

  # generate keys for BibTeX entries
  my $keys = 0;
  foreach my $bibentry (@bibentries) {
    my $key = "";

    # add formatted authors, editors, or collaborations
    {
      my @authors = format_bib_authors("l", 2, "EtAl", $bibentry->names("collaboration"));
      @authors = format_bib_authors("l", 2, "EtAl", $bibentry->names("author")) unless @authors > 0;
      @authors = format_bib_authors("l", 2, "EtAl", $bibentry->names("editor")) unless @authors > 0;
      $key .= join('', map { $_ =~ s/\s//g; substr($_, 0, 4) } @authors);
    }

    # add year
    my $year = $bibentry->get("year") // "";
    $key .= $year;

    # add abbreviated title
    {
      my $suffix = "";
      my $erratum = "";

      my $title = $bibentry->get("title");
      $title = remove_tex_markup($title);
      if ($title =~ s/^erratum[\p{IsPunct}\s]//i) {
        $erratum = "-ERRATUM";
        $title =~ s/\([^()]+\)$//;
        $title =~ s/\[[^[\]]+\]$//;
      }
      $title =~ s/[^\w\d\s]//g;

      # abbreviate title words
      my @words = remove_short_words(split(/\s+/, $title));
      my @wordlens = (3, 3, 2, 2, 2);
      foreach my $word (sort { length($b) <=> length($a) } @words) {

        # add any Roman numeral to suffix, and stop processing title
        if (grep { $word eq $_ } qw(II III IV V VI VII VIII IX)) {
          $suffix .= "-$word";
          last;
        }

        # always include numbers in full
        next if $word =~ /^\d+$/;

        # abbreviate word to the next available length, after removing vowels
        my $wordlen = shift(@wordlens) // 1;
        my $shrt = ucfirst($word);
        $shrt =~ s/[aeiou]//g;
        $shrt = substr($shrt, 0, $wordlen);

        map { s/^$word$/$shrt/ } @words;
      }

      unless (length($suffix) > 0) {

        # add volume number (if any) to suffix for books and proceedings
        $suffix .= '-v' . $bibentry->get("volume") if (grep { $bibentry->type eq $_ } qw(book inbook proceedings)) && $bibentry->exists("volume");

      }

      # add abbreviated title and suffix to key
      $key .= '-' . join('', @words);
      $key .= $suffix . $erratum;

    }

    # sanitise key
    $key = unidecode($key);
    $key =~ s/[^\w\d-]//g;
    $key =~ s/^-//;
    $key =~ s/^--+/-/g;

    # set key to generated key, unless start of key matches generated key
    # - this is so user can further customise key by appending characters
    unless ($bibentry->key =~ /^$key($|-)/) {
      $bibentry->set_key($key);
      ++$keys;
    }

  }
  printf STDERR "$Script: generated keys for %i BibTeX entries\n", $keys if $keys > 0;

}
