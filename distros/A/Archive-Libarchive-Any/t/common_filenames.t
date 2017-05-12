use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );
use File::Temp qw( tempdir );
use File::Spec;

plan skip_all => 'requires archive_read_open_filenames' unless Archive::Libarchive::Any->can('archive_read_open_filenames');
plan tests => 8;

# ported test_splitted_file from test_archive_read_multiple_data_objects.c

my $r;

my @reffiles = (
  "test_read_splitted_rar_aa",
  "test_read_splitted_rar_ab",
  "test_read_splitted_rar_ac",
  "test_read_splitted_rar_ad",
);

my $dir = tempdir( CLEANUP => 1 );
chdir $dir;

extract();

my $a = archive_read_new();
ok $a, 'archive_read_new';

subtest 'Prep' => sub {
  plan tests => 3;
  $r = archive_read_support_filter_all($a);
  is $r, ARCHIVE_OK, 'archive_read_support_filter_all';
  $r = archive_read_support_format_all($a);
  is $r, ARCHIVE_OK, 'archive_read_support_format_all';
  $r = archive_read_open_filenames($a, \@reffiles, 10240);
  is $r, ARCHIVE_OK, 'archive_read_open_filenames';
};

# First header.
subtest 'First header.' => sub {
  plan tests => 9;
  $r = archive_read_next_header($a, my $ae);
  is $r, ARCHIVE_OK, 'archive_read_next_header';
  diag 'archive_error_string = ' . archive_error_string($a) if $r != ARCHIVE_OK;
  is archive_entry_pathname($ae), 'test.txt', 'archive_entry_pathname = test.txt';
  ok eval { archive_entry_mtime($ae) }, 'archive_entry_mtime';
  diag $@ if $@;
  ok eval { archive_entry_ctime($ae) }, 'archive_entry_ctime';
  diag $@ if $@;
  ok eval { archive_entry_atime($ae) }, 'archive_entry_atime';
  diag $@ if $@;
  is archive_entry_size($ae), 20, 'archive_entry_size = 20';
  is archive_entry_mode($ae), 33188, 'archive_entry_mode = 33188';
  my $br = archive_read_data($a, my $buff, 10224);
  is $br, archive_entry_size($ae), 'br = size';
  is $buff, "test text document\015\012", 'buff = test text document';
};

subtest 'Second header.' => sub {
  plan tests => 8;
  $r = archive_read_next_header($a, my $ae);
  is $r, ARCHIVE_OK, 'archive_read_next_header';
  diag 'archive_error_string = ' . archive_error_string($a) if $r != ARCHIVE_OK;
  is archive_entry_pathname($ae), 'testlink', 'archive_entry_pathname = testlink';
  ok eval { archive_entry_mtime($ae) }, 'archive_entry_mtime';
  diag $@ if $@;
  ok eval { archive_entry_ctime($ae) }, 'archive_entry_ctime';
  diag $@ if $@;
  ok eval { archive_entry_atime($ae) }, 'archive_entry_atime';
  diag $@ if $@;
  is archive_entry_size($ae), 0, 'archive_entry_size = 0';
  is archive_entry_mode($ae), 41471, 'archive_entry_mode = 41471';
  is archive_entry_symlink($ae), 'test.txt', 'archive_entry_symlink = test.txt';
};

subtest 'Third header.' => sub {
  plan tests => 9;
  $r = archive_read_next_header($a, my $ae);
  is $r, ARCHIVE_OK, 'archive_read_next_header';
  is archive_entry_pathname($ae), 'testdir/test.txt', 'archive_entry_pathname = testdir/test.txt';
  ok eval { archive_entry_mtime($ae) }, 'archive_entry_mtime';
  diag $@ if $@;
  ok eval { archive_entry_ctime($ae) }, 'archive_entry_ctime';
  diag $@ if $@;
  ok eval { archive_entry_atime($ae) }, 'archive_entry_atime';
  diag $@ if $@;
  is archive_entry_size($ae), 20, 'archive_entry_size = 20';
  is archive_entry_mode($ae), 33188, 'archive_entry_mode = 33188';
  my $br = archive_read_data($a, my $buff, 10224);
  is $br, archive_entry_size($ae), 'br = size';
  is $buff, "test text document\015\012", 'buff = test text document';      
};

