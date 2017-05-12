package t::TestTask;

use List::Util qw(sum);

sub new {
    my ($class, @args) = @_;
    return bless [@args], $class;
}

sub run {
    my $self = shift;
    return sum(@$self);
}

1;
