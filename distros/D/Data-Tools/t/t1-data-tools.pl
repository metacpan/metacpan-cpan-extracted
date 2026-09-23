#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use File::Temp qw( tempdir );
use Data::Tools;

ok( defined $Data::Tools::VERSION, 'Data::Tools loaded' );

my $TMP = tempdir( 'data-tools-t1-XXXXXX', TMPDIR => 1, CLEANUP => 1 );

##############################################################################
# file name/path decomposition
##############################################################################

is( file_path(     '/a/b/c.txt' ), '/a/b/', 'file_path()' );
is( file_name(     '/a/b/c.txt' ), 'c',     'file_name()' );
is( file_name_ext( '/a/b/c.txt' ), 'c.txt', 'file_name_ext()' );
is( file_ext(      '/a/b/c.txt' ), 'txt',   'file_ext()' );

is( file_name(     '/a/b/.hidden' ), '.hidden', 'file_name() keeps dot-file name' );
is( file_name_ext( '/a/b/.hidden' ), '.hidden', 'file_name_ext() keeps dot-file name' );
is( file_ext(      '/a/b/.hidden' ), undef,     'file_ext() is undef for dot-files' );

is( file_name( 'plain.txt' ), 'plain', 'file_name() without path' );

##############################################################################
# file save/load
##############################################################################

ok( file_save( "$TMP/a.txt", 'hello' ),      'file_save()' );
is( file_load( "$TMP/a.txt" ), 'hello',      'file_load()' );
is( file_size( "$TMP/a.txt" ), 5,            'file_size()' );
cmp_ok( file_mtime( "$TMP/a.txt" ), '>', 0,  'file_mtime()' );
cmp_ok( file_ctime( "$TMP/a.txt" ), '>', 0,  'file_ctime()' );
cmp_ok( file_atime( "$TMP/a.txt" ), '>', 0,  'file_atime()' );

is_deeply( file_load_ar( "$TMP/a.txt" ), [ 'hello' ], 'file_load_ar()' );

is( file_load( "$TMP/no-such-file" ), undef, 'file_load() returns undef for missing file' );

ok( file_bin_save( "$TMP/b.bin", "\x00\xff\x10" ), 'file_bin_save()' );
is( file_bin_load( "$TMP/b.bin" ), "\x00\xff\x10", 'file_bin_load()' );

ok( file_text_save( "$TMP/c.txt", "x\ny\n" ),         'file_text_save()' );
is( file_text_load( "$TMP/c.txt" ), "x\ny\n",         'file_text_load()' );
is( file_text_load_first_line( "$TMP/c.txt" ), "x\n", 'file_text_load_first_line()' );
ok( file_text_append( "$TMP/c.txt", "z\n" ),          'file_text_append()' );
is_deeply( file_text_load_ar( "$TMP/c.txt" ), [ "x\n", "y\n", "z\n" ], 'file_text_load_ar()' );

# save with options hash (backward compatible interface)
ok( file_save( { FILE_NAME => "$TMP/d.txt", ENCODING => 'UTF-8' }, 'utf8 data' ), 'file_save() with options hash' );
is( file_load( { FILE_NAME => "$TMP/d.txt", ENCODING => 'UTF-8' } ), 'utf8 data', 'file_load() with options hash' );

##############################################################################
# commands
##############################################################################

is( cmd_read_from( 'echo hi' ), "hi\n", 'cmd_read_from()' );

##############################################################################
# file locking
##############################################################################

my $fh = file_lock_ex_nb( "$TMP/a.txt" );
ok( defined $fh,        'file_lock_ex_nb() acquires lock' );
ok( file_unlock( $fh ), 'file_unlock()' );
close( $fh );

my $fh2 = file_lock_nb( "$TMP/a.txt" );
ok( defined $fh2, 'file_lock_nb() acquires shared lock' );
file_unlock( $fh2 );
close( $fh2 );

##############################################################################
# directories
##############################################################################

ok( dir_path_make( "$TMP/x/y/z" ),  'dir_path_make() creates full path' );
ok( -d "$TMP/x/y/z",                'dir_path_make() path exists' );
is( dir_path_ensure( "$TMP/x/y/z" ), "$TMP/x/y/z", 'dir_path_ensure() returns existing path' );
is( dir_path_ensure( "$TMP/q/w" ),   "$TMP/q/w",   'dir_path_ensure() creates missing path' );

