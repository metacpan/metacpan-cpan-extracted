#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 1;

BEGIN { require "t/commons.pl"; }

# test for the simplest invocation (using the --version option)
@command = ( '-version' );
($stdout, $stderr) = my_run (@command);
ok ($stdout ne '', "Version missing");

__END__
