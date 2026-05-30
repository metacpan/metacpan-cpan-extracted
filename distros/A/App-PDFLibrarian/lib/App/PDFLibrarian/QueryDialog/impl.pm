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

package App::PDFLibrarian::QueryDialog::impl;
$App::PDFLibrarian::QueryDialog::impl::VERSION = '6.0.3';
use Wx qw(:dialog :statictext :combobox :textctrl :sizer :panel :window :id);
use Wx::ArtProvider;
use Wx::Event qw(EVT_BUTTON EVT_TEXT EVT_TEXT_ENTER);

use base qw(Wx::Dialog);

use App::PDFLibrarian qw(%query_databases);

my $query_db_name_combo;
my $query_value_combo;
my $buttonok;

1;

sub new {
  my ($class, $pdffile, $query_db_name, $query_value, $query_values, $error_message) = @_;

  # create dialog
  my $self = $class->SUPER::new(undef, -1, "Import $pdffile - App::PDFLibrarian", &Wx::wxDefaultPosition, &Wx::wxDefaultSize, wxDIALOG_NO_PARENT | wxDEFAULT_DIALOG_STYLE);

  # set dialog icon
  my $icon = Wx::ArtProvider::GetIcon(Wx::ArtProvider::wxART_QUESTION, Wx::ArtProvider::wxART_CMN_DIALOG);
  $self->SetIcon($icon);

  # create panel and sizer
  my $topsizer = Wx::BoxSizer->new(wxVERTICAL);
  my $panel = Wx::Panel->new($self, -1, [-1, -1], [-1, -1], wxTAB_TRAVERSAL | wxBORDER_NONE);
  $panel->SetSizer($topsizer);

  # add static text box for message
  my $message;
  if ($error_message ne '') {
    $message = <<"EOM";
App::PDFLibrarian has queries online database '$query_db_name' with the query value '$query_value'. Unfortunately the query returned the following errors:

$error_message

Please correct the query value and/or select a different online database, and try again.

EOM
  } else {
    $message = <<"EOM";
App::PDFLibrarian would like to query an online database for a BibTeX record for the paper

$pdffile

in order to import the file into the PDF library.

Please select the online database below, and supply a query value which uniquely identified the paper. By default App::PDFLibrarian tries to extract a Digital Object Identifier from the PDF paper for use in the query, but this may well be incorrect and therefore should be double-checked.

EOM
  }
  $message .= <<"EOM";
Please press the 'Run Query' button (or the Enter key) when ready to run the query; press the 'Manual Entry' button to manually enter the BibTeX record; press the 'Skip Import' button (or the Esc key) to skip the import of the PDF paper; or the 'Quit' button to cancel all imports and exit.

EOM
  $topsizer->Add(Wx::StaticText->new($panel, -1, $message, [-1, -1], [500, 300]), 1, wxEXPAND | wxALL, 10);

  # add read-only combo box for query database
  my @query_db_names = sort { $a cmp $b } keys(%query_databases);
  $query_db_name_combo = Wx::ComboBox->new($panel, -1, $query_db_name, [-1, -1], [500, 30], \@query_db_names, wxCB_READONLY | wxTE_PROCESS_ENTER);
  $topsizer->Add($query_db_name_combo, 0, wxEXPAND | wxALL, 10);

  # add editable combo box for DOI
  $query_value_combo = Wx::ComboBox->new($panel, -1, $query_value, [-1, -1], [500, 30], \@{$query_values}, wxTE_PROCESS_ENTER);
  $topsizer->Add($query_value_combo, 0, wxEXPAND | wxALL, 10);

  # create buttons and sizer
  my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
  $buttonok = Wx::Button->new($panel, wxID_OK, 'Run Query');
  $buttonsizer->Add($buttonok, 0, wxALL, 10);
  my $buttonmanual = Wx::Button->new($panel, wxID_EDIT, 'Manual Entry');
  $buttonsizer->Add($buttonmanual, 0, wxALL, 10);
  my $buttonskip = Wx::Button->new($panel, wxID_CANCEL, 'Skip Import');
  $buttonsizer->Add($buttonskip, 0, wxALL, 10);
  my $buttonexit = Wx::Button->new($panel, wxID_EXIT, 'Quit');
  $buttonsizer->Add($buttonexit, 0, wxALL, 10);

  # add buttons to sizer
  $topsizer->Add($buttonsizer, 0, wxALIGN_CENTER);

  # perform final layout
  my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
  $mainsizer->Add($panel, 1, wxEXPAND | wxALL, 0);
  $self->SetSizerAndFit($mainsizer);

  # register events
  EVT_BUTTON($self, $buttonmanual, \&on_manual);
  EVT_BUTTON($self, $buttonexit, \&on_exit);
  EVT_TEXT($self, $query_db_name_combo, \&on_text);
  EVT_TEXT($self, $query_value_combo, \&on_text);
  EVT_TEXT_ENTER($self, $query_db_name_combo, \&on_enter);
  EVT_TEXT_ENTER($self, $query_value_combo, \&on_enter);
  on_text();

  return $self;
}

sub get_data {

  # get query database name
  my $query_db_name_combo_value = $query_db_name_combo->GetValue();
  $query_db_name_combo_value =~ s/^\s+//;
  $query_db_name_combo_value =~ s/\s+$//;

  # get query value
  my $query_value_combo_value = $query_value_combo->GetValue();
  $query_value_combo_value =~ s/^\s+//;
  $query_value_combo_value =~ s/\s+$//;

  return ($query_db_name_combo_value, $query_value_combo_value);
}

sub on_text {
  my ($self, $event) = @_;

  # query database and query value
  my ($query_db_name, $query_value) = get_data();

  # enable/disable "Run Query" button
  $buttonok->Enable(length($query_db_name) > 0 && length($query_value) > 0);

}

sub on_enter {
  my ($self, $event) = @_;

  $self->EndModal(wxID_OK);

}

sub on_manual {
  my ($self, $event) = @_;

  $self->EndModal(wxID_EDIT);

}

sub on_exit {
  my ($self, $event) = @_;

  $self->EndModal(wxID_EXIT);

}
