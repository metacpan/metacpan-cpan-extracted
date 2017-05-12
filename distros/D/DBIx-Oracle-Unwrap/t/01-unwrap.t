#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin qw($Bin);
use DBIx::Oracle::Unwrap;

plan tests => 2;

my $orig_source = 
q{PACKAGE BODY t1 AS

    PROCEDURE T1_A 
    BEGIN
        NULL;
    END;

END;} . chr(0);

my $wrapped = <<EOT2;
create or replace package body t1 wrapped
a000000
1
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
abcd
b
4f 7d
jHlVPGkuG/NtR3pgINCvFOPPFNQwg5m49TOf9b9cuJu/9MMWf8O4dIsGCaasqcqqF+qcUMrq
Ai9qMIBES3W3CpiwLHVE4T9rIiI8cEEKT20qHx/jkaamrx0vBw==

/
EOT2

my $w = DBIx::Oracle::Unwrap->new;
my $unwrapped = $w->unwrap($wrapped);
ok ($unwrapped eq $orig_source, 'Unwrapping text');

$unwrapped = $w->unwrap_file("$Bin/t1_enc.plb");
ok ($unwrapped eq $orig_source, 'Unwrapping file');