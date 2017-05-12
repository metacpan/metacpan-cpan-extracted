use autodie;
use warnings;
use strict;
use Test::More;
use DOCSIS::ConfigFile;
use constant HEXDUMP => -x '/usr/bin/hexdump';

# These two environment variables can be set before running this unittest:
# DOCSIS_INPUT_FILE=/path/to/file.bin
# KEEP_DOCSIS_FILES=$bool

plan skip_all => '"/usr/bin/diff" is not available'   unless -x '/usr/bin/diff';
plan skip_all => '"/usr/bin/docsis" is not available' unless -x '/usr/bin/docsis';

if (HEXDUMP) {
  plan tests => 11;
}
else {
  plan tests => 8;
  diag '/usr/bin/hexdump is missing. Will not dump binary files as hex';
}

mkdir 't/data' unless (-d 't/data/');
my $dc = DOCSIS::ConfigFile->new(advanced_output => 0, shared_secret => '');
my ($data_bin, $data_config, $new_bin);

ok($data_bin = generate_binary(), 'DATA is read');
ok(data_to_file($data_bin, 'data.bin'), 'DATA written to data.bin');
is(docsis('data.bin'), 0, 'docsis decoded data.bin => data.c');
is(hexdump('data.bin'), 0, 'data.bin dumped as data.hex') if HEXDUMP;
ok($data_config = $dc->decode(\$data_bin), 'DC decoded DATA');
data_to_file($data_config, 'data.json');
ok($new_bin = $dc->encode($data_config), 'DC encodede DATA back');
ok(data_to_file($new_bin, 'new.bin'), 'encoded DATA stored to new.bin');
is(hexdump('new.bin'), 0, 'new.bin dumped as new.hex') if HEXDUMP;

if (is(docsis('new.bin'), 0, 'docsis decoded new.bin => new.c')) {
  is(qx{diff -u t/data/data.c t/data/new.c}, '', 'no diff from docsis decoded output');
  is(qx{diff -u t/data/data.hex t/data/new.hex}, '', 'no diff from hexdump output') if HEXDUMP;
}
else {
  ok(0, 'cannot run diff without decoded binary');
  ok(0, 'cannot run diff without decoded binary');
}

unless ($ENV{'KEEP_DOCSIS_FILES'}) {
  unlink map {
    my $n = $_;
    map {"t/data/$n.$_"} qw/ bin hex c json /
  } qw/data new/;
  rmdir "t/data";
}

#=============================================================================

sub docsis {
  my ($in_file, $out_file) = @_[0, 0];
  $out_file =~ s/bin$/c/;
  my $out = qx{/usr/bin/docsis -d t/data/$_[0]};
  my $ret = $?;
  data_to_file($out, $out_file);
  return $ret >> 8;
}

sub hexdump {
  my ($in_file, $out_file) = @_[0, 0];
  $out_file =~ s/bin$/hex/;
  my $out = qx{/usr/bin/hexdump t/data/$in_file};
  my $ret = $?;
  data_to_file($out, $out_file);
  return $ret >> 8;
}

sub generate_binary {
  my $binary = '';

  if ($ENV{'DOCSIS_INPUT_FILE'}) {
    open my $FH, '<', $ENV{'DOCSIS_INPUT_FILE'};
    local $/;
    $binary = <$FH>;
  }
  else {
    $binary .= pack 'C*', map { hex $_ } split /\s/ while (<DATA>);
  }

  return $binary;
}

sub data_to_file {
  open my $NEW, '>', "t/data/$_[1]";
  binmode $NEW;

  if (ref $_[0]) {
    if (eval 'use JSON; 1') {
      print $NEW JSON->new->ascii->pretty->encode($_[0]);
    }
    else {
      diag 'JSON is missing. Will not dump config as JSON';
      return;
    }
  }
  else {
    print $NEW $_[0];
  }

  close $NEW;
}

