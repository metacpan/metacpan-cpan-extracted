use inc::Module::Install;

name 'CHI-Driver-HandlerSocket';
abstract 'Use MySQL HandleSocket for cache';
all_from 'lib/CHI/Driver/HandlerSocket.pm';
author 'Scott Walters <scott@slowass.net>';

perl_version '5.006';

build_requires 'Test::Class' => 0;
build_requires 'Test::Most'  => 0;

requires 'CHI' => '0.241';
requires 'DBI' => '1.26';
requires 'Net::HandlerSocket' => undef;

license 'perl';

my $database = prompt("MySQL database name to test with (a table called 'chi_Default' will be created and then left) ?");
my $user = $database ? prompt("MySQL database username to test with (will be inserted into t/CHIDriverTests-MySQLHandlerSocket.t) ? ") : '';
my $pass = $user ? prompt("MySQL database password to test with (will be inserted into t/CHIDriverTests-MySQLHandlerSocket.t) ? ") : '';

if( $database and $user and $pass ) {
    open my $fh, '>>', 't/CHIDriverTests-MySQLHandlerSocket.t' or warn "oops, couldn't append database login info to the test script: $!";
    if( $fh ) {
        print $fh "database=$database\nuser=$user\npass=$pass\n";
        close $fh;
    }
}

auto_install;

WriteAll;
