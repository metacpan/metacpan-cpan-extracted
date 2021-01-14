# this file tests how bag information could be accessed
BEGIN { chdir 't' if -d 't' }

use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 49;
use Test::Exception;
use strict;


use lib '../lib';

use File::Spec;
use Data::Printer;
use File::Path;
use File::Copy;
use File::Temp qw(tempdir);
use File::Slurp qw( read_file write_file);

use_ok('Archive::BagIt::Role::Portability');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath(''), '', 'normalize_payload_filepath, empty');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath('data/foo'), 'data/foo', 'normalize_payload_filepath, standard');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath('data\foo'), 'data/foo', 'normalize_payload_filepath, windows standard');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath('data\foo\bar\baz'), 'data/foo/bar/baz', 'normalize_payload_filepath, windows standard, long');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath('data/foo bar'), 'data/foo%20bar', 'normalize_payload_filepath, space');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath('data\foo bar'), 'data/foo%20bar', 'normalize_payload_filepath, windows space');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath('data\/foo'), 'data\/foo', 'normalize_payload_filepath, escape \/');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath('"data/foo bar"'), 'data/foo%20bar', 'normalize_payload_filepath, quoted space');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath("data/foo\nbar"), 'data/foo%0Abar', 'normalize_payload_filepath, <LF>');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath("data/foo\rbar"), 'data/foo%0Dbar', 'normalize_payload_filepath, <CR>');
is(Archive::BagIt::Role::Portability::normalize_payload_filepath('data/foo%bar'), 'data/foo%25bar', 'normalize_payload_filepath, percent');

ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('data/>foo'), 'Windows reserved char >' );
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('data/<foo'), 'Windows reserved char <' );
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('foo:'), 'Windows reserved char :' );
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('"'), 'Windows reserved char "' );
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('?'), 'Windows reserved char ?' );
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('*'), 'Windows reserved char *' );
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('|'), 'Windows reserved char |' );
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('CON'), 'Windows reserved name CON');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('PRN'), 'Windows reserved name PRN');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('AUX'), 'Windows reserved name AUX');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('NUL'), 'Windows reserved name NUL');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM1'), 'Windows reserved name COM1');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM2'), 'Windows reserved name COM2');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM3'), 'Windows reserved name COM3');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM4'), 'Windows reserved name COM4');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM5'), 'Windows reserved name COM5');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM6'), 'Windows reserved name COM6');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM7'), 'Windows reserved name COM7');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM8'), 'Windows reserved name COM8');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('COM9'), 'Windows reserved name COM9');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT1'), 'Windows reserved name LPT1');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT2'), 'Windows reserved name LPT2');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT3'), 'Windows reserved name LPT3');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT4'), 'Windows reserved name LPT4');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT5'), 'Windows reserved name LPT5');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT6'), 'Windows reserved name LPT6');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT7'), 'Windows reserved name LPT7');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT8'), 'Windows reserved name LPT8');
ok(Archive::BagIt::Role::Portability::check_if_payload_filepath_violates('LPT9'), 'Windows reserved name LPT9');

is(Archive::BagIt::Role::Portability::chomp_portable("foo\n"), "foo", "chomp_portable(), \\n");
is(Archive::BagIt::Role::Portability::chomp_portable("foo\r"), "foo", "chomp_portable(), \\r");
is(Archive::BagIt::Role::Portability::chomp_portable("foo\r\n"), "foo", "chomp_portable(), \\r\\n");


use_ok('Archive::BagIt');
my $obj = new_ok('Archive::BagIt');
is($obj->__file_find(qw(../bagit_conformance_suite/v0.97/valid/bag-in-a-bag)), 13, '__file_find');
is($obj->__file_find(qw(../bagit_conformance_suite/v0.97/valid/bag-in-a-bag/data)), 9, '__file_find');
is($obj->__file_find(qw(../bagit_conformance_suite/v0.97/valid/bag-in-a-bag), qw(../bagit_conformance_suite/v0.97/valid/bag-in-a-bag/data)), 4, '__file_find');
1;
