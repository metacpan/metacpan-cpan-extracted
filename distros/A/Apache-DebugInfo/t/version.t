#!perl

print "1..2\n";

require 5.004;
print "ok\n";

eval {
  require mod_perl;
  die "\n\n\tWhoops!  Apache::DebugInfo requires mod_perl 1.2401,
\tbut you are only running mod_perl $mod_perl::VERSION.  An upgrade
\tis in order to avoid undesirable (and unsupported)
\tside-effects...\n
\tPlease upgrade.\n\n" 
  if $mod_perl::VERSION < 1.2401;
};

die $@ if $@;
print "ok\n";

exit 0;
