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

package App::PDFLibrarian;
# ABSTRACT: Manage a library of academic papers in PDF format with embedded BibTeX metadata
$App::PDFLibrarian::VERSION = '6.0.1';
use parent 'Exporter';

use Carp;
use Config::IniFiles;
use File::BaseDir;
use File::Path;
use File::Spec;
use FindBin qw($Script);
use Text::BibTeX;

=pod

=head1 NAME

B<App::PDFLibrarian> - Manage a library of academic papers in PDF format with embedded BibTeX metadata.

=head1 INSTALLATION

Requires the following packages:

=over 4

=item * Debian, Ubuntu:

    apt install cpanminus ghostscript libwx-perl libxml2-dev libxslt1-dev perl-base poppler-utils xdg-utils zlib1g-dev

=back

Then install from CPAN:

    cpanm App::PDFLibrarian

=head1 APPLICATIONS

=over 4

=item * B<pdf-lbr-import-pdf>

=item * B<pdf-lbr-edit-bib>

=item * B<pdf-lbr-output-bib>

=item * B<pdf-lbr-output-key>

=item * B<pdf-lbr-replace-pdf>

=item * B<pdf-lbr-remove-pdf>

=item * B<pdf-lbr-rebuild-links>

=item * B<pdf-lbr-iso4-abbr>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016--2026 Karl Wette. Licensed under the GNU General Public License, version 3 or later.

=cut

our $cfgdir;
our $pdflibrarydir;
our $pref_query_database;
our %bibtex_macros;
our %default_filter;
our %default_output_text_format;
our %query_databases;

our @EXPORT_OK = qw($cfgdir $pdflibrarydir $pref_query_database %bibtex_macros %default_filter %default_output_text_format %query_databases);

1;

INIT {

  # allow printing of UTF-8 characters
  binmode(STDOUT, "encoding(utf-8)");

  # check for user home directory
  croak "$Script: could not determine user home directory" unless defined($ENV{HOME}) && -d $ENV{HOME};

  # create configuration directory
  $cfgdir = File::BaseDir->config_home("pdflibrarian");
  File::Path::make_path($cfgdir);

  # read configuration file
  my $cfgfile = File::Spec->catfile($cfgdir, "pdflibrarian.ini");
  my $cfg = Config::IniFiles->new();
  if (-f $cfgfile) {
    $cfg->SetFileName($cfgfile);
    $cfg->ReadConfig();
  }

  # ensure default configuration values are set
  {
    my %default_config =
      (
       'general.pdflibrarydir' => File::Spec->catdir($ENV{HOME}, 'PDFLibrary'),
       'general.prefquery' => 'Astrophysics Data System using Digital Object Identifier',
       'general.default_filter' => 'keyword=d abstract=d',
       'query-ads doi.name' => 'Astrophysics Data System using Digital Object Identifier',
       'query-ads doi.cmd' => 'pdf-lbr-query-ads --query doi:%s',
       'query-ads arxiv.name' => 'Astrophysics Data System using arXiv Article Identifier',
       'query-ads arxiv.cmd' => 'pdf-lbr-query-ads --query arxiv:%s',
       'output-text-format.article' => '%author:fvlj, %title, %journal %volume, %pages (%year).',
      );
    while (my ($section_key, $value) = each %default_config) {
      my ($section, $key) = split /[.]/, $section_key;
      if ($cfg->exists($section, $key)) {
        if (length($cfg->val($section, $key)) == 0) {
          $cfg->setval($section, $key, $value);
        }
      } else {
        $cfg->newval($section, $key, $value);
      }
    }
  }

  # ensure configuration file exists
  $cfg->WriteConfig($cfgfile);

  # set PDF library directory
  $pdflibrarydir = $cfg->val('general', 'pdflibrarydir');
  File::Path::make_path($pdflibrarydir);

  # set query database
  $pref_query_database = $cfg->val('general', 'prefquery');
  foreach my $section ($cfg->GroupMembers('query-ads')) {
    my $name = $cfg->val($section, 'name');
    my $cmd = $cfg->val($section, 'cmd');
    if ($cmd =~ /^[^%]+[%]s[^%]*$/) {
      $query_databases{$name} = $cmd;
    } else {
      croak "$Script: invalid query command '$cmd' for database '$name'";
    }
  }

  # create default field filter for printed BibTeX output
  foreach my $arg (split /\s+/, $cfg->val('general', 'default_filter')) {
    my ($bibfield, $spec) = split(/\s*=\s*/, $arg, 2);
    $default_filter{$bibfield} = $spec;
  }

  # read in BibTeX macros to define by default
  foreach my $key ($cfg->Parameters('macros')) {
    my $macro = lc($key);
    $bibtex_macros{$macro} = $cfg->val('macros', $key);
  }

  # create default formats for plain text output
  foreach my $key ($cfg->Parameters('output-text-format')) {
    my $bibtype = lc($key);
    $default_output_text_format{$bibtype} = $cfg->val('output-text-format', $key);
  }

}
