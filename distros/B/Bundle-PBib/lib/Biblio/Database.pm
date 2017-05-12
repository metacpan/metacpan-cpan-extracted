# --*-Perl-*--
# $Id: Database.pm 10 2004-11-02 22:14:09Z tandler $
#

package Biblio::Database;
use 5.006;
use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}


# This class is a subclass of DBI::db, exported by the DBI module.
use DBI 1.0;
use Biblio::BP;

#use vars qw(@ISA);
#@ISA = qw(DBI::db);

use Carp;

# don't print sql communication
my $debug_sql = 0;


sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my %args = @_;

  #### first check for DSN!

  my $DSN = $ENV{'BIBLIO_DSN'} || $args{'dsn'};
  my $DBMS = $ENV{'BIBLIO_DBMS'} || $args{'dbms'} || 'ODBC';
  my $DBHOST = $ENV{'BIBLIO_HOST'} || $args{'host'} || $args{'dbhost'} ;
  my $DBNAME = $ENV{'BIBLIO_NAME'} || $args{'name'} || $args{'dbname'} || 'biblio';
  my $DBUSER = $ENV{'BIBLIO_USER'} || $args{'user'} || $args{'dbuser'};
  my $DBPASS = $ENV{'BIBLIO_PASS'} || $args{'pass'} || $args{'dbpass'};
  my $DBATTR = $args{'attr'} || $args{'dbattr'};
  $debug_sql = 1 if $args{'debug_sql'};
  $DBMS || $DSN or croak "Missing DBMS or DSN specification, did you give one?\n" .
  		"You can set \$BIBLIO_DBMS or \$BIBLIO_DSN in the environment.\n";

  # If we use Informix, specify host via INFORMIXSERVER env var. At
  # this place, we may need to add special cases for other DBMS;
  # init code that must be done before the first

  # we use ODBC often in case of ADABAS-driver. ADABAS has,
  # like ORACLE, his own user managment inside each Database. So we
  # need user authorisation for ODBC ...

  if ( $DBMS eq 'Informix' ) {
	if ( ! $ENV{INFORMIXSERVER} ) {
	  chomp( $ENV{INFORMIXSERVER} = $DBHOST || `hostname` );
	}
	if ( ! $ENV{INFORMIXDIR} ) {
	  if ( -d '/opt/informix' ) {
		$ENV{INFORMIXDIR} = '/opt/informix';
	  } elsif ( -d '/usr/informix' ) {
		$ENV{INFORMIXDIR} = '/usr/informix';
	  } else {
		croak "Cannot locate Informix directory, please set INFORMIXDIR";
	  }
	}
	if ( $DBNAME !~ /\@/ ) {
	  $DBNAME .= "\@$DBHOST";
	}
  } elsif ( $DBMS eq 'Solid' ) {
	unless ( $ENV{DBI_USER} ) {
	    $ENV{DBI_USER} = $ENV{DBI_PASS} = 'solid';
    }
  } elsif ( $DBMS eq 'mysql' ) {
	unless( $DSN ) {
		$DSN = "dbi:mysql:database=$DBNAME";
		$DSN .= ";host=$DBHOST" if $DBHOST;
	}
  }

  # Connect to database.
  # FIXME: Should set RaiseError to true here.
  $DSN = "dbi:$DBMS:$DBNAME" unless( $DSN );
  $DBATTR = { AutoCommit => 0,
			PrintError => 0,
			RaiseError => 0,
			} unless $DBATTR;
  my $db = DBI->connect($DSN, $DBUSER, $DBPASS, $DBATTR)
      or croak "$DBI::errstr\nCannot connect to $DBMS database $DBNAME ($DSN)";

  # FIXME: Doesn't work as expected. Fields with several blanks
  # should be reduced to the empty string, while they have one blank
  # now. (Or similar, at least that's my impression, not fully
  # checked.) Therefore we set it to 0 and chop the blanks ourselves
  # below.
  $db->{ChopBlanks} = 0;

