package Bio::ConnectDots::ConnectDots;

our $VERSION = '1.0.2';

use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Bio::ConnectDots::DB;
use Bio::ConnectDots::DB::ConnectDots;
use Bio::ConnectDots::DotSet;
use Bio::ConnectDots::ConnectorSet;
use Bio::ConnectDots::ConnectorTable;
use Bio::ConnectDots::Util;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(db
		    label2dotset id2dotset
		    name2cs id2cs
		    name2dt id2dt
		    name2ct id2ct
		    label2labelid
		   );
@OTHER_ATTRIBUTES=qw(connectorsets dotsets connectortables dottables);
%SYNONYMS=();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);
my $VERSION=1.0;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $db=$self->db;
  Bio::ConnectDots::DB::ConnectDots->get($self);
  my $label2labelid= $self->label2labelid({});
  my $connectorsets=$self->connectorsets;
  for my $connectorset (@$connectorsets) {
    my $l2id=$connectorset->label2labelid;
    @$label2labelid{keys %$l2id}=values %$l2id;
  }
}

sub connectorsets {
  my $self=shift;
  if (@_) {
    my $connectorsets=shift;
    my $name2cs=$self->name2cs({});
    my $id2cs=$self->id2cs({});
    for my $connectorset (@$connectorsets) {
      $self->throw("Connectorset must have a version attribute.") unless $connectorset->cs_version;
      $name2cs->{$connectorset->name}{$connectorset->cs_version}=$connectorset;
      $id2cs->{$connectorset->db_id}=$connectorset;
    }
    my $label2labelid=$self->label2labelid({});
    for my $connectorset (@$connectorsets) {
      my $l2id=$connectorset->label2labelid;
      @$label2labelid{keys %$l2id}=values %$l2id;
    }
  }
  my @connectorsets;
  foreach my $csname (keys %{$self->name2cs}) {
	grep { push @connectorsets, $_ } values %{$self->name2cs->{$csname}};
  }
  wantarray? @connectorsets: \@connectorsets;
}
sub dotsets {
  my $self=shift;
  if (@_) {
    my $dotsets=shift;
    my $label2dotset=$self->label2dotset({});
    my $id2dotset=$self->id2dotset({});
    for my $dotset (@$dotsets) {
      $label2dotset->{$dotset->name}=$dotset;
      $id2dotset->{$dotset->db_id}=$dotset;
    }
  }
  my @dotsets=values %{$self->label2dotset};
  wantarray? @dotsets: \@dotsets;
}
sub connectortables {
  my $self=shift;
  if (@_) {
    my $connectortables=shift;
    my $name2ct=$self->name2ct({});
    my $id2ct=$self->id2ct({});
    for my $connectortable (@$connectortables) {
      $name2ct->{$connectortable->name}=$connectortable;
      $id2ct->{$connectortable->db_id}=$connectortable;
    }
  }
  my @connectortables=values %{$self->name2ct};
  wantarray? @connectortables: \@connectortables;
}
sub dottables {
  my $self=shift;
  if (@_) {
    my $dottables=shift;
    my $name2dt=$self->name2dt({});
    my $id2dt=$self->id2dt({});
    for my $dottable (@$dottables) {
      $name2dt->{$dottable->name}=$dottable;
      $id2dt->{$dottable->db_id}=$dottable;
    }
  }
  my @dottables=values %{$self->name2dt};
  wantarray? @dottables: \@dottables;
}

sub connectorset {
  my($self,$name,$version)=@_;  
  if (!$version) { # no specified version, get newest
	foreach my $ver (keys %{$self->name2cs->{$name}}) {
	  $version = $ver if $ver gt $version;
	}
  }
  return $self->name2cs->{$name}->{$version};
}

