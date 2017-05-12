=head1 NAME

Bio::BioStudio::DB::SQLite

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions for SQLite database interaction.

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>.

=cut

package Bio::BioStudio::DB::SQLite;
require Exporter;

use Bio::BioStudio::ConfigData;
use Bio::DB::SeqFeature::Store;
use File::Find;
use IPC::Open2;
use DBI;
use English qw(-no_match_vars);
use Carp;

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  _drop_database
  _fetch_database
  _db_execute
  _db_search
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);


=head1 DATABASE FUNCTIONS

=head2 _dbrepo

=cut
sub _dbrepo
{
  my $repo = Bio::BioStudio::ConfigData->config('conf_path');
  $repo = $repo . 'genome_repository/';
  return $repo;
}

=head2 _dbpath_from_chr

=cut

sub _dbpath_from_chr
{
  my ($chromosome) = @_;
  my $repopath = $chromosome->path_in_repo();
  my $dbname = $chromosome->name() . '.db';
  return $repopath . $dbname;
}

=head2 _dbh

=cut

sub _dbh
{
  my ($chromosome) = @_;
  my $cstr = 'dbi:SQLite:dbname=' . _dbpath_from_chr($chromosome);
  my $dbh = DBI->connect
  (
    $cstr, q{}, q{},
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );
  return $dbh;
}

=head2 _fetch_database

Fetches a Bio::DB::SeqFeature::Store interface for a database containing
the annotations of the argument chromosome. An optional write flag sets whether
or not the interface will support adding, deleting, or modifying features.

  Returns: A L<Bio::DB::SeqFeature::Store> object.

=cut

sub _fetch_database
{
  my ($chromosome, $refresh) = @_;
  $refresh = $refresh || 0;
  my $dbpath = _dbpath_from_chr($chromosome);
  my $dbex = -e $dbpath;
  if (! $dbex && $refresh)
  {
    _drop_database($chromosome);
  }
  my $db = Bio::DB::SeqFeature::Store->new
  (
    -adaptor  => "DBI::SQLite",
    -dsn      => $dbpath,
    -tmpdir   => Bio::BioStudio::ConfigData->config('tmp_path'),
    -write    => 1
  );
  if (! $dbex || $refresh)
  {
    _load_database($chromosome)
  }
  return $db;
}

=head2 _load_database

This function loads a database (which must have been previously created,
see create_database()) with a GFF file. The file is the one corresponding to the
first argument provided unless the alternate is defined, in which case the file
corresponding to the third argument is loaded into a database named after the
first argument.

  Arguments: Optionally, the name of an alternate chromosome to be loaded using
               the database name provided in the first argument

=cut

sub _load_database
{
  my ($chromosome) = @_;
  my ($inh, $outh) = (undef, undef); 
  my $cmd = 'bp_seqfeature_load.pl --noverbose -f -c -a DBI::SQLite';
  $cmd .= ' -d ' . _dbpath_from_chr($chromosome);
  $cmd .= q{ } . $chromosome->path_to_GFF();
  my $pid = open2($outh, $inh, $cmd) || croak "oops on $cmd: $OS_ERROR / $!";
  waitpid $pid, 0;
  return;
}

=head2 _drop_database

This function drops the database associated with a BioStudio chromosome.
 
=cut

sub _drop_database
{
  my ($chromosome) = @_;
  my $dbpath = _dbpath_from_chr($chromosome);
  if ( -e $dbpath)
  {
    unlink $dbpath;
  }
  return;
}

=head2 db_execute

Execute an arbitrary command on an arbitrary database

=cut

sub _db_execute
{
  my ($dbname, $command) = @_;
  my $dbh = _dbh($dbname);
  if ($dbh)
  {
    my $sth = $dbh->prepare($command) or croak ($dbh->errstr . "\n");
    $sth->execute or croak ($dbh->errstr . "\n");
    $sth->finish;
    $dbh->disconnect();
  }
  return;
}

=head2 db_search

Execute a search command on an arbitrary database

=cut

sub _db_search
{
  my ($dbname, $command) = @_;
  my $dbh = _dbh($dbname);
  my @rowrefs = ();
  if ($dbh)
  {
    my $sth = $dbh->prepare($command) or croak ($dbh->errstr . "\n");
    $sth->execute or croak ($dbh->errstr . "\n");
    while (my $aref = $sth->fetchrow_arrayref)
    {
      my @instance = @{$aref};
      push @rowrefs, \@instance;
    }
    $sth->finish;
    $dbh->disconnect();
  }
  return \@rowrefs;
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
