package Database::Async::Backoff;

use strict;
use warnings;

our $VERSION = '0.019'; # VERSION

=head1 NAME

Database::Async::Backoff - support for backoff algorithms in L<Database::Async>

=head1 DESCRIPTION

=cut

use Future::AsyncAwait;
my %class_for_type;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}

sub initial_delay { shift->{initial_delay} }
sub max_delay { shift->{max_delay} }

async sub next {
    my ($self, $code) = @_;
    return $self->{delay} ||= 1;
}

async sub reset {
    my ($self) = @_;
    $self->{delay} = 0;
    $self
}

sub register {
    my ($class, %args) = @_;
    for my $k (keys %args) {
        $class_for_type{$k} = $args{$k}
    }
    $class
}

sub instantiate {
    my ($class, %args) = @_;
    my $type = delete $args{type}
        or die 'backoff type required';
    my $target_class = $class_for_type{$type}
        or die 'unknown backoff type ' . $type;
    return $target_class->new(%args);
}

1;