sub dotset {
  my($self,$name)=@_;
  $self->label2dotset->{$name};
}
sub query {
  my($self,@args)=@_;
  my $args=new Class::AutoClass::Args(@args);
  my $query_type=$args->query_type;
  if ($query_type=~/dot/i || $args->input) {
    my $dottable=new Bio::ConnectDots::DotTable(-connectdots=>$self,-db=>$self->db,%$args);
    $dottable->query($args);
    $self->name2dt->{$dottable->name}=$dottable;
  } else {			# assume it's a ConnectorQuery
    my $connectortable=new Bio::ConnectDots::ConnectorTable(-connectdots=>$self,-db=>$self->db,%$args);
    $connectortable->query($args);
    $self->name2ct->{$connectortable->name}=$connectortable;
  }
}
sub connector_query {
  my($self,@args)=@_;
  my $args=new Class::AutoClass::Args(@args);
  my $connectortable=new Bio::ConnectDots::ConnectorTable
    (-connectdots=>$self,-db=>$self->db,%$args);
  $connectortable->query($args);
  $self->name2ct->{$connectortable->name}=$connectortable;
}
sub dot_query {
  my($self,@args)=@_;
  my $args=new Class::AutoClass::Args(@args);
  my $dottable=new Bio::ConnectDots::DotTable
    (-connectdots=>$self,-db=>$self->db,%$args);
  $dottable->query($args);
  $self->name2dt->{$dottable->name}=$dottable;
}


sub _flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}
1;
__END__

=head1 NAME

Bio::ConnectDots::ConnectDots -- Top level class for 'connect-the-dots'

=head1 SYNOPSIS

  use Bio::ConnectDots::DB;
  use Bio::ConnectDots::ConnectDots;

  my $db=new Bio::ConnectDots::DB(-database=>'test',
                                       -host=>'computername',
                                       -user=>'usename',
                                       -password=>'secret');
  my $cd=my $cd=new Bio::ConnectDots::ConnectDots(-db=>$db);

=head1 DESCRIPTION

This is the top level class for 'Connect the Dots'. At present, it
mainly provides methods for running queries.

Connect the Dots is a general data integration framework targeted 
at translating biological identifiers across multiple transitive databases. 
This software provides an alternative to writing custom parsers to join databases
on common identifiers. See the example queries for details on the scope of database 
joins that can be made.

This software is built upon the PostgreSQL database system (developed with version 7.4.3)
as support for full outer joins is strong. 

=head1 GETTING STARTED

To get started, first you will need to have Postgres installed. http://www.postgresql.org/

Next, you'll need to edit the file C<Bio/ConnectDots/Config.pm> with your Postgres user connections and the name of the database 
that you want to use for Connect the Dots. An example entry from this file looks like: 

  if($db =~ /test/i) {
    $info = {
      host=>'hostname',
      user=>'username',
      password=>'password',
      dbname=>'ctd_unittest'
    };
  }

You'll need to load in some ConnectorSets (databases) with the C<scripts/load.pl> script. An 
example of how to do this can be found in C<scripts/newconnectdot.pl>

At this point you can query the ConnectorSets that you have loaded. There is an example 
query script in C<scripts/example_query.pl>. For details on query options, see below 'Query method'.

For future maintainence of your ConnectorSets, see C<scripts/unload.pl> and C<scripts/update_connectorsets.pl>.

=head1 KNOWN BUGS AND CAVEATS

Please send us bugs that you find. 

=head1 AUTHOR - David Burdick, Nat Goodman

Email dburdick@systemsbiology.org, natg@shore.net

=head1 COPYRIGHT

Copyright (c) 2005 Institute for Systems Biology (ISB). All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 APPENDIX

The rest of the documentation describes the methods.

=head2 Constructors

  Title   : new
  Usage   : $cd=new Bio::ConnectDots::ConnectDots(-db=>$db)
  Function: Reads metadata that tell what ConnectorSets, DotSets, and 
            other elements exist
  Args    : -db => Bio::ConnectDots::DB object connected to database
  Returns : Bio::ConnectDots::ConnectDots object

=head2 Query method

See section below, Full Scoop on Queries, for more explanation.

  Title   : query
  Usage   : see examples below
  Function: Run query, producing a database table
  Args    : see below
  Returns : Nothing

