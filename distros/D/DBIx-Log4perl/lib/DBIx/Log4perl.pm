# $Id: Log4perl.pm 279 2006-09-01 18:36:01Z martin $
require 5.008;

use strict;
use warnings;
use Carp qw(croak cluck);
use Log::Log4perl;
use Data::Dumper;

package DBIx::Log4perl;
use DBIx::Log4perl::Constants qw (:masks $LogMask);
use DBIx::Log4perl::db;
use DBIx::Log4perl::st;

our $VERSION = '0.26';
require Exporter;
our @ISA = qw(Exporter DBI);		# look in DBI for anything we don't do

our @EXPORT = ();		# export nothing by default
our @EXPORT_MASKS = qw(DBIX_L4P_LOG_DEFAULT
		       DBIX_L4P_LOG_ALL
		       DBIX_L4P_LOG_INPUT
		       DBIX_L4P_LOG_OUTPUT
		       DBIX_L4P_LOG_CONNECT
		       DBIX_L4P_LOG_TXN
		       DBIX_L4P_LOG_ERRCAPTURE
		       DBIX_L4P_LOG_WARNINGS
		       DBIX_L4P_LOG_ERRORS
		       DBIX_L4P_LOG_DBDSPECIFIC
		       DBIX_L4P_LOG_DELAYBINDPARAM
		       DBIX_L4P_LOG_SQL
		     );
our %EXPORT_TAGS= (masks => \@EXPORT_MASKS);
Exporter::export_ok_tags('masks'); # all tags must be in EXPORT_OK

sub _dbix_l4p_debug {
    my ($self, $h, $level, $thing, @args) = @_;

    $h = $self->{private_DBIx_Log4perl} if !defined($h);

    return unless $h->{logger}->is_debug();

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Quotekeys = 0;

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + $level
        if $level;

    if (scalar(@args) > 1) {
	$h->{logger}->debug(
	    sub {Data::Dumper->Dump([\@args], [$thing])})
    } elsif (ref($thing) eq 'CODE') {
	$h->{logger}->debug($thing);
    } elsif (ref($args[0])) {
	$h->{logger}->debug(
	    sub {Data::Dumper->Dump([$args[0]], [$thing])})
    } elsif (scalar(@args) == 1) {
	if (!defined($args[0])) {
	    $h->{logger}->debug("$thing:");
	} else {
	    $h->{logger}->debug("$thing: " . DBI::neat($args[0]));
	}
    } else {
	$h->{logger}->debug($thing);
    }
    return;
}

sub _dbix_l4p_info {
    my ($self, $level, $thing) = @_;

    my $h = $self->{private_DBIx_Log4perl};

    return unless $h->{logger}->is_info();

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + $level
        if $level;

    $h->{logger}->info($thing);

    return;
}
sub _dbix_l4p_warning {
    my ($self, $level, $thing, @args) = @_;

    my $h = $self->{private_DBIx_Log4perl};

    return unless $h->{logger}->is_warn();

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Quotekeys = 0;

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + $level
        if $level;

    if (scalar(@args) > 1) {
	$h->{logger}->warn(
	    sub {Data::Dumper->Dump([\@args], [$thing])})
    } elsif (ref($args[0])) {
	$h->{logger}->warn(
	    sub {Data::Dumper->Dump([$args[0]], [$thing])})
    } else {
	$h->{logger}->warn("$thing: " . DBI::neat($args[0]));
    }
    return;
}

sub _dbix_l4p_error {
    my ($self, $level, $thing, @args) = @_;

    my $h = $self->{private_DBIx_Log4perl};

    return unless $h->{logger}->is_error();

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Quotekeys = 0;

    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + $level
        if $level;

    if (scalar(@args) > 1) {
	$h->{logger}->error(
	    sub {Data::Dumper->Dump([\@args], [$thing])})
    } elsif (ref($thing) eq 'CODE') {
        $h->{logger}->error($thing);
    } elsif (ref($args[0])) {
	$h->{logger}->error(
	    sub {Data::Dumper->Dump([$args[0]], [$thing])})
    } else {
	$h->{logger}->error("$thing: " . DBI::neat($args[0]));
    }
    return;
}

