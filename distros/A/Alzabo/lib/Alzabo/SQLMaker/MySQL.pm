package Alzabo::SQLMaker::MySQL;

use strict;
use vars qw($VERSION $AUTOLOAD @EXPORT_OK %EXPORT_TAGS);

use Alzabo::Exceptions;
use Alzabo::Utils;

use Alzabo::SQLMaker;
use base qw(Alzabo::SQLMaker);

$VERSION = 2.0;

my $MADE_FUNCTIONS;

sub import
{
    _make_functions() unless $MADE_FUNCTIONS;

    # used to export function functions
    require Exporter;
    *_import = \&Exporter::import;

    goto &_import;
}

sub _make_functions
{
    local *make_function = \&Alzabo::SQLMaker::make_function;

    foreach ( [ PI => [ 'math' ] ],

	      [ CURDATE => [ 'datetime' ] ],
	      [ CURRENT_DATE => [ 'datetime' ] ],
	      [ CURTIME => [ 'datetime' ] ],
	      [ CURRENT_TIME => [ 'datetime' ] ],
	      [ NOW => [ 'datetime', 'common' ] ],
	      [ SYSDATE => [ 'datetime' ] ],
	      [ CURRENT_TIMESTAMP => [ 'datetime' ] ],

	      [ DATABASE => [ 'system' ] ],
	      [ USER => [ 'system' ] ],
	      [ SYSTEM_USER => [ 'system' ] ],
	      [ SESSION_USER => [ 'system' ] ],
	      [ VERSION => [ 'system' ] ],
	      [ CONNECTION_ID => [ 'system' ] ],
	    )
    {
	make_function( function => $_->[0],
                       min => 0,
                       max => 0,
                       groups => $_->[1]
                     );
    }

    foreach ( [ RAND => [ 'math' ] ],
	      [ UNIX_TIMESTAMP => [ 'datetime' ] ],
	      [ LAST_INSERT_ID => [ 'system' ] ],
	    )
    {
	make_function( function => $_->[0],
                       min => 0,
                       max => 1,
                       quote => [0],
                       groups => $_->[1]
                     );
    }

    make_function( function => 'CHAR',
		   min => 1,
		   max => undef,
		   quote => [0],
		   groups => [ 'string' ],
		 );

    foreach ( [ ENCRYPT => [1,1], [ 'misc' ] ] )
    {
	make_function( function => $_->[0],
                       min => 0,
                       max => 1,
                       quote => $_->[1],
                       groups => $_->[2],
                     );
    }

    foreach ( [ MOD => [0,0], [ 'math' ] ],
	      [ ROUND => [0,0], [ 'math' ] ],
	      [ POW => [0,0], [ 'math' ] ],
	      [ POWER => [0,0], [ 'math' ] ],
	      [ ATAN2 => [0,0], [ 'math' ] ],

	      [ POSITION => [1,1], [ 'string' ] ],
	      [ INSTR => [1,1], [ 'string' ] ],
	      [ LEFT => [1,1], [ 'string' ] ],
	      [ RIGHT => [1,1], [ 'string' ] ],
	      [ FIND_IN_SET => [1,1], [ 'string' ] ],
	      [ REPEAT => [1,0], [ 'string' ] ],

	      [ ENCODE => [1,1], [ 'misc' ] ],
	      [ DECODE => [1,1], [ 'misc' ] ],
	      [ FORMAT => [0,0], [ 'misc' ] ],

	      [ PERIOD_ADD => [0,0], [ 'datetime' ] ],
	      [ PERIOD_DIFF => [0,0], [ 'datetime' ] ],
	      [ DATE_ADD => [1,0], [ 'datetime' ] ],
	      [ DATE_SUB => [1,0] , [ 'datetime' ]],
	      [ ADDDATE => [1,0], [ 'datetime' ] ],
	      [ SUBDATE => [1,0], [ 'datetime' ] ],
	      [ DATE_FORMAT => [1,1], [ 'datetime' ] ],
	      [ TIME_FORMAT => [1,1], [ 'datetime' ] ],
	      [ FROM_UNIXTIME => [0,1], [ 'datetime' ] ],

	      [ GET_LOCK => [1,0], [ 'system' ] ],
	      [ BENCHMARK => [0,1], [ 'system' ] ],
	      [ MASTER_POS_WAIT => [1,0], [ 'system' ] ],

	      [ IFNULL => [0,1], [ 'control' ] ],
	      [ NULLIF => [0,0], [ 'control' ] ],
	    )
    {
	make_function( function => $_->[0],
                       min => 2,
                       max => 2,
                       quote => $_->[1],
                       groups => $_->[2],
                     );
    }

    foreach ( [ LEAST => [1,1,1], [ 'string' ] ],
	      [ GREATEST => [1,1,1], [ 'string' ] ],
	      [ CONCAT => [1,1,1], [ 'string' ] ],
	      [ ELT => [0,1.1], [ 'string' ] ],
	      [ FIELD => [1,1,1], [ 'string' ] ],
	      [ MAKE_SET => [0,1,1], [ 'string' ] ],
	    )
    {
	make_function( function => $_->[0],
                       min => 2,
                       max => undef,
                       quote => $_->[1],
                       groups => $_->[2],
                     );
    }

    foreach ( [ LOCATE => [1,1,0], [ 'string' ] ],
	      [ SUBSTRING => [1,0,0], [ 'string' ] ],
	      [ CONV => [1,0,0], [ 'string' ] ],
	      [ LPAD => [1,0,1], [ 'string' ] ],
	      [ RPAD => [1,0,1], [ 'string' ] ],
	      [ MID => [1,0,0], [ 'string' ] ],
	      [ SUBSTRING_INDEX => [1,1,0], [ 'string' ] ],
	      [ REPLACE => [1,1,1], [ 'string' ] ],

	      [ IF => [0,1,1], [ 'control' ] ],
	    )
    {
	make_function( function => $_->[0],
                       min => 3,
                       max => 3,
                       quote => $_->[1],
                       groups => $_->[2],
                     );
    }

    foreach ( [ WEEK => [1,0], [ 'datetime' ] ],
	      [ YEARWEEK => [1,0], [ 'datetime' ] ],
	    )
    {
	make_function( function => $_->[0],
                       min => 1,
                       max => 2,
                       quote => $_->[1],
                       groups => $_->[2],
                     );
    }

    make_function( function => 'CONCAT_WS',
                   min => 3,
                   max => undef,
                   quote => [1,1,1,1],
                   groups => [ 'string' ],
                 );

    make_function( function => 'EXPORT_SET',
                   min => 3,
                   max => 5,
                   quote => [0,1,1,1,0],
                   groups => [ 'string' ],
                 );

    make_function( function => 'INSERT',
                   min => 3,
                   max => 5,
                   quote => [1,0,0,1],
                   groups => [ 'string' ],
                 );

    foreach ( [ ABS  => [0], [ 'math' ] ],
	      [ SIGN  => [0], [ 'math' ] ],
	      [ FLOOR  => [0], [ 'math' ] ],
	      [ CEILING  => [0], [ 'math' ] ],
	      [ EXP  => [0], [ 'math' ] ],
	      [ LOG  => [0], [ 'math' ] ],
	      [ LOG10  => [0], [ 'math' ] ],
	      [ SQRT  => [0], [ 'math' ] ],
	      [ COS  => [0], [ 'math' ] ],
	      [ SIN  => [0], [ 'math' ] ],
	      [ TAN  => [0], [ 'math' ] ],
	      [ ACOS  => [0], [ 'math' ] ],
	      [ ASIN  => [0], [ 'math' ] ],
	      [ ATAN  => [0], [ 'math' ] ],
	      [ COT  => [0], [ 'math' ] ],
	      [ DEGREES  => [0], [ 'math' ] ],
	      [ RADIANS  => [0], [ 'math' ] ],
	      [ TRUNCATE  => [0], [ 'math' ] ],

	      [ ASCII  => [1], [ 'string' ] ],
	      [ ORD  => [1], [ 'string' ] ],
	      [ BIN  => [0], [ 'string' ] ],
	      [ OCT  => [0], [ 'string' ] ],
	      [ HEX  => [0], [ 'string' ] ],
	      [ LENGTH  => [1], [ 'string' ] ],
	      [ OCTET_LENGTH  => [1], [ 'string' ] ],
	      [ CHAR_LENGTH  => [1], [ 'string' ] ],
	      [ CHARACTER_LENGTH  => [1], [ 'string' ] ],
	      [ TRIM  => [1], [ 'string' ] ],
	      [ LTRIM  => [1], [ 'string' ] ],
	      [ RTRIM  => [1], [ 'string' ] ],
	      [ SOUNDEX  => [1], [ 'string' ] ],
	      [ SPACE  => [0], [ 'string' ] ],
	      [ REVERSE  => [1], [ 'string' ] ],
	      [ LCASE  => [1], [ 'string' ] ],
	      [ LOWER  => [1], [ 'string' ] ],
	      [ UCASE  => [1], [ 'string' ] ],
	      [ UPPER  => [1], [ 'string' ] ],

	      [ RELEASE_LOCK  => [1], [ 'system' ] ],

	      [ DAYOFWEEK  => [1], [ 'datetime' ] ],
	      [ WEEKDAY  => [1], [ 'datetime' ] ],
	      [ DAYOFYEAR  => [1], [ 'datetime' ] ],
	      [ MONTH  => [1], [ 'datetime' ] ],
	      [ DAYNAME  => [1], [ 'datetime' ] ],
	      [ MONTHNAME  => [1], [ 'datetime' ] ],
	      [ QUARTER  => [1], [ 'datetime' ] ],
	      [ YEAR  => [1], [ 'datetime' ] ],
	      [ HOUR  => [1], [ 'datetime' ] ],
	      [ MINUTE  => [1], [ 'datetime' ] ],
	      [ SECOND  => [1], [ 'datetime' ] ],
	      [ TO_DAYS  => [1], [ 'datetime' ] ],
	      [ FROM_DAYS  => [0], [ 'datetime' ] ],
	      [ SEC_TO_TIME  => [0], [ 'datetime' ] ],
	      [ TIME_TO_SEC  => [1], [ 'datetime' ] ],

	      [ INET_NTOA  => [0], [ 'misc' ] ],
	      [ INET_ATON  => [1], [ 'misc' ] ],

	      [ COUNT  => [0], [ 'aggregate', 'common' ] ],
	      [ AVG  => [0], [ 'aggregate', 'common' ] ],
	      [ MIN  => [0], [ 'aggregate', 'common' ] ],
	      [ MAX  => [0], [ 'aggregate', 'common' ] ],
	      [ SUM  => [0], [ 'aggregate', 'common' ] ],
	      [ STD  => [0], [ 'aggregate' ] ],
	      [ STDDEV  => [0], [ 'aggregate' ] ],

	      [ BIT_OR  => [0], [ 'misc' ] ],
	      [ PASSWORD  => [1], [ 'misc' ] ],
	      [ MD5  => [1], [ 'misc' ] ],
	      [ BIT_AND  => [0], [ 'misc' ] ],
	      [ LOAD_FILE  => [1], [ 'misc' ] ],

	      [ AGAINST    => [1], [ 'fulltext' ] ],
	    )
    {
	make_function( function => $_->[0],
		       min => 1,
		       max => 1,
		       quote => $_->[1],
		       groups => $_->[2],
		     );
    }

    foreach ( [ MATCH    => [0], [ 'fulltext' ] ],
	    )
    {
	make_function( function => $_->[0],
		       min => 1,
		       max => undef,
		       quote => $_->[1],
		       groups => $_->[2],
		     );
    }

    make_function( function => 'DISTINCT',
		   min => 1,
		   max => undef,
		   quote => [0],
		   groups => [ 'common' ],
		   allows_alias => 0,
		 );

    make_function( function => 'IN_BOOLEAN_MODE',
		   is_modifier => 1,
		   groups => [ 'fulltext' ],
		);

    $MADE_FUNCTIONS = 1;
}

