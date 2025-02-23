# https://metacpan.org/pod/distribution/Module-CPANfile/lib/cpanfile.pod

requires 'Data::Dumper::Concise';
requires 'Feature::Compat::Try';
requires 'Mojolicious';
requires 'Moo';
requires 'Moo::Role';
requires 'PerlX::Maybe';
requires 'strictures';
requires 'Types::Standard';

on test => sub {
    requires 'Test2::V0';

    requires 'Mojo::UserAgent::Mockable';
    requires 'Test2::Tools::Compare';
};

on 'develop' => sub {
  requires 'perl' => '5.026'; # postfix deref, hash slices, Test2, indented here-docs

  requires 'FindBin';
  requires 'Mojo::File';

  # these were missing when I tried to dzil test
  recommends 'Dist::Zilla::Plugin::MetaProvides::Package';
  recommends 'Dist::Zilla::Plugin::RPM';
  recommends 'Dist::Zilla::Plugin::Repository';
};
