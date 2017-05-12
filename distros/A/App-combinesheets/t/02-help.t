#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 1;

BEGIN { require "t/commons.pl"; }

# test for the simplest invocation (using the -h option)
my @command = ( '-h' );
my ($stdout, $stderr) = my_run (@command);
ok ($stdout =~ m{usage message},
    msgcmd2 ($stdout, "Expected help for ", @command));

__END__
