## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::SQLite.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser|formatter: SQLite database (for DTA EvalCorpus)

package DTA::CAB::Format::SQLite;
use DTA::CAB::Format;
use DTA::CAB::Datum ':all';
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'sqlite', filenameRegex=>qr/\.(?i:sqlite)(?:\:.*)?$/);
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    (
##     ##---- Input
##     doc => $doc,                    ##-- buffered input document
##     db_user => $user,	       ##-- db user (required?)
##     db_pass => $pass,	       ##-- db password (required?)
##     db_dsn  => $dsn,		       ##-- db dsn (set by fromFile())
##     db_opts => \%dbopts,	       ##-- additional options for DBI->connect() ; default={sqlite_unicode=>1}
##     f_which => $f_which,            ##-- restriction (see fromFile())
##     f_where => $f_where,            ##-- target value for restriction (see fromFile())
##     limit => $limit,		       ##-- sql limit clause (default: undef: none)
##     keep_history => $bool,	       ##-- if true, parse history as well as raw data (default: 1)
##     keep_null => $bool,	       ##-- if true, NULL values from db will be kept as undef (default: false)
##     keep_eps => $bool,	       ##-- if true, empty-string values from db will be kept as undef (default: false)
##     keep_temp => $bool,	       ##-- if true, temporary tables will be kept (default: false)
##
##     ##---- Output
##     #(disabled)
##
##     ##---- Common
##     dbh => $dbh,		       ##-- underlying database handle
##     raw => $bool,		       ##-- if false, will call forceDocument() on doc data
##
##     ##---- INHERITED from DTA::CAB::Format
##     #utf8     => $bool,             ##-- always true
##     #level    => $formatLevel,      ##-- 0:compressed, 1:formatted, ...
##     #outbuf   => $stringBuffer,     ##-- buffered output
##    )
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- Input
			   #doc => undef,
			   db_user=>undef,
			   db_pass=>undef,
			   db_dsn=>undef,
			   db_opts=>{
				     sqlite_unicode=>1,
				    },
			   f_which=>undef,
			   f_where=>undef,
			   limit=>undef,
			   keep_history=>1,
			   keep_null=>0,
			   keep_eps=>0,
			   keep_temp=>0,

			   ##-- Output
			   #level  => 0,
			   #outbuf => '',

			   ##-- common
			   #utf8 => 1,
			   #dbh  => undef,
			   #raw => 0,

			   ##-- logging
			   trace_level => 'trace',
			   #trace_level => undef,

			   ##-- user args
			   @_
			  );
}

##==============================================================================
## Methods: db stuff
##  + mostly lifted from DbCgi.pm (svn+ssh://odo.dwds.de/home/svn/dev/dbcgi/trunk/DbCgi.pm @ 7672)
##==============================================================================
our $DBI_INITIALIZED = 0; ##-- package-global sentinel: have we loaded DBI ?

## $class_or_object = $class_or_object->dbi_init();
sub dbi_init {
  return 1 if ($DBI_INITIALIZED);
  eval 'use DBI;';
  $_[0]->logconfess("could not 'use DBI': $@") if ($@);
  return $_[0];
}


## $dbh = $fmt->dbh()
##  + returns database handle; implicitly calls $fmt->dbconnect() if not already connected
sub dbh {
  my $fmt = shift;
  return $fmt->{dbh} if (defined($fmt->{dbh}));
  return $fmt->dbconnect();
}

## $fmt = $fmt->dbconnect()
##  + (re-)connect to database; sets $fmt->{dbh}
sub dbconnect {
  my $fmt = shift;
  #print STDERR __PACKAGE__, "::dbconnect(): dsn=$fmt->{db_dsn}; CWD=", getcwd(), "\n";
  $fmt->dbi_init();
  my $dbh = $fmt->{dbh} = DBI->connect(@$fmt{qw(db_dsn db_user db_pass)}, {AutoCommit=>1,RaiseError=>1, %{$fmt->{db_opts}||{}}})
    or $fmt->logconfess("dbconnect(): could not connect to $fmt->{db_dsn}: $!");
  return $fmt;
}

