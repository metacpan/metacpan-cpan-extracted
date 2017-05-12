requires 'perl', '5.008001';
requires 'Carp';
requires 'Data::Dump';
requires 'Encode';
requires 'Exporter::Tiny';
requires 'File::Temp';
requires 'IO::Handle';
requires 'JSON::XS';
requires 'Sys::Cmd';
requires 'Try::Tiny';

on 'configure' => sub {
  requires 'Module::Build';
  requires 'Module::Build::Pluggable';
  requires 'Module::Build::Pluggable::CPANfile';
};

on 'test' => sub {
  requires 'File::Basename';
  requires 'File::Which';
  requires 'Test::More';
};

on 'develop' => sub {
  requires 'Reply';
  requires 'Term::ReadLine::Gnu';
  requires 'Test::Pod';
  requires 'Test::Spelling';
};
