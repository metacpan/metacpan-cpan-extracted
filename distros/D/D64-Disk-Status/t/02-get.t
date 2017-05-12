########################################
use strict;
use warnings;
use Test::More tests => 5;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Status';
    use_ok($class);
}
########################################
sub get_status {
    my $status = $class->new(
        code        => 52,
        error       => 'FILE TOO LARGE',
        message     => 'file too large',
        description => 'Record position within a relative file indicates that disk overflow will result.',
    );
    return $status;
}
########################################
{
    my $status = get_status();
    is($status->code(), 52, 'get error code from status object');
}
########################################
{
    my $status = get_status();
    is($status->error(), 'FILE TOO LARGE', 'get error text from status object');
}
########################################
{
    my $status = get_status();
    is($status->message(), 'file too large', 'get error message from status object');
}
########################################
{
    my $status = get_status();
    is($status->description(), 'Record position within a relative file indicates that disk overflow will result.', 'get error description from status object');
}
########################################