sub init
{
    1;
}

sub select
{
    my $self = shift;

    #
    # Special check for [ MATCH( $foo_col, $bar_col ), AGAINST('foo bar') ]
    # IN_BOOLEAN_MODE is optional
    #
    for ( my $i = 0; $i <= $#_; $i++ )
    {
	if ( Alzabo::Utils::safe_isa( $_[$i], 'Alzabo::SQLMaker::Function' ) &&
	     $_[$i]->as_string( $self->{driver}, $self->{quote_identifiers} ) =~ /^\s*MATCH/i )
	{
	    $_[$i] = $_[$i]->as_string( $self->{driver}, $self->{quote_identifiers} );

	    $_[$i] .= ' ' . $_[$i + 1]->as_string( $self->{driver}, $self->{quote_identifiers} );

	    splice @_, $i + 1, 1;

	    if ( defined $_[ $i + 1 ] &&
		 Alzabo::Utils::safe_isa( $_[ $i + 1 ], 'Alzabo::SQLMaker::Function' ) &&
		 $_[ $i + 1 ]->as_string( $self->{driver}, $self->{quote_identifiers} ) =~
                 /^\s*IN BOOLEAN MODE/i )
	    {
		$_[$i] .= ' ' . $_[$i + 1]->as_string( $self->{driver}, $self->{quote_identifiers} );
		splice @_, $i + 1, 1;
	    }
	}
    }

    $self->SUPER::select(@_);
}

sub condition
{
    my $self = shift;

    #
    # Special check for [ MATCH( $foo_col, $bar_col ), AGAINST('foo bar') ]
    # IN_BOOLEAN_MODE is optional
    #
    if ( Alzabo::Utils::safe_isa( $_[0], 'Alzabo::SQLMaker::Function' ) &&
	 $_[0]->as_string( $self->{driver}, $self->{quote_identifiers} ) =~ /^\s*MATCH/i )
    {
	$self->{last_op} = 'condition';
	$self->{sql} .=
            join ' ', map { $_->as_string( $self->{driver}, $self->{quote_identifiers} ) } @_;
    }
    else
    {
	$self->SUPER::condition(@_);
    }
}

sub limit
{
    my $self = shift;
    my ($max, $offset) = @_;

    $self->_assert_last_op( qw( from function where and or condition order_by group_by ) );

    if ($offset)
    {
	$self->{sql} .= " LIMIT $offset, $max";
    }
    else
    {
	$self->{sql} .= " LIMIT $max";
    }

    $self->{last_op} = 'limit';

    return $self;
}

sub get_limit
{
    return undef;
}

sub sqlmaker_id
{
    return 'MySQL';
}

1;

__END__

=head1 NAME

Alzabo::SQLMaker::MySQL - Alzabo SQL making class for MySQL

=head1 SYNOPSIS

  use Alzabo::SQLMaker;

  my $sql = Alzabo::SQLMaker->new( sql => 'MySQL' );

=head1 DESCRIPTION

This class implementes MySQL-specific SQL creation.  MySQL does not
allow subselects.  Any attempt to use a subselect (by passing an
C<Alzabo::SQMaker> object in as parameter to a method) will result in
an L<C<Alzabo::Exception::SQL>|Alzabo::Exceptions> error.

=head1 METHODS

Almost all of the functionality inherited from Alzabo::SQLMaker is
used as is.  The only overridden methods are C<limit()> and
C<get_limit()>, as MySQL does allow for a C<LIMIT> clause in its SQL.

=head1 EXPORTED SQL FUNCTIONS

SQL may be imported by name or by tags.  They take arguments as
documented in the MySQL documentation (version 3.23.39).  The
functions (organized by tag) are:

=head2 :math

 PI
 RAND
 MOD
 ROUND
 POW
 POWER
 ATAN2
 ABS
 SIGN
 FLOOR
 CEILING
 EXP
 LOG
 LOG10
 SQRT
 COS
 SIN
 TAN
 ACOS
 ASIN
 ATAN
 COT
 DEGREES
 RADIANS
 TRUNCATE

=head2 :string

 CHAR
 POSITION
 INSTR
 LEFT
 RIGHT
 FIND_IN_SET
 REPEAT
 LEAST
 GREATEST
 CONCAT
 ELT
 FIELD
 MAKE_SET
 LOCATE
 SUBSTRING
 CONV
 LPAD
 RPAD
 MID
 SUBSTRING_INDEX
 REPLACE
 CONCAT_WS
 EXPORT_SET
 INSERT
 ASCII
 ORD
 BIN
 OCT
 HEX
 LENGTH
 OCTET_LENGTH
 CHAR_LENGTH
 CHARACTER_LENGTH
 TRIM
 LTRIM
 RTRIM
 SOUNDEX
 SPACE
 REVERSE
 LCASE
 LOWER
 UCASE
 UPPER

=head2 :datetime

 CURDATE
 CURRENT_DATE
 CURTIME
 CURRENT_TIME
 NOW
 SYSDATE
 CURRENT_TIMESTAMP
 UNIX_TIMESTAMP
 WEEK
 PERIOD_ADD
 PERIOD_DIFF
 DATE_ADD
 DATE_SUB
 ADDDATE
 SUBDATE
 DATE_FORMAT
 TIME_FORMAT
 FROM_UNIXTIME
 DAYOFWEEK
 WEEKDAY
 DAYOFYEAR
 MONTH
 DAYNAME
 MONTHNAME
 QUARTER
 YEAR
 YEARWEEK
 HOUR
 MINUTE
 SECOND
 TO_DAYS
 FROM_DAYS
 SEC_TO_TIME
 TIME_TO_SEC

=head2 :aggregate

These are functions which operate on an aggregate set of values all at
once.

 COUNT
 AVG
 MIN
 MAX
 SUM
 STD
 STDDEV

=head2 :system

These are functions which return information about the MySQL server.

 DATABASE
 USER
 SYSTEM_USER
 SESSION_USER
 VERSION
 CONNECTION_ID
 LAST_INSERT_ID
 GET_LOCK
 RELEASE_LOCK
 BENCHMARK
 MASTER_POS_WAIT

=head2 :control

These are flow control functions:

 IFNULL
 NULLIF
 IF

=head2 :misc

These are functions which don't fit into any other categories.

 ENCRYPT
 ENCODE
 DECODE
 FORMAT
 INET_NTOA
 INET_ATON
 BIT_OR
 BIT_AND
 PASSWORD
 MD5
 LOAD_FILE

=head2 :fulltext

These are functions related to MySQL's fulltext searching
capabilities.

 MATCH
 AGAINST
 IN_BOOLEAN_MODE

NOTE: In MySQL 4.0 and greater, it is possible to say that a search is
in boolean mode in order to change how MySQL handles the argument
given to AGAINST.  This will not work with earlier versions.

=head2 :common

These are functions from other groups that are most commonly used.

 NOW
 COUNT
 AVG
 MIN
 MAX
 SUM
 DISTINCT

=head1 AUTHOR

Dave Rolsky, <dave@urth.org>

=cut
