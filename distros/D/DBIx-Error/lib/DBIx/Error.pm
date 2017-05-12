package DBIx::Error;

# Copyright (C) 2012 Michael Brown <mbrown@fensystems.co.uk>
#
# This program is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 NAME

DBIx::Error - Structured exceptions for DBI

=head1 SYNOPSIS

    use DBIx::Error;

    # Configure exception handler for DBI
    my $db = DBI->connect ( $dsn, $user, $password,
			    { HandleError => DBIx::Error->HandleError,
			      ShowErrorStatement => 1 } );

    # Catch a unique constraint violation (by class name)
    use TryCatch;
    try {
      ...
    } catch ( DBIx::Error::UniqueViolation $err ) {
      die "Name $name is already in use";
    }

    # Catch a unique constraint violation (by SQLSTATE)
    use TryCatch;
    try {
      ...
    } catch ( DBIx::Error $err where { $_->state eq "23505" } ) {
      die "Name $name is already in use";
    }

    # Catch any type of database error
    use TryCatch;
    try {
      ...
    } catch ( DBIx::Error $err ) {
      die "Internal database error [SQL state ".$err->state."]:\n".$err;
    }

=head1 DESCRIPTION

C<DBIx::Error> provides structured exceptions for C<DBI> errors.  Each
five-character C<SQLSTATE> is mapped to a Perl exception class,
allowing exceptions to be caught using code such as

    try {
      ...
    } catch ( DBIx::Error::NotNullViolation $err ) {
      ...
    } catch ( DBIx::Error::UniqueViolation $err ) {
      ...
    }

The exception stringifies to produce the full C<DBI> error message
(including a stack trace).  The original DBI error attributes (C<err>,
C<errstr> and C<state>) are also provided for inspection.

See L</"EXCEPTION CLASS HIERARCHY"> below for a list of supported
exception classes.

=cut

use Scalar::Util qw ( blessed );
use List::MoreUtils qw ( uniq );
use Carp;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use strict;
use warnings;

extends "Throwable::Error";

use 5.010;
our $VERSION = "1.0.1";

=head1 ATTRIBUTES

=over

=item C<message>

The error message, as produced by C<DBI>.

If C<ShowErrorStatement> was set to a true value when connecting to
the database, this message will include the SQL statement that caused
the error.

=cut

has "message" => (
  is => "ro",
  isa => "Str",
  required => 1,
  writer => "_rewrite_message",
);

=item C<stack_trace>

A stack trace, as produced using C<StackTrace::Auto>.

=item C<err>

The native database engine error code, as obtained from C<$DBI::err>.

=cut

has "err" => (
  is => "ro",
  isa => "Value",
  required => 1,
);

=item C<errstr>

The native database engine error message, as obtained from
C<$DBI::errstr>.

=cut

has "errstr" => (
  is => "ro",
  isa => "Str",
  required => 1,
);

=item C<state>

The state code in the standard C<SQLSTATE> five character format, as
obtained from C<$DBI::state>.

=cut

has "state" => (
  is => "ro",
  isa => "Str",
  required => 1,
);

=back

=head1 CLASS METHODS

=over

=item C<< define_exception_classes ( %states ) >>

See L</SUBCLASSING> below.

=cut

sub define_exception_classes {
  my $defining_class = shift;
  my %states = @_;

  # Add "around _exception_class" modifier to return the new classes
  my $meta = $defining_class->meta;
  $meta->add_around_method_modifier ( "exception_class_definition", sub {
    my $orig = shift;
    my $class = shift;
    my $state = shift;

    if ( exists $states{$state} ) {
      my $exception_class = ( ( $states{$state} =~ /::/ ) ? $states{$state} :
			      $defining_class."::".$states{$state} );
      return ( $exception_class, $defining_class );
    } else {
      return $class->$orig ( $state );
    }
  } );

  # Sanity check: verify that all required generic classes have been
  # mapped (either by this class or by a superclass).
  foreach my $generic_state ( uniq map { substr ( $_, 0, 2 )."000" }
			      keys %states ) {
    confess "Missing mapping for generic SQLSTATE ".$generic_state
	unless $defining_class->exception_class_definition ( $generic_state );
  }
}

sub exception_class_definition {}

=item C<< exception_class ( $state ) >>

Get the exception class for the specified SQLSTATE.

=cut

sub exception_class {
  my $class = shift;
  my $state = shift;

  # Determine the generic SQLSTATE
  my $generic_state = substr ( $state, 0, 2 )."000";

  # Determine the exception class, its defining class, and its superclass
  my $exception_class;
  my $defining_class;
  my $exception_superclass;
  if ( ( $exception_class, $defining_class ) =
       $class->exception_class_definition ( $state ) ) {
    # We recognise this exact SQLSTATE
    if ( $state eq $generic_state ) {
      # This is a generic SQLSTATE; the superclass is the defining class
      $exception_superclass = $defining_class;
    } else {
      # This is not a generic SQLSTATE; the superclass can be found by
      # calling ourself recursively.  (The sanity check in
      # define_exception_classes() guarantees that this will work.)
      $exception_superclass = $class->exception_class ( $generic_state );
    }
  } elsif ( ( $exception_class, $defining_class ) =
	    $class->exception_class_definition ( $generic_state ) ) {
    # We don't recognise this exact SQLSTATE, but we do recognise the
    # generic SQLSTATE
    $exception_superclass = $defining_class;
  } else {
    # We don't even recognise the generic SQLSTATE
    $exception_class = __PACKAGE__;
  }

  # Create exception class, if applicable
  if ( ! Class::MOP::does_metaclass_exist ( $exception_class ) ) {
    Moose::Meta::Class->create ( $exception_class,
				 superclasses => [ $exception_superclass ] )
	->make_immutable ( inline_constructor => 0 );
  }

  return $exception_class;
}
  
