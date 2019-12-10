package DataDog::DogStatsd::Helper;

use strict;
use warnings;
our $VERSION = '0.06';

use base qw( Exporter );
our @EXPORT_OK = qw/stats_inc stats_dec stats_timing stats_gauge stats_count stats_histogram stats_event stats_timed/;

use DataDog::DogStatsd;
use Time::HiRes qw(tv_interval gettimeofday);

## no critic (Subroutines::RequireFinalReturn)
sub stats_inc {
    my @args = @_;
    # support stats_inc('test.blabla', 0.1); as well
    if (@args > 1 and $args[1] =~ /^[\d\.]+$/) {
        # actually ppl wants stats_count
        warn "stats_inc sample_rate makes no sense for more than 1\n" if $args[1] > 1;
        $args[1] = {sample_rate => $args[1]};
    }
    get_dogstatsd()->increment(@args);
}
sub stats_dec    { get_dogstatsd()->decrement(@_); }

sub stats_timing {
    my @args = @_;
    # support stats_timing('connection_time', 1000 * $interval, 0.1); as well
    if (@args > 2 and $args[2] =~ /^[\d\.]+$/) {
        # actually ppl wants stats_count
        warn "stats_timing sample_rate makes no sense for more than 1\n" if $args[2] > 1;
        $args[2] = {sample_rate => $args[2]};
    }
    get_dogstatsd()->timing(@args);
}

sub stats_timed (&@) {    ## no critic (ProhibitSubroutinePrototypes)
    my ($sub, $what, $opts) = splice @_, 0, 3;

    my $start = [gettimeofday];

    my (@res, $no_ex);
    if (wantarray) {
        $no_ex = eval { @res = $sub->(@_); 1; };
    } elsif (defined wantarray) {
        $no_ex = eval { $res[0] = $sub->(@_); 1; };
    } else {
        $no_ex = eval { $sub->(@_); 1; };
    }

    if ($no_ex) {
        get_dogstatsd()->timing($what, 1000 * tv_interval($start), $opts);
    } else {
        get_dogstatsd()->increment("$what.failure", $opts);
        die $@;
    }

    return wantarray ? @res : $res[0];
}

sub stats_gauge      { get_dogstatsd()->gauge(@_); }
sub stats_count      { get_dogstatsd()->count(@_); }
sub stats_histogram  { get_dogstatsd()->histogram(@_); }
sub stats_event      { get_dogstatsd()->event(@_); }

my $DOGSTATSD;
sub get_dogstatsd {
    $DOGSTATSD ||= DataDog::DogStatsd->new(
        host        => $ENV{DATADOG_AGENT_HOST},
        port        => $ENV{DATADOG_AGENT_PORT},
        namespace   => $ENV{DATADOG_AGENT_NAMESPACE}
        );
    return $DOGSTATSD;
}

sub set_dogstatsd {
    $DOGSTATSD = pop;
}

1;
__END__

=encoding utf-8

=head1 NAME

DataDog::DogStatsd::Helper - helper for L<DataDog::DogStatsd>

=head1 SYNOPSIS

    use DataDog::DogStatsd::Helper qw(stats_inc stats_dec stats_timing
                                      stats_gauge stats_count
                                      stats_histogram stats_timed);

    stats_inc('logins'); # shortcut for DataDog::DogStatsd->new->increment('logins')
    stats_dec('logins'); # shortcut for DataDog::DogStatsd->new->decrement('logins')
    stats_timing('test.timing', 1); # ->timing
    stats_gauge('test.gauge', 10); # ->gauge
    stats_count('test.count', 20); # ->count
    stats_histogram('test.histogram', 100); # ->histogram
    stats_event('event title', 'event text'); # ->event

    stats_timed {
        my @param = @_;
        # some code
        ...
    } 'test.timing', {tags => \@tags}, @params;

    DataDog::DogStatsd::Helper->get_dogstatsd;
    DataDog::DogStatsd::Helper->set_dogstatsd(DataDog::DogStatsd->new(...));

