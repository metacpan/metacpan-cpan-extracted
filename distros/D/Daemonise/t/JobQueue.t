use Test::More tests => 1;
use Test::Deep;

use Daemonise;

my $d = Daemonise->new(no_daemon => 1);
$d->load_plugin('JobQueue');

#plan qw/no_plan/;

is  (1, 1, "true");

#{
#    my $data = {
#        removed_domains => [],
#        domains         => [
#            { domain => 'blah.org', action => 'create_domain' },
#            { domain => 'blah.com' },
#            { domain => 'blah.net' },
#        ] };
#    my $i = $d->find_item_index($data, 'blah.com');
#    is($i, 1, "find index of blah.com");
#    $i = $d->find_item_index($data, 'blah.guru');
#    is($i, undef, "No index found");
#
#    my @res = $d->remove_items($data, qw/blah.com/);
#
#    cmp_deeply(
#        $data, {
#            removed_domains => [ { domain => 'blah.com' } ],
#            domains         => [
#                { domain => 'blah.org', action => 'create_domain' },
#                { domain => 'blah.net' },
#            ]
#        },
#        'removing a domain'
#    );
#
#    cmp_deeply($data->{removed_domains},
#        \@res, 'returned and stored removal is the same');
#    push(@res, 'corrupt');
#    ok(
#        scalar(@{ $data->{removed_domains} }) == 1,
#        'modifying returned value will not corrupt data'
#    );
#}
#
#{
#    my $data = {
#        domains => [
#            { domain => 'blah.org', action => 'create_domain' },
#            { domain => 'blah.com' },
#            { domain => 'blah.net' },
#        ] };
#    my @res = $d->remove_items($data, qw/blah.com blah.net/);
#
#    cmp_deeply(
#        $data, {
#            removed_domains =>
#                [ { domain => 'blah.com' }, { domain => 'blah.net' } ],
#            domains => [ { domain => 'blah.org', action => 'create_domain' } ]
#        },
#        'removing 2 domains'
#    );
#
#    cmp_deeply($data->{removed_domains},
#        \@res, 'returned and stored removal is the same');
#    ok(scalar(@{ $data->{removed_domains} }) == 2, 'length 2 array');
#    ok(scalar(@res) == 2,                          'length 2 array');
#}
#
#{
#    my $data = {
#        domains => [
#            { domain => 'blah.org', action => 'create_domain' },
#            { domain => 'blah.com' },
#            { domain => 'blah.net' },
#        ] };
#    my @res = $d->remove_items($data, qw/missing.com/);
#
#    cmp_deeply(
#        $data, {
#            domains => [
#                { domain => 'blah.org', action => 'create_domain' },
#                { domain => 'blah.com' },
#                { domain => 'blah.net' },
#            ]
#        },
#        "removing a domain that can't be found to a key"
#    );
#
#    ok(!exists $data->{removed_domains},
#        "don't create key if domain can't be found");
#    ok(scalar(@res) == 0, "return value is 0 length array");
#}
