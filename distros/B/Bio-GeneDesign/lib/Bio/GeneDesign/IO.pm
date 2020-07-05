#
# GeneDesign input/output libraries
#

=head1 NAME

Bio::GeneDesign::IO

=head1 VERSION

Version 5.56

=head1 DESCRIPTION

GeneDesign is a library for the computer-assisted design of synthetic genes

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>

=cut

package Bio::GeneDesign::IO;
require Exporter;

use Bio::SeqIO;
use File::Basename;
use Digest::MD5 qw(md5_hex);
use POSIX qw(log10);
use Carp;

use strict;
use warnings;

our $VERSION = 5.56;

use base qw(Exporter);
our @EXPORT_OK = qw(
  _export_formats
  _isa_BP_format
  _import_sequences
  _import_sequences_from_string
  _split_sequences
  _export_sequences
  _long_att_fix
);

our %EXPORT_TAGS =  (GD=> \@EXPORT_OK);

=head1 Functions

=head2 _export_formats()

return a list of data formats that we are comfortable working with

=cut

sub _export_formats
{
  my @list = qw(genbank fasta);
  return \@list;
}

=head2 _isa_BP_format()

is the requested format possible in bioperl

=cut

sub _isa_BP_format
{
  my ($outformat) = @_;
  return 0 if (! $outformat);
  my $module = "Bio::SeqIO::$outformat";
  (my $require_name = $module . ".pm") =~ s{::}{/}xg;
  my $flag = eval
  {
    require $require_name;
  };
  return 0 if (! $flag);
  return 1;
}

=head2 _import_sequences

NO TEST

=cut

sub _import_sequences
{
  my ($path) = @_;
  my $iterator = Bio::SeqIO->new(-file => $path) || croak("Cannot parse $path");

  my ($filename, $dirs, $suffix) = fileparse($path, qr/\.[^.]*/x);
  $suffix = (substr $suffix, 1) if ((substr $suffix, 0, 1) eq q{.});
  $suffix = 'fasta' if ($suffix eq 'fa');
  return ($iterator, $filename, $suffix);
}

=head2 _import_sequences_from_string

NO TEST

=cut

sub _import_sequences_from_string
{
  my ($string) = @_;
  my $sid = Digest::MD5::md5_hex(time().{}.rand().$$);
  my $fstring = '>' . $sid . "\n" . $string . "\n";
  my $iterator = Bio::SeqIO->new(-string => $fstring, -format => 'fasta') || croak("Cannot parse $string");
  return ($iterator, $sid, 'fasta');
}



=head2 _split_sequences

NO TEST

=cut

sub _split_sequences
{
  my ($inpath, $outpath, $outformat) = @_;
  my ($iterator, $filename, $suffix) = _import_sequences($inpath);
  $outformat = $outformat || $suffix;
  while (my $obj = $iterator->next_seq())
  {
    my $id = $obj->id;
    $id =~ s/\s/\_/g;
    my $thispath = $outpath . q{/} . $id . q{.} . $outformat;
    
  }
}

=head2 _export_sequences

NO TEST

=cut

sub _export_sequences
{
  my ($outpath, $outformat, $seqarr) = @_;

  my ($filename, $dirs, $suffix) = fileparse($outpath, qr/\.[^.]*/x);
  $outpath .= q{.} . $outformat if (! $suffix);
  open (my $OUTFH, '>', $outpath ) || croak ("Cannot write to $outpath ($!)");
  my $FOUT = Bio::SeqIO->new(-fh => $OUTFH, -format => $outformat);
  $FOUT->write_seq($_) foreach (@{$seqarr});
  close $OUTFH;
  return $outpath;
}

=head2 _long_att_fix

=cut

sub _long_att_fix
{
  my ($seqarr) = @_;
  foreach my $seq (@{$seqarr})
  {
    foreach my $feat ($seq->get_SeqFeatures)
    {
      foreach my $tag ($feat->get_all_tags())
      {
        my $value = join(q{}, $feat->get_tag_values($tag));
        $value =~ s/\s//xg;
        $feat->remove_tag($tag);
        $feat->add_tag_value($tag, $value);
      }
    }
  }
  return;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Sarah Richardson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the GeneDesign developers may
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