#    $db->do ('set transaction isolation level read committed;')
#	or croak "$DBI::errstr\nCannot set isolation level";
  $self = {
	'db' => $db,
	%args,
	};
  return bless $self, $class;
}

sub DESTROY ($) {
  my $self = shift;
  $self->disconnect();
}



#
#
# DBI methods
#
#

sub db { return shift->{'db'}; }
sub disconnect { my $self = shift;
  my $db = $self->db();
  $db->disconnect(@_) if($db);
  $self->{'db'} = undef;
}
sub do { return shift->db()->do(@_); }
sub commit { return shift->db()->commit(@_); }

sub prepare {
  my $self = shift;
  my ($stmt, $attr) = @_;

  # Sanitize the query a bit: Chop trailing semicolon, chop comments
  $stmt =~ s/;\s*$//;
  $stmt =~ s/^--.*$/\t/mg;

  return $self->db()->prepare($stmt, $attr);
}

# $table = $db->query(SQL_STMT, \%ATTR, PARAM, ...);
# foreach $row ( @$table ) { <access @$row> }
#
# Make a query and gather complete result. Use it if it's of no
# advantage to output the result row-wise during fetch, it'll save you
# to handle statement handlers, etc.
sub query {
  my $self = shift;
  my ($sql_stmt, $attr, @params) = @_;
  # my $driver = $self->{Driver};
  my ($maxrows, @result) = (undef);	# @result is the empty list

  # Check if maxrows attribute is set.
  if ( defined($attr) && defined(%$attr) && exists($attr->{maxrows}) ) {
	$maxrows = $attr->{maxrows};
	delete($attr->{maxrows});
  }

  my $sth = $self->prepare($sql_stmt, $attr)
      or croak "$DBI::errstr\nCannot prepare SQL stmt \n$sql_stmt";

  $sth->execute(@params)
      or croak "$DBI::errstr\nCannot execute SQL statement";

  # NOTE: We cannot use DBI handle method fetchall_arrayref(), as it
  # won't chop blanks correctly and it won't look at the maxrows
  # attribute. Maybe, at some time, DBI will support our demands
  # directly.
  my @row;
  my $row_count = 0;
  while ( @row = $sth->fetchrow_array() ) {

	# We need to strip SPC bytes at the end.
	#
	# FIXME: Check if that's needed for _all_ database drivers.
	# Check in particular selection of empty columns and columns
	# with only one space. In both cases we should get the empty
	# string!
	foreach ( @row ) {
	    s/\s*$//  if ( defined($_) );
	}

	# We have to copy to be able to keep the reference to the row.
	# Otherwise we would keep $n$ references to the same row...
	# Note: The information that each fetchrow() returns the same
	# row (with different values) is from DBD::Informix, version
	# 0.24. As 0.25 is a complete rewrite, it might be different
	# here. Nevertheless we'll copy for a while.

        # FIXME: Check if it's still the same row. How about
        # $db->fetch? Does this return the same row?

	my @copy_row = @row;
	push (@result, \@copy_row);
#	print STDERR "DEBUG ==> row [$result[$#result]]: @row";

	last  if ( $maxrows  &&  ++$row_count >= $maxrows );
    }

  $sth->finish()
      or carp "$DBI::errstr\nProblems releasing SQL statement";
  return \@result;
}


#
#
# methods
#
#

sub getCiteKeys {
# return all paper IDs
  my $self = shift;
  my @paperIDs;
  my $row;
###  foreach $row (@{$self->queryPapers(undef, undef, ['CiteKey'])})
###    { push @paperIDs, $row->{'CiteKey'}; }
  @paperIDs = keys %{$self->queryPapers(undef, undef, ['CiteKey'])};
# print "@paperIDs\n";
  return @paperIDs;
}


sub papers {
# return all papers as defined in DB
  my $self = shift;
  my $papers = $self->{'biblioPapers'};
  if( not defined($papers) ) {
    $papers = $self->queryPapers();
    $self->{'biblioPapers'} = $papers;
  }
  return $papers;
}

