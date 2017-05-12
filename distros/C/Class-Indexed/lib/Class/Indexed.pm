package Class::Indexed;

################################################################################
# Indexed - An abstract class providing fulltext indexing for classes
# (c) Copyright 2003 Aaron Trevena <aaron.trevena@droogs.org>
# Based on my article for www.perl.com
# inspired by Bulletproof Monk and Tenacious D
#
# Couldn't remember the code to the greatest reverse index in the world,
# this is just a tribute.
#
# The peculiar thing is this my friends,
# the piece of code that I wrote that fateful day looks nothing like this code.
# This is just a tribute. You've got to believe me, and I wish you were there.

=head1 NAME

Class::Indexed : An abstract class providing fine-grained and incremental update fulltext indexing for classes

=head1 SYNOPSIS

use Class::Indexed;

our @ISA = qw(Class::Indexed);

# build the index and metadata tables
Class::Indexed->build_index_tables(database=>$db,host=>$host,username=>$user,password=>$password);

# set which attributes / fields are to be indexed and their weighting, etc
$self->indexed_fields (
                        dbh=>$dbh, key=>'Pub_ID',
                        fields=>[
                                 { name=>'Pub_Name', weight=>1 },
                                ],
                       );

# index an object
$self->index_object();

# index a field or attribute of an object
$self->index_field($self->{Pub_ID}, $field, $value);

# remove the object from the metadata and index tables
$self->delete_location();

# add the object to the metadata table
$self->add_location();

=head1 DESCRIPTION

This abstract class provides inherited indexing functionality to any
class using it as a superclass.