## $fmt = $fmt->dbdisconnect
##  + disconnect from database and deletes $fmt->{dbh}
sub dbdisconnect {
  my $fmt = shift;
  $fmt->{dbh}->disconnect if (UNIVERSAL::can($fmt->{dbh},'disconnect'));
  delete $fmt->{dbh};
  return $fmt;
}

## $sth = $fmt->execsql($sqlstr)
## $sth = $fmt->execsql($sqlstr,\@params)
##  + executes sql with optional bind-paramaters \@params
sub execsql {
  my ($fmt,$sql,$params) = @_;
  $fmt->vlog($fmt->{trace_level}, "execsql(): $sql\n");

  my $sth = $fmt->dbh->prepare($sql)
    or $fmt->logconfess("execsql(): prepare() failed for {$sql}: ", $fmt->dbh->errstr);
  my $rv  = $sth->execute($params ? @$params : qw())
    or $fmt->logconfess("execsql(): execute() failed for {$sql}: ", $sth->errstr);
  return $sth;
}

## \%name2info = $fmt->column_info(                   $table)
## \%name2info = $fmt->column_info(          $schema, $table)
## \%name2info = $fmt->column_info($catalog, $schema, $table)
##  + get column information for table as hashref over COLUMN_NAME; see DBI::column_info()
sub column_info {
  my $fmt = shift;
  my ($sth);
  if    (@_ >= 3) { $sth=$fmt->dbh->column_info(@_[0..2],undef); }
  elsif (@_ >= 2) { $sth=$fmt->dbh->column_info(undef,@_[0,1],undef); }
  else {
    confess(__PACKAGE__, "::column_info(): no table specified!") if (!$_[0]);
    $sth=$fmt->dbh->column_info(undef,undef,$_[0],undef);
  }
  die(__PACKAGE__, "::column_info(): DBI returned NULL statement handle") if (!$sth);
  return $sth->fetchall_hashref('COLUMN_NAME');
}


## @colnames = $fmt->columns(                   $table)
## @colnames = $fmt->columns(          $schema, $table)
## @colnames = $fmt->columns($catalog, $schema, $table)
##  + get column names for $catalog.$schema.$table in db-storage order
sub columns {
  my $fmt  = shift;
  return map {$_->{COLUMN_NAME}} sort {$a->{ORDINAL_POSITION}<=>$b->{ORDINAL_POSITION}} values %{$fmt->column_info(@_)};
}

##======================================================================
## DB Stuff: Data Retrieval


## $row_arrayref = $fmt->fetch1row_arrayref($sql)
## $row_arrayref = $fmt->fetch1row_arrayref($sql,\@params)
##  + get a single row from the database as an ARRAY-ref
*fetch1row = \&fetch1row_arrayref;
sub fetch1row_arrayref {
  my $fmt = shift;
  my $sth = $fmt->execsql(@_);
  return $sth->fetchrow_arrayref();
}

## @row_array = $fmt->fetch1row_array($sql)
## @row_array = $fmt->fetch1row_array($sql,\@params)
##  + get a single row from the database as an array
sub fetch1row_array {
  my $fmt = shift;
  my $row = $fmt->fetch1row_arrayref(@_);
  return defined($row) ? @$row : qw();
}

## $row_hashref = $fmt->fetch1row_hashref($sql,\@params)
##  + get a single row from the database as a hash-ref
sub fetch1row_hashref {
  my $fmt = shift;
  my $sth = $fmt->execsql(@_);
  return $sth->fetchrow_hashref();
}

## $rows_arrayref_of_arrayrefs = $fmt->fetchall_arrayref($sql)
## $rows_arrayref_of_arrayrefs = $fmt->fetchall_arrayref($sql,\@params)
##  + get all rows from the database as an ARRAY-ref
*fetchall = \&fetchall_arrayref;
sub fetchall_arrayref {
  my $fmt = shift;
  my $sth = $fmt->execsql(@_);
  return $sth->fetchall_arrayref();
}

## $rows_arrayref_of_hashrefs = $fmt->fetchall_hashrows($sql,\@params)
##  + get all rows from the database as an array-ref of hash-refs
sub fetchall_hashrows {
  my $fmt = shift;
  my $sth = $fmt->execsql(@_);
  my $acols = $sth->{NAME};
  my $arows = $sth->fetchall_arrayref();
  return $fmt->hashrows($acols,$arows);
}

