#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 5;

BEGIN { require "t/commons.pl"; }

use File::Spec;

# test for error conditions
my $config_file = File::Spec->catfile (test_file(), 'errors.cfg');

my @command = ( '-config', $config_file, '-inputs', 'dummy' );
my ($stdout, $stderr) = my_run (@command);
ok ($stderr =~ m{\[ER01\]},
    msgcmd2 ($stderr, "Expected error ER01 for ", @command));
ok ($stderr =~ m{\[WR01\]} && $stderr =~ m{'0},
    msgcmd2 ($stderr, "Expected warning WR01 ('0) for ", @command));
ok ($stderr =~ m{\[WR01\]} && $stderr =~ m{'jit'},
    msgcmd2 ($stderr, "Expected warning WR01 ('jit') for ", @command));
ok ($stderr =~ m{\[WR02\]} && $stderr =~ m{'=col1'},
    msgcmd2 ($stderr, "Expected warning WR02 ('=col1') for ", @command));
ok ($stderr =~ m{\[WR02\]} && $stderr =~ m{'DUM='},
    msgcmd2 ($stderr, "Expected warning WR02 ('DUM=') for ", @command));

__END__