sub _dbix_l4p_attr_map {
    return {dbix_l4p_logger => 'logger',
	    dbix_l4p_init => 'init',
	    dbix_l4p_class => 'class',
	    dbix_l4p_logmask => 'logmask',
            dbix_l4p_ignore_err_regexp => 'err_regexp'
	   };
}

sub dbix_l4p_getattr {
    my ($self, $item) = @_;

    croak ('wrong arguments - dbix_l4p_getattr(attribute_name)')
      if (scalar(@_) != 2 || !defined($_[1]));

    my $m = _dbix_l4p_attr_map();

    my $h = $self->{private_DBIx_Log4perl};

    if (!exists($m->{$item})) {
	warn "$item does not exist";
	return undef;
    }
    return $h->{$m->{$item}};
}

sub dbix_l4p_setattr {
    my ($self, $item, $value) = @_;

    croak ('wrong arguments - dbix_l4p_setattr(attribute_name, value)')
      if (scalar(@_) != 3 || !defined($_[1]));

    my $m = _dbix_l4p_attr_map();

    my $h = $self->{private_DBIx_Log4perl};

    if (!exists($m->{$item})) {
	warn "$item does not exist";
	return undef;
    }
    $h->{$m->{$item}} = $value;
    1;
}

sub connect {

    my ($drh, $dsn, $user, $pass, $attr) = @_;

    my $dbh = $drh->SUPER::connect($dsn, $user, $pass, $attr);
    return $dbh if (!$dbh);

    #
    # Enable dbms_output for DBD::Oracle else turn off DBDSPECIFIC as we have
    # no support for DBDSPECIFIC in any other drivers.
    # BUT only enable it if the log handle is doing debug as we only call
    # dbms_output_get in that case.
    #
    my $h = $dbh->{private_DBIx_Log4perl};
    $h->{dbd_specific} = 1;
    if (($h->{logger}->is_debug()) &&
            ($h->{logmask} & DBIX_L4P_LOG_DBDSPECIFIC) &&
                ($h->{driver} eq 'Oracle')) {
	$dbh->func('dbms_output_enable');
    } else {
	$h->{logmask} &= ~DBIX_L4P_LOG_DBDSPECIFIC;
    }
    $h->{dbd_specific} = 0;
    return $dbh;
}

sub dbix_l4p_logdie
{
    my ($drh, $msg) = @_;
    _error_handler($msg, $drh);
    die "$msg";
}

1;

__END__

=head1 NAME

DBIx::Log4perl - Perl extension for DBI to selectively log DBI
methods, SQL, parameters, result-sets, transactions etc to a
Log::Log4perl handle.

=head1 SYNOPSIS

  use Log::Log4perl;
  use DBIx::Log4perl;

  Log::Log4perl->init("/etc/mylog.conf");
  my $dbh = DBIx::Log4perl->connect('DBI:odbc:mydsn', $user, $pass);
  $dbh->DBI_METHOD(args);

  or

  use DBIx::Log4perl;
  my $dbh = DBIx::Log4perl->connect('dbi:ODBC:mydsn', $user, $pass,
                                    {dbix_l4p_init => "/etc/mylog.conf",
                                     dbix_l4p_class => "My::Package"});
  $dbh->DBI_METHOD(args);

=head1 DESCRIPTION

B<NOTE: The names of DBIx::Log4perl L</ATTRIBUTES> have changed in version
0.18. They are now all lowercased as per the DBI specification.>

C<DBIx::Log4perl> is a wrapper over DBI which adds logging of your DBI
activity via a Log::Log4perl handle. Log::Log4perl has many advantages
for logging but the ones probably most attractive are:

The ability to turn logging on or off or change the logging you see
without changing your code (or even without restarting your programs
if you use C<init_and_watch>).

Different log levels allowing you to separate warnings, errors and fatals
to different files.

The ability to capture all the information available via DBI when an
error occurs.

=head1 METHODS

DBIx::Log4perl adds the following methods over DBI.

=head2 dbix_l4p_getattr

  $h->dbxi_l4p_getattr('dbix_l4p_logmask');

Returns the value for a DBIx::Log4perl attribute (see L</ATTRIBUTES>).

=head2 dbix_l4p_setattr

 $h->dbix_l4p_setattr('dbix_l4p_logmask', 1);

