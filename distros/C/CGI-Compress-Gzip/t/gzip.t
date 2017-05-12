#!/usr/bin/perl -w  ## no critic (ProhibitExcessMainComplexity)

## no critic (ProhibitBacktickOperators)
## no critic (ProhibitCommentedOutCode)
## no critic (ProhibitQuotedWordLists)
## no critic (ProhibitLocalVars)

use 5.006;
use strict;
use warnings;
use File::Temp qw(tempfile);
use IO::Zlib;
use Compress::Zlib;
use English qw(-no_match_vars);

BEGIN
{
   use Test::More tests => 44;
   use_ok('CGI::Compress::Gzip');
}

# This module behaves differently whether autoflush is on or off
# Make sure it is off
$OUTPUT_AUTOFLUSH = 0;

my $compare = 'Hello World!';  # expected output

# Have to use a temp file since Compress::Zlib doesn't like IO::String
my ($testfh, $testfile) = tempfile(UNLINK => 1);
close $testfh or die;

## Zlib sanity tests

my $zcompare = Compress::Zlib::memGzip($compare);
my $testbuf = $zcompare;
$testbuf = Compress::Zlib::memGunzip($testbuf);
is ($testbuf, $compare, 'Compress::Zlib double-check');

{
   ## no critic (ProhibitBarewordFileHandles,RequireInitializationForLocalVars)
   local *OUT_FILE;
   open OUT_FILE, '>', $testfile or die 'Cannot write a temp file';
   binmode OUT_FILE;
   local *STDOUT = *OUT_FILE;
   my $fh = IO::Zlib->new(\*OUT_FILE, 'wb') or die;
   print {$fh} $compare;
   close $fh or die;
   close OUT_FILE ## no critic (RequireCheckedClose,RequireCheckedSyscalls)
       and diag('Unexpected success closing already closed filehandle');

   my $in_fh;
   open $in_fh, '<', $testfile or die 'Cannot read temp file';
   binmode $in_fh;
   local $INPUT_RECORD_SEPARATOR = undef;
   my $out = <$in_fh>;
   close $in_fh or die;
   is($out, $zcompare, 'IO::Zlib test');
}

## Header tests

{
   my $dummy = CGI::Compress::Gzip->new();

   ok(!$dummy->isCompressibleType(), 'compressible types');
   ok($dummy->isCompressibleType('text/html'), 'compressible types');
   ok($dummy->isCompressibleType('text/plain'), 'compressible types');
   ok(!$dummy->isCompressibleType('image/jpg'), 'compressible types');
   ok(!$dummy->isCompressibleType('application/octet-stream'), 'compressible types');

   {
      local $ENV{HTTP_ACCEPT_ENCODING} = q{};
      my @headers;
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers], [0, []], 'header test - env');
   }

   {
      local $ENV{HTTP_ACCEPT_ENCODING} = 'bzip2';
      my @headers;
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers], [0, []], 'header test - env');
   }

   # For the rest of the tests, pretend browser told us to turn on gzip
   local $ENV{HTTP_ACCEPT_ENCODING} = 'gzip';

   {
      my @headers;
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers], [1, ['-Content_Encoding', 'gzip']], 'header test - env');
   }

   {
      local $CGI::Compress::Gzip::global_give_reason = 1;
      my @headers;
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers], [1, ['-Content_Encoding', 'gzip']], 'header test - reason');
   }

   # Turn off compression
   CGI::Compress::Gzip->useCompression(0);
   {
      my @headers;
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers], [0, []], 'header test - override');
   }
   CGI::Compress::Gzip->useCompression(1);

   # Turn off compression
   $dummy->useCompression(0);
   {
      my @headers;
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers], [0, []], 'header test - override');
   }
   $dummy->useCompression(1);

   {
      local $OUTPUT_AUTOFLUSH = 1;
      my @headers;
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers], [0, []], 'header test - autoflush');
   }

   {
      my @headers = ('text/plain');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['-Content_Type', 'text/plain', '-Content_Encoding', 'gzip']],
                'header test - type');
   }

   {
      my @headers = ('-Content_Type', 'text/plain');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['-Content_Type', 'text/plain', '-Content_Encoding', 'gzip']],
                'header test - type');
   }

   {
      my @headers = ('Content_Type', 'text/plain');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['Content_Type', 'text/plain', '-Content_Encoding', 'gzip']],
                'header test - type');
   }

   {
      my @headers = ('-type', 'text/plain');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['-type', 'text/plain', '-Content_Encoding', 'gzip']],
                'header test - type');
   }

   {
      my @headers = ('Content_Type: text/plain');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['Content_Type: text/plain', '-Content_Encoding', 'gzip']],
                'header test - type');
   }

   {
      my @headers = ('Content_Type: image/gif');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [0, ['Content_Type: image/gif']],
                'header test - type');
   }

   {
      my @headers = ('-Content_Encoding', 'foo');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['-Content_Encoding', 'gzip, foo']],
                'header test - encoding');
   }

   {
      my @headers = ('-Content_Encoding', 'gzip');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [0, ['-Content_Encoding', 'gzip']],
                'header test - encoding');
   }

   {
      my @headers = ('Content-Encoding: foo');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['Content-Encoding: gzip, foo']],
                'header test - encoding');
   }

   {
      my @headers = ('-Status', '200');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['-Status', '200', '-Content_Encoding', 'gzip']],
                'header test - status');
   }

   {
      my @headers = ('Status: 200');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['Status: 200', '-Content_Encoding', 'gzip']],
                'header test - status');
   }

   {
      my @headers = ('Status: 200 OK');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['Status: 200 OK', '-Content_Encoding', 'gzip']],
                'header test - status');
   }

   {
      my @headers = ('Status: 500');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [0, ['Status: 500']],
                'header test - status');
   }

   {
      my @headers = ('-Status', 'junk');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [0, ['-Status', 'junk']],
                'header test - status');
   }

   {
      my @headers = ('Status: junk');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [0, ['Status: junk']],
                'header test - status');
   }

   {
      my @headers = ('-Irrelevent', '1');
      my ($compress, $reason) = $dummy->_can_compress(\@headers);
      is_deeply([$compress, \@headers],
                [1, ['-Irrelevent', '1', '-Content_Encoding', 'gzip']],
                'header test - other');
   }
}

