use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );
use File::Spec;

plan skip_all => 'no test on MSWin32' if $^O eq 'MSWin32';

my $found;
foreach my $path (split /:/, $ENV{PATH})
{
  $found = $path if -x File::Spec->catfile($path, 'gunzip');
}

plan skip_all => 'test requires gunzip in path' unless $found;
plan tests => 4;

my $r;
my $data = unpack 'u', do { local $/; <DATA> };
is length($data), 93, 'got data';
my $signature = substr $data, 0, 4;
is length($signature), 4, 'got signature';

foreach my $function_name (qw( archive_read_support_filter_program_signature archive_read_append_filter_program_signature ))
{
  subtest $function_name => sub {
    plan skip_all => "test requires $function_name" unless Archive::Libarchive::Any->can($function_name);
    plan tests => 8;
    my $a = archive_read_new();

    $r = eval qq{ $function_name(\$a, "gunzip", \$signature) };
    diag $@ if $@;
    is $r, ARCHIVE_OK, 'archive_read_support_filter_program_signature';

    $r = archive_read_support_format_all($a);
    is $r, ARCHIVE_OK, 'archive_read_support_format_all';

    $r = archive_read_open_memory($a, $data);
    is $r, ARCHIVE_OK, 'archive_read_open_memory';
    diag archive_error_string($a) if $r != ARCHIVE_OK;

    $r = archive_read_next_header($a, my $ae);
    is $r, ARCHIVE_OK, 'archive_read_next_header';
    diag archive_error_string($a) if $r != ARCHIVE_OK;

    SKIP: {
      skip 'requires ARCHIVE_FILTER_PROGRAM', 1 unless eval { ARCHIVE_FILTER_PROGRAM() };
      skip 'requires archive_filter_code', 1 unless Archive::Libarchive::FFI->can('archive_filter_code');
      is archive_filter_code($a, 0), ARCHIVE_FILTER_PROGRAM(), 'archive_filter_code';
    };
    is archive_format($a), ARCHIVE_FORMAT_TAR_USTAR, 'archive_format';

    $r = archive_read_close($a);
    is $r, ARCHIVE_OK, 'archive_read_close';

    $r = archive_read_free($a);
    is $r, ARCHIVE_OK, 'archive_read_free';
  }
}

__DATA__
M'XL(`-Y#<$,``]-CH#TP,#`P-S55`-*&YJ8&R#0<*!@:&!N;&)@8FAN;*1@8
M&IB:&3(HF-+!;0REQ26)14"GE&3FXE5'2![J#S@]"D;!*!@%@QP``!VL!?``
#!@``
`

