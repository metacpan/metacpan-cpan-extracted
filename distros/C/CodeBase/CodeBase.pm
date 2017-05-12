# CodeBase module for Perl 5
# Written by: Andrew Ford <andrew@icarus.demon.co.uk>
# $Id: CodeBase.pm,v 1.5 1999/08/10 09:46:39 andrew Exp $

package CodeBase;
$CodeBase::VERSION = '0.86';

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw();


bootstrap CodeBase $VERSION;

# CodeBase error codes
# For detailed explanations refer to the "CodeBase Reference Guide" 
# by Sequiter Software Inc.

# General disk access errors

$CodeBase::e4close              =  -10;         # Closing file
$CodeBase::e4create             =  -20;         # Creating file
$CodeBase::e4len                =  -30;         # Determining file length
$CodeBase::e4len_set            =  -40;         # Setting file length
$CodeBase::e4lock               =  -50;         # Locking file
$CodeBase::e4open               =  -60;         # Opening file
$CodeBase::e4read               =  -70;         # Reading file
$CodeBase::e4remove             =  -80;         # Removing file
$CodeBase::e4rename             =  -90;         # Renaming file
$CodeBase::e4seek               = -100;         # Seeking to a file position
$CodeBase::e4unlock             = -110;         # Unlocking file
$CodeBase::e4write              = -120;         # Writing to file


# Data file specific errors

$CodeBase::e4data               = -200;         # File is not a data file
$CodeBase::e4field_name         = -210;         # Unrecognized field name
$CodeBase::e4field_type         = -220;         # Unrecognized field type
$CodeBase::e4record_len         = -230;         # Record length too large


# Index file specific errors

$CodeBase::e4entry              = -300;         # Tag entry missing
$CodeBase::e4index              = -310;         # Not a correct index file
$CodeBase::e4tag_name           = -330;         # Tag name not found
$CodeBase::e4unique             = -340;         # Unique key error


# Expression evaluation errors

$CodeBase::e4comma_expected     = -400;         # Comma or bracket expected
$CodeBase::e4complete           = -410;         # Expression not complete
$CodeBase::e4data_name          = -420;         # Data file name not located
$CodeBase::e4length_err         = -422;         # IIF() needs parameters of same length
$CodeBase::e4not_constant       = -425;         # SUBSTR() and STR() need constant parameters
$CodeBase::e4num_params         = -430;         # Number of parameters is wrong
$CodeBase::e4overflow           = -440;         # Overflow while evaluating expression
$CodeBase::e4right_missing      = -450;         # Right bracket missing
$CodeBase::e4type_sub           = -460;         # Sub-expression type is wrong
$CodeBase::e4unrec_function     = -470;         # Unrecognized function
$CodeBase::e4unrec_operator     = -480;         # Unrecognized operator
$CodeBase::e4unrec_value        = -490;         # Unrecognized value
$CodeBase::e4unterminated       = -500;         # Unterminated string


# Optimization errors

$CodeBase::e4opt                = -610;         # Optimization error
$CodeBase::e4opt_suspend        = -620;         # Optimization removal error
$CodeBase::e4opt_flush          = -630;         # Optimization file flushing failure


# Relation errors

$CodeBase::e4relate             = -710;         # Relation error
$CodeBase::e4lookup_err         = -720;         # Matching slave record not located


# Severe errors

$CodeBase::e4info               = -910;         # Unexpected information
$CodeBase::e4memory             = -920;         # Out of memory
$CodeBase::e4parm               = -930;         # Unexpected parameter
$CodeBase::e4result             = -950;         # Unexpected result


#package CodeBase::errno;
# sub TIESCALAR {
#     my $type = shift;
#     my $x;
#     bless \$x, $type;
# }
# package CodeBase;
#tie($CodeBase::errno, 'CodeBase::errno');




package CodeBase::FilePtr;