Set the value of the specified DBIx::Log4perl attribute
(see L</ATTRIBUTES>).

=head2 dbix_l4p_logdie

  $h->dbix_l4p_logdie($message);

Calls the internal _error_handler method with the message $message
then dies with Carp::confess.

The internal error handler is inserted into DBI's HandleError if
L</DBIX_L4P_LOG_ERRCAPTURE> is enabled. It attempts to log as much
information about the SQL you were executing, parameters etc.

As an example, you might be checking a $dbh->do which attempts to
update a row really does update a row and want to die with all possible
information about the problem if the update fails. Failing to update a
row would not ordinarily cause DBI's error handler to be called.

  $affected = $dbh->do(q/update table set column = 1 where column = 2/);
  $dbh->dbix_logdie("Update failed") if ($affected != 1);

=head1 GLOBAL VARIABLES

=head2 DBIx::Log4perl::LogMask

This variable controls the amount of logging logged to the
Log::Log4perl handle. There are a number of constants defined which
may be ORed together to obtain the logging level you require:

=head1 CONSTANTS

The following constants may be imported via the C<:masks> group

  use DBIx::Log4perl qw(:masks);

=over

=item DBIX_L4P_LOG_DEFAULT

By default LogMask is set to DBIX_L4P_LOG_DEFAULT which is currently
DBIX_L4P_LOG_TXN | DBIC_L4P_LOG_CONNECT | DBIX_L4P_LOG_INPUT |
DBIX_L4P_LOG_ERRCAPTURE | DBIX_L4P_LOG_ERRORS |
DBIX_L4P_LOG_DBDSPECIFIC.

=item DBIX_L4P_LOG_ALL

Log everything, all possible masks ORed together which also includes
delaying the logging of bind_param (see L</DBIX_L4P_LOG_DELAYBINDPARAM>).

=item DBIX_L4P_LOG_INPUT

Log at Log4perl debug level input SQL to C<do>, C<prepare>, select*
methods and any value returned from C<last_insert_id>. In addition, if
the SQL is an insert/update/delete statement the rows affected will
be logged.

NOTE: Many databases return 0 rows affected for DDL statements like
create, drop etc.

=item DBIX_L4P_LOG_OUTPUT

Log at Log4perl debug level the result-sets generated by select* or
fetch* methods. Be careful, this could produce a lot of output if you
produce large result-sets.

=item DBIX_L4P_LOG_CONNECT

Log at Log4perl debug level any call to the C<connect> and
C<disconnect> methods and their arguments.

On connect the DBI version, DBIx::Log4perl version, the driver name
and version will be logged at Log4perl info level.

=item DBIX_L4P_LOG_TXN

Log at Log4perl debug level all calls to C<begin_work>, C<commit> and
C<rollback>.

=item DBIX_L4P_LOG_ERRORS

Log at Log4perl error level any method which fails which is not caught
by RaiseError. Currently this is only the execute_array method.

=item DBIX_L4P_LOG_WARNINGS

Log at Log4perl warning level any calls to do which return no affected
rows on an insert, update or delete opertion.

=item DBIX_L4P_LOG_ERRCAPTURE

Install a DBI error handler which logs at Log4perl fatal level
as much information as it can about any trapped error. This includes
some or all of the following depending on what is available:

  Handle type being used
  Number of statements under the current connection
  Name of database
  Username for connection to database
  Any SQL being executed at the time
  The error message text
  Any parameters in ParamValues
  Any parameters in ParamArrays
  A stack trace of the error

If you install your own error handler in the C<connect> call it will
be replaced when C<connect> is called in DBI but run from
C<DBIx::Log4perl>'s error handler.

C<DBIx::Log4perl> always returns 0 from the error handler if it is the
only handler which causes the error to be passed on. If you have
defined your own error handler then whatever your handler returns is
passed on.

=item DBIX_L4P_LOG_DBDSPECIFIC

This logging depends on the DBD you are using:

=over 6

=item DBD::Oracle

Use DBD::Oracle's methods for obtaining the buffer containing
C<dbms_output.put_line output>. Whenever C<$dbh-E<gt>execute> is called
DBIx::Log4perl will use C<$dbh-E<gt>func('dbms_output_get')> to obtain
an array of lines written to the buffer with C<put_line>. These will be
written to the log (prefixed with "dbms") at level DEBUG for the
execute method.

