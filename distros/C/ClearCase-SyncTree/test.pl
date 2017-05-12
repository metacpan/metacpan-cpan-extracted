# Automatically generates an ok/nok msg, incrementing the test number.
BEGIN {
   my($next, @msgs);
   sub printok {
      push @msgs, ($_[0] ? '' : 'not ') . "ok @{[++$next]}\n";
      return !$_[0];
   }
   END {
      print "\n1..", scalar @msgs, "\n", @msgs;
   }
}

my $final = 0;

open(STDERR, ">&STDOUT");

use ClearCase::SyncTree;
$final += printok(1);

print <<EOF;

It's impractical to do real tests at install time since (a) a great
deal depends on your local view/VOB configuration and (b) testing would
make permanent changes to a local VOB. So we just test that it loads.
EOF

exit $final;