=head1 DESCRIPTION

DataDog::DogStatsd::Helper is a helper for L<DataDog::DogStatsd>. It's main purpose
is to maintain a global L<DataDog::DogStatsd> object.

=head1 FUNCTIONS

For all the functions below, C<$what> is the name of a metric sent to datadog. C<\%opts>
is a hash reference which can contain a key C<tags> pointing to an array of tags sent
to datadog along with the metric and a key C<sample_rate> with a number between C<0> and
C<1> as value. See
L<https://docs.datadoghq.com/developers/metrics/dogstatsd_metrics_submission/#sample-rates>
for more information on sample rates.

=head2 C<< stats_inc $what, \%opts >>

equivalent to C<< $dogstatsd->increment($what, \%opts) >>

=head2 C<< stats_inc $what, $sample_rate >>

equivalent to C<< $dogstatsd->increment($what, +{sample_rate=>$sample_rate}) >>

=head2 C<< stats_dec $what, \%opts >>

equivalent to C<< $dogstatsd->decrement($what, \%opts) >>

=head2 C<< stats_timing $what $millisec, \%opts >>

equivalent to C<< $dogstatsd->timing($what, $millisec, \%opts) >>

=head2 C<< stats_timing $what $millisec, $sample_rate >>

equivalent to C<< $dogstatsd->timing($what, $millisec, +{sample_rate=>$sample_rate}) >>

Note, C<$millisec> will be truncated to an integer value.

=head2 C<< stats_gauge $what, $measured_value, \%opts >>

equivalent to C<< $dogstatsd->gauge($what, $measured_value, \%opts) >>

=head2 C<< stats_count $what, $increment, \%opts >>

equivalent to C<< $dogstatsd->count($what, $increment, \%opts) >>

=head2 C<< stats_histogram $what, $measured_value, \%opts >>

equivalent to C<< $dogstatsd->histogram($what, $measured_value, \%opts) >>

=head2 C<< stats_event $title, $text, \%opts >>

equivalent to C<< $dogstatsd->event($what, $title, $text, \%opts) >>

Naturally, C<sample_rate> does not make sense in C<\%opts>. C<$opts{tags}>
is processed as usual. Besides that, the C<%opts> hash can contain the
following optional keys:

=over 4

=item date_happened

=item hostname

=item aggregation_key

=item priority

=item source_type_name

=item alert_type

=back

For more information see
L<https://docs.datadoghq.com/developers/events/dogstatsd/>

=head2 C<< stats_timed {BLOCK} $what, \%opts, @other_params >>

this offers a somewhat more convenient interface to timing a
piece of code. It's supposed to be called like this:

 my $value = stats_timed {
     # timed piece of code
     my ($p1, $p2, ...) = @_;
     ...
 } $what, {tags => \@tags}, $param1, $param2, ...;

Before the code block is executed the current time is taken with
C<Time::HiRes::gettimeofday>. Then the code block is executed
in an C<eval> environment. If no exception is thrown the time
is reported the same way C<stats_timing> does. If the code block
ends in an exception, the C<$what.failure> metric is incremented
passing the same tags.

If called in scalar context, the code block is also called in
scalar context and the resulting value is returned.

If called in list context, the code block is also called in
list context and the resulting list is returned.

If called in void context, the code block is also called in
void context.

=head2 C<< DataDog::DogStatsd::Helper->get_dogstatsd >>

returns the internal C<DataDog::DogStatsd> object. This can be used to
modify certain parameters like the C<namespace>.

This function is not exported. It can be called both as function and
as class method.

=head2 C<< DataDog::DogStatsd::Helper->set_dogstatsd(DataDog::DogStatsd->new) >>

allows to set the internal C<DataDog::DogStatsd> object. Useful mainly for
testing.

This function is not exported. It can be called both as function and
as class method.

=head1 AUTHOR

Fayland Lam E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
