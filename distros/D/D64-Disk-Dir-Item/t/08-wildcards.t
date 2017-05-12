########################################
use strict;
use warnings;
use IO::Scalar;
use Text::Convert::PETSCII qw(:convert);
use Test::Exception;
use Test::More tests => 30;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Dir::Item';
    use_ok($class, qw(:all));
}
########################################
sub get_data {
    my @bytes = qw(82 11 00 54 45 53 54 30 31 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my $data = join '', map { chr } map { hex } @bytes;
    return $data;
}
########################################
{
    my %patterns = (
        '*'        => 1,
        '?'        => 0,
        '?*'       => 1,
        '*?'       => 1,
        't*'       => 1,
        't?'       => 0,
        't*zzz'    => 1,
        'te*'      => 1,
        'tes*'     => 1,
        'test*'    => 1,
        'test0*'   => 1,
        'test01*'  => 1,
        'test01**' => 1,
        'test01*z' => 1,
        'test01*?' => 1,
        'test01?*' => 0,
        'te?'      => 0,
        'test0'    => 0,
        'test01'   => 1,
        'test011'  => 0,
        'test01?'  => 0,
        '?est01'   => 1,
        't?st01'   => 1,
        'te?t01'   => 1,
        'tes?01'   => 1,
        'test?1'   => 1,
        'test0?'   => 1,
        '?est02'   => 0,
        '*est02'   => 1,
    );

    my $data = get_data();
    my $item = $class->new($data);

    for my $pattern (keys %patterns) {
        my $expected_result = $patterns{$pattern};
        is($item->match_name(ascii_to_petscii $pattern), $expected_result, "match 'test01' filename against '${pattern}' pattern");
    }
}
########################################