=item C<< HandleError() >>

Returns a code reference suitable for passing as the C<HandleError>
database connection parameter for C<DBI> (or C<DBIx::Class>, or
C<Catalyst::Model::DBIC::Schema>).

=cut

our $last_dbi_exception;

sub HandleError {
  my $class = shift;

  return sub {
    my $msg = shift;
    my $h = shift;

    # Do not modify existing structured exceptions
    die $msg if blessed $msg;

    # Do not create a structured exception unless we have a DBI handle
    # of some sort
    die $msg unless blessed $h;

    # Retrieve error information from DBI handle
    my $err = $h->err;
    my $errstr = $h->errstr;
    my $state = $h->state;

    # Determine exception class
    my $exception_class = $class->exception_class ( $state );

    # Create exception
    my $exception = $exception_class->new ( message => $msg,
					    err => $err,
					    errstr => $errstr,
					    state => $state );

    # Store as most recent DBI exception
    $last_dbi_exception = $exception;

    # Throw exception
    $exception->throw();
  };
}

=item C<< exception_action() >>

Returns a code reference suitable for passing as the
C<exception_action> configuration parameter for C<DBIx::Class::Schema>.

=cut

sub exception_action {
  my $class = shift;

  return sub {
    my $msg = shift;

    # Clear the stored DBI exception
    my $underlying_exception = $last_dbi_exception;
    undef $last_dbi_exception;

    # Do not modify existing structured exceptions
    die $msg if blessed $msg;

    # If we have a stored DBI exception, update its message and
    # rethrow.  We do this because DBIx::Class sometimes stringifies
    # an exception before rethrowing it (e.g. in populate(), to add
    # information about which populate slice caused the problem).
    # This stringification destroys the original exception object, so
    # we must recreate the exception with the updated message.
    if ( defined $underlying_exception ) {
      $underlying_exception->_rewrite_message ( $msg );
      $underlying_exception->throw();
    }

    # Otherwise, generate a generic DBIx::Error::GeneralError exception
    my $state = "S1000"; # "General Error"
    my $exception_class = $class->exception_class ( $state );
    $exception_class->throw ( message => $msg,
			      err => $state,
			      errstr => $msg,
			      state => $state );
  }
}