sub allPaperFields {
	my $self = shift;
	return [ keys(%{$self->{'column-types'}}) ];
  #  return [
	#  "CiteKey", "CiteType", "PBibNote",
	#  "Identifier", "Location", "Authors",
	#  "SuperTitle", "Chapter",
	#  "Edition", "Editors",
	#  "Howpublished", "Institution", "Journal",
	#  "Month", "Keywords", "Number",
	#  "Organization", "Pages", "Publisher",
	#  "School", "Series", "Title",
	#  "ReportType", "Volume", "Year", "Source", "ISBN",
	#  "Category", "CrossRef", "File", "Recommendation",
	#  ];
}

sub biblio_table {
	my ($self) = @_;
	return $self->{'biblio_table'} || 'biblio';
}

my @_citeTypes = qw(
	article
	book
	booklet
	inproceedings
	inbook
	incollection
	inproceedings
	journal
	manual
	masterthesis
	misc
	phdthesis
	proceedings
	report
	unpublished
	email
	web
	video
	talk
	poster
	thesis
	patent
	);
my %_types = (
	'conference' => 6,
	'techreport' => 13,
	);
for( my $i = 0; $i < scalar(@_citeTypes); $i++ ) {
  $_types{$_citeTypes[$i]} = $i;
}
#  print Dumper \%_types;

sub citeTypes {
  return [@_citeTypes];
}
sub CiteTypeForType {
  my ($self, $Type) = @_;
  return defined($Type) ? $_citeTypes[$Type] : undef;
}
sub TypeForCiteType {
  my ($self, $CiteType) = @_;
  return $_types{$CiteType};
}

sub queryPapers {
# query papers, look in $queryFields for $pattern
  my $self = shift;
  my ($pattern, $queryFields, $resultFields, $ignoreCase) = @_;
  $ignoreCase = 1 if not defined($ignoreCase);
  $pattern = lc($pattern) if($ignoreCase);
  $resultFields = $self->allPaperFields() unless defined($resultFields);
  my $table = $self->biblio_table();
  my $sql = 'SELECT ' . join(', ', map($self->quoteField($_), @{$resultFields})) .
	" FROM $table" .
	($queryFields && $pattern ?
	  ' WHERE ' .
	  join(' OR ',
	   map('(' . $self->quoteField($_, $ignoreCase) . 
		   " LIKE " .
			$self->quoteValue($_, $pattern) .
			')', @{$queryFields}))
	: ''
	);
  print STDERR "$sql\n" if( $debug_sql );
  my $papers = $self->query($sql) or
    die "$DBI::errstr\nSelect failed for $sql\n";
  return $self->papersArrayToHash($resultFields, $papers);
}

sub queryPaperWithId ($$) {
  my ($self, $id) = @_;
  my $resultFields = $self->allPaperFields();
  my $table = $self->biblio_table();
  my $sql = 'SELECT ' . join(', ', map($self->quoteField($_, 0), @{$resultFields})) .
	" FROM $table WHERE " . 
		$self->quoteField("CiteKey") . ' = ' . 
		$self->quoteValue("CiteKey", $id);
  print "$sql\n" if( $debug_sql );
  my $papers = $self->query($sql) or
    croak "$DBI::errstr\nSelect failed for $sql\n";
#  return undef unless $papers->[0];
  my $result = $self->papersArrayToHash($resultFields, $papers);
  return $result->{$id};
}

#  my %fieldMapping = qw(
	#  CiteKey	Custom4
	#  Category	Custom1
	#  Recommendation	Custom5
	#  CrossRef	Custom2
	#  File	Custom3
	#  Keywords	Note
	#  PBibNote	Annote
	#  Organization	Organizat
	#  Institution	Institutn
	#  Authors	Author
	#  Editors	Editor
	#  ReportType	RepType
	#  SuperTitle	Booktitle
	#  Source	URL
	#  Location	Address
	#  Howpublished	Howpublish
	#  );
