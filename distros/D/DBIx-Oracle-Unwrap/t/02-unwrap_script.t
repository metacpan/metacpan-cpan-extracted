#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin qw($Bin);
use Capture::Tiny ':all';
use DBIx::Oracle::Unwrap;

plan tests => 4;

my $orig_source = q{PACKAGE BODY t1 AS

    PROCEDURE T1_A 
    BEGIN
        NULL;
    END;

END;} . chr(0);

my $script       = "$Bin/../script/unwrap";
my $wrapped_file = "$Bin/t1_enc.plb";

my ($stdout, $stderr, $exit) = capture {
    system($^X, $script, $wrapped_file);
};

is ($stdout, $orig_source, 'Unwrapped file');

($stdout, $stderr, $exit) = capture {
    system($^X, $script);
};

like ($stderr, qr/No file provided/, 'No file provided');

($stdout, $stderr, $exit) = capture {
    system($^X, $script, "$Bin/NoSuchFile.txt");
};

like ($stderr, qr/Invalid file/, 'File does not exist');

($stdout, $stderr, $exit) = capture {
    system($^X, $script, "$Bin");
};

like ($stderr, qr/Invalid file/, 'Only unwrap regular files');