use vars qw(@ISA);
@ISA = qw(CodeBase::RecordPtr);


# Autoload methods go after =cut, and are processed by the autosplit program.



################################################################################
################################################################################

=head1 NAME

CodeBase - Perl module for accessing dBASE files


=head1 ABSTRACT

The CodeBase module provides a Perl 5 class for accessing dBASE files.
It is a development of an earlier unpublished Perl 4 extension.


=head1 SYNOPSIS

Programs using the CodeBase module must include the line:

    use CodeBase;

The functions that the module provides are listed below, grouped
according to type of function.


=head2 File manipulation functions

    $fh = CodeBase::open($filename, @options);
    $fh = CodeBase::create($filename, @fielddefs);
    $fh->DESTROY();

=head2 File information functions

    $n_recs    = $fh->reccount();
    $recsize   = $fh->recsize();
    $n_fields  = $fh->fldcount();
    @names     = $fh->names();
    $type      = $fh->type($fieldname);
    @fieldinfo = $fh->fieldinfo();

=head2 Navigation functions

    $recno = $fh->recno();
    $fh->goto($recno);
    $fh->skip($n_recs);
    $fh->bof();
    $fh->eof();

=head2 Record manipulation functions

    @values = $fh->fields();
    $value  = $fh->field($fieldname);
    $fh->set_field($fieldname, $value);
    $fh->new_record(@values);
    $fh->replace_record(@values);

    $fh->deleted();
    $fh->delete_record($recno);

    $fh->flush($tries);
    $fh->pack($compress_memo);

    $fh->lock($what, $tries);
    $fh->unlock();


=head2 Index manipulation functions

    $n_tags  = $fh->tag_count();
    @tags    = $fh->tags();
    @taginfo = $fh->taginfo($index_name);
    $fh->open_index($name);
    $fh->create_index($name, $taginfo);
    $fh->reindex();
    $fh->set_tag();
    $fh->seek($key);

    $q = $fh->prepare_query($expr [, $sortexpr [, $desc]]);
    $q->execute;
    $q->next([$skip]);


=head2 Miscellaneous functions

    CodeBase::option(@options);
    $errno   = CodeBase::errno();
    $errmsg  = CodeBase::errmsg($errno);
    $version = CodeBase::libversion;
    $dbtype  = CodeBase::dbtype;


=head1 DESCRIPTION

Each function provided by the CodeBase module is described below.  The
module uses the CodeBase library from Sequiter Software Inc., which
is a C library providing database management functions for dBASE
files.


=head2 File manipulation functions

Existing dBASE files can be opened with C<open()> and new files
created with C<create()>.  Files are implicit closed by the C<DESTROY>
method, which is called when all references to the internal file
handle go out of scope.


=over 4

=item open FILENAME [, OPTION-KEYWORD ...]

Opens the named dBASE file and returns a file handle which can be used
in other CodeBase functions.  The filename should omit the C<.dbf>
extension.  The following options keywords are recognized:
C<"readonly">, C<"noindex"> or C<"exclusive"> (C<"ro"> is a synonym
for C<"readonly"> and C<"x"> is a synonym for C<"exclusive">).  Option
keywords are case-insensitive.  For example to open the file
C<books.dbf> in read-only mode, without opening the production index:

    $fh = CodeBase::open("books", "readonly", "noindex");


=item create FILENAME, FIELD-DEFS
=item create FILENAME, FIELD-DEF-ARRAY, INDEX-TAG

Creates a new dBASE file using the field definitions specified and
returns a file that can be used in other CodeBase functions.  The
field definitions consist of an array of alternating pairs of field
name and field type.

    @field_defs = ( "F1" => "C10",
                    "F2" => "N4" );
    $fh = CodeBase::create("test", @field_defs);

The field types are as follows:

    Type       Code      Length    Decimals
    -------------------------------------------
    Character    C     1 to 65533     0
    Date         D     8              0
    F.P.         F     1 to 19     0 to len - 2
    Logical      L     1              0
    Memo         M     10             0
    Numeric      N     1 to 19     0 to len - 2

