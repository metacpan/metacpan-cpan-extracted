=head1 NAME

DBD::Ovrimos - DBI Driver for Ovrimos (formerly Altera SQL Server)

=head1 SYNOPSIS

     use DBI;
     my $dbh=DBI->connect(
          "dbi:Ovrimos:some.host.com:2500",
          "user",
          "passwd")
          or die "Cannot connect\n";
     # more DBI calls...

=head1 DESCRIPTION

DBI driver for Ovrimos (See L<DBI(3)> for details). This driver is essentially
a rename of DBD::Altera. Since DBI
is a moving target at the time of this writing, this driver should only be
assumed to work with DBI 0.93.
A standard notice in DBD drivers' man pages is that, since the DBI is not yet
stable, any DBD driver should be considered ALPHA software. So be it.
We will try to keep up with the changes, stay tuned at
<http://www.altera.gr/download.html> which is the primary download site for
this driver.

=head1 CURRENT VERSION

Release 0.12 Name change...
Previous release were:
Release 0.11 Essentially a bug-fix.
Release 0.10 (one hair short of 1.00). Main difference from previous version
0.09 is minor alterations to permit use for AGI (Another Gateway Interface).
In other words, how can one use the same module to write both DBI programs
and stored procedures for Ovrimos. Also, stored procedures
are now supported, using the pseudo-SQL "call xxx ..." statement. See
the documentation of Ovrimos for details.

=head1 DRIVER-SPECIFIC BEHAVIOR

=head2 DATA-SOURCE NAME

The dsn string passed to DBI->connect must be of the following form:

     dbi:Ovrimos:host:port

where host is a TCP/IP address in human-readable or dotted-decimal format, and
port is the TCP/IP port number to use (Ovrimos SQLPORT configuration
parameter).

=head2 CONNECTIONS, SESSIONS AND TRANSACTIONS

One can have multiple connections to an Ovrimos database, up to
the limit specified by one's User License. Keep in mind that what the License
calls 'sessions' amount to what are called separate statements in DBI.
Underlying the DBI is a protocol using the ODBC-equivalent 'connections' and
'statements'. Sessions are kept live until commit/rollback, and that can
result in denial of service if you reach the License limit. The database 
handle will reuse an inactive statement handle, so finish() often.

Commit/rollback finish()'es implicitly all open cursors (that's the answer
one asks ODBC with SQL_CURSOR_COMMIT_BEHAVIOR and SQL_CURSOR_ROLLBACK_BEHAVIOR).

Cached statements are not available. In the near future it is planned to
cache SQL statements internally at the SQL Server, so preparing the same
SQL statement as some time before will return a new $sth but without the
cost associated with preparing from scratch.

=head2 DATA TYPES

All ODBC 2.0 data types are supported. The format of time/date values is
as per the SQL/2 Standard, i.e.: S<'DATE YYYY-MM-DD'>, S<'TIME HH:MM:SS'> and
S<'TIMESTAMP YYYY-MM-DD HH:MM:SS'>.

Ovrimos supports some additional types that
are given below alongside their numerical value:

=over 4

=item UNSIGNED SMALLINT = 20

=item UNSIGNED INTEGER  = 21

=item UNSIGNED TINYINT  = 22

=item UNSIGNED BIGINT   = 23

=back

=head2 ERROR HANDLING

As it stands, the DBI does not support the notion of warnings.
Consequently, there are no diagnostics for successful calls.
There is no obstacle in adding this, but since perl code using
DBI will not check $h->errstr for successful operations, there is
not much incentive to actually do it. Diagnostics for failed calls
are inspected with the usual DBI calls. Do not pay any attention to
$h->err; it is dummy. Ovrimos returns Standard SQL
SQLSTATES and assorted messages, modelled principally after ODBC
use. Since many diagnostics can be accumulated by one call, the
diagnostics are merged, separated with newline. In that way, only
the first SQLSTATE in the queue is visible using $h->state. One
has to parse $h->errstr to find out the rest.

=head2 BLOBS

BLOBs are supported via the SQL2 types B<S<LONG VARCHAR>> and B<S<LONG
VARBINARY>>. These are not fetched with SQL queries and the LongReadLen and
LongTruncOk attributes are not honored. Instead, Ovrimos
presents a HTTP interface for retrieving BLOBS. Every BLOB has a Uniform
Resource Identifier that can be found using the built-in B<URI> function.
This makes for easy retrieval of BLOBs in CGI scripts, where the URI can
be embedded in HTML constructs like this:

     my ($name,$uri1,$uri2);
     $sth->bind_columns(undef,\($name,$uri1,$uri2));

     $sth->prepare('select name,uri(blob1),uri(blob2) from blobtest');
     $sth->execute;

     while($sth->fetch) {
          print '<A HREF="' . $uri1 .'">Click here!<A> ';
          print '<IMG SRC="' . $uri2 . '" ALT="Image"><BR>', "\n";
     }