## Tests that are as real-life as we can manage

# Older versions of this test used to set
#     local $ENV{HTTP_ACCEPT_ENCODING} = 'gzip'
# and expected subshells to propagate that value.  I had thought that
# caused some smoke environments to fail, so I switched to passing
# that value as a cmdline argument.  It turns out I was wrong (it was
# $| that caused the failures) but I left it anyway.

# Turn off compression
ok(CGI::Compress::Gzip->useCompression(0), 'Turn off compression');

my $eol = "\015\012"; ## no critic (ProhibitEscapedCharacters)

my $redir = 'http://www.foo.com/';

my $interp = "$^X -Iblib/arch -Iblib/lib";
if (defined $Devel::Cover::VERSION) {
   $interp .= ' -MDevel::Cover';
}
my $basecmd = "$interp t/testhelp";

# Get CGI header for comparison in basic case
my $compareheader = CGI->new(q{})->header();

my $gzip = 'Content-Encoding: gzip' . $eol;


# no compression
{
   my $reason = 'x-non-gzip-reason: user agent does not want gzip' . $eol;
   my $out = `$basecmd simple "$compare"`;
   msgs_match($out, $reason . $compareheader . $compare, 'CGI template');
}

# no body
{
   my $zempty = Compress::Zlib::memGzip(q{});

   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip empty "$compare"`;
   msgs_match($out, $gzip . $compareheader . $zempty, 'no body');
}

# CGI and compression
{
   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip simple "$compare"`;
   msgs_match($out, $gzip . $compareheader.$zcompare, 'Gzipped CGI template');
}

# CGI with charset and compression
{
   my $header = CGI->new(q{})->header(-Content_Type => 'text/html; charset=UTF-8');

   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip charset "$compare"`;
   msgs_match($out, $gzip . $header . $zcompare, 'Gzipped CGI template with charset');
}

# CGI with arguments
{
   my $reason = 'x-non-gzip-reason: incompatible content-type foo/bar' . $eol;
   my $header = CGI->new(q{})->header(-Type => 'foo/bar');

   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip type "$compare"`;
   msgs_match($out, $reason . $header.$compare, 'Un-Gzipped with -Type flag');
}

# CGI redirection and compression
{
   my $reason = 'x-non-gzip-reason: HTTP status not 200' . $eol;
   my $expected_header = CGI->new(q{})->redirect($redir);

   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip redirect "$redir"`;
   msgs_match($out, $reason . $expected_header, 'CGI redirect');
}

# unbuffered CGI
{
   my $reason = 'x-non-gzip-reason: user agent does not want gzip' . $eol;
   my $out = `$basecmd simple "$compare"`;
   msgs_match($out, $reason . $compareheader.$compare, 'unbuffered CGI');
}

# Simulated mod_perl
{
   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip mod_perl "$compare"`;
   msgs_match($out, $gzip . $compareheader . $zcompare, 'mod_perl simulation');
}

# Double print header
{
   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip doublehead "$compare"`;
   msgs_match($out, $gzip . $compareheader . $zcompare, 'double header');
}

# redirected filehandle
{
   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip fh1 "$compare"`;
   msgs_match($out, $gzip . $compareheader . $zcompare, 'filehandle, fh=STDOUT plus select');
}

# redirected filehandle
{
   local $TODO = 'Explicit use of filehandles not yet supported';

   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip fh2 "$compare"`;
   msgs_match($out, $gzip . $compareheader . $zcompare, 'filehandle, explict STDOUT');
}

# redirected filehandle
{
   local $TODO = 'Explicit use of filehandles not yet supported';

   my $out = `$basecmd -DHTTP_ACCEPT_ENCODING=gzip fh3 "$compare"`;
   msgs_match($out, $gzip . $compareheader . $zcompare, 'filehandle, explicit fh');
}

sub msgs_match {
   my ($got, $expected, $message) = @_;
   ## no critic (RegularExpressions::RequireLineBoundaryMatching)
   my ($got_head, $got_body) = split m/\015\012\015\012/xs, $got, 2;
   my ($exp_head, $exp_body) = split m/\015\012\015\012/xs, $expected, 2;
   my %exp = map {lc($_) => 1} split m/\015\012/xs, $exp_head;
   for my $got_head_line (split m/\015\012/xs, $got_head) {
      if (!delete $exp{lc $got_head_line}) {
         return is($got, $expected, $message . ' -- extra header: ' . $got_head_line); # fail
      }
   }
   if (scalar keys %exp) {
      return is($got, $expected, $message . ' -- missing header: ' . [keys %exp]->[0]); # fail
   }
   if ($got_body ne $exp_body) {
      return is($got, $expected, $message . ' -- bodies do not match'); # fail
   }
   return pass($message);
}