sub quoteField($$;$) {
	my ($self, $field, $ignoreCase) = @_;
	my $mapping = $self->{'column-mapping'} || {};
	$field = $mapping->{$field} if exists($mapping->{$field});
	$field = "\"$field\"" if $self->{'quote-column-name'};
	$field = "lower($field)" if $ignoreCase 
			&& $self->{'supports-lower'};
	return $field;
}

sub quoteValue ($$$) {
	my ($self, $field, $value) = @_;
	my $column_types = $self->{'column-types'} || {};
	my $type = $column_types->{$field};
	if( $type =~ /INT/i ) { return $value; }
#  print "$type\n";
	# grab the length from the type, strip any text.
	$type =~ /(\d+)/;
	my $length = $1 || $self->{'column-max-string-length'} || 254;
	if( length($value) > $length ) {
		print STDERR "WARNING: long string value in $field: ", 
			length($value),
			" (max $type) -> might fail ...\n";
	}
	$value =~ s/\'/\'\'/g;
	return "'$value'";
}

sub papersArrayToHash ($$$) {
# map all paper arrays to paper hashs
  my $self = shift;
  my ($resultFields, $papers) = @_;
  my @results = map($self->paperArrayToHash($resultFields, $_), @{$papers});
  my %papers = map( ($_->{'CiteKey'} => $_), @results);
  return \%papers;
}

sub paperArrayToHash ($$$) {
# map the given paper array to a paper hash
	my $self = shift;
	my ($resultFields, $paper) = @_;
#print $paper->[0], " ";
#  print STDERR '.';
	my $r = {}; my $id; my $v; my $i = 0;
	foreach $id (@{$resultFields}) {
		$v = $self->replaceShortcuts($paper->[$i++]);
		$r->{$id} = $v if defined($v) && $v ne '';
	}
	# now check for some important fields
	$r->{'CiteKey'} = '<<no CiteKey found>>' 
		unless defined($r->{'CiteKey'});
	# convert CiteType from numeric to text format
	my $CiteType = $r->{'CiteType'};
	if( defined($CiteType) && 
			$self->{'column-types'}->{'CiteType'} =~ /INT/i &&
			$CiteType =~ /^\d+$/ ) {
		$CiteType = $self->CiteTypeForType($CiteType);
		$r->{'CiteType'} = $CiteType if defined $CiteType;
	}
	# my database (StarOffice) has not all fields I need.
	# therefore I use the PBibNote field to generate the
	# contents of several others
	if( defined($r->{'PBibNote'}) ) {
		my @fields = split(/\r?\n/, $r->{'PBibNote'});
		#my $dump =0;
		my @notes;
		foreach my $f (@fields) {
			if( $f =~ /^([a-z]+)\s*=\s*(.*)\s*$/i ) {
				$r->{$1} = $2; #$dump = 1;
			} else {
				push @notes, $f;
			}
		}
		if( scalar @notes ) {
			$r->{'PBibNote'} = join("\n", @notes);
		} else {
			delete $r->{'PBibNote'};
		}
		#  print Dumper $r if $r->{'CiteKey'} eq 'iRoom-PointRight';
	}
	return $r;
}


#
#
# add & update papers
#
#

my %aliasFields = qw/
	DOI			Source
	/;

