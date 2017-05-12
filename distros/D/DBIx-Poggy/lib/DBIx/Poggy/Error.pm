use strict;
use warnings;

package DBIx::Poggy::Error;

my @fields = qw(err errstr state);

sub new {
    my $proto = shift;
    my $dbh = shift || 'DBI';
    my $self = bless {}, ref($proto) || $proto;
    foreach my $f ( @fields ) {
        $self->{$f} = $dbh->$f();
    }
    return $self;
}

foreach my $f ( @fields ) {
    no strict 'refs';
    *{$f} = sub { return $_[0]->{$f} };
}

1;
