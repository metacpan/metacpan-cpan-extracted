use inc::Module::Install;

my $iswindows = 0;
$iswindows = 1 if $^O =~ /win32/i;

name           'Archive-Rar';
all_from       'lib/Archive/Rar.pm';

requires       'Data::Dumper'     => '0';
requires       'IPC::Cmd'         => '0';
requires       'IPC::Run'         => '0';

if ($iswindows) {
    requires 'Win32::Registry'    => '0';
}

build_requires 'Test::Simple'     => '0';
build_requires 'Test::More'       => '0';

if (not $iswindows) {
  requires_external_bin 'rar';
} else {
  warn "We cannot check at this time that there is a 'rar' command when running on Windows. Please make sure that you have RAR or WinRAR installed before proceeding.";
}

WriteAll;
