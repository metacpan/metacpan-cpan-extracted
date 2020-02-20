package Data::Throttler_CHI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-19'; # DATE
our $DIST = 'Data-Throttler_CHI'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use Log::ger;

use List::Util qw(sum);

sub new {
    my ($class, %args) = @_;

    defined $args{max_items} or die "new: Please specify max_items";
    $args{max_items} >= 1    or die "new: max_items must be at least 1";
    defined $args{interval}  or die "new: Please specify interval";
    $args{interval} >= 1     or die "new: interval must be at least 1";
    defined $args{cache}     or die "new: Please specify cache";

    # calculate nof_buckets
    my $nof_buckets;
    if (defined $args{nof_buckets}) {
        $args{nof_buckets} >= 1 or die "new: nof_buckets must be at least 1";
        $nof_buckets = $args{nof_buckets};
    } else {
        $nof_buckets = $args{interval} ** 0.5;
    }
    $nof_buckets = int($nof_buckets);
    #log_trace "nof_buckets: $nof_buckets";

    # XXX warn if accuracy (interval/nof_buckets) is too low (e.g. 5 min?)

    my $self = {
        t0              => time(),
        max_items       => $args{max_items},
        interval        => $args{interval},
        cache           => $args{cache},
        nof_buckets     => $nof_buckets,
        secs_per_bucket => $args{interval} / $nof_buckets,
    };
    bless $self, $class;
}

sub _print_buckets {
    require Data::Dmp;

    my ($self, $now) = @_;

    my $all_hits = $self->{cache}->get_multi_arrayref([map {"hits.$_"} 1..$self->{nof_buckets}]);
    my $total_hits = sum(grep {defined} @$all_hits) || 0;

    my $all_expires_in = [map {my $e = $self->{cache}->get_expires_at("hits.$_"); defined($e) ? $e-$now : undef} 1..$self->{nof_buckets}];

    print "  hits      : ",Data::Dmp::dmp($all_hits)," total: $total_hits\n";
    print "  expires_in: ",Data::Dmp::dmp($all_expires_in), "\n";
}

sub try_push {
    my $self = shift;

    my $now = time();

    my $secs_after_latest_interval = ($now - $self->{t0}) % $self->{interval};
    my $bucket_num = int(
        $secs_after_latest_interval / $self->{interval} * $self->{nof_buckets}
    ) + 1; # 1 .. nof_buckets

    my $hits = $self->{cache}->get("hits.$bucket_num");

    my $all_hits = $self->{cache}->get_multi_arrayref(
        [map {"hits.$_"} 1..$self->{nof_buckets}]);
    my $total_hits = sum(grep {defined} @$all_hits) || 0;

    #$self->_print_buckets($now);
    return 0 if $total_hits >= $self->{max_items};

    if ($hits) {
        $self->{cache}->set(
            "hits.$bucket_num", $hits+1,
            {expires_at=>$self->{cache}->get_expires_at("hits.$bucket_num")});
    } else {
        $self->{cache}->set(
            "hits.$bucket_num", 1,
            {expires_at => $now + $self->{interval} - $secs_after_latest_interval + ($bucket_num-1) * $self->{secs_per_bucket}});
    }

    #$self->_print_buckets($now);
    1;
}

1;
# ABSTRACT: Data::Throttler-like throttler with CHI backend

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Throttler_CHI - Data::Throttler-like throttler with CHI backend

=head1 VERSION

This document describes version 0.003 of Data::Throttler_CHI (from Perl distribution Data-Throttler_CHI), released on 2020-02-19.

=head1 SYNOPSIS

 use Data::Throttler_CHI;
 use CHI;

 my $throttler = Data::Throttler_CHI->new(
     max_items    => 100,
     interval     => 3600,
     cache        => CHI->new(driver=>"Memory", datastore=>{}),
     #nof_buckets => 100, # optional, default: int(sqrt(interval))
 );

 if ($throttle->try_push) {
     print "Item can be pushed\n";
 } else {
     print "Item must wait\n";
 }

=head1 DESCRIPTION

EXPERIMENTAL, PROOF OF CONCEPT.

This module tries to use L<CHI> as the backend for data throttling. It presents
an interface similar to, but simpler than, L<Data::Throttler>.

=head1 METHODS

=head2 new

Usage:

 my $throttler = Data::Throttler_CHI->new(%args);

Known arguments (C<*> means required):

=over

=item * max_items*

=item * interval*

=item * cache*

CHI instance.

=item * nof_buckets

Optional. Int. Number of buckets. By default calculated using:
int(sqrt(interval)).

=back

=head2 try_push

Usage:

 $bool = $throttler->try_push(%args);

Return 1 if data can be pushed, or 0 if it must wait.

Known arguments:

=over

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Throttler_CHI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Throttler_CHI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Throttler_CHI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Throttler>

L<CHI>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
