use strict;
use Class::STAF;
use Test::Simple tests=>11;

$INC{'PLSTAF.pm'} = "c:/perl/lib/dummy.pm";

package STAF;
our $kOk = 0;

package main;

my ($inject_rc, $inject_result);
my @called_params;

$inject_rc = 0;
my $handle = Class::STAF->new("Prog1");
ok($handle and ref($handle) and $handle->isa('Class::STAF'), 'Returned an object');
ok(compare_arrays(\@called_params, [qw{STAF::STAFHandle Prog1}]), 'Correct constructor parameters');

$inject_result = "string 1";
ok($handle->submit("location", "service", "request") eq $inject_result, 'got submit results');
shift @called_params;
ok(compare_arrays(\@called_params, ["location", "service", "request"]), 'submit request ok');

$inject_result = "string 2";
ok($handle->submit2("sync", "location", "service", "request") eq $inject_result, 'got submit2 results');
shift @called_params;
ok(compare_arrays(\@called_params, ["sync", "location", "service", "request"]), 'submit2 request ok');

$inject_result = "string 3";
ok($handle->host("location")->submit("service", "request") eq $inject_result, 'got host->submit results');
shift @called_params;
ok(compare_arrays(\@called_params, ["location", "service", "request"]), 'host->submit request ok');

$inject_result = "string 4";
ok($handle->host("location")->service("service")->submit("request") eq $inject_result, 'got service->submit results');
shift @called_params;
ok(compare_arrays(\@called_params, ["location", "service", "request"]), 'service->submit request ok');

$handle = undef;
ok(compare_arrays(\@called_params, [1]), 'handle destroyed');

sub compare_arrays {
    my ($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    for (my $ix=0; $ix<@$a1; $ix++) {
        return 0 unless $a1->[$ix] eq $a2->[$ix];
    }
    return 1;
}

package STAF::STAFHandle;

sub new {
    my ($class, $name) = @called_params = @_;
    return bless {name => $name, rc=>$inject_rc}, $class;
}

sub submit {
    @called_params = @_;
    return { rc=>$inject_rc, result=> $inject_result};
}

sub submit2 {
    @called_params = @_;
    return { rc=>$inject_rc, result=> $inject_result};
}

sub unRegister {
    @called_params = (1);
    return $inject_rc;
}

    