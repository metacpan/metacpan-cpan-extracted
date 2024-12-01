use Test2::V0;
use Test2::Plugin::UTF8;
use v5.36;
use lib '../eg/', 'eg', '../lib', 'lib';
#
use At::Error;
#
ok At::Error::register( 'AtTest', 1 ), 'register new fatal "AtTest" error category';
isa_ok my $err = AtTest('Bad things happened'), [
    'At::Error'

        #~ , 'AtTest' # perlclass screws this up
    ],
    'AtTest(...) creates new error object';
ok !$err, 'errors are false';
like dies { throw $err }, qr[Bad things happened], 'throws and prints stacktrace';
#
done_testing;
