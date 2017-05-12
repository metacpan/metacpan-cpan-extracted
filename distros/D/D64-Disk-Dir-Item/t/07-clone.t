########################################
use strict;
use warnings;
use IO::Scalar;
use Test::Exception;
use Test::More tests => 2;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Dir::Item';
    use_ok($class, qw(:all));
}
########################################
sub get_data {
    my @bytes = qw(82 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    return $data;
}
########################################
{
    my $data = get_data();
    my $item = $class->new($data);
    my $clone = $item->clone();
    $item->type($T_SEQ);
    is($clone->data(), $data, 'modifying original item does not change its clone');
}
########################################
