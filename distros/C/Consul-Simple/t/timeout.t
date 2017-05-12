use strict;use warnings;
use Data::Dumper;
use lib '../lib';
use lib 'lib';
use Consul::Simple::Test;
use Test::More qw(no_plan);

use_ok 'Consul::Simple', 'loaded Consul::Simple';
Consul::Simple::Test::init_tests();
exit 0; #for now, not going to distribute the timeout test

eval {
    my @warnings = ();
    ok my $c = Consul::Simple->new(
        kv_prefix => 'CPANTest',
        warning_handler => sub {
            my $warnstr = shift;
            my %args = @_;
            push @warnings, { warnstr => $warnstr, args => \%args };
        }
    ), 'timeout(1): instance created';
    ok $c->KVPut('foo',{ hi => 'there', this => [1,2,3] }), 'timeout(1): PUT succeeded';
    eval {
        kill 19, $Consul::Simple::Test::consul_daemon_pid;  #SIGSTOP - suspend consul
        my @timeout_ret = $c->KVGet('foo');
        ok not (scalar @timeout_ret), 'timeout(1): operation correctly timed out';
        ok (((scalar @warnings) > 1), 'timeout(1): warnings correctly produced');
        ok $warnings[0]->{warnstr} =~ /request failed: http request failed with 500 timed out/, 'timeout(1): first warning string is correct';
        ok $warnings[-1]->{warnstr} =~ /request failed: http request failed with 500 timed out/, 'timeout(1): last warning string is correct';
        kill 18, $Consul::Simple::Test::consul_daemon_pid;  #SIGCONT - continue running consul
        ok my @ret = $c->KVGet('foo'), 'timeout(1): GET succeeded';
        ok my $value = $ret[0]->{Value}, 'timeout(1): Value returned';
        ok ref $value eq 'HASH', 'timeout(1): returned Value is correct type';
        ok $value->{hi} eq 'there', 'timeout(1): returned Value first key is correct';
        ok $value->{this}[0] == 1, 'timeout(1): returned Value second key first value is correct';
        ok $value->{this}[1] == 2, 'timeout(1): returned Value second key second value is correct';
        ok $value->{this}[2] == 3, 'timeout(1): returned Value second key third value is correct';
    };
    ok((not $@), 'timeout(1): inner: no exception thrown');
    ok my $ret = $c->KVDelete('foo'), 'timeout(1): DELETE succeeded';
};
ok((not $@), 'timeout(1): outer: no exception thrown');


eval {
    my @warnings = ();
    ok my $c = Consul::Simple->new(
        kv_prefix => 'CPANTest',
        warning_handler => sub {
            my $warnstr = shift;
            my %args = @_;
            push @warnings, { warnstr => $warnstr, args => \%args };
        }
    ), 'timeout(2): instance created';
    ok $c->KVPut('foo',{ hi => 'there', this => [1,2,3] }), 'timeout(2): PUT succeeded';
    eval {
        kill 19, $Consul::Simple::Test::consul_daemon_pid;  #SIGSTOP - suspend consul
        my $new_pid = fork;
        die "fork failed: $!" unless defined $new_pid;
        if(not $new_pid) { #child
            sleep 5;
            kill 18, $Consul::Simple::Test::consul_daemon_pid;  #SIGCONT - continue running consul
            sleep 12;
            exit;
        }
        ok my @ret = $c->KVGet('foo'), 'timeout(2): GET succeeded';
        ok (((scalar @warnings) > 0), 'timeout(2): warnings correctly produced');
        ok $warnings[0]->{warnstr} =~ /request failed: /, 'timeout(2): first warning string is correct';
        ok $warnings[-1]->{warnstr} =~ /request failed: /, 'timeout(2): last warning string is correct';
        ok my $value = $ret[0]->{Value}, 'timeout(2): Value returned';
        ok ref $value eq 'HASH', 'timeout(2): returned Value is correct type';
        ok $value->{hi} eq 'there', 'timeout(2): returned Value first key is correct';
        ok $value->{this}[0] == 1, 'timeout(2): returned Value second key first value is correct';
        ok $value->{this}[1] == 2, 'timeout(2): returned Value second key second value is correct';
        ok $value->{this}[2] == 3, 'timeout(2): returned Value second key third value is correct';
    };
    ok((not $@), 'timeout(2): inner: no exception thrown');
    ok my $ret = $c->KVDelete('foo'), 'timeout(2): DELETE succeeded';
};
ok((not $@), 'timeout(2): outer: no exception thrown');