# Mapping from known SQLSTATE codes to exception classes.  Mostly
# autogenerated from the PostgreSQL documentation.
my %known_sql_states = (
  "03000" => "SqlStatementNotYetComplete",
  "08000" => "ConnectionException",
  "08003" => "ConnectionDoesNotExist",
  "08006" => "ConnectionFailure",
  "08001" => "SqlclientUnableToEstablishSqlconnection",
  "08004" => "SqlserverRejectedEstablishmentOfSqlconnection",
  "08007" => "TransactionResolutionUnknown",
  "08P01" => "ProtocolViolation",
  "09000" => "TriggeredActionException",
  "0A000" => "FeatureNotSupported",
  "0B000" => "InvalidTransactionInitiation",
  "0F000" => "LocatorException",
  "0F001" => "InvalidLocatorSpecification",
  "0L000" => "InvalidGrantor",
  "0LP01" => "InvalidGrantOperation",
  "0P000" => "InvalidRoleSpecification",
  "20000" => "CaseNotFound",
  "21000" => "CardinalityViolation",
  "22000" => "DataException",
  "2202E" => "ArraySubscriptError",
  "22021" => "CharacterNotInRepertoire",
  "22008" => "DatetimeFieldOverflow",
  "22012" => "DivisionByZero",
  "22005" => "ErrorInAssignment",
  "2200B" => "EscapeCharacterConflict",
  "22022" => "IndicatorOverflow",
  "22015" => "IntervalFieldOverflow",
  "2201E" => "InvalidArgumentForLogarithm",
  "22014" => "InvalidArgumentForNtileFunction",
  "22016" => "InvalidArgumentForNthValueFunction",
  "2201F" => "InvalidArgumentForPowerFunction",
  "2201G" => "InvalidArgumentForWidthBucketFunction",
  "22018" => "InvalidCharacterValueForCast",
  "22007" => "InvalidDatetimeFormat",
  "22019" => "InvalidEscapeCharacter",
  "2200D" => "InvalidEscapeOctet",
  "22025" => "InvalidEscapeSequence",
  "22P06" => "NonstandardUseOfEscapeCharacter",
  "22010" => "InvalidIndicatorParameterValue",
  "22023" => "InvalidParameterValue",
  "2201B" => "InvalidRegularExpression",
  "2201W" => "InvalidRowCountInLimitClause",
  "2201X" => "InvalidRowCountInResultOffsetClause",
  "22009" => "InvalidTimeZoneDisplacementValue",
  "2200C" => "InvalidUseOfEscapeCharacter",
  "2200G" => "MostSpecificTypeMismatch",
  "22004" => "NullValueNotAllowed",
  "22002" => "NullValueNoIndicatorParameter",
  "22003" => "NumericValueOutOfRange",
  "22026" => "StringDataLengthMismatch",
  "22001" => "StringDataRightTruncation",
  "22011" => "SubstringError",
  "22027" => "TrimError",
  "22024" => "UnterminatedCString",
  "2200F" => "ZeroLengthCharacterString",
  "22P01" => "FloatingPointException",
  "22P02" => "InvalidTextRepresentation",
  "22P03" => "InvalidBinaryRepresentation",
  "22P04" => "BadCopyFileFormat",
  "22P05" => "UntranslatableCharacter",
  "2200L" => "NotAnXmlDocument",
  "2200M" => "InvalidXmlDocument",
  "2200N" => "InvalidXmlContent",
  "2200S" => "InvalidXmlComment",
  "2200T" => "InvalidXmlProcessingInstruction",
  "23000" => "IntegrityConstraintViolation",
  "23001" => "RestrictViolation",
  "23502" => "NotNullViolation",
  "23503" => "ForeignKeyViolation",
  "23505" => "UniqueViolation",
  "23514" => "CheckViolation",
  "23P01" => "ExclusionViolation",
  "24000" => "InvalidCursorState",
  "25000" => "InvalidTransactionState",
  "25001" => "ActiveSqlTransaction",
  "25002" => "BranchTransactionAlreadyActive",
  "25008" => "HeldCursorRequiresSameIsolationLevel",
  "25003" => "InappropriateAccessModeForBranchTransaction",
  "25004" => "InappropriateIsolationLevelForBranchTransaction",
  "25005" => "NoActiveSqlTransactionForBranchTransaction",
  "25006" => "ReadOnlySqlTransaction",
  "25007" => "SchemaAndDataStatementMixingNotSupported",
  "25P01" => "NoActiveSqlTransaction",
  "25P02" => "InFailedSqlTransaction",
  "26000" => "InvalidSqlStatementName",
  "27000" => "TriggeredDataChangeViolation",
  "28000" => "InvalidAuthorizationSpecification",
  "28P01" => "InvalidPassword",
  "2B000" => "DependentPrivilegeDescriptorsStillExist",
  "2BP01" => "DependentObjectsStillExist",
  "2D000" => "InvalidTransactionTermination",
  "2F000" => "SqlRoutineException",
  "34000" => "InvalidCursorName",
  "38000" => "ExternalRoutineException",
  "39000" => "ExternalRoutineInvocationException",
  "3B000" => "SavepointException",
  "3B001" => "InvalidSavepointSpecification",
  "3D000" => "InvalidCatalogName",
  "3F000" => "InvalidSchemaName",
  "40000" => "TransactionRollback",
  "40002" => "TransactionIntegrityConstraintViolation",
  "40001" => "SerializationFailure",
  "40003" => "StatementCompletionUnknown",
  "40P01" => "DeadlockDetected",
  "42000" => "SyntaxErrorOrAccessRuleViolation",
  "42601" => "SyntaxError",
  "42501" => "InsufficientPrivilege",
  "42846" => "CannotCoerce",
  "42803" => "GroupingError",
  "42P20" => "WindowingError",
  "42P19" => "InvalidRecursion",
  "42830" => "InvalidForeignKey",
  "42602" => "InvalidName",
  "42622" => "NameTooLong",
  "42939" => "ReservedName",
  "42804" => "DatatypeMismatch",
  "42P18" => "IndeterminateDatatype",
  "42P21" => "CollationMismatch",
  "42P22" => "IndeterminateCollation",
  "42809" => "WrongObjectType",
  "42703" => "UndefinedColumn",
  "42883" => "UndefinedFunction",
  "42P01" => "UndefinedTable",
  "42P02" => "UndefinedParameter",
  "42704" => "UndefinedObject",
  "42701" => "DuplicateColumn",
  "42P03" => "DuplicateCursor",
  "42P04" => "DuplicateDatabase",
  "42723" => "DuplicateFunction",
  "42P05" => "DuplicatePreparedStatement",
  "42P06" => "DuplicateSchema",
  "42P07" => "DuplicateTable",
  "42712" => "DuplicateAlias",
  "42710" => "DuplicateObject",
  "42702" => "AmbiguousColumn",
  "42725" => "AmbiguousFunction",
  "42P08" => "AmbiguousParameter",
  "42P09" => "AmbiguousAlias",
  "42P10" => "InvalidColumnReference",
  "42611" => "InvalidColumnDefinition",
  "42P11" => "InvalidCursorDefinition",
  "42P12" => "InvalidDatabaseDefinition",
  "42P13" => "InvalidFunctionDefinition",
  "42P14" => "InvalidPreparedStatementDefinition",
  "42P15" => "InvalidSchemaDefinition",
  "42P16" => "InvalidTableDefinition",
  "42P17" => "InvalidObjectDefinition",
  "44000" => "WithCheckOptionViolation",
  "53000" => "InsufficientResources",
  "53100" => "DiskFull",
  "53200" => "OutOfMemory",
  "53300" => "TooManyConnections",
  "54000" => "ProgramLimitExceeded",
  "54001" => "StatementTooComplex",
  "54011" => "TooManyColumns",
  "54023" => "TooManyArguments",
  "55000" => "ObjectNotInPrerequisiteState",
  "55006" => "ObjectInUse",
  "55P02" => "CantChangeRuntimeParam",
  "55P03" => "LockNotAvailable",
  "57000" => "OperatorIntervention",
  "57014" => "QueryCanceled",
  "57P01" => "AdminShutdown",
  "57P02" => "CrashShutdown",
  "57P03" => "CannotConnectNow",
  "57P04" => "DatabaseDropped",
  "58000" => "SystemError", # added manually
  "58030" => "IoError",
  "58P01" => "UndefinedFile",
  "58P02" => "DuplicateFile",
  "F0000" => "ConfigFileError",
  "F0001" => "LockFileExists",
  "HV000" => "FdwError",
  "HV005" => "FdwColumnNameNotFound",
  "HV002" => "FdwDynamicParameterValueNeeded",
  "HV010" => "FdwFunctionSequenceError",
  "HV021" => "FdwInconsistentDescriptorInformation",
  "HV024" => "FdwInvalidAttributeValue",
  "HV007" => "FdwInvalidColumnName",
  "HV008" => "FdwInvalidColumnNumber",
  "HV004" => "FdwInvalidDataType",
  "HV006" => "FdwInvalidDataTypeDescriptors",
  "HV091" => "FdwInvalidDescriptorFieldIdentifier",
  "HV00B" => "FdwInvalidHandle",
  "HV00C" => "FdwInvalidOptionIndex",
  "HV00D" => "FdwInvalidOptionName",
  "HV090" => "FdwInvalidStringLengthOrBufferLength",
  "HV00A" => "FdwInvalidStringFormat",
  "HV009" => "FdwInvalidUseOfNullPointer",
  "HV014" => "FdwTooManyHandles",
  "HV001" => "FdwOutOfMemory",
  "HV00P" => "FdwNoSchemas",
  "HV00J" => "FdwOptionNameNotFound",
  "HV00K" => "FdwReplyHandle",
  "HV00Q" => "FdwSchemaNotFound",
  "HV00R" => "FdwTableNotFound",
  "HV00L" => "FdwUnableToCreateExecution",
  "HV00M" => "FdwUnableToCreateReply",
  "HV00N" => "FdwUnableToEstablishConnection",
  "P0000" => "PlpgsqlError",
  "P0001" => "RaiseException",
  "P0002" => "NoDataFound",
  "P0003" => "TooManyRows",
  "S1000" => "GeneralError", # added manually
  "XX000" => "InternalError",
  "XX001" => "DataCorrupted",
  "XX002" => "IndexCorrupted",
);

