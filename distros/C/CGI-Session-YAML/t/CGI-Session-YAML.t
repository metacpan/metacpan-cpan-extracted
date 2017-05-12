# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-Session-YAML.t'
# vim: ft=perl ts=4 sw=4 et ai:

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('CGI::Session::YAML') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $sessiondir = './session';
unless (-d $sessiondir)
{
    mkdir $sessiondir, 0750
        or die "Can't create $sessiondir: $!\n";
}

my $cgi;
eval {
    $cgi = CGI::Session::YAML->new($sessiondir);
    $cgi->param( -name => 'input1', -value => 'value1' );
    $cgi->commit();
};
ok( ! $@ );