## $hash_of_hashres = $fmt->fetchall_hh($sql,$keyfield,\@params)
##  + get all rows from the database as a hash-ref of hash-refs
sub fetchall_hh {
  my ($fmt,$sql,$key) = splice(@_,0,3);
  my $hrows = $fmt->fetchall_hashrows($sql,@_);
  return { map {(($_->{$key}||'')=>$_)} @$hrows };
}

## \@hashrows = $fmt->hashrows(\@array_row_colnames,\@array_rows)
##  + returns ARRAY-ref of HASH-refs for each row of @array_rows rows, keyed by \@array_row_colnames
##  + respects $fmt->{keep_null}
sub hashrows {
  my ($fmt,$anames,$arows) = @_;
  my $hrows = [];
  my ($arow);
  no warnings 'uninitialized';
  foreach $arow (@$arows) {
    push(@$hrows,{map {($anames->[$_]=>$arow->[$_])}
		  grep {
		    (($fmt->{keep_null} || defined($arow->[$_]))
		     &&
		     ($fmt->{keep_eps}  || ($arow->[$_] ne '')))
		  } (0..$#$anames)});
  }
  return $hrows;
}


##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
sub noSaveKeys {
  return ($_[0]->SUPER::noSaveKeys, qw(doc dbh));
}

##==============================================================================
## Methods: I/O: generic
##==============================================================================

## @layers = $fmt->iolayers()
##  + override returns only ':raw'
sub iolayers {
  return qw(:raw);
}

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->close($savetmp)
##  + close current input source, if any
##  + default calls $fmt->{tmpfh}->close() if available and $savetmp is false (default)
##  + always deletes $fmt->{fh} and $fmt->{doc}
sub close {
  my $fmt = shift;
  $fmt->dbdisconnect();
  return $fmt->SUPER::close();
}

## $fmt = $fmt->fromFh($fh)
##  + override calls $fmt->fromFh_str
sub fromFh {
  $_[0]->logconfess("fromFh() not supported");
}

## $fmt = $fmt->fromString(\$string)
sub fromString {
  $_[0]->logconfess("fromString() not supported");
}

## $fmt = $fmt->fromFile($filename)
##  + input from an sqlite db file
##  + sets $fmt->{db_dsn} and calls $fmt->dbconnect();
##  + attempts to parse "$filename" into as "FILE:WHICH=WHERE"
##    where "WHICH=WHERE" may be one of:
##      all=ALL			##-- full corpus
##      doc=DOCID
##      dtadir=DOC_DTADIR
##      dir=DOC_DTADIR		##-- alias for 'dtadir'
##      base=DOC_DTADIR		##-- alias for 'dtadir'
##      s=SQL_SENT_QUERY
##      w=SQL_TOKEN_QUERY
sub fromFile {
  my ($fmt,$filespec) = @_;
  $fmt->vlog($fmt->{trace_level}, "filespec=$filespec");
  $fmt->close();
  if ($filespec =~ /^([^\:]*)\:([^\=]*)(?:\=(.*))?$/) {
    @$fmt{qw(file f_which f_where)} = ($1,$2,$3);
  } else {
    @$fmt{qw(file f_which f_where)} = ($filespec,'all','1');
  }
  $fmt->{db_dsn} = "dbi:SQLite:dbname=$fmt->{file}";
  $fmt->vlog($fmt->{trace_level}, "db_dsn=$fmt->{db_dsn}");
  $fmt->vlog($fmt->{trace_level}, "f_which=".(defined($fmt->{f_which}) ? $fmt->{f_which} : '-undef-'));
  $fmt->vlog($fmt->{trace_level}, "f_where=".(defined($fmt->{f_where}) ? $fmt->{f_where} : '-undef-'));
  return $fmt->dbconnect();
}

##--------------------------------------------------------------
## Methods: Input: Local

## $doc = $fmt->parseDocument()
sub parseDocument {
  my $fmt = shift;

  ##-- preparations
  my $dbh = $fmt->dbh() or $fmt->logconfess("no database handle!");

  ##-- get restrictions -- build @$drows,@$srows,@$wrows, @$shrows,@$whrows
  my $f_which = $fmt->{f_which} || 'all';
  my $tmp   = $fmt->{keep_temp} ? 'tmp' : "tmp$$";
  my $tmpkw = $fmt->{keep_temp} ? ''    : 'temporary';
  my $whorder = 'order by  rdate desc';
  my $shorder = 'order by srdate desc';
  my ($drows,$srows,$wrows, $shrows,$whrows);
  if (!$f_which || $f_which eq 'all') {
    $drows = $fmt->fetchall_hashrows("select * from    doc;");
    $srows = $fmt->fetchall_hashrows("select * from   sent;");
    $wrows = $fmt->fetchall_hashrows("select * from ptoken;");
    if ($fmt->{keep_history}) {
      $shrows = $fmt->fetchall_hashrows("select * from   sent_history $shorder;");
      $whrows = $fmt->fetchall_hashrows("select * from ptoken_history $whorder;");
    }
  }
  elsif ($f_which =~ m/^(?:all|doc|dtadir|dir|base)$/) {
    ##-- restrict: doc
    if ($f_which eq 'doc') {
      ##-- restrict: doc: by sql id
      $drows = $fmt->fetchall_hashrows("select * from doc where doc=?",[$fmt->{f_where}]);
    } else {
      ##-- restrict: doc: by dtadir
      $drows = $fmt->fetchall_hashrows("select * from doc where dtadir=?",[$fmt->{f_where}]);
    }
    $fmt->logconfess("no document found for $fmt->{f_which}=$fmt->{f_where}") if (!@$drows);

    $srows = $fmt->fetchall_hashrows("select * from   sent where doc=?;",[$drows->[0]{doc}]);
    $wrows = $fmt->fetchall_hashrows("select * from ptoken where doc=?;",[$drows->[0]{doc}]);

    if ($fmt->{keep_history}) {
      $shrows = $fmt->fetchall_hashrows("select * from   sent_history where  sent in (select  sent from  sent where doc=?) $shorder;", [$drows->[0]{doc}]);
      $whrows = $fmt->fetchall_hashrows("select * from ptoken_history where token in (select token from token where doc=?) $whorder;", [$drows->[0]{doc}]);
    }
  }
  elsif ($f_which eq 's') {
    ##-- restrict: sentence query
    $fmt->execsql("drop table if exists s_$tmp;");
    $fmt->execsql("create $tmpkw table s_$tmp (sent integer not null primary key);");
    $fmt->execsql("insert or ignore into s_$tmp $fmt->{f_where};");
    $drows = $fmt->fetchall_hashrows("select * from doc where doc in (select doc from s_$tmp natural join sent);");
    $srows = $fmt->fetchall_hashrows("select * from s_$tmp natural join   sent;");
    $wrows = $fmt->fetchall_hashrows("select * from s_$tmp natural join ptoken;");

    if ($fmt->{keep_history}) {
      $shrows = $fmt->fetchall_hashrows("select * from   sent_history where  sent in (select  sent from  s_$tmp) $shorder;");
      $whrows = $fmt->fetchall_hashrows("select * from ptoken_history where token in (select token from  s_$tmp natural join token) $whorder;");
    }
  }
  elsif ($f_which eq 'w') {
    ##-- restrict: token query
    $fmt->execsql("drop table if exists w_$tmp;");
    $fmt->execsql("create $tmpkw table w_$tmp (token integer not null primary key);"); ##-- matched tokens only
    $fmt->execsql("insert or ignore into w_$tmp $fmt->{f_where};");
    $fmt->execsql("drop table if exists s_$tmp;");
    $fmt->execsql("create $tmpkw table s_$tmp (sent integer not null primary key);");
    $fmt->execsql("insert or ignore into s_$tmp select sent from w_$tmp natural join token;");
    $drows = $fmt->fetchall_hashrows("select * from doc where doc in (select doc from s_$tmp natural join sent);");
    $srows = $fmt->fetchall_hashrows("select * from s_$tmp natural join sent;");
    $wrows = $fmt->fetchall_hashrows("select *,(select 1 from w_$tmp wt where wt.token=t.token limit 1) as match from s_$tmp natural join ptoken t;");

    if ($fmt->{keep_history}) {
      $shrows = $fmt->fetchall_hashrows("select * from   sent_history where  sent in (select  sent from  s_$tmp) $shorder;");
      $whrows = $fmt->fetchall_hashrows("select * from ptoken_history where token in (select token from  s_$tmp natural join token) $whorder;");
    }
  }
  else {
    $fmt->logconfess("bad restriction \`".($fmt->{f_which}||'')."=".($fmt->{f_where}||'')."'");
  }

  ##-- hash result arrays by id
  my $id2doc  = { map {($_->{doc}=>$_)}  @$drows };
  my $id2sent = { map {($_->{sent}=>$_)} @$srows };

  ##-- parse //s into //doc/body
  my ($s,$w);
  foreach $s (@$srows) {
    push(@{$id2doc->{$s->{doc}}{body}},$s);
  }

  ##-- parse //w into //s/tokens
  foreach $w (@$wrows) {
    $w->{text} = $w->{wold};
    $w->{toka} = [split('',$w->{toka})] if ($w->{toka});
    push(@{$id2sent->{$w->{sent}}{tokens}},$w);
  }

  ##-- parse history
  if ($fmt->{keep_history}) {
    my ($id2wh,$id2sh) = ({},{});
    push(@{$id2wh->{$_->{token}}},$_) foreach (@$whrows);
    push(@{$id2sh->{$_->{sent}}},$_)  foreach (@$shrows);

    my ($h);
    foreach $w (@$wrows) {
      $w->{history} = $h if (defined($h=$id2wh->{$w->{token}}));
    }
    foreach $s (@$srows) {
      $s->{shistory} = $h if (defined($h=$id2sh->{$s->{sent}}));
    }
  }

  ##-- build final cab doc structure
  my ($doc);
  if (scalar(@$drows)==1) {
    ##-- single source doc: we've already built it
    $doc = $drows->[0];
    $doc->{base} = $doc->{dtadir};
  } else {
    ##-- multiple source docs: splice doc attributes into sentences
    foreach my $drow (@$drows) {
      foreach $s (@{$drow->{body}}) {
	$s->{$_}=$drow->{$_} foreach (grep {$_ ne 'body'} keys %$drow);
      }
    }
    $doc = { body=>[map {@{$_->{body}}} @$drows], };
  }

  ##-- cleanup & return
  if (!$fmt->{keep_temp}) {
    $fmt->execsql("drop table if exists s_$tmp;");
    $fmt->execsql("drop table if exists w_$tmp;");
  }

  $doc = {body=>[]} if (!defined($doc));
  return $fmt->{raw} ? $doc : $fmt->forceDocument($doc);
}

##==============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + override
sub mimeType { return 'application/sqlite'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.sqlite'; }

## $short = $fmt->formatName()
##  + returns "official" short name for this format
##  + default just returns package suffix
sub shortName {
  return 'sqlite';
}


##--------------------------------------------------------------
## Methods: Output: output selection

## $fmt_or_undef = $fmt->toFh($fh,$formatLevel)
##  + select output to filehandle $fh
sub toFh {
  $_[0]->logconfess("toFh() not supported");
}

## $fmt_or_undef = $fmt->toFile($filename)
sub toFile {
  $_[0]->logconfess("toFile() not supported");
}

## $fmt_or_undef = $fmt->toString(\$str)
sub toString {
  $_[0]->logconfess("toString() not supported");
}


##--------------------------------------------------------------
## Methods: Output: Generic API
##  + these methods just dump raw json
##  + you're pretty much restricted to dumping a single document here

## $fmt = $fmt->putAnything($thingy)
##  + just pukes
sub putAnything {
  $_[0]->logconfess("putXYZ() not supported");
}

## $fmt = $fmt->putToken($tok)
## $fmt = $fmt->putSentence($sent)
## $fmt = $fmt->putDocument($doc)
## $fmt = $fmt->putData($data)
BEGIN {
  *putToken = \&putRef;
  *putSentence = \&putRef;
  *putDocument = \&putRef;
  *putData = \&putRef;
}

1; ##-- be happy

__END__
