use strict;
use warnings;
use App::pathed;
use Test::More;
use Test::Differences;

sub check {
    my ($path, $opt, $expect, $test_name) = @_;
    my @result = App::pathed::process($path, $opt);
    eq_or_diff \@result, $expect, $test_name;
}
my $path =
  '/Users/marcel/.rbenv/shims:/Users/marcel/bin:/usr/bin:/bin:/usr/sbin:/sbin';
check(
    $path,
    { delete => ['bin'] },
    ['/Users/marcel/.rbenv/shims'],
    'delete a path part'
);
check(
    $path,
    { delete => [ 'marcel', 'rbenv' ] },
    ['/usr/bin:/bin:/usr/sbin:/sbin'],
    'delete two path parts'
);
check(
    $path,
    { delete => [ 'marcel', 'rbenv' ], split => 1 },
    [ '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    'delete two path parts and split'
);
check(
    '/usr/bin:/usr/sbin:/usr/bin', { unique => 1 },
    ['/usr/bin:/usr/sbin'], 'unique'
);
check(
    '/usr/bin:/usr/sbin',
    {   append  => [ '/foo/one', '/foo/two' ],
        prepend => [ '/bar/one', '/bar/two' ]
    },
    ['/bar/two:/bar/one:/usr/bin:/usr/sbin:/foo/one:/foo/two'],
    'append and prepend several elements'
);
check('/usr/bin:/usr/sbin',
    { append => ['/foo/one'], prepend => ['/bar/one'], delete => ['bin'] },
    ['/bar/one:/foo/one'], 'append, prepend and delete');
check(
    '/foo/bar/one:/usr/bin:/foo/bar/one:/foo/bar/two:/usr/sbin',
    { check => 1 },
    [ '/foo/bar/one is not readable', '/foo/bar/two is not readable' ],
    'check'
);
check(
    '/usr/bin:/usr/sbin', { sep => ';', split => 1 },
    ['/usr/bin:/usr/sbin'], 'different seperator'
);
check(
    '/usr/bin;/usr/sbin',
    { sep => ';', split => 1 },
    [ '/usr/bin', '/usr/sbin' ],
    'different seperator and split'
);
check('/usr/bin;/usr/sbin', { sep => ';', },
    ['/usr/bin;/usr/sbin'], 'different seperator and joining');
check(
    '/usr/bin;/usr/sbin', { sep => ';', delete => ['sbin'] },
    ['/usr/bin'], 'different seperator and delete 1'
);
check(
    '/usr/bin:/usr/sbin', { sep => ';', delete => ['sbin'] },
    [''], 'different seperator and delete 2'
);
done_testing;
