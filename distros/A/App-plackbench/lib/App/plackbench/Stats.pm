package App::plackbench::Stats;
$App::plackbench::Stats::VERSION = '0.7';
use strict;
use warnings;
use autodie;
use v5.10;

use List::Util qw( sum reduce );

sub new {
    my $class = shift;
    my @self = sort { $a <=> $b } @_;
    return bless \@self, $class;
}

sub insert {
    my $self = shift;
    my $n = shift;

    push @{$self}, $n;
    return $self->count();
}

sub finalize {
    my $self = shift;

    @{$self} = sort { $a <=> $b } @{$self};
    return $self;
}

sub count {
    my $self = shift;
    return scalar @{$self};
}

sub mean {
    my $self = shift;

    return unless $self->count();
    return $self->elapsed() / $self->count();
}

sub median {
    my $self = shift;

    return unless $self->count();

    if ($self->count() % 2 == 1) {
        return $self->[$self->count() / 2];
    }

    my $index_a = ($self->count() / 2) + 0.5;
    my $index_b = ($self->count() / 2) - 0.5;
    my $a = $self->[$index_a];
    my $b = $self->[$index_b];
    return ($a + $b) / 2;
}

sub min {
    my $self = shift;

    return unless $self->count();
    return $self->[0];
}

sub max {
    my $self = shift;
    return unless $self->count();
    return $self->[-1];
}

sub standard_deviation {
    my $self = shift;

    return 0 unless $self->count();
    my $mean = $self->mean();

    my $differences_sum = reduce {
        $a + ( ( $b - $mean )**2 );
    }
    0, @{$self};

    my $sd = sqrt( $differences_sum / $self->count() );
    return $sd;
}

sub percentile {
    my $self = shift;
    my $percentile = shift;

    my $n = int(( $percentile / 100 ) * $self->count() + 0.5) - 1;
    $n = 0 if $n < 0;
    return $self->[$n];
}

sub elapsed {
    my $self = shift;

    return sum(@$self) || 0;
}

sub rate {
    my $self = shift;

    return 0 unless $self->elapsed();
    return $self->count() / $self->elapsed();
}

1;

__END__

=head1 NAME

App::plackbench::Stats - Stores request times and generates stats

=head1 CLASS METHODS

=head2 new

Returns a new instance of the class. Takes zero or more times for the initial
list.

=head1 METHODS

=head2 C<insert($time)>

Inserts a number into the collection. The number will be inserted in order.

=head2 count

Returns the number of items in the collection.

=head2 elapsed

Returns the total time took waiting for the requests to complete.

=head2 rate

Returns the rate at which the requests were made (number of requests per second)

=head2 mean

Returns the mean. C<sum / count>

=head2 median

Returns the median.

=head2 min

Returns the smallest number in the collection.

=head2 max

Returns the largest number in the collection.

=head2 standard_deviation

Returns the standard deviation. L<http://en.wikipedia.org/wiki/Standard_deviation>.

=head2 C<percentile($n)>

Returns the number at percentile C<$n>.

=head2 SEE ALSO

L<plackbench>

