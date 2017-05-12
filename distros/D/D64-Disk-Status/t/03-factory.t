########################################
use strict;
use warnings;
use Test::Exception;
use Test::More tests => 13;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Status::Factory';
    use_ok($class);
}
########################################
{
    my $status = $class->new();
    my $test1 = $status->code() == 0;
    my $test2 = $status->error() eq 'OK';
    my $test3 = $status->message() eq 'OK';
    my $test4 = $status->description() eq '';
    ok($test1 && $test2 && $test3 && $test4, 'create default status object');
}
########################################
{
    my $status = $class->new(0);
    my $test1 = $status->code() == 0;
    my $test2 = $status->error() eq 'OK';
    my $test3 = $status->message() eq 'OK';
    my $test4 = $status->description() eq '';
    ok($test1 && $test2 && $test3 && $test4, 'create OK status object');
}
########################################
{
    my $status = $class->new(1);
    my $test1 = $status->code() == 1;
    my $test2 = $status->error() eq 'FILES SCRATCHED';
    my $test3 = $status->message() eq 'files scratched';
    my $test4 = $status->description() eq '';
    ok($test1 && $test2 && $test3 && $test4, 'create FILES SCRATCHED status object');
}
########################################
{
    throws_ok(
        sub { $class->new(1, 2); },
        qr/\QUnable to create status object: Invalid number of arguments ([1,2])\E/,
        'create status object with invalid number of arguments',
    );
}
########################################
{
    throws_ok(
        sub { $class->new('one'); },
        qr/\QUnable to create status object: Illegal argument value ('one')\E/,
        'create status object with invalid argument type (string)',
    );
}
########################################
{
    throws_ok(
        sub { $class->new([]); },
        qr/\QUnable to create status object: Invalid argument type (ARRAY)\E/,
        'create status object with invalid argument type (arrayref)',
    );
}
########################################
{
    throws_ok(
        sub { $class->new({}); },
        qr/\QUnable to create status object: Invalid argument type (HASH)\E/,
        'create status object with invalid argument type (hashref)',
    );
}
########################################
{
    my $status = $class->new(20);
    is($status->code(), 20, 'create status object and get error code');
}
########################################
{
    my $status = $class->new(30);
    is($status->error(), 'SYNTAX ERROR', 'create status object and get error text');
}
########################################
{
    my $status = $class->new(50);
    is($status->message(), 'record not present', 'create status object and get error message');
}
########################################
{
    my $status = $class->new(60);
    is($status->description(), 'This message is generated when a write file that has not been closed is being opened for reading.', 'create status object and get error description');
}
########################################
{
    throws_ok(
        sub { $class->new(666); },
        qr/\QUnable to create status object: Invalid error code number (666)\E/,
        'create status object with invalid error code number',
    );
}
########################################
