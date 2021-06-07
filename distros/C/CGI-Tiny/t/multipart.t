use strict;
use warnings;
use utf8;
use CGI::Tiny::Multipart qw(extract_multipart_boundary parse_multipart_form_data);
use Encode 'encode';
use Test::More;

subtest 'extract_multipart_boundary' => sub {
  is extract_multipart_boundary('multipart/form-data; boundary=---'), '---', 'simple boundary';
  is extract_multipart_boundary('multipart/form-data; boundary=---; foo=bar'), '---', 'simple boundary with following attributes';
  is extract_multipart_boundary('multipart/form-data; boundary="---"'), '---', 'quoted boundary';
  is extract_multipart_boundary('multipart/form-data; boundary="---"; foo="bar"'), '---', 'quoted boundary with following attributes';
  is extract_multipart_boundary('multipart/form-data; boundary="; ;"'), '; ;', 'semicolon boundary';
  is extract_multipart_boundary('multipart/form-data; boundary="a \\\\b \\"; c"'), 'a \b "; c', 'boundary with escapes';
  is extract_multipart_boundary('multipart/form-data'), undef, 'missing boundary';
  is extract_multipart_boundary('multipart/form-data; boundary'), undef, 'missing boundary';
  is extract_multipart_boundary('multipart/form-data; boundary='), undef, 'missing boundary';
  is extract_multipart_boundary('multipart/form-data; boundary=""'), undef, 'missing boundary';
};

my $utf8_snowman = encode 'UTF-8', '☃';
my $utf16le_snowman = encode 'UTF-16LE', "☃...\n";
my $multipart_form = <<"EOB";
preamble\r
--delimiter\r
Content-Disposition: form-data; name="snowman"\r
\r
$utf8_snowman!\r
--delimiter\r
Content-Disposition: form-data; name=snowman\r
Content-Type: text/plain;charset=UTF-16LE\r
\r
$utf16le_snowman\r
--delimiter\r
Content-Disposition: form-data; name="newline\\\\\\""\r
\r

\r
--delimiter\r
Content-Disposition: form-data; name="empty"\r
\r
--delimiter\r
Content-Disposition: form-data; name="empty"\r
\r
\r
--delimiter\r
Content-Disposition: form-data; name="file"; filename="test.dat"\r
Content-Type: application/octet-stream\r
\r
00000000
11111111\0\r
--delimiter\r
Content-Disposition: form-data; name="file"; filename="test2.dat"\r
Content-Type: application/json\r
\r
{"test":42}\r
--delimiter\r
Content-Disposition: form-data; name="snowman"; filename="snowman\\\\\\".txt"\r
Content-Type: text/plain;charset=UTF-16LE\r
\r
$utf16le_snowman\r
--delimiter--\r
postamble
EOB

subtest 'parse_multipart_form_data' => sub {
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter');

  my @files;
  foreach my $i (0..$#$parts) {
    $files[$i] = delete $parts->[$i]{file};
    if (defined $files[$i]) {
      $parts->[$i]{file_contents} = do { local $/; readline $files[$i] };
    }
  }
  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, file_contents => "00000000\n11111111\0"},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, file_contents => '{"test":42}'},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), file_contents => $utf16le_snowman},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (small buffer)' => sub {
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {buffer_size => 5});

  my @files;
  foreach my $i (0..$#$parts) {
    $files[$i] = delete $parts->[$i]{file};
    if (defined $files[$i]) {
      $parts->[$i]{file_contents} = do { local $/; readline $files[$i] };
    }
  }
  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, file_contents => "00000000\n11111111\0"},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, file_contents => '{"test":42}'},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), file_contents => $utf16le_snowman},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (restricted length)' => sub {
  is parse_multipart_form_data(\$multipart_form, 10, 'delimiter'), undef, 'malformed form data';
};

subtest 'parse_multipart_form_data from filehandle' => sub {
  my $input = File::Temp->new;
  binmode $input;
  print $input $multipart_form;
  $input->flush;
  seek $input, 0, 0;
  my $parts = parse_multipart_form_data($input, length($multipart_form), 'delimiter');

  my @files;
  foreach my $i (0..$#$parts) {
    $files[$i] = delete $parts->[$i]{file};
    if (defined $files[$i]) {
      $parts->[$i]{file_contents} = do { local $/; readline $files[$i] };
    }
  }
  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, file_contents => "00000000\n11111111\0"},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, file_contents => '{"test":42}'},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), file_contents => $utf16le_snowman},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data from filehandle (restricted length)' => sub {
  my $input = File::Temp->new;
  binmode $input;
  print $input $multipart_form;
  $input->flush;
  seek $input, 0, 0;
  is parse_multipart_form_data($input, 10, 'delimiter'), undef, 'malformed form data';
};

