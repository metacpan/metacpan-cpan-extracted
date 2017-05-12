package Crypt::Sodium::GenericHash::State;

sub new {
    my ($class, %opts) = @_;
    return bless \%opts, $class;
}

1;