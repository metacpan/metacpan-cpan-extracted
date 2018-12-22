use strict;
use warnings;
use Test::More;
use Cwd;
use FFI;
use FFI::Library;

plan skip_all => 'Test requires Windows'
  unless $^O =~ /^(MSWin32|cygwin)$/;

plan tests => 10;

my $kernel32 = FFI::Library->new("kernel32");
my $user32   = FFI::Library->new("user32");

ok $kernel32, 'FFI::Library.new(kernel32)';
ok $user32, 'FFI::Library.new(user32)';

my $GetCurrentDirectory = $kernel32->function('GetCurrentDirectoryA', 'sIIp');
my $GetWindowsDirectory = $kernel32->function('GetWindowsDirectoryA', 'sIpI');
my $GetModuleHandle     = $kernel32->function('GetModuleHandleA', 'sII');
my $GetModuleFileName   = $kernel32->function('GetModuleFileNameA', 'sIIpI');

ok $GetCurrentDirectory, 'function GetCurrentDirectoryA';
ok $GetWindowsDirectory, 'function GetWindowsDirectoryA';
ok $GetModuleHandle,     'function GetModuleHandleA';
ok $GetModuleFileName,   'function GetModuleFileNameA';


my $d = ' ' x 200;
my $n = $GetCurrentDirectory->(200, $d);
$d = substr($d, 0, $n);

(my $cwd = cwd) =~ s#/#\\#g;
$cwd = Win32::GetCwd() if $^O eq "cygwin";
is $d, $cwd, "\$d=$cwd";

$d = ' ' x 200;
$n = $GetWindowsDirectory->($d, 200);
$d = substr($d, 0, $n);

ok -d $d, "-d \$d";

my $h = $GetModuleHandle->(0);
ok $h, 'GetModuleHandle';

SKIP: {
  skip "cygwin", 1 if $^O eq 'cygwin';

  $d = ' ' x 200;
  $n = $GetModuleFileName->($h, $d, 200);
  $d = substr($d, 0, $n);
  my $exp = $^O eq "MSWin32" ? $^X : Cygwin::posix_to_win_path($^X);
  like $d, qr{^\Q$exp\E(\.exe)?$}, "\$ like ^$exp";
};