sub storePaper {
  my ($self, $ref, $update) = @_;
  my $id = $ref->{'CiteKey'};
  my $old_ref = $self->queryPaperWithId($id);

  # prepare the fields ...
  my %refFields = %$ref;

  unless( defined($old_ref) ) {
    # check for some standard fields that must be present!
	print "no CiteKey" unless defined($ref->{'CiteKey'});
	print "no Category" unless defined($ref->{'Category'});
	if( ! defined($refFields{'Identifier'}) ) {
	  #  my $key = Biblio::BP::Util::genkey(%$ref);
	  #  $key = Biblio::BP::Util::regkey($key);
	  my $key = $ref->{'CiteKey'};
	  print STDERR "Generate new Identifier: $key\n";
	  $refFields{'Identifier'} = $key;
	}
  }

	# ... copy some fields (as defaults for others)
	foreach my $f (keys %aliasFields) {
	  if( defined $refFields{$f} &&
			! defined $refFields{$aliasFields{$f}} ) {
	    $refFields{$aliasFields{$f}} = $refFields{$f};
	  }
	}
	
	# ... set the BibDate
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
		localtime();
	$refFields{'BibDate'} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
		$year + 1900, $mon, $mday, $hour, $min, $sec);
	#  use POSIX qw(strftime);
	#  $now_string = strftime("%a %b %e %H:%M:%S %Y", localtime());

  # ... convert CiteType from text to numeric format
  if( defined($refFields{'CiteType'}) &&
	    $self->{'column-types'}->{'CiteType'} =~ /INT/i ) {
    my $type = $self->TypeForCiteType($refFields{'CiteType'});
	#print "type = $type\n";
	if( defined $type ) {
	  $refFields{'CiteType'} = $type;
	}
  }

  my %bibFields;
  foreach my $f (@{$self->allPaperFields()}) {
    if( exists($refFields{$f}) ) {
	  $bibFields{$f} = $self->quoteValue($f, $refFields{$f});
	  delete $refFields{$f};
	}
  }
  # add all remaining fields to PBibNote field
  if( %refFields ) {
#    print STDERR "remaining fields for $id:\n";
##	print Dumper \%refFields;
    #### ...
	my $note = join("\n", map( "$_ = $refFields{$_}", keys %refFields));
#	print STDERR "$note\n";
	$note = "$bibFields{'PBibNote'}\n\n$note\n" if defined $bibFields{'PBibNote'};
	$bibFields{'PBibNote'} = $self->quoteValue('PBibNote', $note);
  }
#print Dumper \%bibFields;

  my $biblio = $self->biblio_table();
  my $sql;
  if( defined($old_ref) ) {
    # this ref was already in the DB => update it
	my $assignments = join(', ',
	  map($self->quoteField($_, 0) . " = $bibFields{$_}", keys %bibFields));
	$sql = "UPDATE $biblio SET $assignments WHERE " .
  	  $self->quoteField("CiteKey") . " = '$id'"
  } else {
    # this is a new ref => insert it into the DB
	my ($fields, $values) =
	  (join(', ', map($self->quoteField($_, 0), keys %bibFields)),
	   join(', ', values %bibFields));
    $sql = "INSERT INTO $biblio ($fields) VALUES ($values)";
  }
  print "$sql\n" if( $debug_sql );
  $self->do($sql) or
    croak "\nDB access failed:\n\n$DBI::errstr\n\n$sql\n";
}



#
#
# shortcuts
#
#

