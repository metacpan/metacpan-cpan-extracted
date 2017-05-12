=head1 NAME

Bio::BioStudio::DB::MySQL

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

BioStudio functions for MySQL database interaction.

=head1 AUTHOR

Sarah Richardson <SMRichardson@lbl.gov>.

=cut

package Bio::BioStudio::DB::MySQL;
require Exporter;

use Bio::BioStudio::ConfigData;
use Bio::DB::SeqFeature::Store;
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

=head2 _prefix

=cut

sub _prefix
{
  return 'bsdb_';
}

=head2 _realname

=cut

sub _realname
{
  my ($name) = @_;
  return lc _prefix() . $name;
}

=head2 _pass

=cut

sub _pass
{
  return Bio::BioStudio::ConfigData->config('mysql_pass');
}

=head2 _host

=cut

sub _host
{
  return Bio::BioStudio::ConfigData->config('mysql_host');
}

=head2 _port

=cut

sub _port
{
  return Bio::BioStudio::ConfigData->config('mysql_port');
}

=head2 _user

=cut

sub _user
{
  return Bio::BioStudio::ConfigData->config('mysql_user');
}

=head2 _connectstring

=cut

sub _connectstring
{
  my ($realname) = @_;
  my $cstr = 'dbi:mysql';
  if ($realname)
  {
    $cstr .= ':database=' . $realname . q{:};
  }
  else
  {
   $cstr .= ":"; 
  }
  $cstr .= 'host=' . _host() . ';';
  $cstr .= 'port=' . _port() . ';';
  return $cstr;
}

=head2 _dbh

=cut

sub _dbh
{
  my ($realname) = @_;
  my $cstr = _connectstring($realname);
  my $user = _user();
  my $pass = _pass();
  my $dbh = DBI->connect
  (
    $cstr, $user, $pass,
    {
      RaiseError => 1,
      AutoCommit => 1
    }
  );
  return $dbh;
}

=head2 _database_exists
 
=cut
 
sub _database_exists
{
  my ($realname) = @_;
  my $dblist = _list_databases();
  return exists $dblist->{$realname};
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
  my $name = $chromosome->name;
  my $realname = _realname($name);
  my $dbex = _database_exists($realname);
  if ($dbex && $refresh)
  {
    _drop_database($chromosome);
    _create_database($realname);
    _load_database($chromosome);
  }
  elsif (! $dbex)
  {
    _create_database($realname);
    _load_database($chromosome)
  }
  my $db = Bio::DB::SeqFeature::Store->new
  (
    -adaptor  => "DBI::mysql",
    -dsn      => _connectstring($realname),
    -user     => _user(),
    -pass     => _pass(),
    -write    => 1
  );
  return $db;
}

=head2 _list_databases

This function returns a hash reference containing all BioStudio database names
as keys.

=cut

sub _list_databases
{
  my %dblist;
  my $dbh = _dbh();
  my $cmd = 'SHOW DATABASES';
  if ($dbh)
  {
    my $sth = $dbh->prepare($cmd)
      || croak 'Unable to prepare show databases: ' . $dbh->errstr . "\n";
    $sth->execute || croak 'Unable to exec show databases: ' . $dbh->errstr . "\n";
    my $aref;
    while ($aref = $sth->fetchrow_arrayref)
    {
      $dblist{$aref->[0]}++;
    }
    $sth->finish;
    $dbh->disconnect();
  }
  return \%dblist;
}

=head2 _create_database

This function creates a database that is ready to be loaded with
chromosome data. It does NOT load that database.

=cut

sub _create_database
{
  my ($realname) = @_;
  my $dbh = _dbh();
  $dbh->do("create database $realname;");
  $dbh->disconnect();
  return;
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
  my $realname = _realname($chromosome->name());
  my @args = ('bp_seqfeature_load.pl', '--noverbose');
  push @args, '-f';
  push @args, '-c';
  push @args, '-a';
  push @args, 'DBI::mysql';
  push @args, '-d', _connectstring($realname);
  push @args, $chromosome->path_to_GFF();
  push @args, '--user', _user();
  push @args, '-p', _pass();
  local $SIG{CHLD} = 'DEFAULT';
  system(@args) == 0 or croak "system @args failed: $OS_ERROR";
  return;
}

=head2 _drop_database

This function drops the database associated with a BioStudio chromosome.
 
=cut

sub _drop_database
{
  my ($chromosome) = @_;
  my $realname = _realname($chromosome->name());
  if (_database_exists($realname))
  {
    my $dbh = _dbh($realname);
    $dbh->do("DROP DATABASE IF EXISTS $realname;");
    $dbh->disconnect();
  }
  return;
}

=head2 db_execute

Execute an arbitrary command on an arbitrary database

=cut

sub _db_execute
{
  my ($realname, $command) = @_;
  my $dbh = _dbh($realname);
  if ($dbh)
  {
    $dbh->{'mysql_auto_reconnect'} = 1;
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
  my ($realname, $command) = @_;
  my $dbh = _dbh($realname);
  my @rowrefs = ();
  if ($dbh)
  {
    $dbh->{'mysql_auto_reconnect'} = 1;
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