BLOBs are MIME-typed so the HTTP browser knows how to handle them. If one
needs to retrieve a BLOB in an arbitrary script, one can use HTTP facilities
like those in the libwww bundle (see CPAN,
<http://cpan.perl.org/CPAN.html#libwww>). Or, one can just lead a simple life
and do

     require 5.002;
     use strict;
     use IO::Socket;
     my $host;
     my $file;
     my $port=80;
     if($uri =~ m[^http://(.*):(\d*)/(.*)]) {
          ($host,$port,$file)=($1,$2,$3);
     } elsif($uri =~ m[^http://(.*)/(.*)]) {
          ($host,$file)=($1,$2);
     } else {
          die "horribly";
     }
     my $so=IO::Socket::INET->new( Proto=>"tcp", PeerAddr=>$host,
          PeerPort=>$port) or die "in pain";
     print $so "GET /$file HTTP/1.0\r\n\r\n";
     $so->flush() or die "in agony";

One can then proceed to read from $so after skipping the reply header.
If the MIME type is required, it can be found in the 'Content-type:'
attribute of the reply header.

Maybe in a later release this functionality will be included in the driver.

=head2 DRIVER-SPECIFIC ATTRIBUTES

There are some additional attributes that the user can query a $sth for:

=over 4

=item TYPE (also ovrimos_column_type)

Reference to an array of column types as per ODBC, plus the Ovrimos extended types.
TYPE is in capitals because the values returned conform to approved standards
(ODBC, X/Open).

=item ovrimos_column_precision

Reference to an array of column precisions. Has meaning only for vector types
(*CHAR, *BINARY) and NUMERIC/DECIMAL

=item ovrimos_column_scale

Reference to an array of column scales. Has meaning only for NUMERIC/DECIMAL.

=item ovrimos_execution_plan

It is a high-level explanation of the execution plan for the statement. The
format is highly version-dependent and not to be dependent upon, but a human
reader should be able to understand the access path for every range variable
used, the order of range variables, the indices used, which temporary tables
have been created et.c.

=item ovrimos_native_query

The query submitted, but in the form retained by the SQL Server. The SQL
Server applies transformations to the SQL source and disambiguates certain
constructs. The modified source can also be found in the execution plan (see
above).

=back

=head2 LOW-LEVEL LIBRARY

The entire low-level library that implements the Ovrimos protocol
is included. The DBI driver is based on this library, but one could conceivably
use the library on its own. It is the only way, for the time being, to use
scrollable cursors and bookmarks, since the DBI does not support them (yet?).
See the package C<DBD::Ovrimos::lowlevel> in C<Ovrimos.pm>. No documentation is
provided in this version about the low-level library.

=head1 COMFORMANCE

There is a particularity concerning transactions: see
L</CONNECTIONS, SESSIONS AND TRANSACTIONS>.

Cached statements don't exist. Not even the function prepare_cached exists.
Do not use it! You won't find any relevant attribute either.

=head1 KNOWN BUGS

There are no known bugs in the DBD Driver.

=head1 ACKNOWLEDGEMENTS

I would like to thank all the people on the DBI-DEV mailing list that
helped clear some misunderstandings.

=head1 SEE ALSO

DBI(3)

=head1 AUTHOR

     Dimitrios Souflis                  dsouflis@altera.gr,

=head1 COPYRIGHT

     (c) Altera Ltd, Greece             http://www.altera.gr

Permission is granted to use this software library according to the
GNU Library General Public License (see <http://www.gnu.org>).

=cut

require 5.003;
use strict;
use IO::Socket;

package DBD::Ovrimos::lowlevel;

#Declarations for low-level functions and constants
#Essentially a Perl port of the C low-level library

sub _plain_mesg($$);

sub sqlConnect($$$$);
sub sqlConnectOutcome();
sub sqlDisconnect($);
sub sqlAllocStmt($);
sub sqlFreeStmt($);

sub sqlSetConnIntOption($$$);
sub sqlGetConnIntOption($$);
sub sqlSetStmtIntOption($$$);
sub sqlGetStmtIntOption($$);
sub sqlSetRowsetSize($$);
sub sqlGetRowsetSize($);

sub sqlSetIntOption($$$$);
sub sqlGetIntOption($$$);

sub sqlExecDirect($$);
sub sqlPrepare($$);
sub sqlExec($);
sub sqlCloseCursor($);
sub sqlAsyncFinished($);
sub sqlCancel($);
sub sqlSetCursorName($$);
sub sqlGetCursorName($);

sub sqlNest($);
sub sqlCommit($);
sub sqlRollback($);

sub sqlGetConnPending($);
sub sqlGetStmtPending($);

sub sqlGetConnDiagnostics($);
sub sqlGetStmtDiagnostics($);

sub sqlGetExecutionPlan($);
sub sqlGetNativeQuery($);
sub sqlGetRowCount($);

sub sqlGetOutputColDescr($);
sub sqlGetOutputColNb($);
sub sqlGetOutputColName($$);
sub sqlGetOutputColType($$);
sub sqlGetOutputColLength($$);
sub sqlGetOutputColPrecision($$);
sub sqlGetOutputColScale($$);
sub sqlGetOutputColNullable($$);

sub sqlGetParamDescr($);
sub sqlGetParamNb($);
sub sqlGetParamType($$);
sub sqlGetParamLength($$);
sub sqlGetParamPrecision($$);
sub sqlGetParamScale($$);

sub sqlPutParam($$$);
sub sqlResetParams($);

sub sqlCursorThis($);
sub sqlCursorFirst($$);
sub sqlCursorNext($$);
sub sqlCursorLast($$);
sub sqlCursorPrev($$);
sub sqlCursorBookmark($$);
sub sqlCursorGetBookmark($);
sub sqlCursorMove($$$$);

sub sqlGotoRow($$);
sub sqlRowState($$);
sub sqlRowBookmark($$);

sub sqlColValue($$$);
sub sqlColIsNull($$$);

sub _type_size($);
sub _type_overhead($);

sub _byte_order();
sub _column_def_len() {37};
sub _MAXMESGLEN() { 1024*64 };
sub _column_width($);
sub _column_pack_template($);
sub _collapse_null_ind($);

# Here we build a custom packing/unpacking facility to handle values
# Note that BIGINT and UNSIGNED BIGINT are kept in hex
sub _pack($$$);    #_pack(endianity,template,ref array of values) -> string
sub _unpack($$$);   #_unpack(endianity,template,string) -> array of values
sub _swapstring($); #_swapstring(string) -> string
sub _unpack_coldefs($$$);
sub make_date($$$);
sub make_time($$$);
sub break_date($);
sub break_time($);

# template characters:
# a/A     sint8/uint8
# b/B     sint16/uint16
# c/C     sint32/uint32
# d/D     sint64/uint64
# f/F     float/double
# g       date 'DATE YYYY-MM-DD'
# h       time 'TIME HH:MM:SS'
# i       timestamp 'TIMESTAMP YYYY-MM-DD HH:MM:SS'
# y99     <num> chars : fixed length BINARY
# Y99     VARBINARY <num> chars including padding preceded by uint16 actual len
# z       zero-terminated string
# z99     zero-terminated string in field <num> chars wide (excluding null)

# Constants that indicate type of failure for sqlConnect
sub c_ok() {0}
sub c_conn_failed() {1}
sub c_trans_failed() {2}
sub c_auth_failed() {3}

# Options
sub OPTION_ASYNC() {0}
sub OPTION_SEND_BOOKMARKS() {1}
sub OPTION_ISOLATION() {2}

# Row status indicators
sub ROW_OK() {0}
sub ROW_INEXISTANT() {1}
sub ROW_ERROR() {2}

# Return codes
sub RET_OK() {0}
sub RET_STILL_EXEC() {1}
sub RET_ERROR() {2}

# Types
sub T_CHAR() {1}
sub T_VARCHAR() {12}
sub T_LONGVARCHAR() {-1}
sub T_DECIMAL() {3}
sub T_NUMERIC() {2}
sub T_SMALLINT() {5}
sub T_INTEGER() {4}
sub T_REAL() {7}
sub T_FLOAT() {6}
sub T_DOUBLE() {8}
sub T_BIT() {-7}
sub T_TINYINT() {-6}
sub T_BIGINT() {-5}
sub T_BINARY() {-2}
sub T_VARBINARY() {-3}
sub T_LONGVARBINARY() {-4}
sub T_DATE() {9}
sub T_TIME() {10}
sub T_TIMESTAMP() {11}
sub T_USMALLINT() {20}
sub T_UINTEGER() {21}
sub T_UTINYINT() {22}
sub T_UBIGINT() {23}

# Byte orders
sub BYTE_ORDER_LITTLE() {0}
sub BYTE_ORDER_BIG() {1}

# Messages
 sub FUNC_LOGIN() {0}
 sub FUNC_LOGOUT() {1}
 sub FUNC_ALLOC_STMT() {2}
 sub FUNC_FREE_STMT() {3}
 sub FUNC_EXEC() {4}
 sub FUNC_CURSOR_THIS() {5}
 sub FUNC_OPTION_SET() {6}
 sub FUNC_OPTION_GET() {7}
 sub FUNC_STMT_OPTION_SET() {8}
 sub FUNC_STMT_OPTION_GET() {9}
 sub FUNC_STILL_EXEC() {10}
 sub FUNC_GET_DIAGS() {11}
 sub FUNC_GET_STMT_DIAGS() {12}
 sub FUNC_GET_NATIVE_QUERY() {13}
 sub FUNC_GET_EXEC_PLAN() {14}
 sub FUNC_PUT_PARAM() {15}
 sub FUNC_PREPARE() {16}
 sub FUNC_EXEC_DIRECT() {17}
 sub FUNC_DESCRIBE_PARAMS() {18}
 sub FUNC_DESCRIBE_RES_COLS() {19}
 sub FUNC_CURSOR_FIRST() {20}
 sub FUNC_CURSOR_NEXT() {21}
 sub FUNC_CURSOR_LAST() {22}
 sub FUNC_CURSOR_PREV() {23}
 sub FUNC_COMMIT() {24}
 sub FUNC_ROLLBACK() {25}
 sub FUNC_SET_NAME() {26}
 sub FUNC_NEST() {27}
 sub FUNC_RESET_PARAMS() {28}
 sub FUNC_END_EXEC() {29}
 sub FUNC_GET_NAME() {30}
 sub FUNC_GET_ROW_COUNT() {31}
 sub FUNC_CURSOR_GET_BM() {32}
 sub FUNC_CURSOR_GOTO_BM() {33}
 sub FUNC_CANCEL() {34}
 sub FUNC_CALL() {35}
 sub FUNC_BULK() {36}


#
sub _pack($$$) {
 my $endianity=shift;
 my $template=shift;
 my $valuesref=shift;
 my ($buf,$index);
 my $len=scalar @$valuesref;
 for($index=0;$index<$len;$index++) {
     my $c=substr($template,0,1);
     $template=substr($template,1);
     my $val=$$valuesref[$index];
     my $bitstring;
     if($c eq 'z' || $c eq 'y' || $c eq 'Y') {
          my $vallen=length($val);
          my $charlen=$vallen;
          my $xlen=1;
          if($c eq 'y') { $xlen=0; }
          if($template =~ /(\d+)(.*)/) {
               $charlen=$1;
               $template=$2;
          }
          my $templ='a' . $charlen . 'x' . $xlen;
          $bitstring=pack($templ, $val);
          if($c eq 'Y') {
               $bitstring=pack("B",length($val)) . $bitstring;
          }
     } elsif($c eq 'i') {
          if($val =~ /^TIMESTAMP (\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/i) {
               my $val1=make_date($1,$2,$3);
               my $val2=make_time($4,$5,$6);
               $bitstring=_pack($endianity,'hg',[$val2,$val1]);
          }
     } else {
          if($c eq 'd' || $c eq 'D') {
               if($val =~ /^0x(.*)/i) {
                    $val=$1;
               }
          } elsif($c eq 'g') {
               if($val =~ /^DATE (\d\d\d\d)-(\d\d)-(\d\d)/i) {
                    $val=make_date($1,$2,$3);
               }
          } elsif($c eq 'h') {
               if($val =~ /^TIME (\d\d):(\d\d):(\d\d)/i) {
                    $val=make_time($1,$2,$3);
               }
          }
          my $templ=$DBD::Ovrimos::lowlevel::_pack_templates{$c};
          $bitstring=pack $templ,$val;
          if($endianity!=$DBD::Ovrimos::lowlevel::_local_byte_order) {
               $bitstring=_swapstring($bitstring);
          }
     }
     $buf .= $bitstring;
 }
 $buf;
}

sub _unpack($$$) {
 my ($endianity,$template,$buf)=@_;
 my @values=();
 while(length($template)>0) {
     my $c=substr($template,0,1);
     $template=substr($template,1);
     my $val;
     if($c eq 'z' || $c eq 'y' || $c eq 'Y') {
          my $len;
          my $xlen=1;
          my $keeplen;
          if($c eq 'y') { $xlen=0; }
          if($c eq 'Y') {
               $keeplen=unpack($DBD::Ovrimos::lowlevel::_pack_templates{'B'},$buf);
               $buf=substr($buf,2);
          }
          if($template =~ /(\d+)(.*)/) {
               $len=$1;
               $template=$2;
          } else {
               $len=index($buf,chr(0));      # 'z' only
          }
          $val=substr($buf,0,$len+$xlen);
          if($c eq 'z') {
               my $reallen=index($val,chr(0));
               if($reallen!=-1) {
                    $val=substr($val,0,$reallen);
               }
          }
          $buf=substr($buf,$len+$xlen);
          if($c eq 'Y') {
               $val=substr($val,0,$keeplen);
          }
     } elsif($c eq 'i') {
          my $bitstring=substr($buf,0,8);
          $buf=substr($buf,8);
          my ($time,$date)=_unpack($endianity,'hg',$bitstring);
          $val='TIMESTAMP' . substr($date,4) . substr($time,4);
     } else {
          my $templ=$DBD::Ovrimos::lowlevel::_pack_templates{$c};
          my $len=$DBD::Ovrimos::lowlevel::_pack_lengths{$c};
          my $bitstring=substr($buf,0,$len);
          $buf=substr($buf,$len);
          if($endianity!=$DBD::Ovrimos::lowlevel::_local_byte_order) {
               $bitstring=_swapstring($bitstring);
          }
          $val=unpack $templ,$bitstring;
          if($c eq 'd' || $c eq 'D') {
               $val='0x' . $val;
          } elsif($c eq 'g') {
               $val=break_date($val);
          } elsif($c eq 'h') {
               $val=break_time($val);
          }
     }
     push @values,$val;
 }
 @values;
}

sub _swapstring($) {
 my $str=shift;
 my $len=length($str);
 my $i;
 for($i=0; $i<$len/2; $i++) {
     my $t;
     $t=substr($str,$i,1);
     substr($str,$i,1)=substr($str,$len-$i-1,1);
     substr($str,$len-$i-1,1)=$t;
 }
 $str;
}

sub make_date($$$) {
 my ($yy,$mm,$dd)=@_;
 $yy*2^16+$mm*256+$dd;
}

sub make_time($$$) {
 my ($hh,$mm,$ss)=@_;
 $hh*3600+$mm*60+$ss;
}

sub break_date($) {
 my $num=shift;
 my $dd=$num%256;
 my $mm=($num>>8)%256;
 my $yy=($num>>16);
 if(wantarray) {
     return ($yy,$mm,$dd);
 } else {
     return sprintf 'DATE %04d-%02d-%02d', $yy, $mm, $dd;
 }
}

sub break_time($) {
 my $num=shift;
 my $hh=int($num/3600);
 my $mm=int(($num%3600)/60);
 my $ss=$num%60;
 if(wantarray) {
     return ($hh,$mm,$ss);
 } else {
     sprintf 'TIME %02d:%02d:%02d', $hh, $mm, $ss;
 }
}

# Find out local byte order
sub _byte_order() {
     my $local_short=pack 's',[300];
     my $big_endian_short=pack 'n',[300];
     if($local_short eq $big_endian_short) {
          return BYTE_ORDER_BIG;
     } else {
          return BYTE_ORDER_LITTLE;
     }
}

BEGIN {
 $DBD::Ovrimos::lowlevel::_local_byte_order=DBD::Ovrimos::lowlevel::_byte_order();
 %DBD::Ovrimos::lowlevel::_pack_templates=(
     a => 'c',
     A => 'C',
     b => 's',
     B => 'S',
     c => 'l',
     C => 'L',
     d => 'H16',
     D => 'H16',
     f => 'f',
     F => 'd',
     g => 'L',
     h => 'L',
 );
 %DBD::Ovrimos::lowlevel::_pack_lengths=(
     a => 1,
     A => 1,
     b => 2,
     B => 2,
     c => 4,
     C => 4,
     d => 8,
     D => 8,
     f => 4,
     F => 8,
     g => 4,
     h => 4,
 );
}

sub _plain_mesg($$) {
 my $stmtref=shift;
 my $func=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(0,$$stmtref{stmt_handle},$func);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     return undef;
 }
 $ret==RET_OK;
}

sub sqlConnect($$$$) {
 my ($server,$port,$username,$password) = @_;
 my ($so,$endianity,$buf);
 $DBD::Ovrimos::lowlevel::_outcome=c_conn_failed;
 $so=IO::Socket::INET->new(Proto=>'tcp',PeerAddr=>$server,PeerPort=>$port);
 return undef unless defined($so);
 $DBD::Ovrimos::lowlevel::_outcome=c_trans_failed;
 return undef unless 1==$so->read($endianity,1);
 $endianity=ord($endianity);
 my @arg=
     (length($username)+1,$username,length($password)+1,$password);
 $buf=_pack($endianity,"bzbz",\@arg);
 $so->write($buf,length($buf)) or return undef;
 $so->flush() or return undef;
 $so->read($buf,2) or return undef;
 $DBD::Ovrimos::lowlevel::_outcome=c_auth_failed;
 my ($ret)=_unpack($endianity,"b",$buf);
 return undef unless $ret==RET_OK;
 $DBD::Ovrimos::lowlevel::_outcome=c_ok;
 my @empty_array=();
 {
     'endianity'    =>$endianity,
     'osocket'      =>$so,
     'isocket'      =>$so,
     'stmts'        =>\@empty_array,
     'AutoCommit'   =>1,
     'PrintError'   =>1,
     'RaiseError'   =>0,
     'Active'       =>1,
     'AGI'          =>0,
 };
}

sub sqlConnectOutcome() {
 $DBD::Ovrimos::lowlevel::_outcome;
}

sub sqlDisconnect($) {
 my $connref=shift;
 $$connref{'Active'}=0;
 my @arg=(0,0,FUNC_LOGOUT);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$connref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     return undef;
 }
 $$connref{osocket}->close() or return undef;
 $ret==RET_OK;
}

sub sqlAllocStmt($) {
 my $connref=shift;
 unless(defined($connref)) { return undef; }
 my @arg=(0,0,FUNC_ALLOC_STMT);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$connref{isocket}->read($buf,$len) or return undef;
 unless($len==2) { return undef; }
 if ($ret==RET_ERROR) { return undef; }
 my ($stmt)=_unpack($$connref{endianity},"B",$buf);
 {
     'Database'=>$connref,
     stmt_handle=>$stmt,
     rowset_size=>1,
     currrow=>0,
     'Active'=>1,
 };
}

sub sqlFreeStmt($) {
 my $stmtref=shift;
 my $ret=_plain_mesg($stmtref,FUNC_FREE_STMT);
 $$stmtref{'Active'}=0;
 $ret;
}

sub sqlAsyncFinished($) {
 my $stmtref=shift;
 _plain_mesg($stmtref,FUNC_STILL_EXEC);
}

sub sqlCancel($) {
 my $stmtref=shift;
 _plain_mesg($stmtref,FUNC_CANCEL);
}

sub sqlPutParam($$$) {
 my $stmtref=shift;
 my $num=shift;
 my $val=shift;
 if($num<0 || $num>=$$stmtref{paramcount}) {
     return undef;
 }
 my $connref=$$stmtref{'Database'};
 my @arg;
 my $buf;
 if(defined($val)) {
     @arg=(length($val)+2,0,FUNC_PUT_PARAM,$num,$val);
     $buf=_pack($$connref{endianity},"BBBBy".length($val),\@arg);
 } else {
     @arg=(2,0,FUNC_PUT_PARAM,$num);
     $buf=_pack($$connref{endianity},"BBBB",\@arg);
 }
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     return undef;
 }
 $ret==RET_OK;
}

sub sqlResetParams($) {
 my $stmtref=shift;
 _plain_mesg($stmtref,FUNC_RESET_PARAMS);
}

sub sqlPrepare($$) {
 my $stmtref=shift;
 my $cmd=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(length($cmd)+1,$$stmtref{stmt_handle},FUNC_PREPARE,$cmd);
 my $buf=_pack($$connref{endianity},"BBBz",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     return undef;
 }
 $ret==RET_OK;
}

sub sqlExecDirect($$) {
 my $stmtref=shift;
 my $cmd=shift;
 my $connref=$$stmtref{'Database'};
 my $func=FUNC_EXEC_DIRECT;
 if($cmd=~/call (.*)/i) {
     $func=FUNC_CALL;
     $cmd=$1;
 }
 my @arg=(length($cmd)+1,$$stmtref{stmt_handle},$func,$cmd);
 my $buf=_pack($$connref{endianity},"BBBz",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     return undef;
 }
 $ret==RET_OK;
}

sub sqlExec($) {
 my $stmtref=shift;
 _plain_mesg($stmtref,FUNC_EXEC);
}

sub sqlCloseCursor($) {
 my $stmtref=shift;
 _plain_mesg($stmtref,FUNC_END_EXEC);
}

sub sqlSetCursorName($$) {
 my $stmtref=shift;
 my $cname=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(length($cname)+1,$$stmtref{stmt_handle},FUNC_SET_NAME,$cname);
 my $buf=_pack($$connref{endianity},"BBBz",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     return undef;
 }
 $ret==RET_OK;
}

sub sqlGetCursorName($) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(0,$$stmtref{stmt_handle},FUNC_GET_NAME);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     my ($x)=_unpack($$connref{endianity},"z",$buf);
     return $x;
 }
 undef;
}