__PACKAGE__->define_exception_classes ( %known_sql_states );

# StackTrace::Auto prevents inlined constructors
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=back

=head1 USAGE PATTERNS

=head2 Using plain DBI

    use DBI;
    use DBIx::Error;
    use TryCatch;

    my $db = DBI->connect ( $dsn, $user, $password,
			    { HandleError => DBIx::Error->HandleError,
			      ShowErrorStatement => 1 } );

    my $sth = $db->prepare ( "INSERT INTO people VALUES ( ? )" );
    try {
      $sth->execute ( $name );
    } catch ( DBIx::Error::UniqueViolation $err ) {
      die "$name is already present in the database";
    } catch ( DBIx::Error::IntegrityConstraintViolation $err ) {
      die "$name is not allowed";
    }

=head2 Using DBIx::Class

    package MyDB::Schema;
    use base qw ( DBIx::Class::Schema );
    use DBIx::Error;
    __PACKAGE__->exception_action ( DBIx::Error->exception_action );
    __PACKAGE__->load_namespaces();

    use MyDB::Schema;
    use TryCatch;
    my $db = MyDB::Schema->connect ( {
	dsn => $dsn,
	user => $user,
	password => $password,
	HandleError => DBIx::Error->HandleError,
	ShowErrorStatment => 1,
	unsafe => 1,
    } );
    try {
      $db->resultset ( "People" )->create ( { name => $name } );
    } catch ( DBIx::Error::UniqueViolation $err ) {
      die "$name is already present in the database";
    } catch ( DBIx::Error::IntegrityConstraintViolation $err ) {
      die "$name is not allowed";
    }

=head2 Using Catalyst::Model::DBIC::Schema

    package MyDB::Schema;
    use base qw ( DBIx::Class::Schema );
    use DBIx::Error;
    __PACKAGE__->exception_action ( DBIx::Error->exception_action );
    __PACKAGE__->load_namespaces();

    package MyApp::Model::MyDB;
    use base qw ( Catalyst::Model::DBIC::Schema );
    use MyDB::Schema;
    use DBIx::Error;
    __PACKAGE__->config (
      schema_class => "MyDB::Schema",
      connect_info => {
	dsn => $dsn,
	user => $user,
	password => $password,
	HandleError => DBIx::Error->HandleError,
	ShowErrorStatment => 1,
	unsafe => 1,
      },
    );

=head1 LIMITATIONS

=head2 Database engines

B<C<DBIx::Error> can produce an exception of the correct subclass only
if the underlying database engine supports SQLSTATE.>  (If the
underlying driver does not support SQLSTATE then all exceptions will
have the class C<DBIx::Error> and the only way to determine what
actually caused the error will be to examine the text of the error
message.)

C<DBIx::Error> is known to work reliably with PostgreSQL databases.

=head2 Bulk operations

Bulk operations using C<< DBI->execute_array() >> may not work as
expected.  The underlying C<DBI> code will not raise an exception
until the entire bulk operation has completed, and the exception will
represent the most recent failure at the time the operation completes.

