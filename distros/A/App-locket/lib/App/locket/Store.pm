package App::locket::Store;

use strict;
use warnings;

use Any::Moose;

has store => qw/ is ro required 1 isa HashRef /;

sub from {
    return shift->new( store => shift );
}

sub search {
    my $self = shift;
    my $query = shift;

    my @source = sort keys %{ $self->store };
    my @found;
    my $last_found = 0;
    my @clean_query;
    for my $target ( @$query ) {
        @found = sort grep { m/\Q$target\E/ } @source;
        if ( @found != $last_found ) {
            push @clean_query, $target;
            $last_found = @found;
        }
        if ( @found ) {
            @source = @found;
        }
        else {
            last;
        }
    }

    return {
        query => \@clean_query,
        found => \@found,
    };
}

sub all {
    my $self = shift;
    my @result = sort keys %{ $self->store };
    return @result;
}

sub get {
    my $self = shift;
    my $key = shift;
    return $self->store->{ $key };
}

1;
