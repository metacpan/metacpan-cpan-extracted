use CGI;
my $q = new CGI;
print $q->header("text/plain");

if(defined $ENV{$q->param("env")}) {
  # printf STDERR "looking up %s=%s\n", $q->param("env"),
  #                                     $ENV{$q->param("env")};
  print $ENV{$q->param("env")};
} else {
  print "undefined";
}