sub sqlGetExecutionPlan($) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(0,$$stmtref{stmt_handle},FUNC_GET_EXEC_PLAN);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     my ($x)=_unpack($$connref{endianity},"z",$buf);
     return $x;
 }
 undef;
}

sub sqlGetNativeQuery($) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(0,$$stmtref{stmt_handle},FUNC_GET_NATIVE_QUERY);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     my ($x)=_unpack($$connref{endianity},"z",$buf);
     return $x;
 }
 undef;
}

sub sqlGetRowCount($) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(0,$$stmtref{stmt_handle},FUNC_GET_ROW_COUNT);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len!=0) {
     $$connref{isocket}->read($buf,$len) or return undef;
     return _unpack($$connref{endianity},"C",$buf);
 }
 undef;
}

sub sqlSetConnIntOption($$$) {
 my $connref=shift;
 my $option=shift;
 my $value=shift;
 sqlSetIntOption($connref,undef,$option,$value);
}

sub sqlGetConnIntOption($$) {
 my $connref=shift;
 my $option=shift;
 sqlGetIntOption($connref,undef,$option);
}

sub sqlSetStmtIntOption($$$) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 my $option=shift;
 my $value=shift;
 sqlSetIntOption($connref,$stmtref,$option,$value);
}

sub sqlGetStmtIntOption($$) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 my $option=shift;
 sqlGetIntOption($connref,$stmtref,$option);
}