Note: C<create> does not create a production index file -- use
C<create_index> with an empty filename.  The facility to create a
production index at the same time that a database is created may be
added later.  Field and tag information arguments would then be
specified as references.


=item DESTROY FILEHANDLE

The DESTROY function is not normally called explicitly.  It is invoked
automatically when all copies of the file handle generated by C<open()>
or C<create()> go out of scope.  For example:

    {
        my($fh2);
        {
            $fh1 = CodeBase::open("test");
            $fh2 = $fh1;
        }
        # $fh1 is destroyed here, but $fh2 contains a copy of the file
        # handle so CodeBase::DESTROY is not called yet.
   }
   # $fh2 is destroyed as it goes out of scope, so CodeBase::DESTROY
   # is invoked. 

=back


=head2 Navigation functions

=over 4

=item recno

Returns the current record number.  It is equivalent to the dBASE
C<RECNO()> function.

    $recno = $fh->recno

If the file has just been opened, created or packed there is no
current record number and C<recno()> will return C<undef>.


=item goto RECNO

Positions the current record of the database file to the specified
record.  It is equivalent to the dBASE C<GOTO> statement.

    $fh->goto($recno);

The record number for C<CodeBase::goto> should be an integer between 1
and C<CodeBase::reccount>.  It can also take one of the keywords:
C<"TOP"> or C<"BOTTOM">.  The keywords C<"START"> and C<"FIRST"> are
accepted as synonyms for C<"TOP">, and C<"END"> and C<"LAST"> as
synonyms for C<"BOTTOM">.  Only the first character of a keyword is
significant and case is not significant.

Normally C<goto> returns 1 to signify success; if an error occurs it
returns C<undef>.  The error code can then be retrieved with C<errno>.


=item skip N_RECORDS

Skips forwards or backwards in the database file by the specified
number of fields.  It is equivalent to the dBASE C<SKIP>
statement.  The number of fields defaults to one.

    $fh->skip($n_records);

Normally C<skip> returns the new record number; if an error occurs it
returns C<undef>.  The error code can then be retrieved with C<errno>.

=item bof

Returns a boolean value indicating whether the current record is positioned
before the first record.  It is equivalent to the dBASE C<BOF()> function.

    if ($fh->bof()) ...

=item eof

Returns a boolean value indicating whether the current record is positioned
at the end of the file.  It is equivalent to the dBASE C<EOF()> function.

    while (!$fh->eof()) ...


=back


=head2 Record handling functions

=over 4

=item reccount

Returns the number of records in the database file.
It is equivalent to the dBASE C<RECCOUNT()> function.

    $n_recs = $fh->reccount();


=item recsize

Returns the size in bytes of records in the database file (including
the deletion flag).  It is equivalent to the dBASE C<RECWIDTH()>
function.

    $recsize = $fh->recsize();


=item fldcount

Returns the number of fields per record for the database file.

    $n_fields = $fh->fldcount();

It is equivalent to the dBASE C<FLDCOUNT()> function.


=item names

Returns the field names as an array.

    @names = $fh->names();


=item type FIELD

Returns the type of the named field as a string.

    $type = $fh->type("field1");


=item fieldinfo [NAMES]