Args for all queries

  -name       => name of query result.  The result will be stored in a database
                 table with this name
  -create     => controls whether to create the table if it already exists
                 default: create if it does not exist
                 true:    create even if it does exist
  -query_type => string combining the terms 'connector' or 'dot' 
                 with 'inner' or 'outer'. 'full' is accepted as a deprecated 
                 synonym for 'outer'
                 defaults: 
                   if neither 'connector' or 'dot' is specified, program tries to infer 
                      type from other parameters
                   if neither  'inner' or 'outer' is specified, default is 'inner'
  -preview    => gives a fast preview of what the result of the query will look like.
                 false (default): produce the full output of the query
                 true: create short subset of rows from the output

Args for ConnectorQueries (see Full Scoop section below for details)

  -ct_aliases  => ConnectorTable aliases
  -cs_aliases  => ConnectorSet aliases
  -joins       => join expression
  -constraints => constraint expression
  -cs_version  => specifies version of each connectorset/alias to use. If not specified, 
                  it select the newest version lexicographically

Args for dot queries (see Full Scoop section below for details)

  -input              => ConnectorTable or ConnectorSet name
  -outputs            => outputs expression
  -constraints        => constraint expression
  -cs_version         => specifies version of the connectorset to use. If not specified,
                         it select the newest version lexicographically 
                         (only for dot queries from connectorsets)
  -outfile            => Dumps the table, tab delimited, to this file.
  -centric            => Column name. Removes rows where this column is NULL. (applicable in outer dot queries)
  -remove_subsets     => Column name. Removes rows that are a subset of other rows. 
  -collapse           => Column name. Collapses all rows with the given identifier into one row. Default seperator is ','
  -collapse_seperator => String specifying an alternate field seperator.
  -xml_root           => Column name. Outputs to -xml_file a collapsed hierarchical XML document of the dot of the dot
                         table where the given root is used similar to a -collapse table. DTD included
  -xml_file           => Specifies the file name for xml output. Without -xml_root specified, the table
                         is exported by row into XML. DTD included

=head3 Examples

Perl NOTE: These examples use the Perl 'q(..)' syntax for quoted
strings.  This is completely equivalent to regular single-quotes, but
indents better in emacs.

A script for running these examples can be found in the file C<scripts/example_query.pl>.

Inner DotQuery operating on LocusLink ConnectorSet

 $cd->query(
   -name=>'inner_locuslink',
   -query_type=>'inner dot',
   -create=>1,
   -input=>'LocusLink',
   -cs_version=>'20040715',
   -input_type=>'connectorset',
   -outputs=>q(LocusLink, UniGene, refSeq, Organism AS Critter, 
               Hugo AS Gene, 'Alias Symbol' AS Alias),
  );

 +-----------+---------+-----------+--------------+------+-------+
 | LocusLink | UniGene | refSeq    | Critter      | Gene | Alias |
 +-----------+---------+-----------+--------------+------+-------+
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | A1B   |
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | ABG   |
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | GAB   |
 | 5         | Hs.5    | NM_000662 | Homo sapiens | NAT1 | AAC1  |
 +-----------+---------+-----------+--------------+------+-------+


Inner DotQuery with constraint operating on LocusLink ConnectorSet

 $cd->query(
   -name=>'innerNM_locuslink',
   -query_type=>'inner dot',
   -create=>1,
   -input=>'LocusLink',
   -input_type=>'connectorset',
   -outputs=>q(LocusLink, UniGene, refSeq, Organism AS Critter, 
               Hugo AS Gene, 'Alias Symbol' AS Alias),
   -constraints=>q(refSeq = NM_130786),
 );

 +-----------+---------+-----------+--------------+------+-------+
 | LocusLink | UniGene | refSeq    | Critter      | Gene | Alias |
 +-----------+---------+-----------+--------------+------+-------+
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | A1B   |
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | ABG   |
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | GAB   |
 +-----------+---------+-----------+--------------+------+-------+ 


