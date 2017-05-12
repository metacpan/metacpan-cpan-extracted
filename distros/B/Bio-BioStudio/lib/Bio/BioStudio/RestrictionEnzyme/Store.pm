#
# BioStudio module
#

=head1 NAME

Bio::BioStudio::RestrictionEnzyme::Store

=head1 VERSION

Version 2.10

=head1 DESCRIPTION

An object that stores the database handle for a MySQL database full of
restriction enzyme recognition sites - usually corresponding to the sites
found on a chromosome that is being prepared for segmentation.

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>

=cut

package Bio::BioStudio::RestrictionEnzyme::Store;

use base qw(Bio::Root::Root);

use Bio::BioStudio::DB qw(:BS);

use strict;
use warnings;

our $VERSION = 2.10;

my $tblname = 'positions';

=head1 CONSTRUCTORS

=head2 new

There are two required arguments:

    -name       the name of the database
    
    -enzyme_definitions This is a reference to a hash that has
                L<Bio::GeneDesign::RestrictionEnzyme> objects as values. This
                hash can be obtained from the GeneDesign function define_sites.
 
The other arguments are optional:
    
    -file    Path to a dumpfile that is used to quickload the MySQL database.
    
    -create  A flag that causes creation of the database. Otherwise, an attempt
             is made to open a handle to an existing database.
    
=cut

sub new
{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);

  my ($name, $file, $create, $RES) =
     $self->_rearrange([qw(NAME FILE CREATE ENZYME_DEFINITIONS)], @args);

  $self->throw('No name defined') unless ($name);
  $self->{name} = $name;

  $self->throw('No enzymes defined') unless ($RES);
  $self->{enzyme_definitions} = $RES;
    
  $self->{dumpfile} = $file if ($file);
    
  if ($create)
  {
    _drop_database($name);
    _create_database($name);
    $self->_initialize();
  }

  return $self;
}

=head1 FUNCTIONS

=head2 load

Load the database from the dumpfile (defined during the call to new)

=cut

sub load
{
  my ($self) = @_;
  $self->throw('No dumpfile described!') unless ($self->{dumpfile});
  $self->throw('Cannot find dumpfile!') unless (-e $self->{dumpfile});
  my $command = "LOAD DATA LOCAL INFILE \"" . $self->{dumpfile} . "\" INTO TABLE ";
  $command .= _prefix() . $self->{name} . q{.} . $tblname;
  $command .= " FIELDS TERMINATED BY '.' LINES TERMINATED BY '\n' ";
  $command .= '(name, presence, start, end, enzyme, feature, peptide, ';
  $command .= 'overhangs, strand, overhangoffset);';
  return _db_execute($self->{name}, $command);
}

=head2 search

Performs a search of the database.

  -name   search by the name field

  -left   a lower bound for the search on the start field

  -right  an upper bound for the search on the start field

  -enzyme search by the id of the enzyme (BamHI, BssSI etc)

Returns an array reference containing L<Restriction Enzyme|Bio::BioStudio::RestrictionEnzyme>
objects.

=cut