sub sqlSetIntOption($$$$) {
 my $connref=shift;
 my $stmtref=shift;
 my $option=shift;
 my $value=shift;
 my $func=FUNC_OPTION_SET;
 my $stmt_handle=0;
 if(defined($stmtref)) {
     $func=FUNC_OPTION_SET;
     $stmt_handle=$$stmtref{stmt_handle};
 }
 my @arg=(0,$stmt_handle,$func,$option,$value);
 my $buf=_pack($$connref{endianity},"BBBbc",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 if(defined($stmtref)) {
     $$stmtref{pending}=$pending;
 } else {
     $$connref{pending}=$pending;
 }
 $ret==RET_OK;
}

sub sqlGetIntOption($$$) {
 my $connref=shift;
 my $stmtref=shift;
 my $option=shift;
 my $value=shift;
 my $func=FUNC_OPTION_GET;
 my $stmt_handle=0;
 if(defined($stmtref)) {
     $func=FUNC_OPTION_GET;
     $stmt_handle=$$stmtref{stmt_handle};
 }
 my @arg=(0,$stmt_handle,$func,$option);
 my $buf=_pack($$connref{endianity},"BBBb",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 if(defined($stmtref)) {
     $$stmtref{pending}=$pending;
 } else {
     $$connref{pending}=$pending;
 }
 if($len!=4) {
     return undef;
 }
 $$connref{isocket}->read($buf,$len) or return undef;
 _unpack($$connref{endianity},"c",$buf);
}

sub sqlGetConnDiagnostics($) {
 my $connref=shift;
 sqlGetDiagnostics($connref,undef);
}

sub sqlGetStmtDiagnostics($) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 sqlGetDiagnostics($connref,$stmtref);
}

sub sqlGetDiagnostics($$) {
 my $connref=shift;
 my $stmtref=shift;
 my $stmt_handle=0;
 my $func=FUNC_GET_DIAGS;
 if(defined($stmtref)) {
     $func=FUNC_GET_STMT_DIAGS;
     $stmt_handle=$$stmtref{stmt_handle};
 }
 my @arg=(2,$stmt_handle,$func,64*1024-10);
 my $buf=_pack($$connref{endianity},"BBBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 if($len==0) {
     if($pending!=0) {
          return undef;  #oops! diagnostics that are not received?
     }
     return 1;           #ok, no diagnostics
 }
 $$connref{isocket}->read($buf,$len) or return undef;
 my ($diags)=_unpack($$connref{endianity},"z",$buf);
 $diags;
}

sub sqlNest($) {
 my $stmtref=shift;
 _plain_mesg($stmtref,FUNC_NEST);
}

sub sqlCommit($) {
 my $stmtref=shift;
 _plain_mesg($stmtref,FUNC_COMMIT);
}

sub sqlRollback($) {
 my $stmtref=shift;
 _plain_mesg($stmtref,FUNC_ROLLBACK);
}

sub sqlGetConnPending($) {
 my $connref=shift;
 $$connref{pending};
}

sub sqlGetStmtPending($) {
 my $stmtref=shift;
 $$stmtref{pending};
}

sub _unpack_coldefs($$$) {
 my $endianity=shift;
 my $colnb=shift;
 my $buf=shift;
 my $i;
 my @res=();
 for($i=0; $i<$colnb; $i++) {
     my ($name,$type,$length,$scale,$nullable)=_unpack($endianity,"z30abbA",$buf);
     $buf=substr($buf,_column_def_len);
     my %coldef=(
          name => $name,
          type => $type,
          len => $length,
          scale => $scale,
          nullable => $nullable,
     );
     push(@res,\%coldef);
 }
 @res;
}

sub sqlGetParamDescr($) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(0,$$stmtref{stmt_handle},FUNC_DESCRIBE_PARAMS);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len==0) { return undef; }
 $$connref{isocket}->read($buf,$len) or return undef;
 my ($colnb)=_unpack($$connref{endianity},"B",$buf); $buf=substr($buf,2);
 my @params=_unpack_coldefs($$connref{endianity},$colnb,$buf);
 $$stmtref{paramcount}=$colnb;
 $$stmtref{params}=\@params;
 $ret==RET_OK;
}

