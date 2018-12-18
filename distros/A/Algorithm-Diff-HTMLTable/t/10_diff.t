#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;
use Algorithm::Diff::HTMLTable;

my $table = Algorithm::Diff::HTMLTable->new;

{
    my $error;

    eval {
        $table->diff();
        1;
    } or $error = $@;

    like $error, qr/need two filenames/, 'no filenames';
}

{
    my $error;

    eval {
        $table->diff('file1');
        1;
    } or $error = $@;

    like $error, qr/need two filenames/, 'one filenames';
}

{
    my $error;

    eval {
        $table->diff('file1', 'file2', 'file3');
        1;
    } or $error = $@;

    like $error, qr/need two filenames/, 'too many arguments';
}

{
    my $error;

    eval {
        $table->diff('file1', 'file2');
        1;
    } or $error = $@;

    like $error, qr/is not a file/, 'is not a file';
}

{
    my $error;

    eval {
        $table->diff( {}, {} );
        1;
    } or $error = $@;

    like $error, qr/Need either filename/, 'Hashref passed';
}

done_testing();