sub search
{
  my ($self, @args) = @_;
  my ($name, $left, $right, $enzyme) = $self->_rearrange([qw(
       NAME   LEFT   RIGHT   ENZYME)], @args);
  my $command = 'SELECT id, name, presence, eligible, start, end, enzyme, ';
  $command .= 'feature, strand, overhangs, peptide, overhangoffset FROM ';
  $command .= $tblname;
  my @wheres = ();
  push @wheres, "name = '$name'" if ($name);
  push @wheres, "start >= $left" if ($left);
  push @wheres, "end <= $right" if ($right);
  push @wheres, "enzyme = '$enzyme'" if ($enzyme);
  $command .= ' WHERE ' . join(' AND ', @wheres) if (scalar(@wheres));
  $command .= q{;};

  my $results = _db_search($self->{name}, $command, 'mysql');
  my @parse = @{$results};
  my @res = ();
  foreach my $aref (@parse)
  {
    my $eid = $aref->[6];
    my $edef = $self->{enzyme_definitions}->{$eid};
    $self->throw("$eid is undefined for this database") unless $edef;
    
    my %overhangs = map {$_ => 1} split(q{,}, $aref->[9]);
    
    push @res, Bio::BioStudio::RestrictionEnzyme->new
    (
      -dbid       => $aref->[0],
      -name       => $aref->[1],
      -presence   => $aref->[2],
      -eligible   => $aref->[3],
      -start      => $aref->[4],
      -end        => $aref->[5],
      -enzyme     => $edef,
      -featureid  => $aref->[7],
      -strand     => $aref->[8],
      -overhangs  => \%overhangs,
      -peptide    => $aref->[10],
      -offset     => $aref->[11]
    );
  }
  return \@res;
}

=head2 cull

Removes entries from the database.

  Arguments: a reference to a list of numbers that correspond to primary ids in
      the database; all rows whose primary key is in the list will be removed.

=cut

sub cull
{
  my ($self, $cullref) = @_;
  my @list = @{$cullref};
  while (my @portion = splice(@list, 0, 500))
  {
    my $command = 'DELETE from positions where id in (';
    $command .= join(q{,}, @portion) . q{);};
    _db_execute($self->{name}, $command);
  }
  return;
}

=head2 screen

Marks entries in the database as ineligible (sets the eligible field to "no").

  Arguments: a reference to a list of numbers that correspond to primary ids in
      the database; all rows whose primary key is in the list will be marked
      ineligible.
      
=cut

sub screen
{
  my ($self, $screenref) = @_;
  my @list = @{$screenref};
  while (my @portion = splice(@list, 0, 500))
  {
    my $command = "UPDATE positions set `eligible` = \"no\" where id in (";
    $command .= join(q{,}, @portion) . q{);};
    _db_execute($self->{name}, $command);
  }
  return;
}

=head1 Accessor functions

=head2 name

Returns the name of the database.

=cut

sub name
{
  my ($self) = @_;
  return $self->{name};
}

=head2 dumpfile

Returns the path to the file used to quickload the MySQL database.

=cut

sub dumpfile
{
  my ($self) = @_;
  return $self->{dumpfile};
}

=head2 enzyme_definitions

The hash of generic L<GeneDesign RestrictionEnzyme|Bio::GeneDesign::RestrictionEnzyme>
objects that are used to bootstrap creation of L<BioStudio RestrictionEnzyme|Bio::BioStudio::RestrictionEnzyme>
objects. This hash can be created by calling L<define_sites()|Bio::GeneDesign::RestrictionEnzymes::define_sites>

=cut

sub enzyme_definitions
{
  my ($self) = @_;
  return $self->{enzyme_definitions};
}

=head1 Private functions

=head2 _initialize

Creates the only table in the database.

=cut

sub _initialize
{
  my ($self) = @_;
  my $def = $self->_table_definition;
  my $command = "CREATE table IF NOT EXISTS $tblname $def->{$tblname}";
  return _db_execute($self->{name}, $command);
}

=head2 _table_definition

Private: the SQL definition of the table that stores enzyme information

=cut

sub _table_definition
{
  my $hsh =
  {
    $tblname => <<"END",
(
  id              int           not null auto_increment primary key,
  name            varchar(45)   not null,
  presence        varchar(40)   not null,
  eligible        varchar(3)    null,
  start           int           not null,
  end             int           not null,
  enzyme          varchar(45)   not null,
  feature         varchar(100)  not null,
  peptide         varchar(45)   null,
  overhangs       text          null,
  strand          varchar(3)    not null,
  overhangoffset  int           null,
  index ENZYME (enzyme ASC),
  index POSITION (start ASC, end ASC)
)
END
  };
  return $hsh;
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
