use strict;
use warnings;

package Test::APEP::Perl;

use parent qw{Test::Class};
use Test::More;
use Test::Deep;
use Test::Fatal;

use App::Prove::Elasticsearch::Provisioner::Perl;

sub test_get_available_provision_targets : Test(2) {
    my @in = ('perl5.004_05','perl-5.26.2');
    no warnings qw{redefine once};
    local *App::perlbrew::new = sub { return bless({},shift) };
    local *App::perlbrew::available_perls = sub { return @in };
    use warnings;

    my @expected = qw{perl5.004_05};
    my @out = App::Prove::Elasticsearch::Provisioner::Perl::get_available_provision_targets();
    is_deeply(\@out,\@in,"By default all perl versions available returned");

    @out = App::Prove::Elasticsearch::Provisioner::Perl::get_available_provision_targets('5.026');
    is_deeply(\@out,\@expected,"get_available_provision_targets returns available perls less requested version");
}


sub test_pick_platform : Test(2) {
    my $count = 0;
    my ($plat,$platsleft) = App::Prove::Elasticsearch::Provisioner::Perl::pick_platform(qw{a b c perl-666});
    is($plat,'perl-666',"Correct platform chosen");
    cmp_bag($platsleft,['a','b','c'],"Remaining platforms returned correctly");
}

sub test_can_switch_version : Test(1) {
    is(App::Prove::Elasticsearch::Provisioner::Perl::can_switch_version('App::Prove::Elasticsearch::Versioner::Perl'),0,"can_switch_version: negative");
}

sub test_switch_version_to : Test(1) {
    like( exception { App::Prove::Elasticsearch::Provisioner::Perl::switch_version_to(666) },qr/switch version/,"can't switch version");
}

sub test_provision : Test(1) {
    no warnings qw{redefine once};
    local *App::perlbrew::new = sub { return bless({},shift) };
    local *App::perlbrew::run_command_install = sub {};
    local *App::perlbrew::perlbrew_env = sub {};
    use warnings;

    is(App::Prove::Elasticsearch::Provisioner::Perl::provision('zippy'),'zippy',"Provision can run all the way through");
}

__PACKAGE__->runtests();
