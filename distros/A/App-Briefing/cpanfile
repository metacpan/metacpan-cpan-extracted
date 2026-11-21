requires 'perl', '5.020';

requires 'B';
requires 'Carp';
requires 'Encode';
requires 'JSON::MaybeXS';
requires 'Moo';
requires 'namespace::clean';
requires 'Path::Tiny';
requires 'TOML::Tiny::Parser', '0.22';

if ($^O eq 'MSWin32') {
  requires 'Win32';
  requires 'Win32::LongPath';
}

on configure => sub {
  requires 'Module::CPANfile', '1.1004';
};

on test => sub {
  requires 'Cwd';
  requires 'Exporter';
  requires 'File::Temp';
  requires 'FindBin';
  requires 'IPC::Open3';
  requires 'Symbol';
  requires 'Test::More';
};
