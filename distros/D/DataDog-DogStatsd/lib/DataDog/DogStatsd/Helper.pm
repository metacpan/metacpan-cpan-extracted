package DataDog::DogStatsd::Helper;

use strict;
use warnings;
our $VERSION = '0.04';

use base qw( Exporter );
our @EXPORT_OK = qw/stats_inc stats_dec stats_timing stats_gauge stats_count/;

use DataDog::DogStatsd;

## no critic (Subroutines::RequireFinalReturn)
sub stats_inc {
    my @args = @_;
    # support stats_inc('test.blabla', 0.1); as well
    if (@args > 1 and $args[1] =~ /^[\d\.]+$/) {
        # actually ppl wants stats_count
        warn "stats_inc sample_rate makes no sense for more than 1\n" if $args[1] > 1;
        $args[1] = {sample_rate => $args[1]};
    }
    __get_dogstatsd()->increment(@args);
}
sub stats_dec    { __get_dogstatsd()->decrement(@_); }

sub stats_timing {
    my @args = @_;
    # support stats_timing('connection_time', 1000 * $interval, 0.1); as well
    if (@args > 2 and $args[2] =~ /^[\d\.]+$/) {
        # actually ppl wants stats_count
        warn "stats_timing sample_rate makes no sense for more than 1\n" if $args[2] > 1;
        $args[2] = {sample_rate => $args[2]};
    }
    __get_dogstatsd()->timing(@args);
}

sub stats_gauge  { __get_dogstatsd()->gauge(@_); }
sub stats_count  { __get_dogstatsd()->count(@_); }

my $__DOGSTATSD;
sub __get_dogstatsd {
    $__DOGSTATSD ||= DataDog::DogStatsd->new;
    return $__DOGSTATSD;
}

1;
__END__

=encoding utf-8

=head1 NAME

DataDog::DogStatsd::Helper - shortcut/helper for L<DataDog::DogStatsd>

=head1 SYNOPSIS

    use DataDog::DogStatsd::Helper qw(stats_inc stats_dec stats_timing stats_gauge stats_count)

    stats_inc('logins'); # shortcut for DataDog::DogStatsd->new->increment('logins')
    stats_dec('logins'); # shortcut for DataDog::DogStatsd->new->decrement('logins')
    stats_timing('test.timing', 1); # ->timing
    stats_gauge('test.gauge', 10); # ->gauge
    stats_count('test.count', 20); # ->count

=head1 DESCRIPTION

DataDog::DogStatsd::Helper is a helper for L<DataDog::DogStatsd>, it will reuse the instance of L<DataDog::DogStatsd> for all calls.

=head1 AUTHOR

Fayland Lam E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Fayland Lam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