Returns an array containing information about the specified fields or
about all fields if no fields are specified.  For example if the
database open on C<$fh> contains, amongst others, the fields C<field1>
and C<field2> as a 12 character field and a 10 byte numeric field with
3 decimal places respectively then:
 
    @names = ("field1, "field2");
    $fh->fieldinfo(@names);

would return an array containing the values: 

    ("field1", "C12", "field2", "N10.3")

This is a shortcut function.  The same information can be built up by
using C<names> and C<type>:

    foreach $name ($fh->names)
    {
        push(@results, ($name, $fh->type($name)));
    }


=item values [NAMES]

Returns an array containing the values of each of the specified fields, or
of all fields if no field names are specified.

    @values = $fh->values("field1", "field3");


=item field NAME

Returns the value of the named field.

    $value = $fh->field("field1");


=item set_field NAME, VALUE

Sets the value of the named field to the specified value.

    $fh->set_field("field1", $value);

If the field is a date field the value should be formatted in dBASE
date format (e.g. C<"YYYYMMDD">) or should be one of the keywords
C<"YESTERDAY">, C<"TODAY"> or C<"TOMORROW"> (the keywords are not case
sensitive) or may be a number of days to the current date specified as
C<+num> or C<-num>.  For example to set a date field to a week's time:

    $fh->set_field("date", "+7");


=item new_record VALUES

Creates a new record using the values specified.  C<VALUES> may be an
array of field values:

    $fh->new_record({ firstname => "Fred",
                      surname   => "Bloggs"  });

or a reference to a hash, the keys of which are
the field names:

    $fh->new_record("Bloggs", "Fred");

If the values are supplied as an array, a value must be supplied for
each field.  If the values are supplied as a hash unspecified fields
are filled with blanks.  Excess array values or hash keys that are not
names of fields are simply ignored.  The handling of date fields is as
described under C<set_field>.


=item replace_record VALUES

Replaces the fields of the current record with the values specified.
As with C<new_record> C<VALUES> may be an array of field values:

    $fh->replace_record("Bloggs", "Fred");

or a reference to a hash, the keys of which are the field names.

    $fh->replace_record({ firstname => "Fred",
                          surname   => "Bloggs"  });

In the former case a value must be supplied for each field, while in
the latter case unspecified fields are unchanged.  Excess values or
hash keys that are not names of fields are ignored.  The handling of
date fields is as described under C<set_field>.


=item deleted

Returns a boolean value indicating whether the current record is
deleted.

    if ($fh->deleted()) ...

This function is equivalent to the dBASE C<DELETED()> function.


=item delete_record [RECNO]

Deletes the record specified or the current record if called without a record number.

    $fh->delete_record($recno);


=item recall_record [RECNO]

Recalls the record specified or the current record if called without a
record number.  (Not yet implemented).


=item flush [TRIES]

Flushes to file any outstanding changes (made by C<set_field()>.
Records need to be locked while changes are written.  C<TRIES> is the
number of attempts that should be made to aquire the lock.  Subsequent
attempts are made with a one second interval.


=item pack COMPRESS-MEMO-FLAG

Packs the database file removing deleted records.  If flag parameter
is specified as true then memo fields are compressed at the same time:

    $fh->pack(1);


=item lock WHAT [, TRIES]

Locks the specified record or the whole file.  C<WHAT> should either
be C<"FILE"> or a record number (the current record can be referred to
as C<".">.  C<TRIES> is the number of attempts that should be made to
aquire the lock.  Subsequent attempts are made with a one second
interval.

=item unlock

Removes any existing locks on the file.


=back

=head2 Index Handling Functions

A production index file is automatically opened when a database file
is opened, if it exists unless  the C<noindex> option is specified.
An index file can be opened with the C<open_index> method.

=over 4

=item tagcount

Returns the number of index tags.

    $n_tags = $fh->tagcount();


=item tags

Returns an array containing the names of all the tags associated with
the database file.

    @tags = $fh->tags();


=item set_tag TAG

Sets the current index tag to the named tag.  If no tag is specified
the currently selected tag is deselected.

    $fh->set_tag("TAG1") || die "Cannot set index tag.\n";


=item taginfo

Returns an array containing information about tags.  Each element of
the array is a reference to a hash containing attributes of the tag.
The attributes are C<name>, C<expression>, C<filter>, C<order> and
C<duplicates>.

This array is suitable for passing to C<create_index>, for example for
copying the index structure of a file:

    @taginfo = $fh1->taginfo;
    $fh2->create_index(undef, \@taginfo); 


=item create_index NAME, TAGINFO

Creates a new index file.  The index file name is specified by C<NAME>
and should not include the C<.mdx> extension.  If C<NAME> is specified
as C<undef> or C<""> a production index is created.

The new index file will contain the tags specified in the C<TAGINFO>
argument: an array passed by reference, each element of which is a
hash containing attributes of the particular tag.  Valid attributes
are: C<name>, C<expression>, C<filter>, C<duplicates> and C<order>.

For example to create a production index with three tags:

    $fh->create_index( undef,
                       [ { name       => "TAG1",
                           expression => "F1",
                           duplicates => "KEEP" },
                         { name       => "TAG2",
                           expression => "F2",
                           order      => "DESCENDING" },
                         { name       => "TAG3",
                           expression => "UPPER(F3)" }
                       ] );

=item open_index [ NAME ]

Opens the specified index file.  The name should not include the
C<.mdx> extension.  If the name is not specified then the production
index is opened.


=item seek VALUE

Seeks in the currently selected index tag for a match for the
specified value.  Returns 1 if a match is found otherwise the
undefined value is returned and the error code can be retrieved with
C<CodeBase::errno>.  

The search value must be formatted correctly for the index, for
example if an index is generted on C<STR(F1)>, where C<F1> is a
numeric field of width 6, the value be formatted as a right aligned
6-character integer:

    $fh->seek("    42");

For string valued index keys a search value shorter than the tag
expression length will be matched on the initial substring,
e.g. C<"FRED"> would match C<"FREDERICK">.

=back


=head2 Query functions

The query functions interface to the CodeBase Relate/Query module.
The interface is currently incomplete.  All that is provided is the
facility to query a single file.  

A query is prepared (in a similar manner to the Perl DBI query) and
then executed and the result set stepped through.  The functions are:

    $q = $fh->prepare_query($expr [, $sortexpr [, $desc]]);
    $q->execute;
    $q->next([$skip]);

An example of the usage would be:

    $q = $fh->prepare_query('AGE >= 18 .AND. AGE <= 65', 'AGE', 1);
    $q->execute;
    while (my $r = $q->next) {
        @fields = $r->values;
        # do some processing.
    }

I intend to allow more complex queries to be built up in a Perl-ish
manner, but I haven't come up with an interface yet.


=head2 Miscellaneous functions

=over 4

=item CodeBase::option OPTIONS

Sets configuration options for the CodeBase module.  The only option
currently offered is C<trace>.  Setting this to a non-zero value
enables the output of tracing, which can be helpful in debugging.

    # Enable tracing
    CodeBase::option("trace=1");

    # Disable tracing
    CodeBase::option("trace=0");


=item CodeBase::errno

Returns the error code for the last operation.


=item CodeBase::errmsg ERRNO

Returns an explanatory string for the error code C<ERRNO>

=item CodeBase::libversion

Returns the version of the CodeBase library that the module was
compiled and linked against.

=item CodeBase::dbformat

Returns the XBase file format that the library and module were
compiled for.  This will be one of "dBASE IV", "FoxPro" or "Clipper".


=back


=head1 ERRORS

Functions return a value on success and C<undef> on error.  The error
code can be determined by calling C<CodeBase::errno>, and the
equivalent error message by calling C<CodeBase::errmsg>.

A number of variables are defined as symbolic names for the CodeBase
error codes.  Thes variables are all defined in the C<CodeBase>
package and so need to be referred with the package prefix
(e.g. C<$CodeBase::e4close>).

B<General disk access errors>

    $e4close          =  -10;  # Closing file
    $e4create         =  -20;  # Creating file
    $e4len            =  -30;  # Determining file length
    $e4len_set        =  -40;  # Setting file length
    $e4lock           =  -50;  # Locking file
    $e4open           =  -60;  # Opening file
    $e4read           =  -70;  # Reading file
    $e4remove         =  -80;  # Removing file
    $e4rename         =  -90;  # Renaming file
    $e4seek           = -100;  # Seeking to a file position
    $e4unlock         = -110;  # Unlocking file
    $e4write          = -120;  # Writing to file

B<Data file specific errors>

    $e4data           = -200;  # File is not a data file
    $e4field_name     = -210;  # Unrecognized field name
    $e4field_type     = -220;  # Unrecognized field type
    $e4record_len     = -230;  # Record length too large

B<Index file specific errors>

    $e4entry          = -300;  # Tag entry missing
    $e4index          = -310;  # Not a correct index file
    $e4tag_name       = -330;  # Tag name not found
    $e4unique         = -340;  # Unique key error

B<Expression evaluation errors>

    $e4comma_expected = -400;  # Comma or bracket expected
    $e4complete       = -410;  # Expression not complete
    $e4data_name      = -420;  # Data file name not located
    $e4length_err     = -422;  # IIF() needs parameters of same length
    $e4not_constant   = -425;  # SUBSTR() and STR() need constant parameters
    $e4num_params     = -430;  # Number of parameters is wrong
    $e4overflow       = -440;  # Overflow while evaluating expression
    $e4right_missing  = -450;  # Right bracket missing
    $e4type_sub       = -460;  # Sub-expression type is wrong
    $e4unrec_function = -470;  # Unrecognized function
    $e4unrec_operator = -480;  # Unrecognized operator
    $e4unrec_value    = -490;  # Unrecognized value
    $e4unterminated   = -500;  # Unterminated string

B<Optimization errors>

    $e4opt            = -610;  # Optimization error
    $e4opt_suspend    = -620;  # Optimization removal error
    $e4opt_flush      = -630;  # Optimization file flushing failure

B<Relation errors> (not used)

    $e4relate         = -710;  # Relation error
    $e4lookup_err     = -720;  # Matching slave record not located

B<Severe errors>

    $e4info           = -910;  # Unexpected information
    $e4memory         = -920;  # Out of memory
    $e4parm           = -930;  # Unexpected parameter
    $e4result         = -950;  # Unexpected result

For detailed explanations of these codes refer to the I<CodeBase
Reference Guide> by Sequiter Software Inc.

=head1 RESTRICTIONS

Tags cannot be added to existing index files -- the entire index file
must be recreated.  This is a restriction imposed by CodeBase 5.1.



=head1 FUTURE DIRECTIONS

Record fields may be made into an associative array allowing their
values to be accessed and set with the following syntax:

    $val = $file->{"F1"};       
    # rather than:  $val = $file->value("F1");

    $file->{"F1"} = $newval;
    # rather than:  $file->set_value("F1", $newval);

The query functionality will be expanded.


=head1 COMPATIBILTY


=head2 CodeBase Functions

   CodeBase 6.4        CodeBase 5.1         CodeBase.pm
   ============        ============         ===========

   code4calcCreate     expr4calc_create
   code4calcReset      expr4calc_reset
   code4close          d4close_all	    implicit on exit
   code4connect
   code4data           d4data
   code4dateFormat
   code4dateFormatSet
   code4exit           e4exit
   code4flush          d4flush_files
   code4indexExtension
   code4init           d4init
   code4initUndo       d4init_undo
   code4lock
   code4lockClear
   code4lockFileName
   code4lockItem
   code4lockNetworkId
   code4lockUserId
   code4logCreate
   code4logFileName
   code4logOpen
   code4logOpenOff
   code4optAll
   code4optStart       d4opt_start
   code4optSuspend     d4opt_suspend
   code4timeout
   code4timeoutSet
   code4tranCommit
   code4tranRollback
   code4tranStart
   code4tranStatus
   code4unlock         d4unlock_files
   code4unlockAuto
   code4unlockAutoSet


=head2 Data File Functions

   CodeBase 6.4        CodeBase 5.1         CodeBase.pm
   ============        ============         ===========

   d4alias             d4alias
   d4aliasSet          d4alias_set
   d4append
   d4appendBlank       d4append_blank
   d4appendStart       d4append_start
   d4blank
   d4bottom
   d4changed
   d4check
   d4close             d4close              undef $fh
   d4create
   d4delete
   d4deleted
   d4eof
   d4field
   d4fieldInfo         d4field_info
   d4fieldJ            d4field_j
   d4fieldNumber       d4field_number
   d4fileName
   d4flush             d4flush               $fh->flush
   d4flushData         d4flush_data
   d4freeBlocks        d4free_blocks
   d4go                d4go                  $fh->go
   d4goBof             d4go_bof
   d4goData            d4go_data
   d4goEof             d4go_eof
   d4index
   d4lock
   d4lockAdd
   d4lockAddAll
   d4lockAddAppend
   d4lockAddFile
   d4lockAll           d4lock_all
   d4lockAppend        d4lock_append
   d4lockFile          d4lock_file		$fh->lock('FILE')
   d4lockIndex         d4lock_index
   d4lockTest          d4lock_test
   d4lockTestAppend    d4lock_test_append
   d4lockTestFile      d4lock_test_file
   d4log
   d4logStatus
   d4memoCompress      d4memo_compress
   d4numFields         d4num_fields		$fh->fldcount
   d4open              d4open                   $fh = CodeBase::open($file ...)
   d4openClone
   d4optimize
   d4optimizeWrite     d4optimize_write
   d4pack              d4pack
   d4packData          d4pack_data
   d4position          d4position
   d4positionSet       d4position_set
   d4recall            d4recall
   d4recCount          d4reccount
   d4recNo             d4recno			$fh->recno
   d4record
   d4recPosition       d4record_position
   d4recWidth          d4record_width		$fh->recsize
   d4refresh           d4refresh                $fh->refresh
   d4refreshRecord     d4refresh_record
   d4reindex           d4reindex
   d4remove
   d4seek              d4seek                   $fh->seek
   d4seekDouble        d4seek_double
   d4seekN             d4seek_n
   d4seekNext
   d4seekNextDouble
   d4seekNextN
   d4skip              d4skip                   $fh->skip
   d4tag               d4tag
   d4tagDefault        d4tag_default
   d4tagNext           d4tag_next
   d4tagPrev           d4tag_prev
   d4tagSelect         d4tag_select
   d4tagSelected       d4tag_selected
   d4tagSync
   d4top               d4top
   d4unlock            d4unlock
   d4write             d4write
   d4writeData         d4write_data
   d4writeKeys         d4write_keys
   d4zapData           d4zap_data

=head2 Date Functions

   date4formatMdx      date4format_mdx
   date4formatMdx2     date4format_mdx2
   date4timeNow        date4time_now

   dfile4updateHeader  d4update_header
   e4exitTest          e4exit_test
   error4code          e4code
   error4set           e4set

   expr4calcDelete     expr4calc_delete
   expr4calcLookup     expr4calc_lookup
   expr4calcMassage    expr4calc_massage
   expr4calcModify     expr4calc_modify
   expr4calcNameChange expr4calc_name_change
   expr4keyConvert     expr4key_convert
   expr4keyLen         expr4key_len

=head2 Field Functions

   f4assignChar        f4assign_char		$fh->field_set($name, $value)
   f4assignDouble      f4assign_double
   f4assignField       f4assign_field
   f4assignInt         f4assign_int
   f4assignLong        f4assign_long
   f4assignN           f4assign_n
   f4assignPtr         f4assign_ptr
   f4memoAssign        f4memo_assign
   f4memoAssignN       f4memo_assign_n
   f4memoFree          f4memo_free
   f4memoLen           f4memo_len
   f4memoNcpy          f4memo_ncpy
   f4memoPtr           f4memo_ptr
   f4memoSetLen        f4memo_set_len
   f4memoStr           f4memo_str

   file4lenSet         file4len_set
   file4lockHook       file4lock_hook
   file4optimizeWrite  file4optimize_write
   file4readAll        file4read_all
   file4readError      file4read_error
   file4seqRead        file4seq_read
   file4seqReadAll     file4seq_read_all
   file4seqReadInit    file4seq_read_init
   file4seqWrite       file4seq_write
   file4seqWriteFlush  file4seq_write_flush
   file4seqWriteInit   file4seq_write_init
   file4seqWriteRepeat file4seq_write_repeat

   i4tagAdd            i4add_tag
   i4tagInfo           i4tag_info


   relate4createSlave  relate4create_slave
   relate4doAll        relate4do
   relate4doOne        relate4do_one
   relate4errorAction  relate4error_action
   relate4freeRelate   relate4free_relate
   relate4matchLen     relate4match_len
   relate4querySet     relate4query_set
   relate4skipEnable   relate4skip_enable
   relate4sortSet      relate4sort_set


   t4addCalc           t4add_calc
   t4uniqueSet         t4unique_set

   tfile4add           t4add(a)->tagFile, b, c
   tfile4block         t4block(a)->tagFile
   tfile4bottom        t4bottom( (a)->tagFile
   tfile4down          t4down( (a)->tagFile
   tfile4dskip         t4dskip(a)->tagFile, b
   tfile4dump          t4dump(a)->tagFile, b, c
   tfile4eof           t4eof(a)->tagFile
   tfile4flush         t4flush(a)->tagFile
   tfile4freeAll       t4free_all(a)->tagFile
   tfile4go            t4go(a)->tagFile, b, c, 0
   tfile4isDescending  t4is_descending(a)->tagFile
   tfile4key           t4key(a)->tagFile
   tfile4position      t4position(a)->tagFile
   tfile4positionSet   t4position_set(a)->tagFile, b
   tfile4recNo         t4recno(a)->tagFile
   tfile4remove        t4remove(a)->tagFile, b, c
   tfile4removeCalc    t4remove_calc(a)->tagFile, b
   tfile4seek          t4seek(a)->tagFile, b, c
   tfile4skip          t4skip(a)->tagFile, b
   tfile4top           t4top(a)->tagFile
   tfile4up            t4up(a)->tagFile
   tfile4upToRoot      t4up_to_root(a)->tagFile


=head2 Unsupported functions

Many lower level functions are not directly accessible from
CodeBase.pm.  These include:

=over

=item *

conversion functions (c4xxx)

=item *

linked list functions (l4xxx)

=item *

memory functions (m4xxx)

=item *

sort functions (sort4xxx)

=item *

utility functions (u4xxx)

=back



=head1 COPYRIGHT AND TRADEMARKS

The CodeBase module is Copyright (C) 1996-1999, Andrew Ford and Ford &
Mason Ltd.  All rights reserved.  The CodeBase library is copyright
Sequiter Software, Inc.

CodeBase is a trademark of Sequiter Software, Inc.

=head1 AUTHOR

Andrew Ford (andrew@icarus.demon.co.uk)

=head1 SEE ALSO

The Perl reference manual, especially the following sections: 
I<perlmod> (modules),  
I<perldata> (data types),
I<perlobj> (objects),
I<perlref> (references and nested data structures),
I<perldsc> (data structures cookbook), 
I<perllol> (manipulating lists of lists).

The second edition of I<Programming Perl> by Larry Wall and Randal
L. Schwarz (O'Reilly and Associates) covers Perl 5.

The I<CodeBase Reference Guide> and the I<CodeBase User Guide>, both
from Sequiter Software Inc. cover the underlying C library.


=cut

# Preloaded methods go here.



1;
__END__