__DATA__
03 01 01 12 01 03 18 23 01 02 00 01 06 01 07 07 01 03 08 04 00 10 1d 00 0a 04 00 00 00 00 0f 01 02
10 04 00 00 00 8a 17 02 00 00 19 16 01 02 00 02 06 01 07 07 01 03 08 04 00 9c bd 00 0a 04 00 00 00
00 1d 01 00 18 19 01 02 00 67 06 01 07 07 01 05 08 04 00 00 75 30 0a 04 00 00 27 10 0f 01 02 16 13
01 01 69 03 02 00 67 05 01 04 06 01 01 09 04 02 02 00 01 16 1b 01 01 6a 03 02 00 67 05 01 05 06 01
01 09 0c 02 02 00 11 07 02 00 a1 08 02 00 a1 19 16 01 02 00 68 06 01 07 07 01 05 08 04 00 00 75 30
0a 04 00 00 27 10 17 13 01 01 6b 03 02 00 68 05 01 02 06 01 01 09 04 02 02 00 01 17 1b 01 01 6c 03
02 00 68 05 01 03 06 01 01 09 0c 02 02 00 11 09 02 00 a1 0a 02 00 a1 18 23 01 02 00 65 06 01 07 07
01 07 08 04 00 01 86 a0 0e 02 05 f2 0a 04 00 00 27 10 10 04 00 00 00 06 0f 01 02 16 1b 01 01 65 03
02 00 65 05 01 01 06 01 01 09 0c 05 04 5e fb a1 3d 06 04 ff ff ff ff 16 14 01 01 66 03 02 00 65 05
01 02 06 01 01 0a 05 03 03 03 08 28 16 14 01 01 67 03 02 00 65 05 01 03 06 01 01 0a 05 03 03 01 08
06 19 1c 01 02 00 66 06 01 07 07 01 07 08 04 00 01 86 a0 09 04 00 00 05 f2 0a 04 00 00 27 10 17 1b
01 01 68 03 02 00 66 05 01 01 06 01 01 09 0c 03 04 5e fb a1 3d 04 04 ff ff ff ff 0b 15 30 13 06 0e
2b 06 01 04 01 8b 15 4d 01 06 01 01 08 01 02 01 02 0b 15 30 13 06 0e 2b 06 01 04 01 8b 15 4d 01 06
01 01 09 01 02 01 02 0b 18 30 16 06 0e 2b 06 01 04 01 8b 15 4d 01 06 01 01 07 01 40 04 0a 20 00 07
0b 12 30 10 06 0b 2b 06 01 04 01 8b 15 4e 01 02 00 02 01 01 0b 12 30 10 06 0b 2b 06 01 04 01 8b 15
4e 01 07 00 02 01 02 0b 14 30 12 06 0d 2b 06 01 04 01 8b 15 4e 01 87 69 01 00 02 01 01 0b 14 30 12
06 0d 2b 06 01 04 01 8b 15 4e 01 87 69 02 00 04 01 80 0b 1a 30 18 06 0d 2b 06 01 04 01 8b 15 4e 01
87 69 03 00 04 07 77 65 62 73 74 61 72 0b 1b 30 19 06 0d 2b 06 01 04 01 8b 15 4e 01 87 69 04 00 04
08 66 61 66 6b 75 6c 63 65 0b 13 30 11 06 0c 2b 06 01 04 01 8b 15 4d 01 04 07 00 02 01 02 0b 13 30
11 06 0c 2b 06 01 04 01 8b 15 4d 01 03 06 00 02 01 01 0b 13 30 11 06 0c 2b 06 01 04 01 8b 15 4d 01
04 0d 00 02 01 01 0b 12 30 10 06 0b 2b 06 01 02 01 45 01 02 01 07 01 02 01 04 0b 15 30 13 06 0b 2b
06 01 02 01 45 01 02 01 02 01 40 04 0a 20 00 00 0b 15 30 13 06 0b 2b 06 01 02 01 45 01 02 01 03 01
40 04 ff ff ff 80 0b 17 30 15 06 0b 2b 06 01 02 01 45 01 02 01 04 01 04 06 70 75 62 6c 69 63 0b 12
30 10 06 0b 2b 06 01 02 01 45 01 02 01 05 01 02 01 02 0b 12 30 10 06 0b 2b 06 01 02 01 45 01 02 01
06 01 04 01 40 0b 12 30 10 06 0b 2b 06 01 02 01 45 01 02 01 07 02 02 01 04 0b 15 30 13 06 0b 2b 06
01 02 01 45 01 02 01 02 02 40 04 0a 20 00 00 0b 15 30 13 06 0b 2b 06 01 02 01 45 01 02 01 03 02 40
04 ff ff ff 80 0b 18 30 16 06 0b 2b 06 01 02 01 45 01 02 01 04 02 04 07 70 72 69 76 61 74 65 0b 12
30 10 06 0b 2b 06 01 02 01 45 01 02 01 05 02 02 01 03 0b 12 30 10 06 0b 2b 06 01 02 01 45 01 02 01
06 02 04 01 40 0b 12 30 10 06 0b 2b 06 01 02 01 45 01 02 01 07 03 02 01 04 0b 15 30 13 06 0b 2b 06
01 02 01 45 01 02 01 02 03 40 04 c0 a8 c0 ec 0b 15 30 13 06 0b 2b 06 01 02 01 45 01 02 01 03 03 40
04 ff ff ff 00 0b 21 30 1f 06 0b 2b 06 01 02 01 45 01 02 01 04 03 04 10 6d 65 64 32 76 65 76 31 69
62 37 77 6f 6b 39 61 0b 12 30 10 06 0b 2b 06 01 02 01 45 01 02 01 05 03 02 01 03 0b 12 30 10 06 0b
2b 06 01 02 01 45 01 02 01 06 03 04 01 40 0b 11 30 0f 06 0a 2b 06 01 02 01 45 01 06 03 00 02 01 02
0b 13 30 11 06 0c 2b 06 01 02 01 45 01 06 04 01 02 01 02 01 04 0b 13 30 11 06 0c 2b 06 01 02 01 45
01 06 04 01 03 01 02 01 01 0b 13 30 11 06 0c 2b 06 01 02 01 45 01 06 04 01 04 01 02 01 01 0b 13 30
11 06 0c 2b 06 01 02 01 45 01 06 04 01 05 01 02 01 03 0b 13 30 11 06 0c 2b 06 01 02 01 45 01 06 04
01 06 01 02 01 02 0b 14 30 12 06 0c 2b 06 01 02 01 45 01 06 04 01 0b 01 02 02 01 00 0b 16 30 14 06
0c 2b 06 01 02 01 45 01 06 04 01 09 01 40 04 e0 00 00 00 0b 16 30 14 06 0c 2b 06 01 02 01 45 01 06
04 01 0a 01 40 04 ff ff ff 00 06 10 66 44 37 a0 f1 0f f2 12 81 a1 2f 9b 80 6a ef 07 07 10 60 07 75
a0 ba 71 e9 a0 97 b6 99 f0 09 c6 9b f4 ff 00 00 00
