package DBIx::Skinny::Pager::ResultSet;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = +{ %args };
    bless $self, $class;
    return $self;
}

sub iterator {
    $_[0]->{iterator};
}

sub pager {
    $_[0]->{pager};
}

1;
