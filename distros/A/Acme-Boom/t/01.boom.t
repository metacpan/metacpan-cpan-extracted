$SIG{BUS} = $SIG{SEGV} = sub {
  print "1..1\nok 1\n";
  exit 0;
};
eval q{ use Acme::Boom };
$" = qq{\n# };
print STDERR "# $@\n";
die FAIL;