Outer DotQuery operating on LocusLink ConnectorSet

 $cd->query(
   -name=>'outer_locuslink',
   -query_type=>'outer dot',
   -create=>1,
   -input=>'LocusLink',
   -input_type=>'connectorset',
   -outputs=>q(LocusLink, UniGene, refSeq, Organism AS Critter, 
               Hugo AS Gene, 'Alias Symbol' AS Alias),
 );

 +-----------+---------+-----------+--------------+------+-------+
 | LocusLink | UniGene | refSeq    | Critter      | Gene | Alias |
 +-----------+---------+-----------+--------------+------+-------+
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | A1B   |
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | ABG   |
 | 1         | Hs.1    | NM_130786 | Homo sapiens | A1BG | GAB   |
 | 2         | Hs.2    | NM_000014 | Homo sapiens | A2M  | NULL  |
 | 3         | Hs.3    | NULL      | Homo sapiens | A2MP | NULL  |
 | 4         | Hs.4    | NULL      | Homo sapiens | AA   | NULL  |
 | 5         | Hs.5    | NM_000662 | Homo sapiens | NAT1 | AAC1  |
 | 5         | Hs.0    | NULL      | Homo sapiens | ACP1 | NULL  |
 +-----------+---------+-----------+--------------+------+-------+


Outer DotQuery on LocusLink with collapse on LocusLink id

 $cd->query(
   -name=>'outer_locuslink',
   -query_type=>'outer dot',
   -create=>1,
   -collapse=>'LocusLink'
   -input=>'LocusLink',
   -input_type=>'connectorset',
   -outputs=>q(LocusLink, UniGene, refSeq, Organism AS Critter, 
               Hugo AS Gene, 'Alias Symbol' AS Alias),
 );

 +-----------+------------+-----------+--------------+-----------+-------------+
 | LocusLink | UniGene    | refSeq    | Critter      | Gene      | Alias       |
 +-----------+------------+-----------+--------------+-----------+-------------+
 | 1         | Hs.1       | NM_130786 | Homo sapiens | A1BG      | A1B,ABG,GAB |
 | 2         | Hs.2       | NM_000014 | Homo sapiens | A2M       | NULL        |
 | 3         | Hs.3       | NULL      | Homo sapiens | A2MP      | NULL        |
 | 4         | Hs.4       | NULL      | Homo sapiens | AA        | NULL        |
 | 5         | Hs.5,Hs.10 | NM_000662 | Homo sapiens | NAT1,ACP1 | AAC1        |
 +-----------+------------+-----------+--------------+-----------+-------------+

Outer DotQuery output on a ConnectorTable without and (after) with -centric and -remove_subsets options 

 $cd->query(
   -name       => 'image_centric',
   -query_type => 'outer dot',
   -create     => 1,
   -input      => 'image_ct',
   -input_type => 'connectortable',
   -outputs    => q(EPconDBhumanchip1.IMAGE_ID, EPconDBhumanchip1.LocusLink, Unigene.UniGene),
 );
 
 +-----------+-----------+------------+
 | IMAGE_ID  | LocusLink | Unigene    |
 +-----------+-----------+------------+
 | IMAGE1    | 1234      | Hs.1       |
 | IMAGE2    | 2245      | Hs.2       |
 | IMAGE3    | 33369     | Hs.3       |
 | IMAGE3    | 77419     | Hs.3       |
 | IMAGE3    | 77419     | NULL       |
 | NULL      | 11155     | Hs.3       |
 +-----------+-----------+------------+

with:   -centric => 'IMAGE_ID'

 +-----------+-----------+------------+
 | IMAGE_ID  | LocusLink | Unigene    |
 +-----------+-----------+------------+
 | IMAGE1    | 1234      | Hs.1       |
 | IMAGE2    | 2245      | Hs.2       |
 | IMAGE3    | 33369     | Hs.3       |
 | IMAGE3    | 77419     | Hs.3       |
 | IMAGE3    | 77419     | NULL       |
 | NULL      | 11155     | Hs.3       |
 +-----------+-----------+------------+

with both:  -centric => 'IMAGE_ID', -remove_subsets => 'IMAGE_ID'

 +-----------+-----------+------------+
 | IMAGE_ID  | LocusLink | Unigene    |
 +-----------+-----------+------------+
 | IMAGE1    | 1234      | Hs.1       |
 | IMAGE2    | 2245      | Hs.2       |
 | IMAGE3    | 33369     | Hs.3       |
 | IMAGE3    | 77419     | Hs.3       |
 +-----------+-----------+------------+

