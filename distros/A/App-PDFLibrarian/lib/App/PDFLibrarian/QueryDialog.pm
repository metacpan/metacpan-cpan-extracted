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

package App::PDFLibrarian::QueryDialog;
$App::PDFLibrarian::QueryDialog::VERSION = '6.2.0';
use parent 'Exporter';

use Carp;
use FindBin qw($Script);
use Wx qw(:id);

use App::PDFLibrarian;
use App::PDFLibrarian::QueryDialog::impl;
use App::PDFLibrarian::Util qw(unique_list);

our @EXPORT_OK = qw(extract_query_values_from_pdf do_query_dialog);

sub extract_query_values_from_pdf {
  my ($pdffile) = @_;

  # try to extract possible query values
  my @query_values;

  {
    # open PDF file
    my $pdf = PDF::API2->open($pdffile);

    # try to extract a DOI from PDF info structure
    my @pdfinfotags = $pdf->infoMetaAttributes();
    push @pdfinfotags, qw(DOI doi);
    $pdf->infoMetaAttributes(@pdfinfotags);
    my %pdfinfo = $pdf->info();
    while (my ($key, $value) = each %pdfinfo) {
      if ($key =~ /^doi$/i) {
        push @query_values, $value;
      }
    }

    # try to extract a DOI from PDF info structure
    my $xmp = $pdf->xmpMetadata() // "";
    $xmp =~ s/\s+//g;
    while ($xmp =~ m|doi>([^<]+)<|ig) {
      push @query_values, $1;
    }
  }

  if (@query_values == 0 ) {

    # try to use pdftotext to extract PDF text
    my $cmd = "pdftotext '$pdffile' - 2>/dev/null";
    printf STDERR "$Script: running $cmd ...\n";
    flush STDERR;
    open PDFTOTEXT, "$cmd |" or croak "$Script: could not run $cmd";
    foreach my $text (<PDFTOTEXT>) {

      # try to extract a DOI from PDF text
      $text =~ s/\s+/ /g;
      while ($text =~ m{(?:doi[:]? *|https?[:]//[\w.]*doi\.org/)([^ ]+)}ig) {
        push @query_values, $1;
      }

    }
    close PDFTOTEXT;

  }

  return unique_list(@query_values);
}

sub do_query_dialog {
  my ($pdffile, $query_db_name, $query_value, $query_values, $error_message) = @_;
  my ($ui_query_db_name, $ui_query_value);

  # show dialog
  my $dialog = App::PDFLibrarian::QueryDialog::impl->new($pdffile, $query_db_name, $query_value, $query_values, $error_message);
  my $ui = $dialog->ShowModal();

  # cancel all imports and exit
  return ('exit', undef, undef) if $ui == wxID_EXIT;

  # skip import of PDF
  return ('cancel', undef, undef) if $ui == wxID_CANCEL;

  # manually enter BibTeX record
  return ('manual', undef, undef) if $ui == wxID_EDIT;

  # run query of database with given query value
  ($ui_query_db_name, $ui_query_value) = $dialog->get_data();
  return ('query', $ui_query_db_name, $ui_query_value);

}
