#!perl

print "1..2\n";

require 5.004;
print "ok\n";

eval {
  eval { require Apache::Filter; };
  
  exit 0 if $@;
  die "\n\n\tI see you have Apache::Filter installed...
\tIn order to use this version of Apache::SimpleReplace with
\tApache::Filter you need to upgrade to Apache::Filter 1.013 or better.\n\n"
     if $Apache::Filter::VERSION < 1.013;
};

warn $@ if $@;
print "ok\n";

exit 0;