In most (but not all) cases, this will result in a
C<DBIx::Error::InFailedSqlTransaction> exception, since the
transaction will already have been aborted.  To raise an exception
corresponding to the original error (the one which caused the
transaction to abort), the caller would have to parse the
C<ArrayTupleStatus> array and use C<< DBI->set_err() >> to regenerate
the exception corresponding to the appropriate row.

This limitation also applies to operations built on top of
C<< DBI->execute_array() >>, such as C<< DBIx::Class::Schema->populate() >>.

As a general rule: assume that the only sensible exception class that
can be caught from any bulk operation is the root class C<DBIx::Error>:

    try {
      $sth->execute_array ( @args );
    } catch ( DBIx::Error $err ) {
      # Could be any type of DBI error
    }

=begin comment

This limitation in DBI can be worked around using the following patch:

--- DBI.pm.orig	2012-08-09 22:30:15.209056169 +0100
+++ DBI.pm	2012-08-09 22:30:23.362954232 +0100
@@ -1986,6 +1986,5 @@
 		$err_count++;
 		push @$tuple_status, [ $sth->err, $sth->errstr, $sth->state ];
-                # XXX drivers implementing execute_for_fetch could opt to "last;" here
-                # if they know the error code means no further executes will work.
+		last;
 	    }
 	}

=end comment

=head1 CAVEATS

=head2 C<< DBIx::Class::Schema->txn_do() >>

Any plain errors (i.e. C<< die "some_message"; >> statements) within a
C<txn_do()> block will be converted into C<DBIx::Error::GeneralError>
exceptions:

    try {
      $db->txn_do ( sub {
        die "foo";
      } );
    } catch ( $err ) {
      print "Caught ".( ref $err )." exception with message: ".$err;
    }
    # will print "Caught DBIx::Error::GeneralError exception with message: foo"

To avoid this behaviour, use exception objects instead of plain C<die>:

    try {
      $db->txn_do ( sub {
        My::Error->throw ( "foo" );
      } );
    } catch ( $err ) {
      ...
    }

=head1 SUBCLASSING

Applications can define custom SQLSTATE codes to represent
application-specific database errors.  For example, using PostgreSQL's
PL/pgSQL:

    CREATE FUNCTION test_custom_exception() RETURNS void AS $$
    BEGIN
	RAISE EXCEPTION 'Something bad happened'
	    USING ERRCODE = 'MY001';
    END;
    $$ LANGUAGE plpgsql VOLATILE;

These custom SQLSTATE codes can be mapped to Perl exception classes by
subclassing C<DBIx::Error> and defining the appropriate mappings using
the C<define_exception_classes()> class method.  For example:

    package MyApplication::Error::DBI;

    use Moose;
    extends "DBIx::Error";

    __PACKAGE__->define_exception_classes (
      "MY000" => "General",
      "MY001" => "SomethingBadHappened"
    );

    __PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

    1;

The resulting exception classes will be subclasses of the package
which calls C<define_exception_classes()>.  In the above example, the
exception classes will be:

    C<MyApplication::Error::DBI::General>
    C<MyApplication::Error::DBI::SomethingBadHappened>

The exceptions can be caught in the usual way:

    use TryCatch;
    try {
      ...
    } catch ( MyApplication::Error::DBI::SomethingBadHappened $err ) {
      ...
    } catch ( DBIx::Error::UniqueViolation $err ) {
      ...
    }

Mappings for the generic SQLSTATE codes (ending in "000") act as
superclasses for the more specific SQLSTATE codes (ending in anything
other than "000").  You must define mappings for the generic SQLSTATE
codes corresponding to any application-specific SQLSTATE codes.

By default, the exception classes will be prefixed with the name of
the package which calls C<define_exception_classes()>.  You can
override this by specifying full class names for the exception
subclasses, e.g.

    __PACKAGE__->define_exception_classes (
      "QA000" => "MyApp::Error::General"
    );

=head1 EXCEPTION CLASS HIERARCHY

=over

=item C<DBIx::Error>

=over

=cut

# This method is used to generate the following section of
# documentation.
#
sub _build_pod {
  my $count = 0;
  foreach my $state ( sort keys %known_sql_states ) {
    my $exception_class = __PACKAGE__."::".$known_sql_states{$state};
    print "=back\n\n" if $state =~ /000$/ && $count++;
    print "=item C<".$exception_class."> (C<".$state.">)\n\n";
    print "=over\n\n" if $state =~ /000$/;
  }
  print "=cut\n";
}

#
# BEGIN AUTOGENERATED DOCUMENTATION
#

=item C<DBIx::Error::SqlStatementNotYetComplete> (C<03000>)

=over

=back

=item C<DBIx::Error::ConnectionException> (C<08000>)

=over

=item C<DBIx::Error::SqlclientUnableToEstablishSqlconnection> (C<08001>)

=item C<DBIx::Error::ConnectionDoesNotExist> (C<08003>)

=item C<DBIx::Error::SqlserverRejectedEstablishmentOfSqlconnection> (C<08004>)

=item C<DBIx::Error::ConnectionFailure> (C<08006>)

=item C<DBIx::Error::TransactionResolutionUnknown> (C<08007>)

=item C<DBIx::Error::ProtocolViolation> (C<08P01>)

=back

=item C<DBIx::Error::TriggeredActionException> (C<09000>)

=over

=back

=item C<DBIx::Error::FeatureNotSupported> (C<0A000>)

=over

=back

=item C<DBIx::Error::InvalidTransactionInitiation> (C<0B000>)

=over

=back

=item C<DBIx::Error::LocatorException> (C<0F000>)

