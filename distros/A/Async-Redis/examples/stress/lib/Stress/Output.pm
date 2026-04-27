package Stress::Output;
use strict;
use warnings;
use Time::HiRes qw(time);
use JSON::PP qw(encode_json);

sub new {
    my ($class, %args) = @_;
    return bless {
        jsonl_fh  => $args{jsonl_fh},
        stderr_fh => $args{stderr_fh},
        quiet     => $args{quiet} // 0,
    }, $class;
}

sub emit_metric {
    my ($self, $snapshot) = @_;
    my $rec = { kind => 'metric', t => time, %$snapshot };
    print { $self->{jsonl_fh} } encode_json($rec), "\n";

    return if $self->{quiet};

    my $tp     = $snapshot->{throughput}     // {};
    my $errors = $snapshot->{errors_typed}   // {};
    my $lat    = $snapshot->{latency_ms}     // {};
    my $chaos  = $snapshot->{chaos}          // {};
    my $errs_total = 0; $errs_total += $_ for values %$errors;

    my @err_parts;
    for my $type (sort keys %$errors) {
        (my $short = $type) =~ s/^.*:://;
        push @err_parts, "$short:$errors->{$type}";
    }
    my $err_str = @err_parts ? ' (' . join(' ', @err_parts) . ')' : '';

    my $p99_get = $lat->{get}{p99} // 0;

    my $line = sprintf
        "[t=%5.1fs] gets=%d sets=%d pub=%d errs=%d%s p99_get=%.2fms reconns=%d chaos:%d\n",
        $snapshot->{elapsed_s} // 0,
        $tp->{get} // 0,
        $tp->{set} // 0,
        $tp->{publish} // 0,
        $errs_total,
        $err_str,
        $p99_get,
        $snapshot->{reconnects} // 0,
        $chaos->{kills_issued}  // 0;
    print { $self->{stderr_fh} } $line;
    return;
}

sub emit_summary {
    my ($self, $summary) = @_;
    my $rec = { kind => 'summary', t => time, %$summary };
    print { $self->{jsonl_fh} } encode_json($rec), "\n";
    return;
}

1;
