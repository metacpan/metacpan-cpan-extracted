requires 'perl', '=>', '5.008';
requires 'Template::Tiny';

on 'configure' => sub {
  requires 'Module::Build::Pluggable';
  requires 'Module::Build::Pluggable::CPANfile';
};

on 'build' => sub {
  requires 'ExtUtils::CBuilder';
};

on 'test' => sub {
  requires 'Test::More';
  requires 'FindBin';
  requires 'Test::Differences';
  requires 'Test::Fake::HTTPD';
  requires 'Test::Exception';
  requires 'Test::Output';
};