=over

=item C<DBIx::Error::InvalidLocatorSpecification> (C<0F001>)

=back

=item C<DBIx::Error::InvalidGrantor> (C<0L000>)

=over

=item C<DBIx::Error::InvalidGrantOperation> (C<0LP01>)

=back

=item C<DBIx::Error::InvalidRoleSpecification> (C<0P000>)

=over

=back

=item C<DBIx::Error::CaseNotFound> (C<20000>)

=over

=back

=item C<DBIx::Error::CardinalityViolation> (C<21000>)

=over

=back

=item C<DBIx::Error::DataException> (C<22000>)

=over

=item C<DBIx::Error::StringDataRightTruncation> (C<22001>)

=item C<DBIx::Error::NullValueNoIndicatorParameter> (C<22002>)

=item C<DBIx::Error::NumericValueOutOfRange> (C<22003>)

=item C<DBIx::Error::NullValueNotAllowed> (C<22004>)

=item C<DBIx::Error::ErrorInAssignment> (C<22005>)

=item C<DBIx::Error::InvalidDatetimeFormat> (C<22007>)

=item C<DBIx::Error::DatetimeFieldOverflow> (C<22008>)

=item C<DBIx::Error::InvalidTimeZoneDisplacementValue> (C<22009>)

=item C<DBIx::Error::EscapeCharacterConflict> (C<2200B>)

=item C<DBIx::Error::InvalidUseOfEscapeCharacter> (C<2200C>)

=item C<DBIx::Error::InvalidEscapeOctet> (C<2200D>)

=item C<DBIx::Error::ZeroLengthCharacterString> (C<2200F>)

=item C<DBIx::Error::MostSpecificTypeMismatch> (C<2200G>)

=item C<DBIx::Error::NotAnXmlDocument> (C<2200L>)

=item C<DBIx::Error::InvalidXmlDocument> (C<2200M>)

=item C<DBIx::Error::InvalidXmlContent> (C<2200N>)

=item C<DBIx::Error::InvalidXmlComment> (C<2200S>)

=item C<DBIx::Error::InvalidXmlProcessingInstruction> (C<2200T>)

=item C<DBIx::Error::InvalidIndicatorParameterValue> (C<22010>)

=item C<DBIx::Error::SubstringError> (C<22011>)

=item C<DBIx::Error::DivisionByZero> (C<22012>)

=item C<DBIx::Error::InvalidArgumentForNtileFunction> (C<22014>)

=item C<DBIx::Error::IntervalFieldOverflow> (C<22015>)

=item C<DBIx::Error::InvalidArgumentForNthValueFunction> (C<22016>)

=item C<DBIx::Error::InvalidCharacterValueForCast> (C<22018>)

=item C<DBIx::Error::InvalidEscapeCharacter> (C<22019>)

=item C<DBIx::Error::InvalidRegularExpression> (C<2201B>)

=item C<DBIx::Error::InvalidArgumentForLogarithm> (C<2201E>)

=item C<DBIx::Error::InvalidArgumentForPowerFunction> (C<2201F>)

=item C<DBIx::Error::InvalidArgumentForWidthBucketFunction> (C<2201G>)

=item C<DBIx::Error::InvalidRowCountInLimitClause> (C<2201W>)

=item C<DBIx::Error::InvalidRowCountInResultOffsetClause> (C<2201X>)

=item C<DBIx::Error::CharacterNotInRepertoire> (C<22021>)

=item C<DBIx::Error::IndicatorOverflow> (C<22022>)

=item C<DBIx::Error::InvalidParameterValue> (C<22023>)

=item C<DBIx::Error::UnterminatedCString> (C<22024>)

=item C<DBIx::Error::InvalidEscapeSequence> (C<22025>)

=item C<DBIx::Error::StringDataLengthMismatch> (C<22026>)

=item C<DBIx::Error::TrimError> (C<22027>)

=item C<DBIx::Error::ArraySubscriptError> (C<2202E>)

=item C<DBIx::Error::FloatingPointException> (C<22P01>)

=item C<DBIx::Error::InvalidTextRepresentation> (C<22P02>)

=item C<DBIx::Error::InvalidBinaryRepresentation> (C<22P03>)

=item C<DBIx::Error::BadCopyFileFormat> (C<22P04>)

=item C<DBIx::Error::UntranslatableCharacter> (C<22P05>)

=item C<DBIx::Error::NonstandardUseOfEscapeCharacter> (C<22P06>)

=back

=item C<DBIx::Error::IntegrityConstraintViolation> (C<23000>)

=over

=item C<DBIx::Error::RestrictViolation> (C<23001>)

=item C<DBIx::Error::NotNullViolation> (C<23502>)

=item C<DBIx::Error::ForeignKeyViolation> (C<23503>)

=item C<DBIx::Error::UniqueViolation> (C<23505>)

=item C<DBIx::Error::CheckViolation> (C<23514>)

=item C<DBIx::Error::ExclusionViolation> (C<23P01>)

=back

=item C<DBIx::Error::InvalidCursorState> (C<24000>)

=over

=back

=item C<DBIx::Error::InvalidTransactionState> (C<25000>)

=over

=item C<DBIx::Error::ActiveSqlTransaction> (C<25001>)

=item C<DBIx::Error::BranchTransactionAlreadyActive> (C<25002>)

=item C<DBIx::Error::InappropriateAccessModeForBranchTransaction> (C<25003>)

