package Age;
our $VERSION = '1.100840';
sub new { bless {}, shift }

sub comparable {
    my $self = shift;
    sprintf '%s years', $self->{age};
}
1;
