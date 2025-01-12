requires 'perl' => '5.006';

on 'test' => sub {
  requires 'Test::More';
  requires 'Test::Number::Delta';
  requires 'Test2::V0';
};

on 'develop' => sub {
  requires 'perl' => '5.026'; # postfix deref, hash slices, Test2, indented here-docs
  requires 'Carp';
  requires 'Getopt::Long';
  requires 'XML::LibXML';

  recommends 'FindBin';
  recommends 'Module::Util';
  recommends 'Mojo::Template';
  recommends 'Pod::Elemental::Transformer::List';

  # these were missing when I tried to dzil test
  recommends 'Dist::Zilla::Plugin::MetaProvides::Package';
  recommends 'Dist::Zilla::Plugin::RPM';
  recommends 'Dist::Zilla::Plugin::Repository';
};

on 'configure' => sub {
  requires 'ExtUtils::MakeMaker';
};