subtest 'parse_multipart_form_data (discard files)' => sub {
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {discard_files => 1});

  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman)},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (parse all as files)' => sub {
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {parse_as_files => 1});

  my @files;
  foreach my $i (0..$#$parts) {
    $files[$i] = delete $parts->[$i]{file};
    if (defined $files[$i]) {
      $parts->[$i]{file_contents} = do { local $/; readline $files[$i] };
    }
  }
  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, file_contents => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), file_contents => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, file_contents => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, file_contents => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, file_contents => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, file_contents => "00000000\n11111111\0"},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, file_contents => '{"test":42}'},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), file_contents => $utf16le_snowman},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (parse none as files)' => sub {
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {parse_as_files => 0});

  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, content => "00000000\n11111111\0"},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, content => '{"test":42}'},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), content => $utf16le_snowman},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (parse all as files, discard files)' => sub {
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {parse_as_files => 1, discard_files => 1});

  my @files;
  foreach my $i (0..$#$parts) {
    $files[$i] = delete $parts->[$i]{file};
    if (defined $files[$i]) {
      $parts->[$i]{file_contents} = do { local $/; readline $files[$i] };
    }
  }
  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, file_contents => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), file_contents => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, file_contents => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, file_contents => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, file_contents => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman)},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (parse none as files, discard files)' => sub {
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {parse_as_files => 0, discard_files => 1});

  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman)},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (custom file parsing)' => sub {
  my $on_file_buffer = sub {
    my ($buffer, $part, $eof) = @_;
    $part->{file_contents} = '' unless defined $part->{file_contents};
    $part->{file_contents} .= $buffer;
    $part->{eof}++ if $eof;
  };
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {on_file_buffer => $on_file_buffer});

  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, file_contents => "00000000\n11111111\0", eof => 1},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, file_contents => '{"test":42}', eof => 1},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), file_contents => $utf16le_snowman, eof => 1},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (custom file parsing, parse all as files)' => sub {
  my $on_file_buffer = sub {
    my ($buffer, $part, $eof) = @_;
    $part->{file_contents} = '' unless defined $part->{file_contents};
    $part->{file_contents} .= $buffer;
    $part->{eof}++ if $eof;
  };
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {on_file_buffer => $on_file_buffer, parse_as_files => 1});

  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, file_contents => "$utf8_snowman!", eof => 1},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), file_contents => $utf16le_snowman, eof => 1},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, file_contents => "\n", eof => 1},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, file_contents => '', eof => 1},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, file_contents => '', eof => 1},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, file_contents => "00000000\n11111111\0", eof => 1},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, file_contents => '{"test":42}', eof => 1},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), file_contents => $utf16le_snowman, eof => 1},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (custom file parsing, parse none as files)' => sub {
  my $on_file_buffer = sub {
    my ($buffer, $part, $eof) = @_;
    $part->{file_contents} = '' unless defined $part->{file_contents};
    $part->{file_contents} .= $buffer;
    $part->{eof}++ if $eof;
  };
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {on_file_buffer => $on_file_buffer, parse_as_files => 0});

  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18, content => "00000000\n11111111\0"},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11, content => '{"test":42}'},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman), content => $utf16le_snowman},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (custom file parsing, discard files)' => sub {
  my $on_file_buffer = sub {
    my ($buffer, $part, $eof) = @_;
    $part->{file_contents} = '' unless defined $part->{file_contents};
    $part->{file_contents} .= $buffer;
    $part->{eof}++ if $eof;
  };
  my $parts = parse_multipart_form_data(\$multipart_form, length($multipart_form), 'delimiter', {on_file_buffer => $on_file_buffer, discard_files => 1});

  is_deeply $parts, [
    {headers => {'content-disposition' => 'form-data; name="snowman"'},
      name => 'snowman', filename => undef, size => length($utf8_snowman) + 1, content => "$utf8_snowman!"},
    {headers => {'content-disposition' => 'form-data; name=snowman', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => undef, size => length($utf16le_snowman), content => $utf16le_snowman},
    {headers => {'content-disposition' => 'form-data; name="newline\\\\\\""'},
      name => 'newline\"', filename => undef, size => 1, content => "\n"},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="empty"'},
      name => 'empty', filename => undef, size => 0, content => ''},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test.dat"', 'content-type' => 'application/octet-stream'},
      name => 'file', filename => 'test.dat', size => 18},
    {headers => {'content-disposition' => 'form-data; name="file"; filename="test2.dat"', 'content-type' => 'application/json'},
      name => 'file', filename => 'test2.dat', size => 11},
    {headers => {'content-disposition' => 'form-data; name="snowman"; filename="snowman\\\\\\".txt"', 'content-type' => 'text/plain;charset=UTF-16LE'},
      name => 'snowman', filename => 'snowman\".txt', size => length($utf16le_snowman)},
  ], 'right multipart form data';
};

subtest 'parse_multipart_form_data (tempfile args)' => sub {
  my $body_string = <<"EOB";
-----\r
Content-Disposition: form-data; name="file"; filename="test.dat"\r
Content-Type: application/octet-stream\r
\r
00000000
11111111\0\r
-------\r
EOB
  my $parts = parse_multipart_form_data(\$body_string, length($body_string), '---', {tempfile_args => [SUFFIX => '.tmp']});
  is scalar(@$parts), 1, 'one form field';
  like "$parts->[0]{file}", qr/\.tmp\z/, 'right tempfile extension';
};

subtest 'parse_multipart_form_data (empty)' => sub {
  my $body_string = <<"EOB";
preamble\r
\r
-------\r
\r
postamble\r
-----\r
Content-Disposition: should-be-ignored\r
\r
\r
-------\r
EOB
  is_deeply parse_multipart_form_data(\$body_string, length($body_string), '---'), [], 'empty multipart form data';
};

subtest 'parse_multipart_form_body (malformed)' => sub {
  my $body_string = <<"EOB";
--fribble\r
not a header\r
\r
--fribble--\r
EOB
  is parse_multipart_form_data(\$body_string, length($body_string), 'fribble'), undef, 'malformed multipart form data';
};

subtest 'parse_multipart_form_body (unterminated)' => sub {
  my $body_string = <<"EOB";
--fribble\r
\r
\r
--fribble\r
EOB
  is parse_multipart_form_data(\$body_string, length($body_string), 'fribble'), undef, 'unterminated multipart form data';
};

done_testing;
