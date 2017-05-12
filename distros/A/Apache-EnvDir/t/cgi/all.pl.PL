use CGI;

my $q = new CGI;

print $q->header("text/plain");

foreach my $var (sort keys %ENV) {
  printf "%s:%s\n", $var, $ENV{$var};
}