=item C<DBIx::Error::InappropriateIsolationLevelForBranchTransaction> (C<25004>)

=item C<DBIx::Error::NoActiveSqlTransactionForBranchTransaction> (C<25005>)

=item C<DBIx::Error::ReadOnlySqlTransaction> (C<25006>)

=item C<DBIx::Error::SchemaAndDataStatementMixingNotSupported> (C<25007>)

=item C<DBIx::Error::HeldCursorRequiresSameIsolationLevel> (C<25008>)

=item C<DBIx::Error::NoActiveSqlTransaction> (C<25P01>)

=item C<DBIx::Error::InFailedSqlTransaction> (C<25P02>)

=back

=item C<DBIx::Error::InvalidSqlStatementName> (C<26000>)

=over

=back

=item C<DBIx::Error::TriggeredDataChangeViolation> (C<27000>)

=over

=back

=item C<DBIx::Error::InvalidAuthorizationSpecification> (C<28000>)

=over

=item C<DBIx::Error::InvalidPassword> (C<28P01>)

=back

=item C<DBIx::Error::DependentPrivilegeDescriptorsStillExist> (C<2B000>)

=over

=item C<DBIx::Error::DependentObjectsStillExist> (C<2BP01>)

=back

=item C<DBIx::Error::InvalidTransactionTermination> (C<2D000>)

=over

=back

=item C<DBIx::Error::SqlRoutineException> (C<2F000>)

=over

=back

=item C<DBIx::Error::InvalidCursorName> (C<34000>)

=over

=back

=item C<DBIx::Error::ExternalRoutineException> (C<38000>)

=over

=back

=item C<DBIx::Error::ExternalRoutineInvocationException> (C<39000>)

=over

=back

=item C<DBIx::Error::SavepointException> (C<3B000>)

=over

=item C<DBIx::Error::InvalidSavepointSpecification> (C<3B001>)

=back

=item C<DBIx::Error::InvalidCatalogName> (C<3D000>)

=over

=back

=item C<DBIx::Error::InvalidSchemaName> (C<3F000>)

=over

=back

=item C<DBIx::Error::TransactionRollback> (C<40000>)

=over

=item C<DBIx::Error::SerializationFailure> (C<40001>)

=item C<DBIx::Error::TransactionIntegrityConstraintViolation> (C<40002>)

=item C<DBIx::Error::StatementCompletionUnknown> (C<40003>)

=item C<DBIx::Error::DeadlockDetected> (C<40P01>)

=back

=item C<DBIx::Error::SyntaxErrorOrAccessRuleViolation> (C<42000>)

=over

=item C<DBIx::Error::InsufficientPrivilege> (C<42501>)

=item C<DBIx::Error::SyntaxError> (C<42601>)

=item C<DBIx::Error::InvalidName> (C<42602>)

=item C<DBIx::Error::InvalidColumnDefinition> (C<42611>)

=item C<DBIx::Error::NameTooLong> (C<42622>)

=item C<DBIx::Error::DuplicateColumn> (C<42701>)

=item C<DBIx::Error::AmbiguousColumn> (C<42702>)

=item C<DBIx::Error::UndefinedColumn> (C<42703>)

=item C<DBIx::Error::UndefinedObject> (C<42704>)

=item C<DBIx::Error::DuplicateObject> (C<42710>)

=item C<DBIx::Error::DuplicateAlias> (C<42712>)

=item C<DBIx::Error::DuplicateFunction> (C<42723>)

=item C<DBIx::Error::AmbiguousFunction> (C<42725>)

=item C<DBIx::Error::GroupingError> (C<42803>)

=item C<DBIx::Error::DatatypeMismatch> (C<42804>)

=item C<DBIx::Error::WrongObjectType> (C<42809>)

=item C<DBIx::Error::InvalidForeignKey> (C<42830>)

=item C<DBIx::Error::CannotCoerce> (C<42846>)

=item C<DBIx::Error::UndefinedFunction> (C<42883>)

=item C<DBIx::Error::ReservedName> (C<42939>)

=item C<DBIx::Error::UndefinedTable> (C<42P01>)

=item C<DBIx::Error::UndefinedParameter> (C<42P02>)

=item C<DBIx::Error::DuplicateCursor> (C<42P03>)

=item C<DBIx::Error::DuplicateDatabase> (C<42P04>)

=item C<DBIx::Error::DuplicatePreparedStatement> (C<42P05>)

=item C<DBIx::Error::DuplicateSchema> (C<42P06>)

=item C<DBIx::Error::DuplicateTable> (C<42P07>)

=item C<DBIx::Error::AmbiguousParameter> (C<42P08>)

=item C<DBIx::Error::AmbiguousAlias> (C<42P09>)

=item C<DBIx::Error::InvalidColumnReference> (C<42P10>)

=item C<DBIx::Error::InvalidCursorDefinition> (C<42P11>)

=item C<DBIx::Error::InvalidDatabaseDefinition> (C<42P12>)

=item C<DBIx::Error::InvalidFunctionDefinition> (C<42P13>)

=item C<DBIx::Error::InvalidPreparedStatementDefinition> (C<42P14>)

=item C<DBIx::Error::InvalidSchemaDefinition> (C<42P15>)

=item C<DBIx::Error::InvalidTableDefinition> (C<42P16>)

=item C<DBIx::Error::InvalidObjectDefinition> (C<42P17>)

=item C<DBIx::Error::IndeterminateDatatype> (C<42P18>)

