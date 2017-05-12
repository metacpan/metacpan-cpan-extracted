package Algorithm::ConsistentHash::Ketama::Bucket;
use strict;

sub new {
    my ($class, %args) = @_;
    my $self = bless {%args}, $class;
    return $self;
}

sub label { $_[0]->{label} }
sub weight { $_[0]->{weight} }

1;

__END__

=head1 NAME

Algorithm::ConsistentHash::Ketama::Bucket - A Bucket Object

=head1 SYNOPSIS

    my @buckets = $ketama->buckets;

    my $bucket = shift @buckets;
    $bucket->label;
    $bucket->weight;

=head1 DESCRIPTION

This class simply represents a bucket in Algorithm::ConsistentnHash::Ketama.
There are no interface to add a bucket using this object. This class is just
a utility to represent this data.

=head1 METHODS

=head2 new

Creates a new bucket object

=head2 label

Returns the string label for this bucket

=head2 weight

Returns the weight of this bucket

=cut