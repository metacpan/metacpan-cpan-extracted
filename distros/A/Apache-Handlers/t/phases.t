# $Id: phases.t,v 1.1 2002/01/07 15:29:27 jgsmith Exp $

BEGIN { print "1..12\n"; }

use Apache::Handlers qw: CHILDINIT TRANS HEADERPARSER ACCESS AUTHEN AUTHZ TYPE FIXUP CONTENT LOG CLEANUP CHILDEXIT run_phase :;

# load everything

BEGIN {

CHILDINIT {
  print "ok   1\n";
};

TRANS {
  print "ok   2\n";
};

HEADERPARSER {
  print "ok   3\n";
};

ACCESS {
  print "ok   4\n";
};

AUTHEN {
  print "ok   5\n";
};

AUTHZ {
  print "ok   6\n";
};

TYPE {
  print "ok   7\n";
};

FIXUP {
  print "ok   8\n";
};

CONTENT {
  print "ok   9\n";
};

LOG {
  print "ok   10\n";
};

CLEANUP {
  print "ok   11\n";
};

CHILDEXIT {
  print "ok   12\n";
};

}

# now expect everything to print in order

1;
