package Brackup::ChunkIterator;
use strict;
use warnings;
use Carp qw(croak);

sub new {
    my ($class, @files) = @_;
    return bless {
        filelist => \@files,
        chunkmag => [],
    }, $class;
}

# returns either PositionedChunks, or, in cases of files
# without contents (like directories/symlinks), returns
# File objects... returns undef on end of files/chunks.
sub next {
    my $self = shift;

    # magazine already loaded?  fire.
    my $next = shift @{ $self->{chunkmag} };
    return $next if $next;

    # else reload...
    my $file = shift @{ $self->{filelist} } or
        return undef;

    ($next, @{$self->{chunkmag}}) = $file->chunks;
    return $next if $next;
    return $file;
}

sub mux_into {
    my ($self, $n_copies) = @_;
    my @iters;
    for (1..$n_copies) {
        push @iters, Brackup::ChunkIterator::SlaveIterator->new;
    }
    my $on_empty = sub {
        my $next = $self->next;
        foreach my $peer (@iters) {
            push @{$peer->{mag}}, $next;
        }
    };
    foreach (@iters) {
        $_->{on_empty} = $on_empty;
    }
    return @iters;
}

package Brackup::ChunkIterator::SlaveIterator;
use strict;
use warnings;
use Carp qw(croak);

sub new {
    my $class = shift;
    return bless {
        'on_empty' => undef, # subref
        'mag'      => [],
    }, $class;
}

sub next {
    my $self = shift;
    # the magazine itself could be true, but contain only undef: (undef),
    # which signals the end.
    return shift @{$self->{mag}} if @{$self->{mag}};
    $self->{on_empty}->();
    return shift @{$self->{mag}};
}

sub behind_by {
    my $self = shift;
    return scalar @{$self->{mag}};
}

1;
