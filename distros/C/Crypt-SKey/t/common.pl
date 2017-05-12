sub have_module {
  my $module = shift;
  return eval "use $module; 1";
}

sub need_module {
  my $module = shift;
  skip_test("$module not installed") unless have_module($module);
}

sub skip_test {
  my $msg = @_ ? shift() : '';
  print "1..0 # Skipped: $msg\n";
  exit;
}
1;