Class::Indexed is designed to provide most of the functionality described
in the article : 'Adding Search Functionality to Perl Applications'
( http://www.perl.com/pub/a/2003/09/25/searching.html ) and I recommend
you read it through to gain understanding of the code and principles
involved.

see the examples for the best explaination of how to use this class

=head1 EXPORT

None by default.

=cut

use strict;
use DBI;
use Class::Indexed::Words;

our $VERSION = 0.01;

################################################################################
# Public methods

=head1 METHODS

=head2 build_index_tables

builds the index and metadata tables, you need to run this before you can use the indexing

my $success = Class::Indexed->build_index_tables(database=>$db,host=>$host,username=>$user,password=>$password);

=cut

sub build_index_tables {
    my ($self,%options) = @_;
    my $success = 0;
    my $dbh = DBI->connect("dbi:mysql:$options{database}:$options{host}", $options{username}, $options{password})
	or die " couldn't connect to db : $options{database} host : $options{host} ";

    my $indextable = $options{indexname} || 'CIRIND';
    my $metadatatable = $options{indexmetadata} || 'CIMETA';

    # create index table
    my $query = <<endindex;
create table $indextable (
CIRIND_Word varchar(64) not null,
CIRIND_Score float,
CIMETA_ID int not null,
CIRIND_Fields varchar(255),
primary key ( CIRIND_Word, CIMETA_ID )
)
endindex
    my $rv = $dbh->do($query);

    # create index metadata table
    $query = <<endmetadata;
create table $metadatatable (
CIMETA_ID integer primary key auto_increment,
CIMETA_Title varchar(64),
CIMETA_Type varchar(16),
CIMETA_Key varchar(32),
CIMETA_KeyValue varchar(128),
CIMETA_URL varchar(255),
CIMETA_Summary text
)
endmetadata
    $rv = $dbh->do($query);
    return $success;
}

=head2 index_object

indexes the object, updates the metadata if required

$self->index_object();

before you can call index_object you must set the fields to be indexed
with the indexed_fields method

=cut

sub index_object {
  my $self = shift;
  foreach my $field (keys %{$self->{_RIND_fields}}) {
      warn "index object : $field : $self->{$field}\n";
      my $success = $self->index_field($field,$self->{$field});
      warn "success : $success\n";
  }
}

=head2 index_field

indexes a particular field or attribute of the object

$self->index_field($fieldname,$value)

takes the name of the attribute/field and the new value

before you can call index_field you must set the fields to be indexed
with the indexed_fields method

=cut

sub index_field {
  my ($self,$field,$value) = @_;
  warn "index_field : $field,$value \n";
  return 0 unless ($self->{_RIND_fields}{$field});
  $self->{_RIND_index_table} ||= 'CIRIND';
  $self->{_RIND_location_table} ||= 'CIMETA';

  my %newwords;
  my @newwords;

  # extract new words from current field or lookup or replacement text
  if ((defined $value and $value ne '') or ( $self->{_RIND_fields}{$field}{replace} || $self->{_RIND_fields}{$field}{lookup} )) {
  MODE: {
	  if (defined $self->{_RIND_fields}{$field}{replace}) {
	      $value = get_words($self->{_RIND_fields}{$field}{replace});
	      last;
	  }
	  if (defined $self->{_RIND_fields}{$field}{lookup} ) {
	      my $column = $self->{_RIND_fields}{$field}{lookup};
	      my $table = $self->{_RIND_fields}{$field}{lookup_table};
	      my $query = $self->{_RIND_fields}{$field}{query};
	      warn "value : $value / column : $column / query : $query \n";
	      unless (defined $query and $query ne '') {
		  $query = qq{select $column from $table where $field = };
		  if ($value =~ /\D/) {
		      $value =~ s/(['"])/\\$1/g;
		      $query .= qq{'$value'};
		  } else {
		      $query .= $value;
		  }
	      }
	      warn "query : $query \n";
	      $value = join ( ' ',@{$self->{_RIND_dbh}->selectcol_arrayref($query)} );
	      last;
	  }
      }				# end of MODE switch

      warn "value : $value \n";
      # get words from value
      @newwords = get_words($value);
      foreach ( @newwords ) {
	  next if $stopwords{$_};
	  $newwords{$_} += $self->{_RIND_fields}{$field}{weight};
      }
      warn "new words : ", @newwords, "\n";
  }

  # get old words from reverse index for current object
  my $location = $self->{_RIND_location};
  my $query = "select * from $self->{_RIND_index_table} where CIMETA_ID = ?";
  my $sth = $self->{_RIND_dbh}->prepare($query);
  my $rv = $sth->execute($location);

  # update reverse index words for this field of this object
  warn "update reverse index \n";
  while ( my $row = $sth->fetchrow_hashref() ) {
    next unless ($row->{CIRIND_Fields} =~  m/'$field'/); # skip unless this word was in the old value of this field
    $self->{__RIND_locationwords}{$row->{CIRIND_Word}} = $row;
    if (exists $newwords{$row->{CIRIND_Word}}) {
      $self->_RIND_UpdateFieldEntry($row,$field,$newwords{$row->{CIRIND_Word}});
      delete $newwords{$row->{CIRIND_Word}}
    } else {
      $self->_RIND_RemoveFieldEntry($row,$field,$location);
    }
  }

  warn "add to reverse index", keys %newwords , "\n";
  foreach (keys %newwords) {
      warn "adding field entry $_ : $newwords{$_} : $field \n";
      $self->_RIND_AddFieldEntry($location,$_,$newwords{$_},$field);
  }
  return 1;
}

=head2 delete_location

remove the object from the metadata and index tables

$self->delete_location();

=cut

sub delete_location {
  my $self = shift;
  $self->{_RIND_index_table} ||= 'CIRIND';
  $self->{_RIND_location_table} ||= 'CIMETA';
  my $query = "delete from $self->{_RIND_index_table} where CIMETA_ID = ?";
  my $sth = $self->{_RIND_dbh}->prepare($query);
  my $rv1 = $sth->execute($self->{_RIND_location});
  $query = "delete from $self->{_RIND_location_table} where CIMETA_ID = ?";
  $sth = $self->{_RIND_dbh}->prepare($query);
  my $rv2 = $sth->execute($self->{_RIND_location});

  return "$rv1:$rv2";
}

=head2 add_location

add the object to the metadata table

$self->add_location();

=cut

sub add_location {
    my ($self,%options) = @_;
    $self->{_RIND_index_table} ||= 'CIRIND';
    $self->{_RIND_location_table} ||= 'CIMETA';
    my $dbh = $options{dbh} || $self->{_dbh};
    my $query = qq{ insert into $self->{_RIND_location_table}
 ( CIMETA_Title,CIMETA_Type, CIMETA_Key, CIMETA_KeyValue, CIMETA_URL, CIMETA_Summary )
 values (?,?,?,?,?,?) };
    warn "query : $query \n";
    my $location_sth = $dbh->prepare($query);
    my @values = map { $_ || 'null' } @options{qw(Title Type Key KeyValue URL Summary)};
    my $rv = $location_sth->execute(@values);
    $self->{_RIND_location} = $location_sth->{mysql_insertid};
    return $rv;
}

=head2 indexed_fields

set which attributes / fields are to be indexed and their weighting, etc
$self->indexed_fields (
                        dbh=>$dbh, key=>'Pub_ID',
                        fields=>[
                                 { name=>'Pub_Name', weight=>1 },
                                ],
                       );


=cut

sub indexed_fields {
  my ($self,%args) = @_;
  $self->{_RIND_index_table} ||= 'CIRIND';
  $self->{_RIND_location_table} ||= 'CIMETA';
  if (keys %args) {
    $self->{_RIND_dbh} = $args{dbh} if defined $args{dbh};
    if ( defined $args{key} ) {
      $self->{RIND_key} = $args{key};
      ($self->{_RIND_location}) = $args{dbh}->selectrow_array("Select CIMETA_ID from $self->{_RIND_location_table} where CIMETA_Key = '$args{key}' and CIMETA_KeyValue = " . $args{dbh}->quote($self->{$args{key}}));
    }
    if ( defined $args{fields} ) {
      foreach ( @{$args{fields}} ) { 
	$self->{_RIND_fields}{$_->{name}} = $_;
      }
    }
  }
  return @{$self->{_RIND_fields}} if wantarray;
}

=head1 AUTHOR

Aaron J. Trevena, E<lt>aaron.trevena@droogs.orgE<gt>

=head1 SEE ALSO

L<perl>.

=cut

####################################################################################
# private methods : don't touch below here
#
# I don't reccomend mucking about with these as they are very self-referential

sub _RIND_UpdateFieldEntry {
  my ($self,$row, $field, $score) = @_;
  my %fields = ( $row->{CIRIND_Fields} =~ m/'(.*?)':([\d.]+)/g );

  # recalculate total score
  my $newscore = ($row->{CIRIND_Score} - $fields{$field} ) + $score;
  return 1 if ($fields{$field} == $score); # skip if score unchanged

  # update entry
  $fields{$field} = $score;
  my $newfields;
   foreach (keys %fields) {
    $newfields .= "'$_':$fields{$_}";
  }
  $self->_RIND_UpdateIndex( word=>$row->{CIRIND_Word},location=>$row->{CIMETA_ID},
			    newscore=>$newscore,newfields=>$newfields );
}

sub _RIND_AddFieldEntry {
  my ($self,$location, $word, $score, $field) = @_;
  warn "_RIND_AddFieldEntry : ($location, $word, $score, $field) \n";
  # check if record already exists for this location and update/insert entry
  if (exists $self->{__RIND_locationwords}{$word}) {
    # recalculate total score
    my $newscore = $self->{__RIND_locationwords}{$word}{CIRIND_Score} + $score;
    # update entry, appending field and score to end
    my $newfields = $self->{__RIND_locationwords}{$word}{CIRIND_Fields} . "'$field':$score";
    $self->_RIND_UpdateIndex( word=>$word,location=>$location, newscore=>$newscore,newfields=>$newfields );
  } else {
    # insert new entry
    $self->_RIND_UpdateIndex( insert=>1, word=>$word,location=>$location, newscore=>$score,newfields=>"'$field':$score" );
  }
}

sub _RIND_RemoveFieldEntry {
  my ($self,$row, $field, $location) = @_;

  # check if record contains scores from other fields
  my %fields = ( $row->{CIRIND_Fields} =~ m/'(.*?)':([d.]+)/g ) ;
  if ( keys %fields > 1 ) {
    # recalculate total score
    my $newscore = $row->{CIRIND_Score} - $fields{$field};
    delete $fields{$field};
    my $newfields;
    foreach (keys %fields) {
      $newfields .= "'$_':$fields{$_}";
    }
    # update entry
    $self->_RIND_UpdateIndex( word=>$row->{CIRIND_Word},location=>$location, newscore=>$newscore,newfields=>$newfields );
  } else {
    # delete entry
    $self->_RIND_UpdateIndex( delete=>1, word=>$row->{CIRIND_Word}, location=>$location);
  }
}

sub _RIND_UpdateIndex {
  my ($self,%args) = @_;
  my $query = qq{ update $self->{_RIND_index_table}
                  set CIRIND_Score = ?, CIRIND_Fields = ?
                  where CIRIND_Word = ? and CIMETA_ID = ? };
  my @args = ($args{newscore},$args{newfields},$args{word},$args{location});

 MODE:{
    if ($args{insert}) {
      $query = qq{ insert into $self->{_RIND_index_table} ( CIRIND_Score, CIRIND_Fields, CIRIND_Word, CIMETA_ID)
                   values (?,?,?,?) };
      last;
    }
    if ($args{delete}) {
      $query = "delete from $self->{_RIND_index_table} where CIRIND_Word = ? and CIMETA_ID = ?";
      shift(@args); shift(@args); # remove unused arguments
      last;
    }
  } # end of MODE switch
  my $sth = $self->{_RIND_dbh}->prepare($query);
  warn " .. _RIND_UpdateIndex ";
  warn " args : @args";
  my $rv = $sth->execute(@args);
  return $rv;
}


##################################################################################

1;

##################################################################################
##################################################################################

