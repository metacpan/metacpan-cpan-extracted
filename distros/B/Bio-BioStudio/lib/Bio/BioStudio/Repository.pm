#
# BioStudio genome repository functions
#

=head1 NAME

Bio::BioStudio::Repository

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Repository;
require Exporter;

use Bio::BioStudio::ConfigData;
use Bio::BioStudio::Exceptions;
#use File::Path qw(make_path);
use File::Find;
use Carp;
use English qw(-no_match_vars);

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  _dir_in_repository
  _path_in_repository
  _path_to_DB
  _list_repository
  _prepare_repository
  _list_species
  _gather_species
  _gather_latest
  _gather_oldest
  _repobase
  _endslash
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

my $VERNAME = qr{([\w]+)_[chr]*([\w\d]+)_(\d+)_(\d+)([\_\w+]*)}msix;

=head1 Functions

=cut

=head2 _repobase

=cut

sub _repobase
{
  my $conf = Bio::BioStudio::ConfigData->config('conf_path');
  return $conf . 'genome_repository/';
}

=head2 _species_list

=cut

sub _list_species
{
  my ($repo) = @_;
  $repo = _endslash($repo) || _repobase();
  my %species = ();
  opendir my $dh, $repo || croak "Can't read repo: $OS_ERROR";
  while (defined(my $name = readdir $dh))
  {
    next if ($name eq q{.} || $name eq q{..});
    my $tl = $repo . q{/} . $name;
    next unless (-d "$repo/$name");
    $species{$name} = $tl;
  }
  return %species;
}

=head2 _dir_in_repository

=cut

sub _dir_in_repository
{
  my ($chromosome) = @_;
  my $path = $chromosome->repo() . $chromosome->species . q{/};
  $path .= $chromosome->seq_id . q{/};
  #make_path($path) unless (-e $path);
  return $path;
}

=head2 _path_in_repository

=cut

sub _path_in_repository
{
  my ($chromosome) = @_;
  my $path = _dir_in_repository($chromosome);
  $path .= $chromosome->name . ".gff";
  return $path;
}

=head2 _path_to_DB

=cut

sub _path_to_DB
{
  my ($chromosome) = @_;
  my $path = _dir_in_repository($chromosome);
  $path .= $chromosome->name . ".db";
  return $path;
}

=head2 _list_repository

=cut

sub _list_repository
{
  my ($repo) = @_;
  $repo = _endslash($repo) || _repobase();
  my @srcs;
  find sub { push @srcs, $File::Find::name}, $repo;
  my %sources;
  foreach (grep { $_ =~ m{\.gff\z}msix} @srcs)
  {
    $sources{$1}++ if ($_ =~ /($VERNAME)/msx);
  }
  return \%sources;
}

=head2 _gather_species

=cut

sub _gather_species
{
  my ($species, $repo) = @_;
  $repo = _endslash($repo) || _repobase();
  my $base = $repo . $species . q{/};
  my %specieshsh;
  opendir my $SH, $base || croak ("Can't opendir: $base $OS_ERROR");
  my @dirs = grep {-d "$base/$_" && ! m{^\.*$}msx} readdir($SH);
  closedir $SH;
  foreach my $dir (@dirs)
  {
    my $cbase = $base . $dir . q{/};
    opendir my $CH, $cbase || croak("Can't opendir: $cbase $OS_ERROR");
    my @chrs = grep { m{\.gff$}msix} readdir($CH);
    closedir $CH;
    my @cleans;
    foreach my $path (@chrs)
    {
      my $clean = $path;
      $clean =~ s{\.gff$}{}msx;
      push @cleans, $clean;
    }
    $specieshsh{$dir} = \@cleans;
  }
  return \%specieshsh;
}

=head2 _gather_wildtypes

=cut

sub _gather_oldest
{
  my ($species) = @_;
  my @list = ();
  my $ref = _gather_species($species);
  foreach my $chrid (keys %{$ref})
  {
    my @chrlist = @{$ref->{$chrid}};
    my %sortcrit;
    foreach my $chr (@chrlist)
    {
      if ($chr =~ $VERNAME)
      {
        my ($genver, $chrver) = ($3, $4);
        $sortcrit{$genver . $chrver} = $chr;
      }
      else
      {
        print "Warning: $chr doesn't parse\n";
      }
    }
    my @sorted = sort {$a <=> $b} keys %sortcrit;
    push @list, $sorted[0] if (scalar @sorted);
  }
  return \@list;
}

=head2 _gather_latest

=cut

sub _gather_latest
{
  my ($species, $repo) = @_;
  my @list = ();
  my $ref = _gather_species($species, $repo);
  foreach my $chrid (sort keys %{$ref})
  {
    my @chrlist = @{$ref->{$chrid}};
    my %sortcrit;
    foreach my $chr (@chrlist)
    {
      if ($chr =~ $VERNAME)
      {
        my ($genver, $chrver) = ($3, $4);
        $sortcrit{$genver . $chrver} = $chr;
      }
      else
      {
        print "Warning: $chr doesn't parse\n";
      }
    }
    my @sorted = sort {$b <=> $a} keys %sortcrit;
    push @list, $sortcrit{$sorted[0]} if (scalar @sorted);
  }
  return \@list;
}


=head2 _prepare_repository

=cut

sub _prepare_repository
{
  my ($repo, $species, $chrnum) = @_;
  $repo = _endslash($repo) || _repobase();
  return unless ($species);
  my $spath = $repo . $species . q{/};
  my $cpath = undef;
  if (! -e $spath)
  {
    mkdir $spath;
    chmod 0777, $spath;
  }
  if ($chrnum)
  {
    $cpath = $spath . $chrnum . q{/};
    if (! -e $cpath)
    {
      mkdir $cpath;
      chmod 0777, $cpath;
    }
  }
  return $chrnum  ? $cpath  : $spath;
}

=head2 _endslash

=cut

sub _endslash
{
  my ($path) = @_;
  if ($path && substr($path, -1, 1) ne q{/})
  {
    $path .= q{/};
  }
  return $path;
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

