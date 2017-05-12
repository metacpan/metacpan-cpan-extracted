# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CPANPLUS-Shell-Wx.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN {
    use_ok('CPANPLUS');
    use_ok('Wx');
    use_ok('CPANPLUS::Shell::Wx');
    use_ok('CPANPLUS::Shell::Wx::App');
    use_ok('CPANPLUS::Shell::Wx::Configure');
    use_ok('CPANPLUS::Shell::Wx::Frame');
    use_ok('CPANPLUS::Shell::Wx::ModulePanel');
    use_ok('CPANPLUS::Shell::Wx::ModuleTree');
    use_ok('CPANPLUS::Shell::Wx::PODReader');
    use_ok('CPANPLUS::Shell::Wx::UpdateWizard');
    use_ok('CPANPLUS::Shell::Wx::util');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $cps;
my $shell;

## Test Wx first
ok(1,'Wx_new');
#ok(1,'Wx_shell');
sub Wx_new{my $cps=CPANPLUS::Shell::Wx->new();return $cps->isa('CPANPLUS::Shell::Wx');}
#sub Wx_shell{shell(Wx);}