XML output options. Same query as above

 $cd->query(
   -name       => 'image_centric',
   -query_type => 'outer dot',
   -create     => 1,
   -input      => 'image_ct',
   -input_type => 'connectortable',
   -outputs    => q(EPconDBhumanchip1.IMAGE_ID, EPconDBhumanchip1.LocusLink, Unigene.UniGene),
   -xml_file   => 'image_centric.xml',
 );

XML Output:

  <!DOCTYPE DotTable [<!ELEMENT DotTable (row*)>
     <!ATTLIST DotTable name CDATA #REQUIRED>
     <!ELEMENT row (IMAGE_ID*,LocusLink*,Unigene*)>
     <!ATTLIST row line CDATA>
     <!ELEMENT IMAGE_ID (#PCDATA)>
     <!ELEMENT LocusLink (#PCDATA)>
     <!ELEMENT Unigene (#PCDATA)>]>
  <DotTable name='image_centric'>
  <row line='1'>
    <IMAGE_ID>IMAGE1</IMAGE_ID>
    <LocusLink>1234</LocusLink>
    <Unigene>Hs.1</Unigene>
  </row>
  <row line='1'>
    <IMAGE_ID>IMAGE2</IMAGE_ID>
    <LocusLink>2245</LocusLink>
    <Unigene>Hs.2</Unigene>
  </row>
  ...
  </DotTable>

XML Output with -xml_root='IMAGE_ID' (DTD omitted)

 $cd->query(
   -name       => 'image_centric',
   -query_type => 'outer dot',
   -create     => 1,
   -input      => 'image_ct',
   -input_type => 'connectortable',
   -outputs    => q(EPconDBhumanchip1.IMAGE_ID, EPconDBhumanchip1.LocusLink, Unigene.UniGene),
   -xml_file   => 'image_centric.xml',
   -xml_root   => 'IMAGE_ID',
 );

 <DotTable name='image_centric'>
   <IMAGE_ID id='IMAGE1'>
     <LocusLink>1234</LocusLink>
     <Unigene>Hs.1</Unigene>
   </IMAGE_ID>
   <IMAGE_ID id='IMAGE2'>
     <LocusLink>2245</LocusLink>
     <Unigene>Hs.2</Unigene>
   </IMAGE_ID>
   ...
 </DotTable>


Inner ConnectorQuery operating on LocusLink, HsUnigene, and HGU133A ConnectorSets

 $cd->query(
   -name=>'inner_cs',
   -query_type=>'inner connector',
   -create=>1,
   -cs_aliases=>q(HsUnigene AS UG, HGU133A AS Affy),
   -joins=>q(LocusLink.LocusLink=UG.LocusLink AND
             UG.UniGene=Affy.UniGene),
   -cs_version=>'LocusLink=20040715, UG=20040231, Affy=v2.0'
 );

 +-----------+------+----+
 | LocusLink | Affy | UG |
 +-----------+------+----+
 |         9 |   13 |  2 |
 |        12 |   13 |  6 |
 |        10 |   14 |  3 |
 |        11 |   15 |  4 |
 +-----------+------+----+


Inner ConnectorQuery operating on ConnectorTable produced by previous
query and HsUnigene ConnectorSet

 $cd->query(
   -name=>'inner_cs_ct',
   -query_type=>'inner connector',
   -create=>1,
   -cs_aliases=>q(HsUnigene AS UG),
   -joins=>q(inner_cs.Affy.UniGene=UG.UniGene)
   -cs_version=>'UG=20040231'
 );

 +--------------------+---------------+-------------+----+
 | inner_cs_LocusLink | inner_cs_Affy | inner_cs_UG | UG |
 +--------------------+---------------+-------------+----+
 |                  9 |            13 |           2 |  2 |
 |                  9 |            13 |           2 |  6 |
 |                 12 |            13 |           6 |  2 |
 |                 12 |            13 |           6 |  6 |
 |                 10 |            14 |           3 |  3 |
 |                 11 |            15 |           4 |  4 |
 +--------------------+---------------+-------------+----+


Outer ConnectorQuery operating on LocusLink, HsUnigene, and HGU133A
ConnectorSets.  

 $cd->query(
   -name=>'outer_cs',
   -query_type=>'outer connector',
   -create=>1,
   -cs_aliases=>q(HsUnigene AS UG, HGU133A AS Affy),
   -joins=>q(LocusLink.LocusLink=UG.LocusLink AND
             UG.UniGene=Affy.UniGene),
 );

 +-------+------+-----------+
 | UG    | Affy | LocusLink |
 +-------+------+-----------+
 |  1    | NULL |         8 |
 |  2    |   13 |         9 |
 |  3    |   14 |        10 |
 |  4    |   15 |        11 |
 |  5    |   16 |      NULL |
 |  6    |   13 |        12 |
 |  NULL |   17 |      NULL |
 |  NULL | NULL |         7 |
 +-------+------+-----------+


Outer ConnectorQuery operating on ConnectorTable produced by previous
query and HsUnigene ConnectorSet. 

 $cd->query(
   -name=>'outer_cs_ct',
   -query_type=>'outer connector',
   -create=>1,
   -cs_aliases=>q(HsUnigene AS UG),
   -joins=>q(outer_cs.Affy.UniGene=UG.UniGene)
 );

 +--------------------+---------------+-------------+------+
 | outer_cs_LocusLink | outer_cs_Affy | outer_cs_UG | UG   |
 +--------------------+---------------+-------------+------+
 |                  8 |          NULL |           1 | NULL |
 |                  9 |            13 |           2 |    2 |
 |                  9 |            13 |           2 |    6 |
 |                 10 |            14 |           3 |    3 |
 |                 11 |            15 |           4 |    4 |
 |               NULL |            16 |           5 |    5 |
 |                 12 |            13 |           6 |    2 |
 |                 12 |            13 |           6 |    6 |
 |               NULL |            17 |        NULL | NULL |
 |                  7 |          NULL |        NULL | NULL |
 |               NULL |          NULL |        NULL |    1 |
 +--------------------+---------------+-------------+------+



Outer ConnectorQuery that joins three copies of the inner_ct
ConnectorTable produced in a previous query.  

 $cd->query(
   -name=>"ct_ct_ct_join",
   -query_type=>'outer connector',
   -create=>1,
   -ct_aliases=>q(outer_ct AS ct0, outer_ct AS ct1, outer_ct AS ct2),
   -cs_aliases=>q(HsUnigene AS UG),
   -joins=>q(ct0.LocusLink.LocusLink=ct1.LocusLink.LocusLink AND
             ct1.UG.UniGene=ct2.UG.UniGene),
 );

 +---------------+----------+--------+---------------+----------+--------+---------------+----------+--------+
 | ct0_LocusLink | ct0_Affy | ct0_UG | ct1_LocusLink | ct1_Affy | ct1_UG | ct2_LocusLink | ct2_Affy | ct2_UG |
 +---------------+----------+--------+---------------+----------+--------+---------------+----------+--------+
 |             8 |     NULL |      1 |             8 |     NULL |      1 |             8 |     NULL |      1 |
 |             9 |       13 |      2 |             9 |       13 |      2 |             9 |       13 |      2 |
 |             9 |       13 |      2 |             9 |       13 |      2 |            12 |       13 |      6 |
 |            10 |       14 |      3 |            10 |       14 |      3 |            10 |       14 |      3 |
 |            11 |       15 |      4 |            11 |       15 |      4 |            11 |       15 |      4 |
 |          NULL |       16 |      5 |          NULL |     NULL |   NULL |          NULL |     NULL |   NULL |
 |            12 |       13 |      6 |            12 |       13 |      6 |             9 |       13 |      2 |
 |            12 |       13 |      6 |            12 |       13 |      6 |            12 |       13 |      6 |
 |          NULL |       17 |      0 |          NULL |     NULL |   NULL |          NULL |     NULL |   NULL |
 |             7 |     NULL |      0 |             7 |     NULL |      0 |          NULL |     NULL |   NULL |
 |          NULL |     NULL |      0 |          NULL |       16 |      5 |          NULL |       16 |      5 |
 |          NULL |     NULL |      0 |          NULL |       17 |      0 |          NULL |     NULL |   NULL |
 |          NULL |     NULL |      0 |          NULL |     NULL |   NULL |          NULL |       17 |      0 |
 |          NULL |     NULL |      0 |          NULL |     NULL |   NULL |             7 |     NULL |      0 |
 +---------------+----------+--------+---------------+----------+--------+---------------+----------+--------+

=head2 Full Scoop on Queries

Queries produce 'warehouse' tables that are stored in the
database. Queries DO NOT return data to the program -- to get the
results of a query, you have to run regular Postgres SQL queries against the
warehouse tables.

The system supports two broad classes of queries: (1)
ConnectorQueries, and (2) DotQueries.

ConnectorQueries create tables of related Connectors, eg, entries
from LocusLink, UniGene, etc, that are linked.  The result of a
ConnectorQuery is a ConnectorTable.  

NEW: ConnectorQueries can operate on ConnectorSets or other
ConnectorTables.  This makes it possible to create ConnectorTables in
'stages'. For example, one could create separate ConnectorTables for
human, mouse, rat, ... genes, then combine pairs using a homology
ConnectorSet or ConnectorTable.

DotQueries produce tables that contain actual identifiers, eg,
LocusLink id's, UniGene id's, etc. that are linked.  The result of a
DotQuery is a DotTable.  DotQueries are usually run against
ConnectorTables, although as a special case, they can also be run
against individual ConnectorSets. 

In the end, users want DotTables.  ConnectorTables are a scaffold
against which many different DotQueries can be run.

Both ConnectorQueries and DotQueries come in two 'flavors' depending
on the kind of relational joins that are done: inner, and outer (aka
full). As the names suggest, 'inner' queries use regular inner joins,
while 'outer' queries use full outer joins.  In most cases, 'inner'
queries return less data than 'outer' and are much more efficient.

Queries are expressed in a structured, textual query language which is
vaguely reminiscent of SQL. 

For advanced use by software, it's also possible to express queries
using objects.  In essense, it's possible to feed the query methods
the object structures produced by the code that parses the text
language.  This interface is not described in this document.  

=head3 ConnectorQueries

A ConnectorQuery usually 'joins' 2 or more ConnectorSets or
ConnectorTables, each of which can be 'constrained'.  It is also
possible for a ConnectorQuery to operate on a single input (ie,
ConnectorSet or ConnectorTable) in which case the query must have a
constraint (else it would accomplish nothing).

A ConnectorQuery has 4 parts: -constraints, -joins, -ct_aliases, -cs_aliases.  
All are optional, except that at least one of -constraints or -joins must be 
specified, or else the query would do nothing. Each part is specified in text 
form (or, can be specified by objects as noted above).

=head4 -constraints and -joins

Here is a simple example of -contraints and -joins.

 -constraints => "LocusLink.Hugo = AA AND LocusLink.Organism = 'Homo sapiens'"
 -joins       => "LocusLink.LocusLink=HsUnigene.LocusLink AND HsUnigene.UniGene=HGU133A.UniGene"

See, like I said, it's very SQL-esque.

Queries on ConnectorTables are slightly more complex, because a
ConnectorTable refers to multiple underlying ConnectorSets.  For
example, suppose HumanGenes is a ConnectorTable that connects data
from LocusLink, UniGene, and various Affy datasets for human genes.
Now suppose you want to constrain HumanGenes to rows whose LocusLink
data has Hugo = AA.  You'd say this as follows:

 -constraints => "HumanGenes.LocusLink.Hugo = AA"

In general, a term referring to a ConnectorSet will have the form

 <ConnectorSet>.<label>

while a term referring to a ConnectorTable will have the form

 <ConnectorTable>.<column -- ie, underlying ConnectorSet>.<label>

This is true for joins as well as constraints.  Thus, to join
HumanGenes with HsUnigene on LocusLink (kind of silly to do in this
example, but bear with me), you'd say

 -joins => "HumanGenes.LocusLink.LocusLink=HsUnigene.LocusLink"

The query language supports a limited form of 'OR'.  Instead of a
single label, you can specify a list of labels, or the wildcard '*' in
any term.  Also, in constraints, you can specify a list of constants
instead of a single constant.  Here's an example of a list join

 -joins => "HumanGenes.LocusLink.[Hugo,'Alias Symbol']=HsUnigene.'Gene Name'

The join expression means that we'll join a HumanGenes row with an
HsUnigene connector if the Hugo symbol or any Alias Symbol in the LocusLink connector matches the Gene Name in the HsUnigene connector. Lists can appear on both sides of the join, eg, 

 -joins => "HumanGenes.LocusLink.[Hugo,'Alias Symbol']=HsUnigene.['Gene Name',Title]

This means we'll join a HumanGenes row with an
HsUnigene connector if the Hugo symbol or any Alias Symbol in the LocusLink connector matches the Gene Name or Title in the HsUnigene connector.  Note that the order of labels in the lists doesn't matter: the system does NOT match the first label on the left with the first on the right or anything like that.

Constraints are similar:

 -constraints => "HumanGenes.LocusLink.* = [caspase-1, casp1]"

The constraint expression means that we'll accept a HumanGenes row if any
dot in it's LocusLink component equals 'caspase-1' or 'casp1'.

=head4 Constraint Operators

The full set of allowable constraint operators are

  =, ==
  <, <=, !=, >=, >

  IN, NOT IN
  EXISTS

If no operator is provided, the default is '='.

 '=' and '==' are synonymous. 

All operators except EXISTS require that a constant or list of
constants be provided.  The EXISTS operator merely tests that the
specified term exists, and is similar to the SQL operator IS NOT NULL.

In most cases, IN and NOT IN operate on lists, eg, LocusLink.Hugo IN
[AA A1BG].  However, it does work to provide these oparators with
single constants, eg, LocusLink.Hugo IN AA.  If '=' or '!=' are given
lists, they are translated into 'IN' and 'NOT IN' respectively.

=head4 -ct_aliases and -cs_aliases

ct_aliases defines a list of ConnectorTable aliases and is only
needed if the same ConnectorTable is used multiple times in the query.
Likewise, -cs-aliases defines a list of ConnectoSet aliases and is
only needed if the same ConnectorSet is used multiple times in the
query.  Aliases can also be used to define shorthands for inputs with
long names.

The syntax is SQL-like:  <real name> AS <alias>,...
For example,

 -cs_aliases => "LocusLink AS HumanLL, LocusLink AS MouseLL"
 -ct_aliases => "HumanGenes AS HG, MouseGenes AS MG"

=head3 DotQueries

A DotQuery retrieves identifiers that are connected via a
ConnectorTable or ConnectorSet.  You can also further constrain the
ConnectorTable or ConnectorSet.

A DotQuery has 3 parts: -input, -outputs, -constraints.  The first two are mandatory.

 -input gives the name of the input ConnectorTable or ConnectorSet.  
 A further parameter -input_type tells which kind of object it is.

 -outputs lists the fields (ie, dots) that are output.  When operating
 on a ConnectorTable, each output is specified by giving the name of a
 column (which refers to a ConnectorSet) and the label of the
 identifier.  

For example to retrieve the Hugo symbol from the LocusLink connector
and Title from the UniGene connector, you would ask for

 -outputs => "LocusLink.Hugo, UniGene.Title"

You can also give a new name to the output using the SQL-like AS keyword, for example,

 -outputs => "LocusLink.Hugo AS GeneSymbol, UniGene.Title AS GeneName"

CAVEAT:  Do not use quoted phrases as the output names, eg LocusLink.Hugo AS 'Gene Symbol'. 

When operating on a ConnectorSet, outputs can be specified more simply
since the ConnectorSet name is implicit.  For example, the retrieve the 
LocusLink, UniGene, and refSeq identifiers from the LocusLink ConnectorSet:

 -outputs => "LocusLink, UniGene, refSeq"

Constraints are almost the same as for ConnectorQueries, except that
that the input name is implicit.  When operating on a ConnectorSet, a term 
need only state the label.  For example,

 -constraints => "Hugo in IN [AA A2MP]"

When operating on a ConnectorTable, a term must provide a column and label, eg,

 -constraints => "LocusLink.Hugo in IN [AA A2MP]"

=cut
