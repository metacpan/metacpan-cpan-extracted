package Astro::STSDAS::Table::Constants;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
		 TT_ROW_ORDER
		 TT_COL_ORDER
		 CHAR_SZ
		 TY_REAL
		 TY_DOUBLE
		 TY_INT
		 TY_SHORT
		 TY_BOOL
		 TY_STRING
		 %TypeSize
		 %TypeUPack
		 %TypeIndef
		 %HdrType
		 %Types
		);

our $VERSION = '0.01';

use constant TT_ROW_ORDER => 11;
use constant TT_COL_ORDER => 12;

use constant CHAR_SZ => 2;

# column data representation types; from IRAF unix/hlib/iraf.h
use constant TY_BOOL   =>  1;
use constant TY_SHORT  =>  3;
use constant TY_INT    =>  4;
use constant TY_REAL   =>  6;
use constant TY_DOUBLE =>  7;
# special to STSDAS tables
use constant TY_STRING => -1;

our @Types = ( TY_BOOL, TY_SHORT, TY_INT, TY_REAL, TY_DOUBLE, TY_STRING );
our %Types = map { $_ => 1 } @Types;

# from IRAF unix/hlib/iraf.h
our %TypeSize = (
		 TY_BOOL()   => 2 * CHAR_SZ, 
		 TY_SHORT()  => 1 * CHAR_SZ,
		 TY_INT()    => 2 * CHAR_SZ,
		 TY_REAL()   => 2 * CHAR_SZ,
		 TY_DOUBLE() => 4 * CHAR_SZ,
		);


# use Perl pack types which have as exact a length as possible
our %TypeUPack = (
		  TY_BOOL()   => 'l',
		  TY_SHORT()  => 's',
		  TY_INT()    => 'l',
		  TY_REAL()   => 'f',
		  TY_DOUBLE() => 'd',
		  TY_STRING() => 'a',
		 );


# values that indicate the data are undefined.
# these are taken from the IRAF unix/hlib/iraf.h file,
# except for the TY_DOUBLE value, which is from the STSDAS Table
# tbtables.h file.
our %TypeIndef = ( 
		  TY_BOOL()   => '', # not possible
		  TY_SHORT()  => -32767,	
		  TY_INT()    => -2147483647,
		  # since Perl is double precision, do this to get
		  # single precision value of 1.6e38
		  TY_REAL()   => unpack('f', pack('f', 1.6e38)), 
		  TY_DOUBLE() => 1.6e38, 
		  TY_STRING() => ''  # not meaningful
		 );

our %HdrType = ( 
		b => TY_BOOL,
		i => TY_INT,
		r => TY_REAL,
		d => TY_DOUBLE,
		t => TY_STRING,
		);

1;