subtest 'Fourth header.' => sub {
  plan tests => 7;
  $r = archive_read_next_header($a, my $ae);
  is $r, ARCHIVE_OK, 'archive_read_next_header';
  is archive_entry_pathname($ae), 'testdir', 'archive_entry_pathname = testdir';
  ok eval { archive_entry_mtime($ae) }, 'archive_entry_mtime';
  diag $@ if $@;
  ok eval { archive_entry_ctime($ae) }, 'archive_entry_ctime';
  diag $@ if $@;
  ok eval { archive_entry_atime($ae) }, 'archive_entry_atime';
  diag $@ if $@;
  is archive_entry_size($ae), 0, 'archive_entry_size = 0';
  is archive_entry_mode($ae), 16877, 'archive_entry_mode = 16877';  
};

subtest 'Fifth header.' => sub {
  plan tests => 7;
  $r = archive_read_next_header($a, my $ae);
  is $r, ARCHIVE_OK, 'archive_read_next_header';
  is archive_entry_pathname($ae), 'testemptydir', 'archive_entry_pathname = testemptydir';
  ok eval { archive_entry_mtime($ae) }, 'archive_entry_mtime';
  diag $@ if $@;
  ok eval { archive_entry_ctime($ae) }, 'archive_entry_ctime';
  diag $@ if $@;
  ok eval { archive_entry_atime($ae) }, 'archive_entry_atime';
  diag $@ if $@;
  is archive_entry_size($ae), 0, 'archive_entry_size = 0';
  is archive_entry_mode($ae), 16877, 'archive_entry_mode = 16877';
};

subtest 'Test EOF' => sub {
  plan tests => 4;
  $r = archive_read_next_header($a, my $ae);
  is $r, ARCHIVE_EOF, 'archive_read_next_header';
  is archive_file_count($a), 5, 'archive_file_count = 5';
  $r = archive_read_close($a);
  is $r, ARCHIVE_OK, 'archive_read_close';
  $r = archive_read_free($a);
  is $r, ARCHIVE_OK, 'archive_read_free';
};

chdir(File::Spec->rootdir);

sub extract
{
  while(!eof DATA)
  {
    my $filename = <DATA>;
    last unless defined $filename;
    chomp $filename;
    my $data = '';
    while(!eof DATA)
    {
      my $line = <DATA>;
      last if $line =~ /^::::/;
      $data .= unpack 'u', $line;
    }
    open my $fh, '>', $filename;
    binmode $fh;
    print $fh $data;
    close $fh;
  }
}

__DATA__
test_read_splitted_rar_aa
M4F%R(1H'`,^0<P``#0````````"$4G0@D#(`%````!0````#0J+(OK=VVCX4
M,`@`I($``'1E<W0N='AT@`BW=MH^MW;:/G1E<W0@=&5X="!D;V-U;65N=`T*
*G2]T()`R``@`````
::::::::::::::
test_read_splitted_rar_ab
M``@````#>T3)MM%,V#X4,`@`_Z$``'1E<W1L:6YKP`C13-@^4%_:/G1E<W0N
M='ATS>!T()`Z`!0````4`````T*BR+YC=]H^%#`0`*2!``!T97-T9&ER7'1E
*<W0N='ATP,QC=P``
::::::::::::::
test_read_splitted_rar_ac
MVCYC=]H^=&5S="!T97AT(&1O8W5M96YT#0JAR'3@D#$````````````#````
M`&-WVCX4,`<`[4$``'1E<W1D:7+`S&-WVCYD=]H^YN=TX)`V````````````
*`P````"=J]4^%```
::::::::::::::
test_read_splitted_rar_ad
D,`P`[4$``'1E<W1E;7!T>61I<H#,G:O5/L5=VC[$/7L`0`<`
::::::::::::::
