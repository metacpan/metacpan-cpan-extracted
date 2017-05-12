#!/usr/bin/perl
#
#   @(#)$Id: t02ixtype.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test ix_types attribute
#
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2008-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use DBD::Informix qw(:ix_types);
use strict;
use warnings;

# You need to update this list if any types are added (unlikely) or if
# any types are removed (IX_COLLECTION is the plausible candidate).
# The IX_xxxx name is defined in Informix.xs
# The numeric value is defined in sqltypes.h
my %typeinfo = (
    "IX_ROW"        => [ IX_ROW,          22 ],
    "IX_SMALLINT"   => [ IX_SMALLINT,      1 ],
    "IX_INTEGER"    => [ IX_INTEGER,       2 ],
    "IX_SERIAL"     => [ IX_SERIAL,        6 ],
    "IX_INT8"       => [ IX_INT8,         17 ],
    "IX_SERIAL8"    => [ IX_SERIAL8,      18 ],
    "IX_BIGINT"     => [ IX_BIGINT,       52 ],
    "IX_BIGSERIAL"  => [ IX_BIGSERIAL,    53 ],
    "IX_DECIMAL"    => [ IX_DECIMAL,       5 ],
    "IX_MONEY"      => [ IX_MONEY,         8 ],
    "IX_FLOAT"      => [ IX_FLOAT,         3 ],
    "IX_SMALLFLOAT" => [ IX_SMALLFLOAT,    4 ],
    "IX_CHAR"       => [ IX_CHAR,          0 ],
    "IX_VARCHAR"    => [ IX_VARCHAR,      13 ],
    "IX_NCHAR"      => [ IX_NCHAR,        15 ],
    "IX_NVARCHAR"   => [ IX_NVARCHAR,     16 ],
    "IX_LVARCHAR"   => [ IX_LVARCHAR,     43 ],
    "IX_BOOLEAN"    => [ IX_BOOLEAN,      45 ],
    "IX_DATE"       => [ IX_DATE,          7 ],
    "IX_DATETIME"   => [ IX_DATETIME,     10 ],
    "IX_INTERVAL"   => [ IX_INTERVAL,     14 ],
    "IX_BYTE"       => [ IX_BYTE,         11 ],
    "IX_TEXT"       => [ IX_TEXT,         12 ],
    "IX_FIXUDT"     => [ IX_FIXUDT,       41 ],
    "IX_VARUDT"     => [ IX_VARUDT,       40 ],
    "IX_SET"        => [ IX_SET,          19 ],
    "IX_MULTISET"   => [ IX_MULTISET,     20 ],
    "IX_LIST"       => [ IX_LIST,         21 ],
    "IX_COLLECTION" => [ IX_COLLECTION,   23 ],
    "IX_BLOB"       => [ IX_BLOB,       1011 ],
    "IX_CLOB"       => [ IX_CLOB,       1012 ]
);

my $ntests = keys %typeinfo;
stmt_note("1..$ntests\n");

my $fail = 0;
foreach my $key (sort keys %typeinfo)
{
    my $arrref = $typeinfo{$key};
    my $val0 = $arrref->[0];
    my $val1 = $arrref->[1];
    if ($val0 == $val1)
    {
        stmt_ok;
        printf("# %-13s = %d\n", $key, $val0);
    }
    else
    {
        stmt_nok "# $key is $val0 but should be $val1\n";
        $fail++;
    }
}

all_ok if $fail == 0;