=item C<DBIx::Error::InvalidRecursion> (C<42P19>)

=item C<DBIx::Error::WindowingError> (C<42P20>)

=item C<DBIx::Error::CollationMismatch> (C<42P21>)

=item C<DBIx::Error::IndeterminateCollation> (C<42P22>)

=back

=item C<DBIx::Error::WithCheckOptionViolation> (C<44000>)

=over

=back

=item C<DBIx::Error::InsufficientResources> (C<53000>)

=over

=item C<DBIx::Error::DiskFull> (C<53100>)

=item C<DBIx::Error::OutOfMemory> (C<53200>)

=item C<DBIx::Error::TooManyConnections> (C<53300>)

=back

=item C<DBIx::Error::ProgramLimitExceeded> (C<54000>)

=over

=item C<DBIx::Error::StatementTooComplex> (C<54001>)

=item C<DBIx::Error::TooManyColumns> (C<54011>)

=item C<DBIx::Error::TooManyArguments> (C<54023>)

=back

=item C<DBIx::Error::ObjectNotInPrerequisiteState> (C<55000>)

=over

=item C<DBIx::Error::ObjectInUse> (C<55006>)

=item C<DBIx::Error::CantChangeRuntimeParam> (C<55P02>)

=item C<DBIx::Error::LockNotAvailable> (C<55P03>)

=back

=item C<DBIx::Error::OperatorIntervention> (C<57000>)

=over

=item C<DBIx::Error::QueryCanceled> (C<57014>)

=item C<DBIx::Error::AdminShutdown> (C<57P01>)

=item C<DBIx::Error::CrashShutdown> (C<57P02>)

=item C<DBIx::Error::CannotConnectNow> (C<57P03>)

=item C<DBIx::Error::DatabaseDropped> (C<57P04>)

=back

=item C<DBIx::Error::SystemError> (C<58000>)

=over

=item C<DBIx::Error::IoError> (C<58030>)

=item C<DBIx::Error::UndefinedFile> (C<58P01>)

=item C<DBIx::Error::DuplicateFile> (C<58P02>)

=back

=item C<DBIx::Error::ConfigFileError> (C<F0000>)

=over

=item C<DBIx::Error::LockFileExists> (C<F0001>)

=back

=item C<DBIx::Error::FdwError> (C<HV000>)

=over

=item C<DBIx::Error::FdwOutOfMemory> (C<HV001>)

=item C<DBIx::Error::FdwDynamicParameterValueNeeded> (C<HV002>)

=item C<DBIx::Error::FdwInvalidDataType> (C<HV004>)

=item C<DBIx::Error::FdwColumnNameNotFound> (C<HV005>)

=item C<DBIx::Error::FdwInvalidDataTypeDescriptors> (C<HV006>)

=item C<DBIx::Error::FdwInvalidColumnName> (C<HV007>)

=item C<DBIx::Error::FdwInvalidColumnNumber> (C<HV008>)

=item C<DBIx::Error::FdwInvalidUseOfNullPointer> (C<HV009>)

=item C<DBIx::Error::FdwInvalidStringFormat> (C<HV00A>)

=item C<DBIx::Error::FdwInvalidHandle> (C<HV00B>)

=item C<DBIx::Error::FdwInvalidOptionIndex> (C<HV00C>)

=item C<DBIx::Error::FdwInvalidOptionName> (C<HV00D>)

=item C<DBIx::Error::FdwOptionNameNotFound> (C<HV00J>)

=item C<DBIx::Error::FdwReplyHandle> (C<HV00K>)

=item C<DBIx::Error::FdwUnableToCreateExecution> (C<HV00L>)

=item C<DBIx::Error::FdwUnableToCreateReply> (C<HV00M>)

=item C<DBIx::Error::FdwUnableToEstablishConnection> (C<HV00N>)

=item C<DBIx::Error::FdwNoSchemas> (C<HV00P>)

=item C<DBIx::Error::FdwSchemaNotFound> (C<HV00Q>)

=item C<DBIx::Error::FdwTableNotFound> (C<HV00R>)

=item C<DBIx::Error::FdwFunctionSequenceError> (C<HV010>)

=item C<DBIx::Error::FdwTooManyHandles> (C<HV014>)

=item C<DBIx::Error::FdwInconsistentDescriptorInformation> (C<HV021>)

=item C<DBIx::Error::FdwInvalidAttributeValue> (C<HV024>)

=item C<DBIx::Error::FdwInvalidStringLengthOrBufferLength> (C<HV090>)

=item C<DBIx::Error::FdwInvalidDescriptorFieldIdentifier> (C<HV091>)

=back

=item C<DBIx::Error::PlpgsqlError> (C<P0000>)

=over

=item C<DBIx::Error::RaiseException> (C<P0001>)

=item C<DBIx::Error::NoDataFound> (C<P0002>)

=item C<DBIx::Error::TooManyRows> (C<P0003>)

=back

=item C<DBIx::Error::GeneralError> (C<S1000>)

=item C<DBIx::Error::InternalError> (C<XX000>)

=over

=item C<DBIx::Error::DataCorrupted> (C<XX001>)

=item C<DBIx::Error::IndexCorrupted> (C<XX002>)

=cut

#
# END AUTOGENERATED DOCUMENTATION
#

=back

=back

=back

=head1 AUTHOR

Michael Brown <mbrown@fensystems.co.uk>

=cut

1;