sub sqlGetParamNb($) {
 my $stmtref=shift;
 $$stmtref{paramcount};
}

sub sqlGetParamType($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $paramsc=$$stmtref{params};
 my $coldef=$$paramsc[$icol];
 $$coldef{type};
}

sub sqlGetParamLength($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $paramsc=$$stmtref{params};
 my $coldef=$$paramsc[$icol];
 $$coldef{len};
}

sub sqlGetParamPrecision($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $paramsc=$$stmtref{params};
 my $coldef=$$paramsc[$icol];
 $$coldef{len};
}

sub sqlGetParamScale($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $paramsc=$$stmtref{params};
 my $coldef=$$paramsc[$icol];
 $$coldef{scale};
}

sub sqlGetOutputColDescr($) {
 my $stmtref=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(0,$$stmtref{stmt_handle},FUNC_DESCRIBE_RES_COLS);
 my $buf=_pack($$connref{endianity},"BBB",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len==0) { return undef; }
 $$connref{isocket}->read($buf,$len) or return undef;
 my ($colnb)=_unpack($$connref{endianity},"B",$buf); $buf=substr($buf,2);
 my @res=_unpack_coldefs($$connref{endianity},$colnb,$buf);
 $$stmtref{colnb}=$colnb;
 $$stmtref{res}=\@res;
 $$stmtref{row_width}=0;
 $$stmtref{row_template}='';
 my $coldefref;
 foreach $coldefref (@res) {
     $$stmtref{row_width}+=_column_width($coldefref);
     $$stmtref{row_template}.=_column_pack_template($coldefref);
 }
 $ret==RET_OK;
}

sub sqlGetOutputColNb($) {
 my $stmtref=shift;
 $$stmtref{colnb};
}

sub sqlGetOutputColName($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $resc=$$stmtref{res};
 my $coldef=$$resc[$icol];
 $$coldef{name};
}

sub sqlGetOutputColType($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $resc=$$stmtref{res};
 my $coldef=$$resc[$icol];
 $$coldef{type};
}

sub sqlGetOutputColLength($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $resc=$$stmtref{res};
 my $coldef=$$resc[$icol];
 $$coldef{len};
}

sub sqlGetOutputColPrecision($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $resc=$$stmtref{res};
 my $coldef=$$resc[$icol];
 $$coldef{len};
}

sub sqlGetOutputColScale($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $resc=$$stmtref{res};
 my $coldef=$$resc[$icol];
 $$coldef{scale};
}

sub sqlGetOutputColNullable($$) {
 my $stmtref=shift;
 my $icol=shift;
 my $resc=$$stmtref{res};
 my $coldef=$$resc[$icol];
 $$coldef{nullable};
}

sub sqlGetRowsetSize($) {
 my $stmtref=shift;
 $$stmtref{rowset_size};
}

sub sqlSetRowsetSize($$) {
 my $stmtref=shift;
 my $sz=shift;
 my $row_width=$$stmtref{row_width};
 my $max_sz=int((_MAXMESGLEN-2-6)/($row_width+6));
 if($sz>$max_sz) {
     $sz=$max_sz;
 }
 $$stmtref{rowset_size}=$sz;
}

sub _column_width($) {
 my $coldefref=shift;
 my $type=$$coldefref{type};
 my $len=$$coldefref{len};
 my $w;
 if($type==T_DECIMAL || $type==T_NUMERIC) {
     $w=_type_size($type);
 } else {
     $w=$len*_type_size($type)+_type_overhead($type);
 }
 $w+1;         #plus null indicator
}

sub _column_pack_template($) {
 my $coldefref=shift;
 my $t=$$coldefref{type};
 my $len=$$coldefref{len};
 if($t==T_BIGINT) {
     return "Ad"
 } elsif($t==T_TIMESTAMP) {
     return "Ai";
 } elsif($t==T_UBIGINT) {
     return "AD"
 } elsif($t==T_DECIMAL || $t==T_NUMERIC || $t==T_DOUBLE || $t==T_FLOAT) {
     return "AF";
 } elsif($t==T_INTEGER) {
     return "Ac";
 } elsif($t==T_UINTEGER) {
     return "AC";
 } elsif($t==T_TIME) {
     return "Ah";
 } elsif($t==T_DATE) {
     return "Ag";
 } elsif($t==T_REAL) {
     return "Af";
 } elsif($t==T_SMALLINT) {
     return "Ab";
 } elsif($t==T_USMALLINT) {
     return "AB";
 } elsif($t==T_LONGVARCHAR || $t==T_LONGVARBINARY) {
     return "AC";
 } elsif($t==T_TINYINT) {
     return "Aa";
 } elsif($t==T_BIT || $t==T_UTINYINT) {
     return "AA";
 } elsif($t==T_CHAR || T_VARCHAR) {
     return "Az" . $len;
 } elsif($t==T_BINARY) {
     return "Ay" . $len;
 } elsif($t==T_VARBINARY) {
     return "AY" . $len;
 } else {
     return undef;
 }
}

sub _type_size($) {
 my $t=shift;
 if($t==T_TIMESTAMP || $t==T_BIGINT || $t==T_UBIGINT ||
    $t==T_DECIMAL || $t==T_NUMERIC || $t==T_DOUBLE || $t==T_FLOAT) {
     return 8;
 } elsif($t==T_INTEGER || $t==T_UINTEGER || $t==T_TIME || $t==T_DATE ||
    $t==T_REAL) {
     return 4;
 } elsif($t==T_SMALLINT || $t==T_USMALLINT) {
     return 2;
 } elsif($t==T_LONGVARCHAR || $t==T_LONGVARBINARY) {
     return 0;
     # so that 0*length+type_overhead=type_overhead
 } else {
     return 1;
 }
}

sub _type_overhead($) {
 my $t=shift;
 if($t==T_CHAR || $t==T_VARCHAR) {
     return 1;
 } elsif($t==T_VARBINARY) {
     return 2;
 } elsif($t==T_LONGVARCHAR || $t==T_LONGVARBINARY) {
     return 4;
 } else {
     return 0;
 }
}

sub sqlCursorMove($$$$) {
 my $stmtref=shift;
 my $irow=shift;
 my $func=shift;
 my $fetch=shift;
 my $connref=$$stmtref{'Database'};
 my @arg=(6,$$stmtref{stmt_handle},$func,$fetch,$irow);
 my $buf=_pack($$connref{endianity},"BBBBC",\@arg);
 $$connref{osocket}->write($buf,length($buf)) or return undef;
 $$connref{osocket}->flush() or return undef;
 $$connref{isocket}->read($buf,6) or return undef;
 my ($len,$ret,$pending)=_unpack($$connref{endianity},"BBB",$buf);
 $$stmtref{pending}=$pending;
 if($len==0) { return undef; }
 $$connref{isocket}->read($buf,$len) or return undef;
 if($ret!=RET_OK) {
     return undef;
 }
 my ($w)=_unpack($$connref{endianity},"B",$buf); $buf=substr($buf,2);
 if($w != $$stmtref{row_width}) {
     return undef;
 }
 my @rows=();
 my $i;
 for($i=0; $i<$fetch; $i++) {
     my ($st,$bm)=_unpack($$connref{endianity},"bC",$buf); $buf=substr($buf,6);
     my $rw=undef;
     if($st==ROW_OK) {
          my @x=_unpack($$connref{endianity},$$stmtref{row_template},$buf);
          $buf=substr($buf,$w);
          $rw=_collapse_null_ind(\@x);
     }
     my %rowdata=( state=> $st, bookmark=> $bm, data=>$rw);
     push(@rows,\%rowdata);
 }
 $$stmtref{rows}=\@rows;
 $$stmtref{currrow}=0;
 $ret==RET_OK;
}