sub replaceShortcuts {
# look in $text and replace all shortcuts
  my ($self, $text) = @_;
  return undef unless defined($text);
  # check, if there is any {} field at all -> this is *much* faster!
  return $text unless $text =~ /\{/;
  my $shortcuts = $self->shortcuts();
  my $pattern = join("|", map( /:$/ ? "$_.*" : $_, (keys(%{$shortcuts}))));
#print $pattern;
  $text =~ s/\{($pattern)\}/ $self->expandShortcut($shortcuts, $1) /ge;
  return $text;
}
sub expandShortcut {
  my ($self, $shortcuts, $text) = @_;
  my @pars = split(/:/, $text);
  my $k = shift @pars; if( @pars ) { $k = "$k:"; }
  my $v = $shortcuts->{$k};
  $v =~ s/%(\d)/ $pars[$1-1] /ge;
#print "\n\n$k ---- $v\n\n";
  return $v;
}

sub shortcuts_table {
	my ($self) = @_;
	return $self->{'shortcuts_table'};
}
sub shortcuts {
	my ($self) = @_;
	return $self->{'shortcuts'} if defined($self->{'shortcuts'});
	my $shortcuts_table = $self->shortcuts_table();
	return $self->{'shortcuts'} = {} unless $shortcuts_table;
	my $sql = "SELECT * FROM $shortcuts_table";
	print "$sql\n" if( $debug_sql );
	my $result = $self->query($sql);
	unless( $result ) {
		print STDERR "$DBI::errstr\nSelect failed for $sql\n";
		return {};
	}
	#use Data::Dumper;
	#  print Dumper $self;
	my %scs = map(($_->[0] => $_->[1]), @{$result});
	return $self->{'shortcuts'} = \%scs;
}

sub updateShortcuts {
  my ($self) = @_;
  delete $self->{'shortcuts'};
}

1;

#
# $Log: Database.pm,v $
# Revision 1.17  2003/06/16 09:07:41  tandler
# - support for 'mysql' dbms
# - DB design can now be configured (columns in DB)
# - field to DB column mapping can now be configured
# - the CiteType column in DB can be a text or numeric format,
#   numeric format is automatically converted
# - field "BibDate" is always updated in storePaper() call
#
# Revision 1.16  2003/05/22 11:49:53  tandler
# some fixes. Custom2 is now CrossRef
#
# Revision 1.15  2003/05/19 13:03:35  tandler
# disable AutoComit, we commit explicitely.
#
# Revision 1.14  2003/04/16 15:03:23  tandler
# suppress empty fields (needed for DBD::CSV)
# the name of the shortcuts table can now be configured (no shortcuts are used, if set to empty of undef).
#
# Revision 1.13  2003/04/15 17:35:58  tandler
# some support for DBD::CSV
#  - more flexibility to configure dbname, quoting of fields etc.
# --> still need improvement ...
#
# Revision 1.12  2003/04/15 13:48:34  tandler
# fixed prototypes
#
# Revision 1.11  2003/04/14 09:43:41  ptandler
# field mapping updated
#
# Revision 1.10  2003/01/27 21:10:20  ptandler
# use CiteKey as StarOffice's "Identifier" field
#
# Revision 1.9  2003/01/14 11:06:52  ptandler
# new config
#
# Revision 1.8  2002/11/05 18:27:52  peter
# PBibNote handling fix
#
# Revision 1.7  2002/11/03 22:12:06  peter
# PBibNote handling
#
# Revision 1.6  2002/09/11 10:43:44  peter
# BP::readpbib
#
# Revision 1.5  2002/08/22 10:38:04  peter
# - Field name fix
# - citeType fix (report instead of techreport, techreport is now an alias)
# - use alias fields for import of records
#
# Revision 1.4  2002/06/06 07:26:59  Diss
# renamed PaperID -> CiteKey (new canonical fields due to bp)
#
# Revision 1.3  2002/06/03 11:38:31  Diss
# support to add/update refs in biblio DB
#
# Revision 1.2  2002/04/03 10:10:16  Diss
# include some stuff from NPC's Database.pm
#
# Revision 1.1  2002/03/27 10:00:50  Diss
# new module structure, not yet included in LitRefs/LitUI (R2)
#
# Revision 1.6  2002/03/18 11:15:47  Diss
# major additions: replace [] refs, generate bibliography using [{}], ...
#
# Revision 1.5  2002/03/07 12:01:51  Diss
# per default return all fields in queries
#
# Revision 1.4  2002/02/25 12:20:08  Diss
# Biblio can now ignore case in queries (using the SQL lower function),
# LitUI queries are now case-insensitive, and system() is used to open files.
#
# Revision 1.3  2002/02/11 11:57:06  Diss
# lit UI with search dialog, script to start/stop biblio, and more ...
#
# Revision 1.2  2002/01/26 18:21:54  ptandler
# - disconnect from Biblio-DB in LitRef's destructor (DESTROY)
#   -> this allows to re-read the entries without re-connecting
# - moved Word-Doc support from LitUI to LitRef
#
# Revision 1.1  2002/01/14 08:30:26  ptandler
# new module "Biblio.pm" to access biblio database via DBI/ODBC
# LitRefs can get all defined paperIDs now from BIBLIO (using Biblio.pm)
#