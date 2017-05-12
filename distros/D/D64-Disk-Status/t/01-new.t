########################################
use strict;
use warnings;
use Test::Exception;
use Test::More tests => 9;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Status';
    use_ok($class);
}
########################################
{
    can_ok($class, qw(new code error message description));
}
########################################
{
    throws_ok(
        sub { $class->new(); },
        qr/Failed to instantiate status object: Missing error "code" parameter/,
        'attempt to create a new disk status object without arguments',
    );
}
########################################
{
    my %args = (
        error       => 'SYNTAX ERROR',
        message     => 'invalid filename',
        description => 'Pattern matching was invalidly used in the OPEN or SAVE command.',
    );
    throws_ok(
        sub { $class->new(%args); },
        qr/Failed to instantiate status object: Missing error "code" parameter/,
        'attempt to create a new disk status object without error code',
    );
}
########################################
{
    my %args = (
        code        => 'thirty three',
        error       => 'SYNTAX ERROR',
        message     => 'invalid filename',
        description => 'Pattern matching was invalidly used in the OPEN or SAVE command.',
    );
    throws_ok(
        sub { $class->new(%args); },
        qr/Failed to instantiate status object: Invalid error "code" parameter/,
        'attempt to create a new disk status object with non-numeric error code',
    );
}
########################################
{
    my %args = (
        code        => 33,
        message     => 'invalid filename',
        description => 'Pattern matching was invalidly used in the OPEN or SAVE command.',
    );
    throws_ok(
        sub { $class->new(%args); },
        qr/Failed to instantiate status object: Missing "error" text parameter/,
        'attempt to create a new disk status object without error text',
    );
}
########################################
{
    my %args = (
        code        => 33,
        error       => 'SYNTAX ERROR',
        description => 'Pattern matching was invalidly used in the OPEN or SAVE command.',
    );
    throws_ok(
        sub { $class->new(%args); },
        qr/Failed to instantiate status object: Missing error "message" parameter/,
        'attempt to create a new disk status object without error message',
    );
}
########################################
{
    my %args = (
        code        => 33,
        error       => 'SYNTAX ERROR',
        message     => 'invalid filename',
    );
    throws_ok(
        sub { $class->new(%args); },
        qr/Failed to instantiate status object: Missing error "description" parameter/,
        'attempt to create a new disk status object without error description',
    );
}
########################################
{
    my $status = $class->new(
        code        => 0,
        error       => 'OK',
        message     => 'no errors',
        description => 'OK, no error exists.',
    );
    is(ref $status, $class, 'successfully create a new disk status object');
}
########################################
