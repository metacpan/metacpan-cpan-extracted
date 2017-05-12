package DBIx::MoCo::Column::URI;
use strict;
use warnings;
use URI;

sub URI {
    my $self = shift;
    return URI->new($$self);
}

sub URI_as_string {
    my $class = shift;
    my $uri = shift or return;
    return $uri->as_string;
}

1;