sub _collapse_null_ind($) {
 my $listref=shift;
 my @data=();
 my $i;
 for($i=0; $i<scalar(@$listref); $i+=2) {
     if($$listref[$i]==0) {
          push(@data,$$listref[$i+1]);
     } else {
          push(@data,undef);
     }
 }
 \@data;
}

sub sqlCursorThis($) {
 my $stmtref=shift;
 sqlCursorMove($stmtref,0,FUNC_CURSOR_THIS,$$stmtref{rowset_size});
}

sub sqlCursorFirst($$) {
 my $stmtref=shift;
 my $irow=shift;
 sqlCursorMove($stmtref,$irow,FUNC_CURSOR_FIRST,$$stmtref{rowset_size});
}

sub sqlCursorNext($$) {
 my $stmtref=shift;
 my $irow=shift;
 sqlCursorMove($stmtref,$irow,FUNC_CURSOR_NEXT,$$stmtref{rowset_size});
}

sub sqlCursorLast($$) {
 my $stmtref=shift;
 my $irow=shift;
 sqlCursorMove($stmtref,$irow,FUNC_CURSOR_LAST,$$stmtref{rowset_size});
}

sub sqlCursorPrev($$) {
 my $stmtref=shift;
 my $irow=shift;
 sqlCursorMove($stmtref,$irow,FUNC_CURSOR_PREV,$$stmtref{rowset_size});
}

sub sqlCursorBookmark($$) {
 my $stmtref=shift;
 my $bm=shift;
 sqlCursorMove($stmtref,$bm,FUNC_CURSOR_GOTO_BM,$$stmtref{rowset_size});
}

sub sqlColValue($$$) {
 my $stmtref=shift;
 my $icol=shift;
 my $irow=shift;
 my $rows=$$stmtref{rows};
 my $row=$$rows[$irow];
 my $data=$$row{data};
 #$$$$$stmtref{rows}[$irow]{data}[$icol];
 $$data[$icol];
}

sub sqlColIsNull($$$) {
 my $stmtref=shift;
 my $icol=shift;
 my $irow=shift;
 undefined(sqlColValue($stmtref,$icol,$irow));
}

sub sqlRowState($$) {
 my $stmtref=shift;
 my $irow=shift;
 my $rows=$$stmtref{rows};
 my $row=$$rows[$irow];
 $$row{state};
}

sub sqlRowBookmark($$) {
 my $stmtref=shift;
 my $irow=shift;
 my $rows=$$stmtref{rows};
 my $row=$$rows[$irow];
 $$row{bookmark};
}

package DBD::Ovrimos;

use vars qw($VERSION);      #so that VERSION_FROM will work

$VERSION="0.11";
$DBD::Ovrimos::drh=undef;
@DBD::Ovrimos::connections=();
$DBD::Ovrimos::err='';
$DBD::Ovrimos::errStr='';

sub driver {
 return $DBD::Ovrimos::drh if $DBD::Ovrimos::drh;
 $DBD::Ovrimos::drh=DBI::_new_drh('DBD::Ovrimos::dr',
     {
          'Name'         => 'Ovrimos',
          'Version'      => $DBD::Ovrimos::VERSION,
          'Err'          => \$DBD::Ovrimos::err,
          'Errstr'       => \$DBD::Ovrimos::errStr,
          'Atribution'   => 'DBD::Ovrimos by Dimitrios Souflis',
     });
}

sub AGIdb() {
 my ($ofh,$ifh);
 $ofh=new IO::Handle;
 $ifh=new IO::Handle;
 if(!$ifh->fdopen(fileno(STDIN),"r")) {
     return undef;
 }
 if(!$ofh->fdopen(fileno(STDOUT),"w")) {
     return undef;
 }
 my @empty_array=();
 bless {
     'endianity'    =>$DBD::Ovrimos::lowlevel::_local_byte_order,
     'isocket'      =>$ifh,
     'osocket'      =>$ofh,
     'stmts'        =>\@empty_array,
     'AutoCommit'   =>1,
     'PrintError'   =>0,
     'RaiseError'   =>0,
     'Active'       =>1,
     'AGI'          =>1,
     'Err'          => \$DBD::Ovrimos::err,
     'Errstr'       => \$DBD::Ovrimos::errStr,
 }, 'DBD::Ovrimos::db';
}

package DBD::Ovrimos::dr;

$DBD::Ovrimos::dr::imp_data_size=$DBD::Ovrimos::dr::imp_data_size=0;

sub errstr {
 my $self=shift;
 ${$self->{'Errstr'}};
}

sub state {
 my $self=shift;
 substr(${$self->{'Errstr'}},0,5);
}

sub err {
 my $self=shift;
 if(${$self->{'Errstr'}} eq '') {
     return 0;
 } else {
     return 1;                     # arbitrary non-0 value
 }
}

sub connect {
 my $driver=shift;
 my $dsn=shift;
 my $user=shift;
 my $pass=shift;
 my $attr=shift;
 my $host;
 my $port;
 $DBD::Ovrimos::errStr='';
 if($dsn =~ /^(.*):(.*)/) {
     ($host,$port)=($1,$2);
 } else {
     $DBD::Ovrimos::errStr.="08001 Malformed dsn '$dsn'";
     return undef;
 }
 my $connref=DBD::Ovrimos::lowlevel::sqlConnect($host,$port,$user,$pass);
 if(!defined($connref)) {
     my $o=DBD::Ovrimos::lowlevel::sqlConnectOutcome();
     if($o==DBD::Ovrimos::lowlevel::c_conn_failed) {
          $DBD::Ovrimos::errStr.="08001 Connection to $host:$port impossible";
     } elsif($o==DBD::Ovrimos::lowlevel::c_auth_failed) {
          $DBD::Ovrimos::errStr.="08004 Authentication as $user failed";
     } else {
          $DBD::Ovrimos::errStr.="08S01 Connection to $host:$port failed";
     }
     return undef;
 }
 my ($dbh,$h)=DBI::_new_dbh($DBD::Ovrimos::drh,$connref,undef);
 push(@DBD::Ovrimos::connections,$h);
 $dbh;
}

sub DESTROY {
 disconnect_all();
}

sub disconnect_all {
 my $connref;
 for $connref (@DBD::Ovrimos::connections) {
     if(!DBD::Ovrimos::lowlevel::sqlDisconnect($connref)) {
          $DBD::Ovrimos::errStr.="01002 Disconnect error";
     }
 }
}

package DBD::Ovrimos::db;

$DBD::Ovrimos::db::imp_data_size=$DBD::Ovrimos::db::imp_data_size=0;

sub _w {
 my $self=shift;
 my $msg=shift;

 if($$self{'PrintError'}) {
     warn $msg;
 }
 if($$self{'RaiseError'}) {
     die $msg;
 }
 if(${$self->{'Errstr'}} ne '') {
     ${$self->{'Errstr'}}.="\n";
 }
 ${$self->{'Errstr'}}.=$msg;
 $msg;
}

sub errstr {
 my $self=shift;
 ${$self->{'Errstr'}};
}

sub state {
 my $self=shift;
 substr(${$self->{'Errstr'}},0,5);
}