NOTE: If L</DBIX_L4P_LOG_DBDSPECIFIC> is enabled, DBIx::Log4perl calls
C<$dbh-E<gt>func(dbms_output_enable)> after the connect method has
succeeded. This will use DBD::Oracle's default buffer size. If you want
to change the buffer size see DBD::Oracle and change it after the connect
method has returned.

As useful as this may seem you are warned against using it as when the
dbms_output buffer is full it will generate an Oracle exception which
is probably not what you want. This can happen if the procedure you
call calls dbms_output.put_line too often and fills the buffer before
returning to DBI.

=back

=item DBIX_L4P_LOG_DELAYBINDPARAM

If set (and it is not the default) this prevents the logging of
bind_param method calls and instead the bound parameters and parameter
types (if available) are logged with the execute method
instead. Example output for:

    my $st = $ph->prepare(q/insert into mje2 values(?,?)/);
    $st->bind_param(1, 1);
    $st->bind_param(2, "fred");
    $st->execute;

will output something like:

    DEBUG - prepare(0.1): 'insert into mje values(?,?)'
    DEBUG - $execute(0.1) = [{':p1' => 1,':p2' => 'fred'},undef];
    DEBUG - affected(0.1): 1

instead of the more usual:

    DEBUG - prepare(0.1): 'insert into mje values(?,?)'
    DEBUG - $bind_param(0.1) = [1,1];
    DEBUG - $bind_param(0.1) = [2,'fred'];
    DEBUG - execute(0.1)
    DEBUG - affected(0.1): 1

where the parameter names and values are displayed in the {} after
execute and the parameter types are the next argument. Few DBDs
support the ParamTypes attribute in DBI and hence mostly these are
displayed as C<undef> as in the above case which was using
DBD::Oracle. Most (if not all) DBDs support ParamValues but you might
want to check that before setting this flag.

=item DBIX_L4P_LOG_SQL

If set this logs the SQL passed to the do, prepare and select*
methods. This just separates SQL logging from what
L</DBIX_L4P_LOG_INPUT> does and is generally most useful when combined
with L<DBIX_L4P_LOG_DELAYBINDPARAM>.

=back

=head1 ATTRIBUTES

When you call connect you may add C<DBIx::Log4perl> attributes to those
which you are passing to DBI. You may also get and set attributes after
connect using C<dbix_l4p_getattr()> and C<dbix_l4p_setattr()>.
C<DBIx::Log4perl> supports the following attributes:

=over

=item C<dbix_l4p_init>

This is the string to pass on to Log::Log4Perl's C<init> method. It is
the name of the Log::Log4perl configuration file to use. e.g.

  Log::Log4perl::init('/etc/log4perl.conf');

See L<Log::Log4perl>.

=item C<dbix_l4p_log>

This is the string to pass on to Log::Log4Perl's C<get_logger> method
e.g.

  $logger = Log::Log4perl->get_logger('mysys.dbi');

See L<Log::Log4perl>.

=item C<dbix_l4p_logger>

If you have already initialised and created your own Log::Log4perl
handle you can pass it in as C<dbix_l4p_logger> and C<DBIx::Log4perl>
will ignore L</dbix_l4p_log> and L</dbix_l4p_init>.

=item C<dbix_l4p_logmask>

A mask of the flags defined under L</CONSTANTS>.

=item C<dbix_l4p_ignore_err_regexp>

A regular expression which will be matched against $DBI::err in the
error handler and execute and if it matches no diagnostics will be
output; the handler will just return (maybe causing the next handler
in the chain to be called if there is one).

An example of where this can be useful is if you are raising
application errors in your procedures (e.g., RAISE_APPLICATION_ERROR
in Oracle) where the error indicates something that is expected. Say
you validate a web session by looking for the session ID via a
procedure and raise an error when the session is not found. You
probably don't want all the information DBIx::Log4perl normally
outputs to the error log about this error in which case you set the
regular expression to match your error number and it will no longer
appear in the log.

=back

