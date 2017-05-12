# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 3;

my $OS = '-';

BEGIN {
    use_ok('Config::Find');
    use_ok('Config::Find::Any');
    use_ok('Config::Find::Where');

    if ($^O=~/Win32/) {
        require Win32;
        $OS = uc Win32::GetOSName();
    }
};

diag( "Testing Config::Find $Config::Find::VERSION, Perl $], $^X, OS: $^O ($OS)" );

#########################
