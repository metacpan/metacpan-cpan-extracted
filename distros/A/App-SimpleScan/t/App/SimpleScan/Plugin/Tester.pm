package App::SimpleScan::Plugin::Tester;

sub options {
  # Test that the option handler unpacks this correctly.
  ['tester', \$tester];
}

sub pragmas {
  return [test, sub { 'test' } ];
}

sub test_modules {
  return ("Test::Demo");
}

sub per_test_code {
  return (qq(diag "test code inserted"));
}
1;