Although these attributes are supported the recommended way to use
DBIx::Log4perl it to use Log::Log4perl in your application and call
the C<Log::Log4Perl-E<gt>init> to define your log4perl configuration file.
DBIx::Log4perl will then call
C<Log::Log4perl-E<gt>get_logger("DBIx::Log4perl")> (as was intended by the
authors of Log::Log4perl) and all you need is a
C<log4perl.logger.DBIx.Log4perl> entry in your configuration file.

=head1 Log::Log4perl CONFIGURATION FILE

Please see L<Log::Log4perl> for full details of the configuration file
and appenders. DBIx::Log4perl contains a sample configuration file you
may use to get started. It looks like this:

  log4perl.logger = FATAL, LOGFILE

  log4perl.appender.LOGFILE=Log::Log4perl::Appender::File
  log4perl.appender.LOGFILE.filename=/tmp/log
  log4perl.appender.LOGFILE.mode=append
  log4perl.appender.LOGFILE.Threshold = ERROR

  log4perl.appender.LOGFILE.layout=PatternLayout
  log4perl.appender.LOGFILE.layout.ConversionPattern=[%r] %F %L %c - %m%n

  log4perl.logger.DBIx.Log4perl=DEBUG, A1
  log4perl.appender.A1=Log::Log4perl::Appender::File
  log4perl.appender.A1.filename=/tmp/xlog
  log4perl.appender.A1.mode=append
  log4perl.appender.A1.layout=Log::Log4perl::Layout::SimpleLayout

This is perhaps the most simple configuration. It says fatal errors go
to /tmp/log and debug and above go to /tmp/xlog. It also uses the
SimpleLayout which prefixes each line with the log level. You can
use:

  log4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout
  log4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n

to make Log::Log4perl prefix the line with a timestamp, module name and
filename. DBIx::Log4perl sets C<$Log::Log4perl::caller_depth> in each
method so when Log4perl outputs the module/file DBIx::Log4perl
is ignored. This is extremely useful if you need to see where a DBI
method is called from.

=head1 FORMAT OF LOG

=head2 Example output

For a connect the log will contain something like:

  DEBUG - connect(0): DBI:mysql:mjetest, bet
  INFO - DBI: 1.50, DBIx::Log4perl: 0.01, Driver: mysql(3.0002_4)

For

  $sth = $dbh->prepare('insert into mytest values (?,?)');
  $sth->execute(1, 'one');

you will get:

  DEBUG - prepare(0.1): 'insert into mytest values (?,?)'
  DEBUG - $execute(0.1) (insert into mytest values (?,?)) = [1,'one'];

In this latter case the SQL is repeated for convenience but this only
occurs if C<execute> is called with parameters. If C<execute> is
called without any arguments the SQL is not repeated in the
C<execute>. Also note the output will include bind_param calls if you
bound parameters seperately but how this is logged depends on
L</DBIX_L4P_LOG_DELAYBINDPARAM>.

The numbers in the () after a method name indicate which connection or
statement handle the operation was performed on. The first connection
your application makes will be connection 0 (see "connect(0)"
above). Each statement method will show the connection number followed
by a '.' and the statement number (e.g., "prepare(0.1)" above is the
second statement handle on the first connection).

NOTE: Some DBI methods are combinations of various methods
e.g. selectrow_* methods. For some of these methods DBI does not
actually call all the lower methods because the driver implements
selectrow_* methods in C. For these cases, DBIx::Log4perl will only be
able to log the selectrow_* method, the SQL, any parameters and any
returned result-set and you will not necessarily see a prepare,
execute and fetch in the log. e.g.,

  $dbh->selectrow_array('select b from mytest where a = ?',undef,1);

results in:

  DEBUG - $selectrow_array = ['select b from mytest where a = ?',undef,1];

with no evidence prepare/execute/fetch was called.

If C<DBIX_L4P_LOG_ERRCAPTURE> is set all possible information about an
error is written to the log by the error handler. In addition a few
method calls will attempt to write a separate log entry containing
information which may not be available in the error handler e.g.

  $sth = $dbh->prepare(q/insert into mytest values (?,?)/);
  $sth->bind_param_array(1, [51,1,52,53]);
  $sth->bind_param_array(2, ['fiftyone', 'one', 'fiftythree', 'fiftytwo']);
  $inserted = $sth->execute_array( { ArrayTupleStatus => \@tuple_status } );