my @entries = read_dir_entries( $TMP );
ok( ( grep { $_ eq 'a.txt' } @entries ), 'read_dir_entries() lists files' );
ok( ! ( grep { /^\.\.?$/ } @entries ),   'read_dir_entries() skips . and ..' );

##############################################################################
# glob_tree() and fftwalk()
##############################################################################

file_save( "$TMP/x/y/deep.txt", 'deep' );

my @globbed = glob_tree( "$TMP/*.txt" );
ok( ( grep { m{/a\.txt$}    } @globbed ), 'glob_tree() finds top level file' );
ok( ( grep { m{/deep\.txt$} } @globbed ), 'glob_tree() descends into subdirs' );

my $files = fftwalk( FFT_FILES, $TMP );
ok( ( grep { m{/deep\.txt$} } @$files ), 'fftwalk( FFT_FILES ) finds files' );
ok( ! ( grep { m{/x/y$}     } @$files ), 'fftwalk( FFT_FILES ) skips dirs' );

my $dirs = fftwalk( FFT_DIRS, $TMP );
ok( ( grep { m{/x/y/z$} } @$dirs ), 'fftwalk( FFT_DIRS ) finds dirs' );

my $all = fftwalk( FFT_ALL, $TMP );
cmp_ok( scalar @$all, '>', scalar @$files, 'fftwalk( FFT_ALL ) returns files and dirs' );

is_deeply( fftwalk( 0, $TMP ), [], 'fftwalk() with zero TYPE does nothing' );

my @acc;
fftwalk( { TYPE => FFT_FILES, ARRAY => \@acc }, $TMP );
ok( scalar @acc > 0, 'fftwalk() with options hash appends to ARRAY' );

##############################################################################
# glob_tree()/fftwalk() must not loop on symlinked directories
##############################################################################

SKIP:
{
  my $LOOP = "$TMP/symloop";
  dir_path_make( "$LOOP/a/b" );
  dir_path_make( "$LOOP/shared" );
  file_save( "$LOOP/top.txt",      'top'  );
  file_save( "$LOOP/a/b/deep.txt", 'deep' );
  file_save( "$LOOP/shared/s.txt", 's'    );

  # 'up' points back at the top of the tree, so descending it is a loop
  skip( 'symlinks are not supported on this system', 6 )
      unless eval { symlink( '../../', "$LOOP/a/b/up" ) };

  # two distinct symlinks to one real dir -- NOT a loop, both must still work
  symlink( '../shared', "$LOOP/a/link1" );
  symlink( '../shared', "$LOOP/a/link2" );

  # the alarm turns a runaway walk into a failed test instead of a hung suite
  my @g;
  ok( eval { local $SIG{ 'ALRM' } = sub { die "timeout\n" };
             alarm 30; @g = glob_tree( "$LOOP/*.txt" ); alarm 0; 1 },
      'glob_tree() terminates on a symlink loop' );
  ok( ! ( grep { m{/up/} } @g ), 'glob_tree() does not descend the looping symlink' );
  is( scalar( grep { m{/s\.txt$} } @g ), 3,
      'glob_tree() still reaches a shared dir through each distinct symlink' );

  my $w;
  ok( eval { local $SIG{ 'ALRM' } = sub { die "timeout\n" };
             alarm 30; $w = fftwalk( FFT_FULL, $LOOP ); alarm 0; 1 },
      'fftwalk( FFT_FULL ) terminates on a symlink loop' );
  ok( ! ( grep { m{/up/} } @$w ), 'fftwalk( FFT_FULL ) does not descend the looping symlink' );

  my $nf = fftwalk( FFT_ALL, $LOOP );
  ok( ! ( grep { m{/up} } @$nf ), 'fftwalk() without FFT_FOLLOW ignores symlinked dirs' );
}

##############################################################################
# escaping
##############################################################################

is( str_escape( "a=b\nc:d\\e\tf\r" ), 'a\=b\nc\:d\\\\e\tf\r', 'str_escape()' );
is( str_unescape( str_escape( "a=b\nc:d\\e\tf\r" ) ), "a=b\nc:d\\e\tf\r", 'str_unescape() round trip' );