sub err {
 my $self=shift;
 if(${$self->{'Errstr'}} eq '') {
     return 0;
 } else {
     return 1;                     # arbitrary non-0 value
 }
}

sub DESTROY {
 my $self=shift;
 if($$self{'AGI'}) {
     return 1;
 }
 DBD::Ovrimos::lowlevel::sqlDisconnect($self);
}

sub disconnect {
 my $self=shift;
 my $i;
 ${$self->{'Errstr'}}='';
 for($i=0; $i<scalar(@DBD::Ovrimos::connections);$i++) {
     if($DBD::Ovrimos::connections[$i]->{osocket}==$self->{osocket}) {
          splice(@DBD::Ovrimos::connections,$i,1);
          last;
     }
 }
 if(!DBD::Ovrimos::lowlevel::sqlDisconnect($self)) {
     _w($self,'01002 Disconnect error');
 }
 1;
}

sub do {
 my $self=shift;
 my $cmd=shift;
 my @params=@_;
 ${$self->{'Errstr'}}='';
 my $stmtref=_reuse_stmt($self);
 if(!defined($stmtref)) {
     if($$self{'AGI'}) {
          return undef;
     }
     $stmtref=DBD::Ovrimos::lowlevel::sqlAllocStmt($self);
     if(!defined($stmtref)) {
          _w($self,DBD::Ovrimos::lowlevel::sqlGetConnDiagnostics($self));
          return undef;
     }
     $$stmtref{'Database'}=$self;      # must do it by hand here
 }
 # if params supplied, prepare, put params and then execute
 my $ret1;
 if(defined(@params)) {
     $ret1=DBD::Ovrimos::lowlevel::sqlPrepare($stmtref,$cmd);
     if(!$ret1) {
          _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($stmtref));
          if(!$$self{'AGI'}) {
               DBD::Ovrimos::lowlevel::sqlFreeStmt($stmtref);
          }
          return undef;
     }
     my $parnb=DBD::Ovrimos::lowlevel::sqlGetParamNb($stmtref);
     if($parnb!=scalar(@params)) {
          _w($self,'07001 Wrong number of parameters');
          if(!$$self{'AGI'}) {
               DBD::Ovrimos::lowlevel::sqlFreeStmt($stmtref);
          }
          return undef;
     }
     my $i;
     for($i=1; $i<=$parnb; $i++) {
          my $rv=bind_param($self,$i,$params[$i-1]);
          if(!$rv) {
               if(!$$self{'AGI'}) {
                    DBD::Ovrimos::lowlevel::sqlFreeStmt($stmtref);
               }
               return undef;
          }
     }
     $ret1=DBD::Ovrimos::lowlevel::sqlExec($stmtref);
 } else {
     $ret1=DBD::Ovrimos::lowlevel::sqlExecDirect($stmtref,$cmd);
 }
 if(!$ret1) {
     _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($stmtref));
     if(!$$self{'AGI'}) {
          DBD::Ovrimos::lowlevel::sqlFreeStmt($stmtref);
     }
     return undef;
 }
 my $rows=DBD::Ovrimos::lowlevel::sqlGetRowCount($stmtref);
 if($$self{'Autocommit'}) {
     if(!$$self{'AGI'}) {
          my $ret2=DBD::Ovrimos::lowlevel::sqlFreeStmt($stmtref);
          if(!$ret2) {
               _w($self,DBD::Ovrimos::lowlevel::sqlGetConnDiagnostics($self));
               return undef;
          }
     }
 } else {
     my $stmts=$$self{stmts};
     $$stmtref{'Active'}=0;
     push(@$stmts,$stmtref);       # will be Free'd at _trans
 }
 $rows==0? '0E0' : $rows;
}

sub prepare {
 my $self=shift;
 my $cmd=shift;
 my $attr=shift;
 ${$self->{'Errstr'}}='';
 my $stmtref=_reuse_stmt($self);
 if(!defined($stmtref)) {
     if($$self{'AGI'}) {
          return undef;
     }
     $stmtref=DBD::Ovrimos::lowlevel::sqlAllocStmt($self);
     if(!defined($stmtref)) {
          _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($self));
          return undef;
     }
 }
 my $ret=DBD::Ovrimos::lowlevel::sqlPrepare($stmtref,$cmd);
 if(!$ret) {
     _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($stmtref));
     return undef;
 }
 if(!DBD::Ovrimos::lowlevel::sqlGetOutputColDescr($stmtref)) {
     _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($stmtref));
     return undef;
 }
 #This demands caching of rows. Will actually set it at closest possible num
 DBD::Ovrimos::lowlevel::sqlSetRowsetSize($stmtref,10000);
 if(!DBD::Ovrimos::lowlevel::sqlGetParamDescr($stmtref)) {
     _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($stmtref));
     return undef;
 }
 if(!$$self{'AGI'}) {
     my ($sth,$h)=DBI::_new_sth($self,$stmtref,undef);
     my $stmts=$$self{stmts};
     push(@$stmts,$h);
     return $sth;
 } else {
     my $stmts=$$self{stmts};
     push(@$stmts,$stmtref);
     return $stmtref;
 }
}

sub commit {
 my $self=shift;
 _trans($self,\&DBD::Ovrimos::lowlevel::sqlCommit);
}

sub rollback {
 my $self=shift;
 _trans($self,\&DBD::Ovrimos::lowlevel::sqlRollback);
}

sub _trans {
 my $self=shift;
 my $func=shift;
 my $stmts=$$self{stmts};
 my $i;
 my $ret=1;
 ${$self->{'Errstr'}}='';
 for($i=0; $i<scalar(@$stmts); $i++) {
     my $target=$$stmts[$i];
     my $ret2=&$func($target);
     if(!$ret2) {
          _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($target));
     }
     $ret &&= $ret2;
     if(!$$self{'AGI'}) {
          $ret2=DBD::Ovrimos::lowlevel::sqlFreeStmt($target);
          _delete_stmt_handle($self,$$target{stmt_handle});
     }
     if(!$ret2) {
          _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($target));
     }
     $ret &&= $ret2;
 }
 $ret;
}

sub _delete_stmt_handle {
 my $self=shift;
 my $stmt_handle=shift;
 my $stmts=$$self{stmts};
 my $i;
 for($i=0; $i<scalar(@$stmts); $i++) {
     my $target=$$stmts[$i];
     if($$target{stmt_handle}==$stmt_handle) {
          splice(@$stmts,$i,1);
          last;
     }
 }
}

sub _reuse_stmt {
 my $self=shift;
 my $stmts=$$self{stmts};
 my $i;
 if(scalar(@$stmts)==0 && $$self{'AGI'}==1) {
     return bless {
          'Database'=>$self,
          stmt_handle=>0,  # dummy handle
          rowset_size=>1,
          currrow=>0,
          'Active'=>1,
          'Err'          => \$DBD::Ovrimos::err,
          'Errstr'       => \$DBD::Ovrimos::errStr,
     }, 'DBD::Ovrimos::st';
 }
 for($i=0; $i<scalar(@$stmts); $i++) {
     my $target=$$stmts[$i];
     if(!$$target{'Active'}) {
          splice(@$stmts,$i,1);
          return $target;
     }
 }
 undef;
}

sub FETCH {
 my $self=shift;
 my $key=shift;
 if($key eq 'AutoCommit') {
     return $$self{'AutoCommit'};
 } elsif($key eq 'Active') {
     return $$self{'Active'};
 } elsif($key eq 'Kids') {
     return scalar(@{$self->{stmts}});
 } elsif($key eq 'ActiveKids') {
     return scalar(grep { $_->{'Active'} } @{$self->{stmts}});
 }
 undef;
}

sub STORE {
 my $self=shift;
 my $key=shift;
 my $value=shift;
 if($key eq 'AutoCommit') {
     $$self{'AutoCommit'}=$value;
 } else {
     $self->DBD::_::db::STORE($key,$value);
 }
}

package DBD::Ovrimos::st;

$DBD::Ovrimos::st::imp_data_size=$DBD::Ovrimos::st::imp_data_size=0;

