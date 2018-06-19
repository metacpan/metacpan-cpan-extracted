use strict;
use warnings;

package Test::APEP::Gitz;

use parent qw{Test::Class};
use Test::More;
use Test::Deep;

use App::Prove::Elasticsearch::Provisioner::Git;

sub test_get_available_provision_targets : Test(1) {
    my @expected = qw{apple banana orange};
    no warnings qw{redefine once};
    local *Git::command = sub { return @expected };
    use warnings;

    my @out = App::Prove::Elasticsearch::Provisioner::Git::get_available_provision_targets();
    is_deeply(\@out,\@expected,"get_available_provision_targets ");
}

sub test_pick_platform : Test(2) {
    my $count = 0;
    no warnings qw{redefine once};
    local *Capture::Tiny::capture_stderr = sub {};
    local *Git::command = sub { return "blahblahblah" unless $count; $count++; return 0 };
    use warnings;

    my ($plat,$platsleft) = App::Prove::Elasticsearch::Provisioner::Git::pick_platform(qw{a b c});
    is($plat,'a',"Correct platform chosen");
    cmp_bag($platsleft,['b','c'],"Remaining platforms returned correctly");
}

sub test_can_switch_version : Test(2) {
    is(App::Prove::Elasticsearch::Provisioner::Git::can_switch_version('App::Prove::Elasticsearch::Versioner::Git'),1,"can_switch_version: positive");
    is(App::Prove::Elasticsearch::Provisioner::Git::can_switch_version('App::Prove::Elasticsearch::Versioner::Moo'),'',"can_switch_version: negative");
}

sub test_switch_version_to_and_provision : Test(2) {
    no warnings qw{redefine once};
    local *Git::command = sub { return "@_" };
    use warnings;
    is( App::Prove::Elasticsearch::Provisioner::Git::switch_version_to(666),"reset --hard 666","switch_version_to: ref reset occurred");
    is( App::Prove::Elasticsearch::Provisioner::Git::provision(666),"reset --hard 666","provision: ref reset occurred");
}

__PACKAGE__->runtests();