when the mytest table has a primary key on the first column and a row
with 1 already exists will result in:

  ERROR - $Error = [1062,'Duplicate entry \'1\' for key 1','S1000'];
  ERROR -          for 1,fiftytwo

because the @tuple_status is not available in the error handler. In
this output 1062 is the native database error number, the second
argument is the error text, the third argument the state and the
additional lines attempt to highlight the parameters which caused the
problem.

=head2 Example captured error

By default, DBIx::Log4perl replaces any DBI error handler you have
with its own error handler which first logs all possible information
about the SQL that was executing when the error occurred, the
parameters involved, the statement handle and a stack dump of where
the error occurred.  Once DBIx::Log4perl's error handler is executed
it continues to call any error handler you have specifically set in
you Perl DBI code.

Assuming you'd just run the following script:

  use Log::Log4perl qw(get_logger :levels);
  Log::Log4perl->init_and_watch("example.conf");
  my $dbh = DBIx::Log4perl->connect('dbi:Oracle:XE', 'user', 'password) or
      die "$DBD::errstr";
  $dbh->do("insert into mytable values(?, ?)", undef, 1,
           'string too long for column - will be truncated which is an error');
  $dbh->disconnect;

but the string argument to the insert is too big for the column then
DBIx::Log4perl would provide error output similar to the following:

  FATAL -   ============================================================
  DBD::Oracle::db do failed: ORA-12899: value too large for column
   "BET"."MYTABLE"."B" (actual: 64, maximum: 10) (DBD ERROR: error possibly
   near <*> indicator at char 32 in 'insert into martin values(:p1, :<*>p2)')
   [for Statement "insert into martin values(?, ?)"]
  lasth Statement (DBIx::Log4perl::db=HASH(0x974cf64)):
    insert into martin values(?, ?)
  DB: XE, Username: user
  handle type: db
  SQL: Possible SQL: /insert into mytable values(?, ?)/
  db Kids=0, ActiveKids=0
  DB errstr: ORA-12899: value too large for column "BET"."MYTABLE"."B"
   (actual: 64, maximum: 10) (DBD ERROR: error possibly near <*> indicator
   at char 32 in 'insert into mytable values(:p1, :<*>p2)')
  ParamValues captured in HandleSetErr:
    1,'string too long for column - will be truncated which is an error',
  0 sub statements:
  DBI error trap at /usr/lib/perl5/site_perl/5.8.8/DBIx/Log4perl/db.pm line 32
        DBIx::Log4perl::db::do('DBIx::Log4perl::db=HASH(0x97455d8)',
        'insert into mytable values(?, ?)', 'undef', 1, 'string too long for
         column - will be truncated which is an error') called at errors.pl
         line 12
  ============================================================

What this shows is:

o the error reported by the DBD and the method called (do in this case).

o the last handle used and the SQL for the last statement executed

o the connection the error occurred in

o the handle type the error occurred on, db or stmt (db in this case)

o Other possible SQL that may be in error under this db
connection e.g. if you were executing multiple statements on a single
db connection

o the Kids and ActiveKids value for this db - (see DBI docs)

o the error message text in C<DBI::errstr>

o any sql parameters passed to DBI (see L<DBI> for ParamValues)

o a trace of where the problem occurred In this case the final problem
  was in db.pm but as this is DBIx::Log4perl's do method, the real
  issue was in the stack element below this which was errors.pl line
  12.

=head2 Use of Data::Dumper

DBIx::log4perl makes extensive use of Data::Dumper to output arguments
passed to DBI methods. In some cases it combines the method called
with the data it is logging e.g.

  DEBUG - $execute = [2,'two'];

This means the execute method was called with placeholder arguments
of 2 and 'two'. The '$' prefixing execute is because Data::Dumper was
called like this:

  Data::Dumper->dump( [ \@execute_args ], [ 'execute'] )

so Data::Dumper believes it is dumping $execute. DBIx::Log4perl uses
this method extensively to log the method and arguments - just ignore
the leading '$' in the log.


=head1 NOTES

During the development of this module I came across of large number of
issues in DBI and various DBDs. I've tried to list them here but in
some cases I cannot give the version the problem was fixed in because
it was not released at the time of writing.

=head2 DBI and $h->{Username}

If you get an error like:

  Can't get DBI::dr=HASH(0x83cbbc4)->{Username}: unrecognised attribute name

in the error handler it is because it was missing from DBI's XS code.

This is fixed in DBI 1.51.

=head2 DBI and $h->{ParamArrays}

This is the same issue as above for $h->{Username}.

=head2 DBD::ODBC and ParamValues

In DBD::ODBC 1.13 you cannot obtain ParamValues after an execute has
failed. I believe this is because DBD::ODBC insists on describing a
result-set before returning ParamValues and that is not necessary for
ParamValues.

Fixed in 1.14.

=head2 DBD::mysql and ParamArrays

DBD::mysql 3.002_4 does not support ParamArrays.

I had to add the following to dbdimp.c to make it work:

  case 'P':
    if (strEQ(key, "PRECISION"))
      retsv= ST_FETCH_AV(AV_ATTRIB_PRECISION);
    /* + insert the following block */
    if (strEQ(key, "ParamValues")) {
        HV *pvhv = newHV();
        if (DBIc_NUM_PARAMS(imp_sth)) {
            unsigned int n;
            SV *sv;
            char key[100];
            I32 keylen;
            for (n = 0; n < DBIc_NUM_PARAMS(imp_sth); n++) {
                keylen = sprintf(key, "%d", n);
                hv_store(pvhv, key, keylen, newSVsv(imp_sth->params[n].value), 0);
            }
        }
        retsv = newRV_noinc((SV*)pvhv);
    }
    /* - end of inserted block */
    break;

I believe this code is now added in DBD::mysql 3.0003_1.

=head1 Contributing

There are six main ways you may help with the development and
maintenance of this module:

=over

=item Submitting patches

Please get the latest version from CPAN and submit any patches against
that.

=item Reporting installs

Install CPAN::Reporter and report you installations. This is easy to
do - see L</CPAN Testers Reporting>.

=item Report bugs

If you find what you believe is a bug then enter it into the
L<http://rt.cpan.org/Dist/Display.html?Name=DBIx::Log4perl>
system. Where possible include code which reproduces the problem
including any schema required and the versions of software you are
using.

If you are unsure whether you have found a bug report it anyway.

=item pod comments and corrections

If you find inaccuracies in the DBIx::Log4perl pod or have a comment
which you think should be added then go to L<http://annocpan.org> and
submit them there. I get an email for every comment added and will
review each one and apply any changes to the documentation.

=item Review DBIx::Log4perl

Add your review of DBIx::Log4perl on L<http://cpanratings.perl.org>.

=item submit test cases

The test suite for DBIx::Log4perl is pitifully small. Any test cases
would be gratefully received. In particular, it would be really nice
to add support for Test::Database.

=back

=head1 CPAN Testers Reporting

Please, please, please (is that enough), consider installing
CPAN::Reporter so that when you install perl modules a report of the
installation success or failure can be sent to cpan testers. In this
way module authors 1) get feedback on the fact that a module is being
installed 2) get to know if there are any installation problems. Also
other people like you may look at the test reports to see how
successful they are before choosing the version of a module to
install.

CPAN::Reporter is easy to install and configure like this:

  perl -MCPAN -e shell
  cpan> install CPAN::Reporter
  cpan> reload cpan
  cpan> o conf init test_report

Simply answer the questions to configure CPAN::Reporter.

You can find the CPAN testers wiki at L<http://wiki.cpantesters.org/>
and the installation guide for CPAN::Reporter at
L<http://wiki.cpantesters.org/wiki/CPANInstall>.

=head1 TO_DO

=over

=item better testing

=back

=head1 REQUIREMENTS

You will need at least Log::Log4perl 1.04 and DBI 1.50.

DBI-1.51 contains the changes listed under L</NOTES>.

Versions of Log::Log4perl before 1.04 work but unfortunately you will
get code references in some of the log output where DBIx::Log4perl
does:

  $log->logwarn(sub {Data::Dumper->Dump(something)})

The same applies to logdie. See the Log4perl mailing list for details.

=head1 SEE ALSO

L<DBI>

L<Log::Log4perl>

=head1 AUTHOR

M. J. Evans, E<lt>mjevans@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 - 2012 by M. J. Evans

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
