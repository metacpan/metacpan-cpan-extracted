requires 'perl' => '5.016000';
requires 'Moose';
requires 'MooseX::StrictConstructor';
requires 'MooseX::SlurpyConstructor';
requires 'JSON';
requires 'YAML::PP', '>= 0.015';
requires 'Module::Runtime';
requires 'Module::Find';

on test => sub {
  requires 'JSON::MaybeXS';
  requires 'Data::Printer';
  requires 'File::Slurp';
  requires 'Test::More';
  requires 'Test::Exception';
  requires 'FindBin';
  requires 'IO::Dir';
  requires 'File::Slurp';
  requires 'Test::Pod';
};

on develop => sub {
  requires 'MooseX::Types::Path::Class';
  requires 'MooseX::DataModel';
  requires 'JSON::MaybeXS';
  requires 'Sort::Topological';
  requires 'Template';
  requires 'Mojo::UserAgent';
  requires 'IO::Socket::SSL';
};