sub _w {
 my $self=shift;
 my $msg=shift;

 if($$self{'PrintError'}) {
     warn $msg;
 }
 if($$self{'RaiseError'}) {
     die $msg;
 }
 if(${$self->{'Errstr'}} ne '') {
     ${$self->{'Errstr'}}.="\n";
 }
 ${$self->{'Errstr'}}.=$msg;
 $msg;
}

sub errstr {
 my $self=shift;
 ${$self->{'Errstr'}};
}

sub state {
 my $self=shift;
 substr(${$self->{'Errstr'}},0,5);
}

sub err {
 my $self=shift;
 if(${$self->{'Errstr'}} eq '') {
     return 0;
 } else {
     return 1;                     # arbitrary non-0 value
 }
}

sub execute {
 my $self=shift;
 my @params=@_;
 ${$self->{'Errstr'}}='';
 if(defined(@params)) {
     my $parnb=$$self{paramcount};
     if($parnb!=scalar(@params)) {
          _w($self,'07001 Wrong number of parameters');
          if(!$$self{'AGI'}) {
               DBD::Ovrimos::lowlevel::sqlFreeStmt($self);
               _delete_stmt_handle($$self{'Database'},$$self{stmt_handle});
          }
          return undef;
     }
     my $i;
     for($i=1; $i<=$parnb; $i++) {
          my $rv=bind_param($self,$i,$params[$i-1]);
          if(!$rv && !$$self{'AGI'}) {
               DBD::Ovrimos::lowlevel::sqlFreeStmt($self);
               _delete_stmt_handle($$self{'Database'},$$self{stmt_handle});
               return undef;
          }
     }
 }
 if(!DBD::Ovrimos::lowlevel::sqlExec($self)) {
     _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($self));
     return undef;
 }
 my $rows=DBD::Ovrimos::lowlevel::sqlGetRowCount($self);
 if(!defined($rows)) {
     _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($self));
 }
 $$self{rowcount}=$rows;
 $$self{start}=1;
 $rows==0? '0E0' : $rows;
}

sub DESTROY {
 my $self=shift;
 my $connref=$$self{'Database'};
 if($$connref{'AGI'}) {
     return 1;
 }
 $self->finish;
}

sub finish {
 my $self=shift;
 if(!$$self{Active}) {
     return 1;      # finished already
 }
 $$self{Active}=0;
 my $connref=$$self{'Database'};
 my $stmts=$$connref{stmts};
 ${$self->{'Errstr'}}='';
 if(!DBD::Ovrimos::lowlevel::sqlCloseCursor($self)) {
     _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($self));
     return undef;
 }
 1;
}

sub _advance {
 my $self=shift;
 my $rows=$$self{rows};
 ${$self->{'Errstr'}}='';
 if(!defined($rows) || $$self{currrow}>=scalar(@$rows)-1) {
     my $where;
     if($$self{start}) {
          $$self{start}=0;
          $where=0;
     } else {
          $where=$$self{rowset_size}-1;
     }
     my $ret=DBD::Ovrimos::lowlevel::sqlCursorNext($self,$where);
     if(!$ret) {
          _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($self));
          return undef;
     }
     $$self{currrow}=0;
 } else {
     $$self{currrow}++;
 }
 my $row=$$rows[$$self{currrow}];
 if($$row{'state'}==DBD::Ovrimos::lowlevel::ROW_INEXISTANT) {
     return undef;
 }
 1;
}

sub fetchrow_arrayref {
 my $self=shift;
 ${$self->{'Errstr'}}='';
 if(!_advance($self)) {
     return undef;
 }
 my $rows=$$self{rows};
 my $row=$$rows[$$self{currrow}];
 my $rowdata=$$row{data};
 if(exists($$self{bindings})) {
     my $i;
     for($i=0; $i<$$self{colnb}; $i++) {
          my $value=$$rowdata[$i];
          my $ref=$$self{bindings}->[$i];
          if(ref($ref)) {
               $$ref=$value;
          }
     }
 }
 $rowdata;
}

sub fetch {
 my $self=shift;
 fetchrow_arrayref($self);
}

sub fetchrow_array {
 my $self=shift;
 @$self->fetchrow_arrayref();
}

sub fetchrow_hashref {
 my $self=shift;
 my $rowdata=fetchrow_arrayref($self);
 return undef if !$rowdata;
 my $resref=$$self{res};
 my $b=exists($$self{bindings});
 my %h=();
 my $i;
 for($i=0; $i<$$self{colnb}; $i++) {
     my $coldefref=$$resref[$i];
     my $name=$$coldefref{name};
     my $value=$$rowdata[$i];
     $h{$name}=$value;
     if($b) {
          my $ref=$$self{bindings}->[$i];
          if(ref($ref)) {
               $$ref=$value;
          }
     }
 }
 \%h;
}

sub rows {
 my $self=shift;
 $$self{rowcount};
}

sub bind_columns {
 my $self=shift;
 my $attrs=shift;
 my @refs=@_;
 ${$self->{'Errstr'}}='';
 if($$self{colnb}!=scalar(@refs)) {
     _w($self,'S1002 Invalid number of columns to bind');
     return undef;
 }
 $$self{bindings}=\@refs;
 1;
}

sub bind_col {
 my $self=shift;
 my $num=shift;
 my $ref=shift;
 my $attrs=shift;
 ${$self->{'Errstr'}}='';
 if($num<1 || $num>$$self{colnb}) {
     _w($self,'S1002 Invalid column number to bind');
     return undef;
 }
 if(!exists($$self{bindings})) {
     $$self{bindings}=[];
 }
 $$self{bindings}->[$num-1]=$ref;
 1;
}

sub FETCH {
 my $self=shift;
 my $key=shift;
 if($key eq 'NUM_OF_FIELDS') {
     return $$self{colnb};
 } elsif($key eq 'NUM_OF_PARAMS') {
     return $$self{paramcount};
 } elsif($key eq 'Active') {
     return $$self{'Active'};
 } elsif($key eq 'NAME') {
     my @a=map { $_->{name} } @{$self->{res}};
     return \@a;
 } elsif($key eq 'NULLABLE') {
     my @a=map { $_->{nullable} } @{$self->{res}};
     return \@a;
 } elsif($key eq 'ovrimos_column_type' || $key eq 'TYPE') {
     my @a=map { $_->{type} } @{$self->{res}};
     return \@a;
 } elsif($key eq 'ovrimos_column_precision') {
     my @a=map { $_->{len} } @{$self->{res}};
     return \@a;
 } elsif($key eq 'ovrimos_column_scale') {
     my @a=map { $_->{scale} } @{$self->{res}};
     return \@a;
 } elsif($key eq 'CursorName') {
     return DBD::Ovrimos::lowlevel::sqlGetCursorName($self);
 } elsif($key eq 'ovrimos_execution_plan') {
     return DBD::Ovrimos::lowlevel::sqlGetExecutionPlan($self);
 } elsif($key eq 'ovrimos_native_query') {
     return DBD::Ovrimos::lowlevel::sqlGetNativeQuery($self);
 } else {
     return undef;
 }
}

sub bind_param {
 my $self=shift;
 my $num=shift;
 my $value=shift;
 my $attr=shift;
 my $connref=$$self{'Database'};

 ${$self->{'Errstr'}}='';
 if($num<1 || $num>$$self{paramcount}) {
     _w($self,'S1093 Invalid parameter number to bind');
     return undef;
 }

 my $coldefref=$$self{params}->[$num-1];
 my $templ=substr(DBD::Ovrimos::lowlevel::_column_pack_template($coldefref),1);     #skip null ind/tor
 my $val=DBD::Ovrimos::lowlevel::_pack($$connref{endianity},$templ,[$value]);
 my $ret=DBD::Ovrimos::lowlevel::sqlPutParam($self,$num-1,$val);
 if(!$ret) {
     _w($self,DBD::Ovrimos::lowlevel::sqlGetStmtDiagnostics($self));
 }
 $ret;
}

1;