is( str_url_escape( 'ab c/d' ), 'ab%20c%2Fd', 'str_url_escape()' );
is( str_url_escape( "\x{00E4}b" ), '%C3%A4b',  'str_url_escape() encodes to UTF-8 bytes' );
is( str_url_unescape( 'ab%20c%2Fd' ), 'ab c/d', 'str_url_unescape()' );

is( str_html_escape( q{<a href="x">&`=\\} ), '&#60;a href&#61;&#34;x&#34;&#62;&#38;&#96;&#61;&#92;', 'str_html_escape()' );
is( str_html_escape_text( q{<a href="x">&} ), '&#60;a href="x"&#62;&#38;', 'str_html_escape_text() leaves quotes' );
is( str_html_escape_attr( q{<a href="x">&} ), '&#60;a href=&#34;x&#34;&#62;&#38;', 'str_html_escape_attr() escapes quotes' );

is( str_html_unescape( '&lt;a&gt;&amp;' ),   '<a>&', 'str_html_unescape() named entities' );
is( str_html_unescape( '&#65;&#x42;' ),      'AB',   'str_html_unescape() numeric entities' );
is( str_html_unescape( '&nosuchentity;' ),   '&nosuchentity;', 'str_html_unescape() leaves unknown entities' );
is( str_html_unescape( '&#0;' ),             '&#0;', 'str_html_unescape() rejects invalid code point' );
is( str_html_unescape( str_html_escape_text( '<&>' ) ), '<&>', 'str_html_unescape() round trip' );

is( str_hex( 'AB' ),     '4142', 'str_hex()' );
is( str_unhex( '4142' ), 'AB',   'str_unhex()' );
is( str_unhex( str_hex( "\x00\xff" ) ), "\x00\xff", 'str_hex()/str_unhex() round trip' );

##############################################################################
# string formatting helpers
##############################################################################

is( str_num_comma( 1234567 ),      '1`234`567', 'str_num_comma() default separator' );
is( str_num_comma( 1234567, ',' ), '1,234,567', 'str_num_comma() custom separator' );

is( str_pad( 'ab',  5 ),      'ab   ', 'str_pad() left align' );
is( str_pad( 'ab', -5 ),      '   ab', 'str_pad() right align' );
is( str_pad( 'ab',  5, '.' ), 'ab...', 'str_pad() custom pad char' );
is( str_pad( 'abcdef', 3 ),   'abc',   'str_pad() truncates' );
is( str_pad_center( 'ab', 6 ), '  ab  ', 'str_pad_center()' );

is( str_countable( 0, 'file', 'files' ), 'files', 'str_countable() zero' );
is( str_countable( 1, 'file', 'files' ), 'file',  'str_countable() one' );
is( str_countable( 2, 'file', 'files' ), 'files', 'str_countable() many' );

is( str_kmg_to_num( '2k'   ), 2048,       'str_kmg_to_num() kilo' );
is( str_kmg_to_num( '1.5M' ), 1572864,    'str_kmg_to_num() mega, fractional' );
is( str_kmg_to_num( '10'   ), 10,         'str_kmg_to_num() plain number' );
is( str_kmg_to_num( 'zz'   ), undef,      'str_kmg_to_num() invalid input' );

is( str_hms_to_secs( '1h30m' ), 5400, 'str_hms_to_secs() hours and minutes' );
is( str_hms_to_secs( '90'    ), 90,   'str_hms_to_secs() bare number is seconds' );
is( str_hms_to_secs( '1w'    ), 604800, 'str_hms_to_secs() weeks' );

is( str_capitalize( 'hELLO' ), 'Hello', 'str_capitalize()' );
is( str_initials( 'James Webb Space Telescope' ), 'JWST', 'str_initials()' );

cmp_ok( str_password_strength( 'abc' ), '<', str_password_strength( 'aB3$xY9z!Q' ),
        'str_password_strength() rates complex password higher' );

##############################################################################
# hash <-> string
##############################################################################

my $hr = { 'a' => 1, 'b=c' => "d\ne" };

my $str = hash2str( $hr );
is_deeply( str2hash( $str ), $hr, 'hash2str()/str2hash() round trip with escapes' );

is( hash2str_keys( $hr, 'a' ), "a=1\n", 'hash2str_keys() selects keys' );
is( $hr->{ 'a' }, 1, 'hash2str_keys() does not modify the source hash' );

my $ustr = hash2str_url( $hr );
is_deeply( str2hash_url( $ustr ), $hr, 'hash2str_url()/str2hash_url() round trip' );

is_deeply( url2hash( 'a=1&b=x%20y' ), { A => 1, B => 'x y' }, 'url2hash() upper-cases keys' );

is( hash2json( { a => 1 } ), '{"a":1}', 'hash2json()' );
is_deeply( json2hash( '{"a":1}' ), { a => 1 }, 'json2hash()' );
like( hash2json_pp( { a => 1 } ), qr/\n/, 'hash2json_pp() is pretty printed' );
is_deeply( json2hash( hash2json_pp( { a => 1 } ) ), { a => 1 }, 'hash2json_pp() round trip' );

##############################################################################
# hash case conversion
##############################################################################

is_deeply( hash_uc( { a => 1, b => 2 } ), { A => 1, B => 2 }, 'hash_uc()' );
is_deeply( hash_lc( { A => 1, B => 2 } ), { a => 1, b => 2 }, 'hash_lc()' );

my %ipl = ( A => 1 );
hash_lc_ipl( \%ipl );
is_deeply( \%ipl, { a => 1 }, 'hash_lc_ipl() works in place' );

my %ipl2 = ( a => 1 );
hash_uc_ipl( \%ipl2 );
is_deeply( \%ipl2, { A => 1 }, 'hash_uc_ipl() works in place' );

##############################################################################
# hash save/load
##############################################################################

ok( hash_save( "$TMP/h.txt", { a => 1, b => 2 } ), 'hash_save()' );
is_deeply( hash_load( "$TMP/h.txt" ), { a => 1, b => 2 }, 'hash_load()' );

ok( hash_save_keys( "$TMP/hk.txt", { a => 1, b => 2 }, 'a' ), 'hash_save_keys()' );
is_deeply( hash_load( "$TMP/hk.txt" ), { a => 1 }, 'hash_save_keys() saves only given keys' );

ok( hash_save_url( "$TMP/hu.txt", { 'a b' => 'c d' } ), 'hash_save_url()' );
is_deeply( hash_load_url( "$TMP/hu.txt" ), { 'a b' => 'c d' }, 'hash_load_url()' );

ok( hash_save_json( "$TMP/hj.txt", { a => 1 } ), 'hash_save_json()' );
is_deeply( hash_load_json( "$TMP/hj.txt" ), { a => 1 }, 'hash_load_json()' );

ok( hash_save_json_pp( "$TMP/hjp.txt", { a => 1 } ), 'hash_save_json_pp()' );
is_deeply( hash_load_json( "$TMP/hjp.txt" ), { a => 1 }, 'hash_load_json() reads pretty printed json' );

##############################################################################
# hash_validate()
##############################################################################

ok(   hash_validate( { a => '5'  }, { a => 'int' } ),        'hash_validate() accepts int' );
ok( ! hash_validate( { a => 'x'  }, { a => 'int' } ),        'hash_validate() rejects non-int' );
ok(   hash_validate( { a => '5'  }, { a => 'int(1,10)' } ),  'hash_validate() accepts int in range' );
ok( ! hash_validate( { a => '50' }, { a => 'int(1,10)' } ),  'hash_validate() rejects int out of range' );
ok(   hash_validate( { a => '1.5' }, { a => 'real' } ),      'hash_validate() accepts real' );
ok(   hash_validate( { a => 'abc' }, { a => 're: ^abc' } ),  'hash_validate() accepts matching regexp' );
ok( ! hash_validate( { a => 'AbC' }, { a => 're: ^abc' } ),  'hash_validate() regexp is case sensitive' );
ok(   hash_validate( { a => 'AbC' }, { a => 'rei: ^abc' } ), 'hash_validate() REI: ignores case' );
ok(   hash_validate( { a => $TMP  }, { a => '-d' } ),        'hash_validate() accepts existing dir' );
ok( ! hash_validate( { a => $TMP  }, { a => '-f' } ),        'hash_validate() rejects dir as file' );
ok(   hash_validate( { a => "$TMP/a.txt" }, { a => '-f' } ), 'hash_validate() accepts existing file' );

is_deeply( [ hash_validate( { a => 'x', b => 2 }, { a => 'int' } ) ], [ 'a', 'b' ],
           'hash_validate() in list context returns sorted invalid keys' );
is_deeply( [ hash_validate( { a => { b => 'x' } }, { a => { b => 'int' } } ) ], [ 'a/b' ],
           'hash_validate() reports nested keys with path' );

##############################################################################
# hash locking
##############################################################################

my $lh = { a => 1, b => { c => 2 } };
hash_lock_recursive( $lh );
eval { $lh->{ zz } = 1 };
ok( $@, 'hash_lock_recursive() locks top level' );
eval { $lh->{ b }{ zz } = 1 };
ok( $@, 'hash_lock_recursive() locks nested hashes' );

hash_unlock_recursive( $lh );
eval { $lh->{ zz } = 1 };
ok( ! $@, 'hash_unlock_recursive() unlocks' );

my $kh = { a => 1, b => { c => 2 } };
hash_keys_lock_recursive( $kh );
eval { $kh->{ zz } = 1 };
ok( $@, 'hash_keys_lock_recursive() forbids new keys' );
eval { $kh->{ a } = 9 };
ok( ! $@, 'hash_keys_lock_recursive() still allows value changes' );

##############################################################################
# traversal and lists
##############################################################################

my $tr = { a => 1, b => [ 2, 3 ], c => { d => 4 } };
hr_traverse_vals( $tr, sub { return $_[0] * 10 } );
is_deeply( $tr, { a => 10, b => [ 20, 30 ], c => { d => 40 } }, 'hr_traverse_vals() descends into hashes and arrays' );

my $ar = [ 1, [ 2 ], { a => 3 } ];
ar_traverse_vals( $ar, sub { return $_[0] + 1 } );
is_deeply( $ar, [ 2, [ 3 ], { a => 4 } ], 'ar_traverse_vals()' );

is_deeply( [ list_uniq( qw( a b a c b ) ) ], [ qw( a b c ) ], 'list_uniq() keeps first occurrence order' );

is( perl_package_to_file( 'Data::Tools::CSV' ), 'Data/Tools/CSV.pm', 'perl_package_to_file()' );

##############################################################################
# digests
##############################################################################

is( md5_hex( 'abc' ),  '900150983cd24fb0d6963f7d28e17f72', 'md5_hex()' );
is( sha1_hex( 'abc' ), 'a9993e364706816aba3e25717850c26c9cd0d89d', 'sha1_hex()' );
is( length( wp_hex( 'abc' ) ), 128, 'wp_hex() returns 512 bit digest' );

file_save( "$TMP/dig.txt", 'abc' );
is( md5_hex_file(  "$TMP/dig.txt" ), md5_hex( 'abc' ),  'md5_hex_file()' );
is( sha1_hex_file( "$TMP/dig.txt" ), sha1_hex( 'abc' ), 'sha1_hex_file()' );
is( wp_hex_file(   "$TMP/dig.txt" ), wp_hex( 'abc' ),   'wp_hex_file()' );
is( md5_hex_file( "$TMP/no-such-file" ), undef, 'md5_hex_file() undef for missing file' );

##############################################################################
# random data
##############################################################################

is( length( create_random_id( 20 ) ),  20, 'create_random_id() honours length' );
is( length( create_random_id() ),     128, 'create_random_id() defaults to 128' );
like( create_random_id( 32, 'ab' ), qr/^[ab]{32}$/, 'create_random_id() honours letter set' );
is( length( create_random_binary( 20 ) ), 20, 'create_random_binary() honours length' );
isnt( create_random_id( 64 ), create_random_id( 64 ), 'create_random_id() is not constant' );

##############################################################################
# freeze/thaw
##############################################################################

my $data = { a => 1, b => [ 1, 2 ], c => { d => 'x' } };
is_deeply( ref_thaw( ref_freeze( $data ) ), $data, 'ref_freeze()/ref_thaw() round trip' );
eval { ref_freeze( 'not a reference' ) };
ok( $@, 'ref_freeze() dies on non-reference' );

##############################################################################
# numbers
##############################################################################

is( int2hex( 255 ), 'FF',  'int2hex()' );
is( hex2int( 'ff' ), 255,  'hex2int()' );
is( hex2int( int2hex( 4095 ) ), 4095, 'int2hex()/hex2int() round trip' );

is( bcd2int( pack( 'H*', '1234' ) ), 1234,   'bcd2int()' );
is( bcd2str( pack( 'H*', '1234' ) ), '1234', 'bcd2str()' );
is( bcd2str( pack( 'H*', '0012' ) ), '0012', 'bcd2str() keeps leading zeroes' );

is( unpack( 'H*', int2bcd( 1234 ) ),    '1234',     'int2bcd()' );
is( unpack( 'H*', int2bcd( 5 ) ),       '05',       'int2bcd() pads an odd digit count' );
is( unpack( 'H*', int2bcd( 0 ) ),       '00',       'int2bcd() zero' );
is( unpack( 'H*', int2bcd( 1234, 4 ) ), '00001234', 'int2bcd() pads to the given byte length' );
is( unpack( 'H*', int2bcd( '0012' ) ),  '12',       'int2bcd() ignores leading zeroes in the input' );
is( bcd2str( int2bcd( '99999999999999999999' ) ), '99999999999999999999',
    'int2bcd() converts numbers wider than an integer when given as a string' );

is( bcd2int( int2bcd( 987654 ) ),    987654, 'bcd2int()/int2bcd() round trip' );
is( bcd2int( int2bcd( 987654, 8 ) ), 987654, 'bcd2int()/int2bcd() round trip, padded' );
is_deeply( [ map { bcd2int( int2bcd( $_ ) ) } 0 .. 300 ], [ 0 .. 300 ],
           'int2bcd() round trips exactly over a range' );

eval { int2bcd( -5 ) };
like( $@, qr/non-negative integer/, 'int2bcd() rejects negative numbers' );
eval { int2bcd( 'abc' ) };
like( $@, qr/non-negative integer/, 'int2bcd() rejects non-numbers' );
eval { int2bcd( 12345, 2 ) };
like( $@, qr/needs more than/, 'int2bcd() rejects a number too wide for the given length' );
eval { int2bcd( 7, 0 ) };
like( $@, qr/positive byte length/, 'int2bcd() rejects a zero byte length' );

##############################################################################
# format_ascii_table()
##############################################################################

my $table = format_ascii_table( [ [ 'NAME', 'QTY' ], [ 'apple', 12 ], [ 'kiwi', 3 ] ] );
is( $table, <<'END', 'format_ascii_table() array of arrays' );
+-------------+
| NAME  | QTY |
+-------------+
| apple |  12 |
| kiwi  |   3 |
+-------------+
END

my $table_fmt = format_ascii_table( [ [ '|10', '>6' ], [ 'NAME', 'QTY' ], [ 'apple', 12 ] ], FMT => 1 );
is( $table_fmt, <<'END', 'format_ascii_table() with FMT row' );
+---------------------+
|    NAME    |    QTY |
+---------------------+
|   apple    |     12 |
+---------------------+
END

my $table_aoh = format_ascii_table( [ { n => 'a', q => 1 }, { n => 'b', q => 2 } ] );
is( $table_aoh, <<'END', 'format_ascii_table() array of hashes' );
+-------+
| n | q |
+-------+
| a | 1 |
| b | 2 |
+-------+
END

##############################################################################
# text io encoding
##############################################################################

eval { data_tools_set_text_io_utf8() };
ok( ! $@, 'data_tools_set_text_io_utf8()' );
eval { data_tools_set_text_io_bin() };
ok( ! $@, 'data_tools_set_text_io_bin()' );
eval { data_tools_set_text_io_encoding( 'bad encoding name!' ) };
ok( $@, 'data_tools_set_text_io_encoding() rejects invalid encoding name' );
data_tools_set_text_io_bin();

##############################################################################

done_testing();
