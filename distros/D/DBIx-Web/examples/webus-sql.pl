#!perl -w
BEGIN {
print "CGI::Bus applications database installer/updater\n";
}
use DBI;

my $root =input('Database manager',    'root');
my $rpsw =input('Manager\'s password', '');
my $cgbd =input('Database name',       'cgibus');
my $cgbu =input('Database user',       'cgibus');
my $cgbp =input('User\'s password',    '********');

print "Connecting to 'DBI:mysql:mysql' as '$root'...\n";
my $mysql=DBI->connect("DBI:mysql:mysql",$root,$rpsw)
        ||die("Couls not connect to mysql as '$root'");
my $db   =$mysql;

print "Executing <DATA>, some SQL DML error messages may be ignored...\n\n";
my $row;
my $cmd ='';
my $cmt ='';
while ($row =<DATA>) {
  chomp($row);
  if ($cmd && ($row =~/^#/ || ($cmd !~/^\s*\{/ && $cmd =~/;\s*$/) )) {
     my $v;
     chomp($cmd);
     print $cmt ||$cmd, " -> ";
     if   ($cmd =~/^\s*\{/) {$v =eval($cmd);   print $@ ? $@ : 'ok'}
     else {$v =$db->do($cmd); print $db->err ? $db->errstr : 'ok'}
     print ': ', defined($v) ? $v : 'null', "\n\n";
     $cmd ='';
     $cmt ='';
  }
  next if $row =~/^\s*#*\s*$/;
  if    ($row =~/^#/ && $cmd !~/^\s*\{/) {
        $cmt =$row;
  }
  elsif ($row =~/^\s*#/ || $row eq '') {
  }
  else {
        $cmd .=($cmd ? "\n" : '') .$row;
  }
}

sub input {
 my ($pr, $dv) =@_;
 print $pr, @_ >1 ? ' [' .(defined($dv) ? $dv : 'null') .']' :'', ': ';
 my $r =<STDIN>;
 chomp($r);
 $r eq '' ? $dv : $r
}

#
##########################################
# DATABASE DEFINITIONS & UPDATES
##########################################
#
__END__
#
#
CREATE DATABASE IF NOT EXISTS cgibus;
#
#
{$db->do("GRANT ALL PRIVILEGES ON ${cgbd}.* TO ${cgbu}\@localhost IDENTIFIED BY '${cgbp}' WITH GRANT OPTION;")}
#
#
{$db=undef; $db =DBI->connect("DBI:mysql:$cgbd",$cgbu,$cgbp); <STDIN>}
#
#
# Groupware Organizer PDM
#========================
# '-' - reserved fields
#
#
create table gworganizer (
        id       varchar(60) primary key,
        idnv     varchar(60),  #   new version (value) pointer
        idpr     varchar(60),  #   previous record pointer
        idrm     varchar(60),  # + reply master pointer
        idrr     varchar(60),  # + reply root pointer
        idpt     varchar(60),  # - point to record        idlr     varchar(60),  # - location record pointer
        lslote   varchar(60),  # - location slot
        cuser    varchar(60),  #   creator user
        ctime    datetime,     #   created time
        uuser    varchar(60),  #   updator user
        utime    datetime,     #   updated time
        puser    varchar(60),  #   principal user
        prole    varchar(60),  #   principal role
        auser    varchar(60),  #   actor user
        arole    varchar(60),  #   actor role
        aopt     varchar(10),  # - actor options: 'respond', 'see', 'edit'
        rrole    varchar(60),  #   reader role        mailto   varchar(255), # + mail receipients
        mailtime datetime,     # - mailed time
        status   varchar(10),  #   record status
        progress decimal,      # - progress of the work
        etime    datetime,     #   end time
        stime    datetime,     #   start time
        period   varchar(20),  # + period of record (y, m, d, h)
        record   varchar(10),  #   record type
        object   varchar(60),  #   object name
        doctype  varchar(60),  #   document type
        subject  varchar(255), #   subject, title
        comment  text          #   comment, text
) # TYPE = BDB  # use mysqld-max, do not use fulltext
;
#
#CREATE INDEX idnv     ON gworganizer (idnv,    etime);
#CREATE INDEX idpr     ON gworganizer (idpr,    etime);
#CREATE INDEX idrm     ON gworganizer (idrm,    etime);
#CREATE INDEX idrr     ON gworganizer (idrr,    etime);
#CREATE INDEX record   ON gworganizer (record,  etime);
#CREATE INDEX object   ON gworganizer (object,  etime);
#CREATE INDEX doctype  ON gworganizer (doctype, etime);
#CREATE INDEX auser    ON gworganizer (auser,   etime);
#CREATE INDEX arole    ON gworganizer (arole,   etime);
#CREATE FULLTEXT INDEX ftext ON gworganizer 
#                    (object,doctype,subject,comment);
#
#
#
# Notes PDM (mysql)
#========================
# '-' - reserved fields
create table notes (
        id       varchar(60) primary key,
        idnv     varchar(60),  #   new version (value) pointer
        idpr     varchar(60),  #   previous record pointer
        idrm     varchar(60),  #   reply master pointer
        cuser    varchar(60),  #   creator user
        ctime    datetime,     #   created time
        uuser    varchar(60),  #   updator user
        utime    datetime,     #   updated time
        prole    varchar(60),  #   principal role
        rrole    varchar(60),  #   reader role
        status   varchar(10),  #   record status
        record   varchar(10),  # - record type
        object   varchar(60),  # - object name
        doctype  varchar(60),  # - document type
        subject  varchar(255), #   subject, title
        comment  text          #   comment, text
) # TYPE = BDB  # use mysqld-max, do not use fulltext
;
#
#CREATE INDEX idnv     ON notes (idnv,    utime);
#CREATE INDEX idrm     ON notes (idrm,    utime);
#CREATE INDEX cuser    ON notes (cuser,   utime);
#CREATE INDEX uuser    ON notes (uuser,   utime);
#CREATE INDEX prole    ON notes (prole,   utime);
#CREATE INDEX rrole    ON notes (rrole,   utime);
#CREATE INDEX subject  ON notes (subject, utime);
#CREATE FULLTEXT INDEX ftext ON notes
#                     (subject,comment);
#
#
#
{"2002-04-09 'gwo' update"
 ###########################
}
#
#
DROP   INDEX idnv     ON gworganizer;
CREATE INDEX idnv     ON gworganizer (idnv,    etime, utime);

#DROP   INDEX idnv_st  ON gworganizer;
#CREATE INDEX idnv_st  ON gworganizer (idnv,    status, etime);
#DROP   INDEX status   ON gworganizer;
#CREATE INDEX status   ON gworganizer (status,  idnv,   etime);

DROP   INDEX idpr     ON gworganizer;
CREATE INDEX idpr     ON gworganizer (idpr,    etime, utime);
DROP   INDEX idrm     ON gworganizer;
CREATE INDEX idrm     ON gworganizer (idrm,    etime, utime);
DROP   INDEX idrr     ON gworganizer;
CREATE INDEX idrr     ON gworganizer (idrr,    etime, utime);
DROP   INDEX record   ON gworganizer;
CREATE INDEX record   ON gworganizer (record,  etime, utime);
DROP   INDEX object   ON gworganizer;
CREATE INDEX object   ON gworganizer (object,  etime, utime);
DROP   INDEX doctype  ON gworganizer;
CREATE INDEX doctype  ON gworganizer (doctype, etime, utime);
DROP   INDEX auser    ON gworganizer;
CREATE INDEX auser    ON gworganizer (auser,   etime, utime);
DROP   INDEX arole    ON gworganizer;
CREATE INDEX arole    ON gworganizer (arole,   etime, utime);
#DROP   INDEX uuser    ON gworganizer;
#CREATE INDEX uuser    ON gworganizer (uuser,   etime, utime);
#DROP   INDEX cuser    ON gworganizer;
#CREATE INDEX cuser    ON gworganizer (cuser,   etime, utime);
#DROP   INDEX rrole    ON gworganizer;
#CREATE INDEX rrole    ON gworganizer (rrole,   etime, utime);

DROP   INDEX ftext    ON gworganizer;
#CREATE FULLTEXT INDEX ftext ON gworganizer(object,doctype,subject,comment);
#
#
#
{"2002-04-09 'notes' update"
 ###########################
}
##
DROP   INDEX idnv     ON notes;
CREATE INDEX idnv     ON notes (idnv,    utime desc,  ctime desc);
#DROP   INDEX idnv_st  ON notes;
#CREATE INDEX idnv_st  ON notes (idnv,    status, utime desc, ctime desc);
#DROP   INDEX utime    ON notes;
#CREATE INDEX utime    ON notes (utime desc,  ctime desc);

DROP   INDEX idrm     ON notes;
CREATE INDEX idrm     ON notes (idrm,    utime desc,  ctime desc);
DROP   INDEX cuser    ON notes;
CREATE INDEX cuser    ON notes (cuser,   utime desc,  ctime desc);
DROP   INDEX uuser    ON notes;
CREATE INDEX uuser    ON notes (uuser,   utime desc,  ctime desc);
DROP   INDEX prole    ON notes;
CREATE INDEX prole    ON notes (prole,   utime desc,  ctime desc);
DROP   INDEX rrole    ON notes;
CREATE INDEX rrole    ON notes (rrole,   utime desc,  ctime desc);
DROP   INDEX subject  ON notes;
CREATE INDEX subject  ON notes (subject, utime desc,  ctime desc);

DROP   INDEX ftext    ON notes;
#CREATE FULLTEXT INDEX ftext ON notes (subject, comment);
#
#
#
{"2002-05-19 'notes' update"
 ###########################
}
#
ALTER TABLE notes ADD COLUMN mailto varchar(255) AFTER rrole
#
#
#
{"2003-10-21 'gworganizer' update"
 ###########################
}
#
ALTER TABLE gworganizer ADD COLUMN project varchar(60) AFTER object;
ALTER TABLE gworganizer ADD COLUMN cost    decimal     AFTER project;
DROP   INDEX project   ON gworganizer;
CREATE INDEX project   ON gworganizer (project,  etime, utime);
#
#
#